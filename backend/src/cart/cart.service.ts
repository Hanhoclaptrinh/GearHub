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

    // su dung upsert nguyen tu de tranh loi duplicate khi goi dong thoi
    private async getOrCreateCart(userId: string) {
        return this.prisma.cart.upsert({
            where: { userId },
            update: {},
            create: { userId },
            include: { items: true }
        });
    }

    async addToCart(userId: string, data: AddToCartDto) {
        const variant = await this.prisma.productVariant.findUnique({
            where: { id: data.variantId },
            include: { product: true }
        });

        if (!variant || !variant.isActive || !variant.product.isActive) {
            throw new NotFoundException('Sản phẩm không tồn tại hoặc đã ngừng kinh doanh');
        }

        const cart = await this.getOrCreateCart(userId);

        const existingItem = await this.prisma.cartItem.findUnique({
            where: {
                cartId_productVariantId: {
                    cartId: cart.id,
                    productVariantId: data.variantId
                }
            }
        });

        const currentQuantity = existingItem ? existingItem.quantity : 0;
        if (variant.stock < currentQuantity + data.quantity) {
            throw new BadRequestException(`Sản phẩm ${variant.name} chỉ còn ${variant.stock} sản phẩm trong kho (Bạn đã có ${currentQuantity} trong giỏ)`);
        }

        await this.prisma.cartItem.upsert({
            where: {
                cartId_productVariantId: {
                    cartId: cart.id,
                    productVariantId: data.variantId
                }
            },
            update: {
                quantity: { increment: data.quantity }
            },
            create: {
                cartId: cart.id,
                productVariantId: data.variantId,
                quantity: data.quantity
            }
        });

        return this.getCart(userId);
    }

    async getCart(userId: string) {
        const cart = await this.prisma.cart.findUnique({
            where: { userId },
            include: {
                items: {
                    include: {
                        productVariant: {
                            include: {
                                product: {
                                    select: {
                                        id: true,
                                        name: true,
                                        slug: true,
                                        thumbnailUrl: true,
                                        isActive: true,
                                        variants: true
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

        // filter va canh bao san pham da het hang hoac dung kinh doanh
        const itemsWithTotal = cart.items.map(item => {
            const isAvailable = 
                item.productVariant.isActive && 
                item.productVariant.product.isActive && 
                item.productVariant.stock > 0;

            return {
                ...item,
                isAvailable,
                itemTotal: item.quantity * Number(item.productVariant.price)
            };
        });

        const cartTotal = itemsWithTotal
            .filter(item => item.isAvailable)
            .reduce((sum, item) => sum + item.itemTotal, 0);

        return {
            ...cart,
            items: itemsWithTotal,
            cartTotal
        };
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
            where: { id, cart: { userId } },
            include: { productVariant: true }
        });

        if (!cartItem) throw new NotFoundException('Món hàng không tồn tại trong giỏ');

        if (cartItem.productVariant.stock < data.quantity) {
            throw new BadRequestException(`Kho chỉ còn ${cartItem.productVariant.stock} sản phẩm`);
        }

        await this.prisma.cartItem.update({
            where: { id },
            data: { quantity: data.quantity }
        });

        return this.getCart(userId);
    }

    async removeItem(userId: string, id: string) {
        const item = await this.prisma.cartItem.findFirst({
            where: { id, cart: { userId } }
        });

        if (!item) throw new NotFoundException('Món hàng không tồn tại');

        await this.prisma.cartItem.delete({
            where: { id }
        });

        return this.getCart(userId);
    }

    async clearCart(userId: string) {
        const cart = await this.prisma.cart.findUnique({
            where: { userId }
        });
        if (!cart) return;

        return await this.prisma.cartItem.deleteMany({
            where: { cartId: cart.id }
        });
    }

    async clearSelectedItems(userId: string, data: ClearSelectedDto) {
        const cart = await this.prisma.cart.findUnique({
            where: { userId }
        });
        if (!cart) return;

        await this.prisma.cartItem.deleteMany({
            where: {
                cartId: cart.id,
                productVariantId: { in: data.variantIds }
            }
        });

        return this.getCart(userId);
    }

    async syncCart(userId: string, data: SyncCartDto) {
        const cart = await this.getOrCreateCart(userId);

        // gom cac item trung variantId tu client gui len
        const aggregatedItems = data.items.reduce((acc, item) => {
            const existing = acc.find(i => i.variantId === item.variantId);
            if (existing) {
                existing.quantity += item.quantity;
            } else {
                acc.push({ ...item });
            }
            return acc;
        }, [] as { variantId: string; quantity: number }[]);

        // lay danh sach bien the tu db de check stock va isactive
        const variantIds = aggregatedItems.map(i => i.variantId);
        const variants = await this.prisma.productVariant.findMany({
            where: {
                id: { in: variantIds },
                isActive: true,
                product: { isActive: true }
            },
            select: { id: true, stock: true }
        });

        // thuc hien dong bo
        await Promise.all(
            aggregatedItems.map(async (item) => {
                const v = variants.find(v => v.id === item.variantId);
                if (!v) return;

                // tim xem mon nay da co trong gio hang cua user chua
                const existingInCart = cart.items.find(i => i.productVariantId === item.variantId);
                const currentInCart = existingInCart ? existingInCart.quantity : 0;

                // tinh so luong cuoi cung: (trong db + local gui len) nhung khong vuot qua so luong ton kho
                const finalQuantity = Math.min(currentInCart + item.quantity, v.stock);

                if (finalQuantity <= 0) return;

                // dung upsert voi finalQty da duoc tinh
                return this.prisma.cartItem.upsert({
                    where: {
                        cartId_productVariantId: {
                            cartId: cart.id,
                            productVariantId: item.variantId
                        }
                    },
                    update: { quantity: finalQuantity },
                    create: {
                        cartId: cart.id,
                        productVariantId: item.variantId,
                        quantity: finalQuantity
                    }
                });
            })
        );
        // tra ve gio hang de UI cap nhat
        return this.getCart(userId);
    }
}
