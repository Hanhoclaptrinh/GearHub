import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { AddToCartDto } from './dto/add-to-cart.dto';
import { ProductsService } from 'src/products/products.service';
import { UpdateCartItemDto } from './dto/update-cart-item.dto';
import { ClearSelectedDto } from './dto/clear-selected.dto';
import { SyncCartDto } from './dto/sync-cart.dto';

@Injectable()
export class CartService {
    constructor(
        private prisma: PrismaService,
        private productService: ProductsService
    ) { }

    // tao cart cho user khi vao app
    private async getOrCreateCart(userId: string) {
        let cart = await this.prisma.cart.findUnique({
            where: { userId },
            include: { items: true }
        });

        if (!cart) {
            cart = await this.prisma.cart.create({
                data: { userId },
                include: { items: true }
            });
        }

        return cart;
    }

    // them sp vao gio
    async addToCart(userId: string, data: AddToCartDto) {
        const variant = await this.prisma.productVariant.findUnique({
            where: { id: data.variantId },
            select: { stock: true, name: true }
        });

        if (!variant) throw new NotFoundException('Sản phẩm không tồn tại hoặc đã bị xóa');

        // them vao gio hang nhieu hon so luong con lai
        if (variant.stock < data.quantity)
            throw new BadRequestException(`Sản phẩm ${variant.name} chỉ còn ${variant.stock} sản phẩm trong kho`);

        const cart = await this.getOrCreateCart(userId); // dam bao luon co 1 gio hang

        return this.prisma.cartItem.upsert({
            where: {
                cartId_productVariantId: {
                    cartId: cart.id,
                    productVariantId: data.variantId
                }
            },
            update: {
                quantity: { increment: data.quantity } // cong don neu da co sp
            },
            create: {
                cartId: cart.id,
                productVariantId: data.variantId,
                quantity: data.quantity // chua co thi tao moi
            }
        });
    }

    async getCart(userId: string) {
        const cart = await this.prisma.cart.findUnique({
            where: { userId },
            include: {
                // lay danh sach cac sp trong gio
                items: {
                    include: {
                        // lay thong tin bien the tung sp
                        productVariant: {
                            include: {
                                // lay thong tin goc cua sp
                                product: {
                                    select: {
                                        id: true,
                                        name: true,
                                        slug: true,
                                        thumbnailUrl: true
                                    }
                                }
                            }
                        }
                    },
                    orderBy: { createdAt: 'desc' }
                }
            }
        });

        if (!cart) return this.getOrCreateCart(userId);

        // tinh tien tung sp trong gio
        const itemsWithTotal = cart.items.map(item => ({
            ...item,
            itemTotal: item.quantity * Number(item.productVariant.price)
        }));

        // tong tien trong gio
        const cartTotal = itemsWithTotal.reduce((sum, item) => sum + item.itemTotal, 0);

        return {
            ...cart,
            items: itemsWithTotal,
            cartTotal
        }
    }

    async getCartCount(userId: string) {
        const cart = await this.prisma.cart.findUnique({
            where: { userId },
            include: { _count: { select: { items: true } } }
        });

        return { count: cart?._count.items || 0 };
    }

    async updateQuantity(userId: string, id: string, data: UpdateCartItemDto) {
        const cartItem = await this.prisma.cartItem.findFirst({
            where: {
                id,
                cart: { userId }
            },
            include: { productVariant: true }
        });
        if (!cartItem) throw new NotFoundException('Món hàng không tồn tại trong giỏ');

        if (cartItem.productVariant.stock < data.quantity)
            throw new BadRequestException(`Kho chỉ còn ${cartItem.productVariant.stock} sản phẩm`);

        await this.prisma.cartItem.update({
            where: { id },
            data: { quantity: data.quantity }
        });

        // cap nhat ui
        return this.getCart(userId);
    }

    async removeItem(userId: string, id: string) {
        // item phai nam trong gio moi cho xoa
        const item = await this.prisma.cartItem.findFirst({
            where: {
                id,
                cart: { userId }
            }
        });

        if (!item) throw new NotFoundException('Món hàng không tồn tại');

        await this.prisma.cartItem.delete({
            where: { id }
        });

        // cap nhat ui
        return this.getCart(userId);
    }

    async clearCart(userId: string) {
        const cart = await this.prisma.cart.findUnique({
            where: { userId }
        });
        if (!cart) return;

        return await this.prisma.cartItem.deleteMany({
            where: { cartId: cart.id }
        })
    }

    async clearSelectedItems(userId: string, data: ClearSelectedDto) {
        const cart = await this.prisma.cart.findUnique({
            where: { userId }
        });
        if (!cart) return;

        await this.prisma.cartItem.deleteMany({
            where: {
                cartId: cart.id,
                productVariantId: {
                    in: data.variantIds // chi xoa nhung sp duoc chon
                }
            }
        });

        return this.getCart(userId);
    }

    // dong bo hoa gio hang khi khach hang chua dang nhap va dang nhap
    // khach chua login -> them hang
    // khach login -> sync toan bo sp vao
    async syncCart(userId: string, data: SyncCartDto) {
        const cart = await this.getOrCreateCart(userId);

        await Promise.all(
            data.items.map(item => {
                this.prisma.cartItem.upsert({
                    where: {
                        cartId_productVariantId: {
                            cartId: cart.id,
                            productVariantId: item.variantId
                        }
                    },
                    update: {
                        quantity: { increment: item.quantity }
                    },
                    create: {
                        cartId: cart.id,
                        productVariantId: item.variantId,
                        quantity: item.quantity
                    }
                })
            })
        );

        return this.getCart(userId);
    }
}
