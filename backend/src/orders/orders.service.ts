import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { CartService } from 'src/cart/cart.service';
import { PrismaService } from 'src/prisma/prisma.service';
import { ProductsService } from 'src/products/products.service';
import { ActivityLogService } from 'src/activity-log/activity-log.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { OrderStatus, Prisma, Role, PaymentStatus, PaymentMethod, TransactionStatus } from '@prisma/client';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';

@Injectable()
export class OrdersService {
    constructor(
        private prisma: PrismaService,
        private productService: ProductsService,
        private cartService: CartService,
        private activityLogService: ActivityLogService
    ) { }

    async createOrder(userId: string, data: CreateOrderDto) {
        const { items, ...shippingInfor } = data;
        const variantIds = items.map(i => i.variantId);

        return await this.prisma.$transaction(async (tx) => {
            // lay thong tin variant truc tiep tu db
            const variants = await tx.productVariant.findMany({
                where: { id: { in: variantIds } },
                include: {
                    product: { select: { name: true } }
                }
            });

            if (variants.length !== items.length) {
                throw new NotFoundException('Một số sản phẩm không tồn tại trong hệ thống');
            }

            // tinh tong tien va kiem tra stock trong kho
            let totalAmount = 0;
            const orderItemsData = items.map(item => {
                const variant = variants.find(v => v.id === item.variantId);
                if (!variant) {
                    throw new NotFoundException(`Sản phẩm với ID ${item.variantId} không tồn tại`);
                }

                // kiem tra kho
                if (variant.stock < item.quantity) {
                    throw new BadRequestException(`Sản phẩm ${variant.name} chỉ còn ${variant.stock} sản phẩm`);
                }

                totalAmount += Number(variant.price) * item.quantity;

                return {
                    productVariantId: item.variantId,
                    quantity: item.quantity,
                    priceAtPurchase: variant.price, // gia tai thoi diem mua hang
                    productName: variant.product.name,
                    variantName: variant.name
                };
            });

            // tinh thue VAT 10%
            const vatAmount = totalAmount * 0.1;
            const finalTotal = totalAmount + vatAmount;

            // tao order
            const order = await tx.order.create({
                data: {
                    userId,
                    totalAmount: finalTotal,
                    ...shippingInfor,
                    items: {
                        create: orderItemsData
                    },
                    tracking: {
                        create: {
                            statusLabel: 'Đặt hàng thành công',
                            description: 'Đơn hàng đã được hệ thống tiếp nhận và đang chờ xử lý'
                        }
                    }
                }
            });

            // tru stock trong kho
            for (const item of items) {
                const variant = variants.find(v => v.id === item.variantId);
                const result = await tx.productVariant.updateMany({
                    where: { id: item.variantId, stock: { gte: item.quantity } },
                    data: {
                        stock: { decrement: item.quantity }
                    }
                });
                if (result.count === 0) {
                    throw new BadRequestException(`Sản phẩm ${variant?.name || item.variantId} không đủ tồn kho`);
                }
            }

            // don gio hang
            // xoa cac sp da mua
            await tx.cartItem.deleteMany({
                where: {
                    cart: { userId },
                    productVariantId: { in: variantIds }
                }
            });

            return order;
        });
    }

    async getMyOrders(userId: string, query: { page?: number; limit?: number; status?: OrderStatus }) {
        const { page = 1, limit = 10, status } = query;
        const skip = (page - 1) * limit;

        const [orders, total] = await Promise.all([
            this.prisma.order.findMany({
                where: {
                    userId,
                    ...(status && { status }) // loc theo status
                },
                include: {
                    items: {
                        include: {
                            productVariant: {
                                include: {
                                    product: {
                                        select: {
                                            name: true,
                                            thumbnailUrl: true
                                        }
                                    }
                                }
                            }
                        }
                    }
                },
                orderBy: { createdAt: 'desc' },
                skip,
                take: Number(limit)
            }),
            this.prisma.order.count({ where: { userId, ...(status && { status }) } })
        ]);

        return {
            data: orders,
            meta: {
                total,
                page,
                lastPage: Math.ceil(total / limit)
            }
        };
    }

    // all order admin
    async getAllOrders(
        query: {
            page?: number;
            limit?: number;
            status?: OrderStatus;
            search?: string
        }
    ) {
        const {
            page = 1,
            limit = 10,
            status,
            search
        } = query;
        const skip = (page - 1) * limit;

        const whereCondition: any = {
            ...(status && { status }),
            ...(search && {
                OR: [
                    { id: { contains: search } },
                    { receiverName: { contains: search } },
                    { receiverPhone: { contains: search } },
                ]
            })
        };

        const [orders, total] = await Promise.all([
            this.prisma.order.findMany({
                where: whereCondition,
                include: {
                    user: {
                        select: {
                            email: true,
                            profile: {
                                select: { fullName: true }
                            }
                        }
                    },
                    _count: { select: { items: true } }
                },
                orderBy: { createdAt: 'desc' },
                skip,
                take: Number(limit)
            }),

            this.prisma.order.count({ where: whereCondition })
        ]);

        return {
            data: orders,
            meta: {
                total,
                page,
                lastPage: Math.ceil(total / limit),
            },
        };
    }

    async getOrderDetail(userId: string, id: string) {
        const order = await this.prisma.order.findFirst({
            where: {
                id,
                userId
            },
            include: {
                items: {
                    include: {
                        productVariant: {
                            include: {
                                product: {
                                    select: {
                                        name: true,
                                        thumbnailUrl: true
                                    }
                                }
                            }
                        }
                    }
                },
                tracking: {
                    orderBy: { createdAt: 'asc' }
                },
                transaction: true
            }
        });

        if (!order) throw new NotFoundException('Không tìm thấy đơn hàng này');

        return order;
    }

    async updateOrderStatus(orderId: string, data: UpdateOrderStatusDto) {
        const { status, description } = data;
        return await this.prisma.$transaction(async (tx) => {
            const order = await tx.order.findUnique({
                where: { id: orderId },
                include: { items: true }
            });
            if (!order) throw new NotFoundException('Không tìm thấy đơn hàng');

            // hoan kho neu don hang bi huy hoac khach tra hang hoac giao hang that bai
            const refundStatuses: OrderStatus[] = [OrderStatus.CANCELLED, OrderStatus.RETURNED, OrderStatus.FAILED];
            const isNewRefundStatus = refundStatuses.includes(status as OrderStatus);
            const isCurrentRefundStatus = refundStatuses.includes(order.status as OrderStatus);

            if (isNewRefundStatus && !isCurrentRefundStatus) {
                for (const item of order.items) {
                    await tx.productVariant.update({
                        where: { id: item.productVariantId },
                        data: { stock: { increment: item.quantity } }
                    });
                }
            } else if (!isNewRefundStatus && isCurrentRefundStatus) {
                // hoan lai kho neu don hang chuyen tu trang thai huy/tra ve trang thai dang xu ly
                for (const item of order.items) {
                    const variant = await tx.productVariant.findUnique({
                        where: { id: item.productVariantId },
                        select: { stock: true, name: true }
                    });
                    if (!variant) throw new NotFoundException(`Sản phẩm variant ${item.productVariantId} không tồn tại`);
                    if (variant.stock < item.quantity) {
                        throw new BadRequestException(`Sản phẩm ${variant.name} không đủ tồn kho để khôi phục đơn hàng (Hiện còn: ${variant.stock})`);
                    }
                    await tx.productVariant.update({
                        where: { id: item.productVariantId },
                        data: { stock: { decrement: item.quantity } }
                    });
                }
            }

            // cap nhat trang thai don hang
            const updatedOrder = await tx.order.update({
                where: { id: orderId },
                data: { status }
            });

            if (isNewRefundStatus) {
                if (order.paymentStatus === PaymentStatus.PAID) {
                    await tx.order.update({
                        where: { id: orderId },
                        data: { paymentStatus: PaymentStatus.REFUNDED }
                    });

                    await tx.transaction.updateMany({
                        where: { orderId: orderId },
                        data: { status: TransactionStatus.FAILED }
                    });
                }
            } else if (status === OrderStatus.DELIVERED && order.paymentMethod === PaymentMethod.COD) {
                await tx.order.update({
                    where: { id: orderId },
                    data: { paymentStatus: PaymentStatus.PAID }
                });

                await tx.transaction.upsert({
                    where: { orderId: orderId },
                    update: {
                        status: TransactionStatus.SUCCESS,
                        amount: order.totalAmount,
                        provider: 'CASH',
                        paymentMethod: order.paymentMethod,
                        description: `Thanh toán COD cho đơn hàng #${orderId.slice(0, 8)}`,
                        paymentDate: new Date(),
                    },
                    create: {
                        orderId: orderId,
                        status: TransactionStatus.SUCCESS,
                        amount: order.totalAmount,
                        provider: 'CASH',
                        paymentMethod: order.paymentMethod,
                        description: `Thanh toán COD cho đơn hàng #${orderId.slice(0, 8)}`,
                        paymentDate: new Date(),
                    }
                });
            }

            // tracking cho khach theo doi
            await tx.orderTracking.create({
                data: {
                    orderId,
                    statusLabel: this.mapStatusToLabel(status),
                    description: description || `Đơn hàng đã được chuyển sang trạng thái ${status}`
                }
            });

            return updatedOrder;
        });
    }

    private mapStatusToLabel(status: OrderStatus): string {
        const labels = {
            [OrderStatus.PENDING]: 'Chờ xác nhận',
            [OrderStatus.CONFIRMED]: 'Đã xác nhận',
            [OrderStatus.PROCESSING]: 'Đang đóng gói',
            [OrderStatus.SHIPPING]: 'Đang giao hàng',
            [OrderStatus.DELIVERED]: 'Giao hàng thành công',
            [OrderStatus.CANCELLED]: 'Đã hủy đơn',
            [OrderStatus.RETURNED]: 'Khách trả hàng',
            [OrderStatus.FAILED]: 'Giao hàng thất bại',
        };
        return labels[status] || status;
    }

    // user huy don hang
    async cancelOrder(userId: string, id: string) {
        return await this.prisma.$transaction(async (tx) => {
            const order = await tx.order.findFirst({
                where: {
                    id, userId
                },
                include: { items: true }
            });
            if (!order) throw new NotFoundException('Đơn hàng không tồn tại');
            if (order.status !== OrderStatus.PENDING) {
                throw new BadRequestException('Chỉ có thể hủy đơn hàng đang chờ xác nhận');
            }

            // hoan kho
            for (const item of order.items) {
                await tx.productVariant.update({
                    where: { id: item.productVariantId },
                    data: {
                        stock: { increment: item.quantity }
                    }
                });
            }

            // cap nhat lai trang thai don hang
            const updatedOrder = await tx.order.update({
                where: { id },
                data: { status: OrderStatus.CANCELLED }
            });

            // tracking
            await tx.orderTracking.create({
                data: {
                    orderId: id,
                    statusLabel: 'Đã hủy đơn',
                    description: 'Đơn hàng đã được hủy bởi người mua'
                }
            });

            return updatedOrder;
        });
    }

    async getTopSellingProducts(limit = 5) {
        const topItems = await this.prisma.orderItem.groupBy({
            by: ['productVariantId'],
            _sum: { quantity: true },
            orderBy: {
                _sum: { quantity: 'desc' }
            },
            take: limit,
        });

        const details = await Promise.all(
            topItems.map(async (item) => {
                const variant = await this.prisma.productVariant.findUnique({
                    where: { id: item.productVariantId },
                    select: { name: true, product: { select: { name: true } } }
                });

                return {
                    ...variant,
                    totalSold: item._sum.quantity
                }
            })
        );
        return details;
    }

    async getAdminStats() {
        const [revenue, orderCounts, userCount, lowStockVariants, latestLogs] = await Promise.all([
            // tong doanh thu tu cac don hang da thanh toan (paymentStatus = PAID)
            this.prisma.order.aggregate({
                _sum: { totalAmount: true },
                where: { paymentStatus: PaymentStatus.PAID }
            }),

            // dem so luong don hang theo tung trang thai
            this.prisma.order.groupBy({
                by: ['status'],
                _count: { id: true }
            }),

            // tong so khach hang da dang ky
            this.prisma.user.count({
                where: { role: Role.USER }
            }),

            // san pham sap het hang (stock < 10)
            this.prisma.productVariant.count({
                where: { stock: { lt: 10 } }
            }),

            // lay 7 log gan nhat
            this.activityLogService.findAll({ page: 1, limit: 7 })
        ]);

        const formattedOrders = orderCounts.reduce((acc, curr) => {
            acc[curr.status] = curr._count.id;
            return acc;
        }, {});

        // fetch revenue & orders trend data (last 7 days)
        const trends = await this.getTrends(7);

        return {
            totalRevenue: revenue._sum.totalAmount || 0,
            ordersByStatus: formattedOrders,
            totalUsers: userCount,
            lowStockAlert: lowStockVariants,
            revenueTrends: trends.revenue,
            orderTrends: trends.orders,
            latestLogs: latestLogs.data
        }
    }

    private async getTrends(days: number) {
        const now = new Date();
        const startDate = new Date();
        startDate.setDate(now.getDate() - (days - 1));
        startDate.setHours(0, 0, 0, 0);

        /// query 1 lan lay toan bo order trong khoang thoi gian
        const allOrders = await this.prisma.order.findMany({
            where: { createdAt: { gte: startDate } },
            select: {
                createdAt: true,
                totalAmount: true,
                paymentStatus: true
            }
        });

        // stat chua du lieu cac ngay
        const statsMap = new Map<string, { orders: number; revenue: number }>();

        for (let i = 0; i < days; i++) {
            const d = new Date(startDate);
            d.setDate(d.getDate() + i);
            const dateStr = d.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit' });
            statsMap.set(dateStr, { orders: 0, revenue: 0 });
        }

        // do du lieu vao map
        allOrders.forEach(order => {
            const dateStr = order.createdAt.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit' });
            if (statsMap.has(dateStr)) {
                const current = statsMap.get(dateStr)!;
                current.orders += 1;
                if (order.paymentStatus === PaymentStatus.PAID) {
                    current.revenue += Number(order.totalAmount || 0);
                }
                statsMap.set(dateStr, current);
            }
        });

        const result = Array.from(statsMap.entries()).map(([date, data]) => ({
            date,
            orders: data.orders,
            revenue: data.revenue
        }));

        return {
            orders: result.map(d => ({ date: d.date, count: d.orders })),
            revenue: result.map(d => ({ date: d.date, value: d.revenue }))
        };
    }

    async reOrder(userId: string, id: string) {
        // lay thong tin don cu
        const oldOrder = await this.prisma.order.findFirst({
            where: { id, userId },
            include: { items: true }
        });
        if (!oldOrder) throw new NotFoundException('Không tìm thấy đơn hàng cũ');

        // chuan bi du lieu cho don hang moi
        // lay lai danh sach variantId va quantity tu don hang cu
        const itemsForNewOrder = oldOrder.items.map(item => ({
            variantId: item.productVariantId,
            quantity: item.quantity
        }));

        // tai su dung thong tin ship
        const reOrderData: CreateOrderDto = {
            receiverName: oldOrder.receiverName,
            receiverPhone: oldOrder.receiverPhone,
            shippingAddress: oldOrder.shippingAddress,
            note: `Mua lại từ đơn hàng #${oldOrder.id.slice(0, 8)}`,
            items: itemsForNewOrder
        };

        return this.createOrder(userId, reOrderData);
    }
}
