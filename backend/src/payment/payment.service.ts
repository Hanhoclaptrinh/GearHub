import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { VnPayGateway } from './gateway/vnpay.gateway';
import { PrismaService } from 'src/prisma/prisma.service';
import { OrderStatus, PaymentMethod, PaymentStatus, TransactionStatus } from '@prisma/client';

@Injectable()
export class PaymentService {
    private readonly logger = new Logger(PaymentService.name);

    constructor(
        private prisma: PrismaService,
        private vnpayGateway: VnPayGateway
    ) { }

    async createPaymentUrl(orderId: string, ipAddr: string, platform: string = 'web') {
        const description = `Gearhub thanh toan don hang #${orderId.slice(0, 8)}`;

        const order = await this.prisma.order.findUnique({
            where: { id: orderId },
        });

        if (!order) throw new NotFoundException('Đơn hàng không tồn tại');

        if (order.paymentStatus === PaymentStatus.PAID) {
            throw new BadRequestException('Đơn hàng đã được thanh toán');
        }

        if (order.status === OrderStatus.CANCELLED) {
            throw new BadRequestException('Đơn hàng đã bị hủy');
        }

        const paymentUrl = await this.vnpayGateway.createPayment({
            orderId: order.id,
            amount: Number(order.totalAmount),
            ipAddr,
            orderInfo: description,
            platform
        });

        // tao bang ghi giao dich o trang thai pending
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

    async processVnpayReturn(query: any) {
        try {
            const isValid = await this.vnpayGateway.verifyReturn(query);
            if (!isValid) {
                return { success: false, message: 'Chữ ký không hợp lệ' };
            }

            const orderId = query['vnp_TxnRef'];
            if (!orderId) {
                return { success: false, message: 'Thiếu thông tin đơn hàng' };
            }

            return await this.confirmPayment(query);
        } catch (error) {
            this.logger.error(`Error in vnpayReturn: ${error.message}`, error.stack);
            return { success: false, message: error.message || 'Lỗi xử lý thanh toán' };
        }
    }

    async processVnpayIpn(query: any) {
        try {
            const isValid = await this.vnpayGateway.verifyReturn(query);
            if (!isValid) {
                return { RspCode: '97', Message: 'Chữ ký không hợp lệ' };
            }

            const orderId = query['vnp_TxnRef'];
            const responseCode = query['vnp_ResponseCode'];
            const vnpAmount = Number(query['vnp_Amount']);

            if (!orderId) {
                return { RspCode: '01', Message: 'Đơn hàng không tồn tại' };
            }

            const order = await this.prisma.order.findUnique({
                where: { id: orderId },
            });

            if (!order) {
                return { RspCode: '01', Message: 'Đơn hàng không tồn tại' };
            }

            if (Math.floor(Number(order.totalAmount) * 100) !== vnpAmount) {
                return { RspCode: '04', Message: 'Số tiền thanh toán không khớp' };
            }

            if (order.paymentStatus === PaymentStatus.PAID) {
                return { RspCode: '02', Message: 'Đơn hàng đã được thanh toán' };
            }

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

    private async confirmPayment(query: any) {
        const orderId = query['vnp_TxnRef'];
        const transactionNo = query['vnp_TransactionNo'];
        const vnpAmount = Number(query['vnp_Amount']);
        const responseCode = query['vnp_ResponseCode'];

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

        if (Math.floor(Number(order.totalAmount) * 100) !== vnpAmount) {
            return { success: false, message: 'Số tiền thanh toán không khớp' };
        }

        if (order.paymentStatus === PaymentStatus.PAID) {
            return { success: true, orderId };
        }

        if (responseCode === '00') {
            await this.prisma.$transaction(
                async (tx) => {
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

                    await tx.order.update({
                        where: { id: orderId },
                        data: {
                            paymentStatus: PaymentStatus.PAID,
                            paymentMethod: PaymentMethod.PAYMENT_GATEWAY,
                            status: OrderStatus.CONFIRMED
                        },
                    });

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
            }).catch(() => {});
            return { success: false, message: 'Thanh toán thất bại' };
        }
    }

    async getAllTransactions(query: { page?: number; limit?: number; search?: string }) {
        const { page = 1, limit = 10, search } = query;
        const skip = (page - 1) * limit;

        const where: any = {};
        if (search) {
            where.OR = [
                { transactionCode: { contains: search } },
                { orderId: { contains: search } },
            ];
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
