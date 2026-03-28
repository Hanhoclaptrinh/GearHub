import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { CartService } from 'src/cart/cart.service';
import { PrismaService } from 'src/prisma/prisma.service';
import { ProductsService } from 'src/products/products.service';
import { CreateOrderDto } from './dto/create-order.dto';
import { OrderStatus } from '@prisma/client';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';

@Injectable()
export class OrdersService {
    constructor(
        private prisma: PrismaService,
        private productService: ProductsService,
        private cartService: CartService
    ) { }

    async createOrder(userId: string, data: CreateOrderDto) {
        const { items, ...shippingInfor } = data;
        const variantIds = items.map(i => i.variantId);

        return await this.prisma.$transaction(async (tx) => {
            // lay thong tin variant truc tiep tu db
            const variants = await tx.productVariant.findMany({
                where: { id: { in: variantIds } }
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
                    priceAtPurchase: variant.price // gia tai thoi diem mua hang
                };
            });

            // tao order
            const order = await tx.order.create({
                data: {
                    userId,
                    totalAmount,
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
                await tx.productVariant.update({
                    where: { id: item.variantId },
                    data: {
                        stock: { decrement: item.quantity }
                    }
                });
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

    async getMyOrders(userId: string) {
        return this.prisma.order.findMany({
            where: { userId },
            select: {
                id: true,
                totalAmount: true,
                status: true,
                createdAt: true,
                paymentMethod: true,
                items: {
                    take: 1,
                    select: {
                        productVariant: {
                            select: {
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
            orderBy: { createdAt: 'desc' } // don moi nhat hien len dau
        })
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
                            select: {
                                id: true,
                                name: true,
                                sku: true,
                                attributes: true,
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
                    orderBy: { updatedAt: 'desc' }
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

            // hoan kho
            // khi trang thai moi la cancelled va trang thai hien tai khong phai cancelled
            if (status === OrderStatus.CANCELLED && order.status !== OrderStatus.CANCELLED) {
                for (const item of order.items) {
                    await tx.productVariant.update({
                        where: { id: item.productVariantId },
                        data: { stock: { increment: item.quantity } }
                    });
                }
            }

            // cap nhat trang thai don hang
            const updateOrder = await tx.order.update({
                where: { id: orderId },
                data: { status }
            });

            // tracking cho khach theo doi
            await tx.orderTracking.create({
                data: {
                    orderId,
                    statusLabel: this.mapStatusToLabel(status),
                    description: description || `Đơn hàng đã được chuyển sang trạng thái ${status}`
                }
            });

            return updateOrder;
        });
    }

    private mapStatusToLabel(status: OrderStatus): string {
        const labels = {
            [OrderStatus.PENDING]: 'Chờ xác nhận',
            [OrderStatus.PROCESSING]: 'Đang xử lý',
            [OrderStatus.SHIPPING]: 'Đang giao hàng',
            [OrderStatus.DELIVERED]: 'Giao hàng thành công',
            [OrderStatus.CANCELLED]: 'Đã hủy đơn',
        };
        return labels[status] || status;
    }
}
