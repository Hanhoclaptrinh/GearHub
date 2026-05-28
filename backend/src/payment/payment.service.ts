import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { VnPayGateway } from './gateway/vnpay.gateway';
import { PrismaService } from 'src/prisma/prisma.service';
import { OrderStatus, PaymentMethod, PaymentStatus, TransactionStatus, NotificationType, InventoryTransactionType } from '@prisma/client';
import { PromotionService } from 'src/promotion/promotion.service';
import { NotificationService } from 'src/notification/notification.service';
import { InventoriesService } from 'src/inventories/inventories.service';
import moment from 'moment';

@Injectable()
export class PaymentService {
    private readonly logger = new Logger(PaymentService.name);

    constructor(
        private prisma: PrismaService,
        private promotionService: PromotionService,
        private vnpayGateway: VnPayGateway,
        private notificationService: NotificationService,
        private inventoriesService: InventoriesService,
    ) { }

    /**
     * tạo đường dẫn thanh toán vnpay cho đơn hàng
     * hàm này sẽ kiểm tra trạng thái đơn hàng, gọi gateway để sinh url thanh toán
     * đồng thời khởi tạo hoặc cập nhật transaction ở trạng thái chờ
     */
    async createPaymentUrl(orderId: string, ipAddr: string, platform: string = 'web') {
        // nội dung mô tả giao dịch thanh toán
        const description = `Gearhub thanh toan don hang #${orderId.slice(0, 8)}`;

        const order = await this.prisma.order.findUnique({
            where: { id: orderId },
        });
        if (!order) throw new NotFoundException('Đơn hàng không tồn tại');

        // chặn thanh toán nếu đơn hàng đã được thanh toán trước đó
        if (order.paymentStatus === PaymentStatus.PAID) {
            throw new BadRequestException('Đơn hàng đã được thanh toán');
        }

        // chặn thanh toán nếu đơn hàng đã bị hủy
        if (order.status === OrderStatus.CANCELLED) {
            throw new BadRequestException('Đơn hàng đã bị hủy');
        }

        // gọi gateway vnpay để sinh link thanh toán
        const paymentUrl = await this.vnpayGateway.createPayment({
            orderId: order.id,
            amount: Number(order.totalAmount),
            ipAddr,
            orderInfo: description,
            platform
        });

        // tạo hoặc cập nhật bản ghi giao dịch sang trạng thái pending
        await this.prisma.transaction.upsert({
            where: {
                orderId: order.id,
            },
            update: {
                description: description,
                amount: order.totalAmount,
                status: TransactionStatus.PENDING,
                provider: 'VNPAY',
                paymentMethod: PaymentMethod.PAYMENT_GATEWAY,
                createdAt: new Date(),
            },
            create: {
                orderId: order.id,
                description: description,
                amount: order.totalAmount,
                paymentMethod: PaymentMethod.PAYMENT_GATEWAY,
                status: TransactionStatus.PENDING,
                provider: 'VNPAY',
            },
        });

        return { paymentUrl };
    }

    /**
     * thực hiện hoàn tiền đơn hàng qua cổng vnpay
     * kiểm tra tính hợp lệ của đơn hàng và giao dịch cũ, lấy ngày giao dịch
     * call api hoàn tiền của vnpay gateway, và cập nhật trạng thái cơ sở dữ liệu nếu thành công
     */
    async refundOrder(orderId: string, adminEmail: string, ipAddr: string) {
        // tìm thông tin đơn hàng cùng giao dịch đi kèm
        const order = await this.prisma.order.findUnique({
            where: { id: orderId },
            include: { transaction: true }
        });
        if (!order) {
            throw new NotFoundException('Đơn hàng không tồn tại');
        }

        // chỉ hoàn tiền cho đơn hàng đã thanh toán thành công và chưa được hoàn
        if (order.paymentStatus !== PaymentStatus.PAID) {
            throw new BadRequestException('Đơn hàng chưa được thanh toán hoặc đã được hoàn tiền');
        }

        // kiểm tra giao dịch gốc có tồn tại và thành công hay không
        const transaction = order.transaction;
        if (!transaction || transaction.status !== TransactionStatus.SUCCESS) {
            throw new BadRequestException('Không tìm thấy giao dịch thanh toán thành công cho đơn hàng này');
        }

        // chỉ hỗ trợ hoàn tiền tự động đối với các giao dịch thanh toán qua vnpay
        if (transaction.provider !== 'VNPAY') {
            throw new BadRequestException('Phương thức thanh toán này không hỗ trợ hoàn tiền tự động qua VNPay');
        }

        let transactionDate = moment(transaction.paymentDate || transaction.createdAt).format('YYYYMMDDHHmmss');
        try {
            if (transaction.rawResponse) {
                const raw = JSON.parse(transaction.rawResponse);
                if (raw && raw['vnp_PayDate']) {
                    transactionDate = raw['vnp_PayDate'];
                }
            }
        } catch (e) {
            this.logger.error(`Error parsing transaction rawResponse: ${e.message}`);
        }

        // gửi yêu cầu hoàn tiền toàn phần sang gateway
        const refundRes = await this.vnpayGateway.fullRefund({
            orderId,
            amount: Number(order.totalAmount),
            ipAddr,
            transactionNo: transaction.providerTransactionId || '',
            transactionDate,
            createBy: adminEmail
        });

        // kiểm tra mã phản hồi trả về từ cổng thanh toán vnpay
        const responseCode = refundRes['vnp_ResponseCode'];
        if (responseCode !== '00') {
            throw new BadRequestException(`Yêu cầu hoàn tiền VNPay thất bại: ${refundRes['vnp_Message'] || responseCode}`);
        }

        await this.prisma.$transaction(async (tx) => {
            // hoàn trả voucher cho user
            const userVoucher = await tx.userVoucher.findFirst({
                where: { orderId },
            });
            if (userVoucher) {
                if (userVoucher.usedAt) {
                    // giảm số lượt sử dụng của voucher đi khi đã dùng thành công
                    await tx.voucher.update({
                        where: { id: userVoucher.voucherId },
                        data: { usedCount: { decrement: 1 } },
                    });
                }
                await tx.userVoucher.update({
                    where: { id: userVoucher.id },
                    data: { usedAt: null, orderId: null },
                });
            }

            // cộng lại số lượng stock sản phẩm
            const orderItems = await tx.orderItem.findMany({
                where: { orderId },
            });
            for (const item of orderItems) {
                await this.inventoriesService.adjustStock({
                    variantId: item.productVariantId,
                    type: InventoryTransactionType.ORDER_CANCEL,
                    quantity: item.quantity,
                    referenceId: orderId,
                    reason: `Hoàn kho khi hoàn tiền đơn hàng #${orderId.slice(0, 8)}`,
                    tx,
                });
            }

            // tiền đã hoàn trả - mark giao dịch thành refunded
            await tx.transaction.update({
                where: { orderId },
                data: {
                    status: TransactionStatus.REFUNDED,
                    description: `Đã hoàn trả tiền giao dịch thành công`
                }
            });

            // trạng thái thanh toán - refunded
            await tx.order.update({
                where: { id: orderId },
                data: {
                    paymentStatus: PaymentStatus.REFUNDED,
                    status: OrderStatus.CANCELLED
                }
            });

            // tracking đơn hàng ghi nhận việc hoàn tiền thành công
            await tx.orderTracking.create({
                data: {
                    orderId,
                    statusLabel: 'Đã hoàn tiền',
                    description: `Đã hoàn tiền thành công số tiền ${Number(order.totalAmount).toLocaleString('vi-VN')} VND qua cổng VNPay`
                }
            });
        });

        // gửi thông báo đẩy cho khách hàng
        try {
            await this.notificationService.sendToUser(order.userId, {
                notification: {
                    title: 'Đơn hàng đã được hoàn tiền',
                    body: `Đơn hàng #${order.id.slice(0, 8)} đã được hoàn tiền thành công số tiền ${Number(order.totalAmount).toLocaleString('vi-VN')} VND`,
                },
                data: {
                    type: 'order',
                    orderId: order.id,
                },
                type: NotificationType.ORDER,
            });
        } catch (error) {
            this.logger.error(`Lỗi gửi push notification cho user ${order.userId}: ${error.message}`);
        }

        return { success: true, message: 'Hoàn tiền thành công', data: refundRes };
    }

    /**
     * xử lý callback chuyển hướng từ vnpay sau khi người dùng thực hiện thanh toán
     * 
     * thực hiện xác thực chữ ký bảo mật (checksum) từ vnpay, kiểm tra mã đơn hàng
     * và tiến hành cập nhật trạng thái thanh toán để hiển thị kết quả trên giao diện client
     */
    async processVnpayReturn(query: any) {
        try {
            // xác thực chữ ký bảo mật (secure hash) của dữ liệu callback trả về từ vnpay
            const isValid = await this.vnpayGateway.verifyReturn(query);
            if (!isValid) {
                return { success: false, message: 'Chữ ký không hợp lệ' };
            }

            // trích xuất mã đơn hàng (vnp_TxnRef) để kiểm tra sự tồn tại của giao dịch
            const orderId = query['vnp_TxnRef'];
            if (!orderId) {
                return { success: false, message: 'Thiếu thông tin đơn hàng' };
            }

            // tiến hành xác nhận và cập nhật trạng thái đơn hàng
            return await this.confirmPayment(query);
        } catch (error) {
            this.logger.error(`Error in vnpayReturn: ${error.message}`, error.stack);
            return { success: false, message: error.message || 'Lỗi xử lý thanh toán' };
        }
    }

    /**
     * xử lý webhook Instant Payment Notification (IPN) từ vnpay gửi đến (server-to-server)
     * 
     * dùng để cập nhật trạng thái đơn hàng tự động ngay cả khi người dùng
     * tắt trình duyệt khi đang thanh toán. Hàm này tuân thủ quy chuẩn kiểm tra bảo mật của vnpay:
     * xác thực chữ ký bảo mật (checksum) để tránh dữ liệu bị thay đổi trên đường truyền
     * kiểm tra sự tồn tại của mã đơn hàng (vnp_TxnRef) trong hệ thống database
     * so khớp số tiền thanh toán thực tế nhận từ vnpay với giá trị đơn hàng được lưu trong hệ thống (x100)
     * kiểm tra trạng thái đơn hàng hiện tại để tránh việc cập nhật trùng lặp
     * tiến hành lưu và cập nhật kết quả thanh toán
     */
    async processVnpayIpn(query: any) {
        try {
            // xác thực chữ ký bảo mật (checksum) của vnpay để đảm bảo gói tin toàn vẹn và đến từ nguồn tin cậy
            const isValid = await this.vnpayGateway.verifyReturn(query);
            if (!isValid) {
                return { RspCode: '97', Message: 'Chữ ký không hợp lệ' };
            }

            const orderId = query['vnp_TxnRef'];
            const vnpAmount = Number(query['vnp_Amount']);

            // kiểm tra sự hiện diện của mã đơn hàng nhận từ webhook
            if (!orderId) {
                return { RspCode: '01', Message: 'Đơn hàng không tồn tại' };
            }

            // truy vấn đơn hàng từ db để đối chiếu thông tin
            const order = await this.prisma.order.findUnique({
                where: { id: orderId },
            });

            // đảm bảo đơn hàng thực sự tồn tại trong hệ thống
            if (!order) {
                return { RspCode: '01', Message: 'Đơn hàng không tồn tại' };
            }

            // kiểm tra số tiền: số tiền vnpay gửi về = tiền gốc * 100
            if (Math.floor(Number(order.totalAmount) * 100) !== vnpAmount) {
                return { RspCode: '04', Message: 'Số tiền thanh toán không khớp' };
            }

            // kiểm tra trạng thái: tránh cập nhật đè khi đơn hàng đã được xử lý thanh toán trước đó
            if (order.paymentStatus === PaymentStatus.PAID) {
                return { RspCode: '02', Message: 'Đơn hàng đã được thanh toán' };
            }

            // thực hiện cập nhật trạng thái đơn hàng, trừ kho, áp dụng voucher...
            const result = await this.confirmPayment(query);
            if (result.success) {
                return { RspCode: '00', Message: 'Thanh toán thành công' };
            } else {
                return { RspCode: '99', Message: result.message || 'Lỗi xử lý thanh toán' };
            }
        } catch (error) {
            this.logger.error(`Error in vnpayIpn: ${error.message}`, error.stack);
            return { RspCode: '99', Message: error.message || 'Lỗi xử lý thanh toán' };
        }
    }

    /**
     * xác nhận kết quả thanh toán từ vnpay gửi về
     * kiểm tra tính hợp lệ của đơn hàng và số tiền giao dịch, nếu thành công (res code = 00)
     * thực hiện cập nhật trạng thái giao dịch, đơn hàng, áp dụng voucher, tăng soldcount và ghi nhận lịch sử đơn hàng
     */
    private async confirmPayment(query: any) {
        const orderId = query['vnp_TxnRef'];
        const transactionNo = query['vnp_TransactionNo'];
        const vnpAmount = Number(query['vnp_Amount']);
        const responseCode = query['vnp_ResponseCode'];

        // tìm kiếm đơn hàng cùng các sản phẩm chi tiết trong đơn hàng để cập nhật kho
        const order = await this.prisma.order.findUnique({
            where: { id: orderId },
            include: {
                items: {
                    include: {
                        productVariant: {
                            include: { product: true }
                        }
                    }
                }
            }
        });

        if (!order) {
            throw new NotFoundException('Đơn hàng không tồn tại');
        }

        // so khớp số tiền thực tế của đơn hàng với số tiền vnpay phản hồi
        if (Math.floor(Number(order.totalAmount) * 100) !== vnpAmount) {
            return { success: false, message: 'Số tiền thanh toán không khớp' };
        }

        // nếu đơn hàng đã ở trạng thái đã thanh toán thì bỏ qua các bước xử lý sau
        if (order.paymentStatus === PaymentStatus.PAID) {
            return { success: true, orderId };
        }

        // xử lý cập nhật trạng thái khi giao dịch thanh toán thành công
        if (responseCode === '00') {
            await this.prisma.$transaction(
                async (tx) => {
                    // cập nhật trạng thái giao dịch sang thành công và lưu thông tin đối soát từ vnpay
                    await tx.transaction.update({
                        where: { orderId: orderId },
                        data: {
                            status: TransactionStatus.SUCCESS,
                            providerTransactionId: transactionNo,
                            transactionCode: transactionNo,
                            description: query['vnp_OrderInfo'],
                            paymentDate: new Date(),
                            rawResponse: JSON.stringify(query)
                        },
                    });

                    // cập nhật đơn hàng thành đã thanh toán và xác nhận đơn hàng
                    await tx.order.update({
                        where: { id: orderId },
                        data: {
                            paymentStatus: PaymentStatus.PAID,
                            paymentMethod: PaymentMethod.PAYMENT_GATEWAY,
                            status: OrderStatus.CONFIRMED
                        },
                    });

                    // đánh dấu voucher giảm giá đã được sử dụng nếu có áp dụng voucher
                    const userVoucher = await tx.userVoucher.findUnique({
                        where: { orderId: orderId }
                    });
                    if (userVoucher) {
                        await this.promotionService.markVoucherUsed(order.userId, userVoucher.voucherId, orderId, tx);
                    }

                    // cập nhật soldcount cho từng item trong đơn hàng
                    for (const item of order.items) {
                        if (!item.productVariant || !item.productVariant.product) continue;
                        const product = item.productVariant.product;
                        await tx.product.update({
                            where: { id: product.id },
                            data: {
                                soldCount: { increment: item.quantity }
                            }
                        });
                    }

                    // tracking
                    await tx.orderTracking.create({
                        data: {
                            orderId: orderId,
                            statusLabel: 'Thanh toán thành công',
                            description: `Thanh toán ${Number(order.totalAmount).toLocaleString('vi-VN')} VND qua VNPay thành công - Transaction ID: ${transactionNo}`
                        }
                    });
                },
                { timeout: 30000 }
            );
            return { success: true, orderId };
        } else {
            await this.prisma.transaction.update({
                where: { orderId: orderId },
                data: {
                    status: TransactionStatus.FAILED,
                    providerTransactionId: transactionNo,
                    rawResponse: JSON.stringify(query)
                },
            }).catch(() => { });
            return { success: false, message: 'Thanh toán thất bại' };
        }
    }

    async getAllTransactions(query: {
        page?: number;
        limit?: number;
        search?: string;
        paymentMethod?: PaymentMethod;
        status?: TransactionStatus;
        startDate?: string;
        endDate?: string;
    }) {
        const { page = 1, limit = 10, search, paymentMethod, status, startDate, endDate } = query;
        const skip = (page - 1) * limit;

        const where: any = {};
        if (search) {
            where.OR = [
                { transactionCode: { contains: search } },
                { orderId: { contains: search } },
            ];
        }

        if (paymentMethod) {
            where.paymentMethod = paymentMethod;
        }

        if (status) {
            where.status = status;
        }

        if (startDate || endDate) {
            where.createdAt = {};
            if (startDate) {
                where.createdAt.gte = new Date(startDate);
            }
            if (endDate) {
                const d = new Date(endDate);
                d.setHours(23, 59, 59, 999);
                where.createdAt.lte = d;
            }
        }

        const [items, total] = await Promise.all([
            this.prisma.transaction.findMany({
                where,
                skip,
                take: Number(limit),
                include: {
                    order: {
                        include: {
                            user: {
                                select: {
                                    email: true
                                }
                            },
                            items: true
                        }
                    }
                },
                orderBy: { createdAt: 'desc' }
            }),
            this.prisma.transaction.count({ where })
        ]);

        return {
            data: items,
            meta: {
                total,
                page: Number(page),
                limit: Number(limit),
                lastPage: Math.ceil(total / Number(limit))
            }
        };
    }
}
