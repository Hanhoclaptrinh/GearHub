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

    async createPaymentUrl(orderId: string, ipAddr: string) {
        const order = await this.prisma.order.findUnique({
            where: { id: orderId },
        });

        if (!order) throw new NotFoundException('Đơn hàng không tồn tại');

        const paymentUrl = await this.vnpayGateway.createPayment({
            orderId: order.id,
            amount: Number(order.totalAmount),
            ipAddr
        });

        // tao bang ghi giao dich o trang thai pending
        await this.prisma.transaction.upsert({
            where: {
                orderId: order.id,
            },
            update: {
                amount: order.totalAmount,
                status: TransactionStatus.PENDING,
                provider: 'VNPAY',
                paymentMethod: PaymentMethod.PAYMENT_GATEWAY,
                createdAt: new Date(),
            },
            create: {
                orderId: order.id,
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
            // log received query parameters
            // this.logger.debug(`VNPay return query: ${JSON.stringify(query)}`);

            // kiem tra chu ky
            const isValid = await this.vnpayGateway.verifyReturn(query);
            if (!isValid) {
                // this.logger.warn('VNPay signature verification failed');
                return { success: false, message: 'Chữ ký không hợp lệ' };
            }

            const orderId = query['vnp_TxnRef'];
            const responseCode = query['vnp_ResponseCode'];
            const transactionNo = query['vnp_TransactionNo'];

            if (!orderId) {
                // this.logger.error('Missing vnp_TxnRef in VNPay response');
                return { success: false, message: 'Thiếu thông tin đơn hàng' };
            }

            // this.logger.log(`Processing payment - Order: ${orderId}, Response: ${responseCode}, TxnNo: ${transactionNo}`);

            // giao dich thanh cong khi responseCode = '00'
            if (responseCode === '00') {
                // lay thong tin don hang va item
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
                    // this.logger.error(`Order not found: ${orderId}`);
                    throw new NotFoundException('Đơn hàng không tồn tại');
                }

                // this.logger.debug(`Found order: ${order.id}, items count: ${order.items.length}`);

                // su dung transaction de cap nhat dong thoi
                const result = await this.prisma.$transaction(
                    async (tx) => {
                        // cap nhat transaction
                        // this.logger.log(`[STEP 1] Updating transaction for order: ${orderId}`);
                        const updatedTransaction = await tx.transaction.update({
                            where: { orderId: orderId },
                            data: {
                                status: TransactionStatus.SUCCESS,
                                providerTransactionId: transactionNo,
                                paymentDate: new Date(),
                            },
                        });
                        // this.logger.log(`Transaction updated - ID: ${updatedTransaction.id}, Status: SUCCESS, PaymentDate: ${updatedTransaction.paymentDate}`);

                        // cap nhat order
                        // this.logger.log(`[STEP 2] Updating order: ${orderId}`);
                        const updatedOrder = await tx.order.update({
                            where: { id: orderId },
                            data: {
                                paymentStatus: PaymentStatus.PAID,
                                paymentMethod: PaymentMethod.PAYMENT_GATEWAY,
                                status: OrderStatus.CONFIRMED
                            },
                        });
                        // this.logger.log(`Order updated - Status: ${updatedOrder.status}, PaymentStatus: ${updatedOrder.paymentStatus}, PaymentMethod: ${updatedOrder.paymentMethod}`);

                        // cap nhat soldCount cho tung product
                        let productUpdateCount = 0;
                        for (const item of order.items) {
                            if (!item.productVariant || !item.productVariant.product) {
                                // this.logger.warn(`Skipping item - missing product variant or product data`);
                                continue;
                            }

                            const product = item.productVariant.product;
                            const newSoldCount = (product.soldCount || 0) + item.quantity;

                            // this.logger.log(`[STEP 3.${productUpdateCount + 1}] Updating product: ${product.id} (${product.name}), qty: ${item.quantity}`);
                            const updatedProduct = await tx.product.update({
                                where: { id: product.id },
                                data: {
                                    soldCount: newSoldCount
                                }
                            });
                            // this.logger.log(`✓ Product updated - ID: ${updatedProduct.id}, Sold: ${updatedProduct.soldCount}`);
                            productUpdateCount++;
                        }

                        if (productUpdateCount === 0) {
                            // this.logger.warn(`Warning: No products were updated for order ${orderId}`);
                        }

                        // tao order tracking
                        this.logger.log(`[STEP 4] Creating order tracking`);
                        const tracking = await tx.orderTracking.create({
                            data: {
                                orderId: orderId,
                                statusLabel: 'Thanh toán thành công',
                                description: `Thanh toán ${Number(order.totalAmount).toLocaleString('vi-VN')} VND qua VNPay thành công - Transaction ID: ${transactionNo}`
                            }
                        });
                        // this.logger.log(`✓ OrderTracking created - ID: ${tracking.id}`);

                        return { orderId, transactionId: updatedTransaction.id, productCount: productUpdateCount };
                    },
                    {
                        timeout: 30000, // 30 seconds timeout
                    }
                );

                // this.logger.log(`Payment processed successfully - Order: ${orderId}, Transactions: 1, Products: ${result.productCount}`);
                return { success: true, orderId };
            }

            // this.logger.warn(`Payment failed - Order: ${orderId}, ResponseCode: ${responseCode}`);

            // update transaction status thanh FAILED neu response code khac '00'
            if (responseCode && responseCode !== '00') {
                try {
                    await this.prisma.transaction.update({
                        where: { orderId: orderId },
                        data: {
                            status: TransactionStatus.FAILED,
                            providerTransactionId: transactionNo,
                        },
                    });
                    // this.logger.log(`Transaction marked as FAILED: ${orderId}, Code: ${responseCode}`);
                } catch (updateError) {
                    // this.logger.error(`Error updating failed transaction: ${updateError}`);
                }
            }

            return { success: false, message: 'Thanh toán thất bại' };
        } catch (error) {
            // this.logger.error(`Error processing VNPay return: ${error.message}`, error.stack);
            return { success: false, message: error.message || 'Lỗi xử lý thanh toán' };
        }
    }
}
