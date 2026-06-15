import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { AddToCartDto } from './dto/add-to-cart.dto';
import { UpdateCartItemDto } from './dto/update-cart-item.dto';
import { ClearSelectedDto } from './dto/clear-selected.dto';
import { SyncCartDto } from './dto/sync-cart.dto';

@Injectable()
export class CartService {
    constructor(
        private prisma: PrismaService
    ) { }

    // các sản phẩm được gợi ý khi thêm một sản phẩm vào giỏ hàng
    private readonly recommendationProductSelect = {
        id: true,
        categoryId: true,
        brandId: true,
        name: true,
        slug: true,
        thumbnailUrl: true,
        tagline: true,
        description: true,
        soldCount: true,
        averageRating: true,
        reviewCount: true,
        attributeConfig: true,
        brand: {
            select: {
                id: true,
                name: true,
                slug: true,
                logoUrl: true
            }
        },
        category: {
            select: {
                id: true,
                name: true,
                slug: true,
                parentId: true,
                parent: {
                    select: {
                        id: true,
                        name: true,
                        slug: true
                    }
                }
            }
        },
        assets: {
            where: { isPrimary: true },
            take: 1
        },
        variants: {
            where: {
                isActive: true,
                stock: { gt: 0 }
            },
            orderBy: { price: 'asc' as const },
            select: {
                id: true,
                sku: true,
                name: true,
                price: true,
                stock: true,
                attributes: true,
                imageUrl: true,
                isActive: true
            }
        }
    };

    // dùng upsert để tạo một giỏ hàng mới nếu chưa có
    // tránh lỗi duplicate
    private async getOrCreateCart(userId: string) {
        return this.prisma.cart.upsert({
            where: { userId },
            update: {},
            create: { userId },
            include: { items: true }
        });
    }

    /**
     * thêm sản phẩm vào giỏ hàng của người dùng
     * 
     * kiểm tra trạng thái hoạt động và số lượng tồn kho của sản phẩm trước khi thêm
     * tự động tăng số lượng nếu đã có sẵn hoặc tạo mới nếu chưa có trong giỏ hàng
     */
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

        // kiểm tra stock còn lại trong kho tránh thêm quá số lượng stock
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

    /**
     * lấy thông tin chi tiết giỏ hàng của người dùng
     * 
     * tự động tạo giỏ hàng mới nếu chưa tồn tại trong hệ thống
     * tính toán trạng thái khả dụng của từng sản phẩm dựa trên số lượng tồn kho và trạng thái hoạt động
     * tính tổng tiền của từng sản phẩm và tổng giá trị của toàn bộ giỏ hàng
     */
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

        // lấy danh sách fs đang hoạt động cho các variant trong giỏ hàng
        const variantIds = cart.items.map(i => i.productVariantId);
        const now = new Date();
        const activeFlashSales = await this.prisma.flashSaleProduct.findMany({
            where: {
                productVariantId: { in: variantIds },
                startsAt: { lte: now },
                expiresAt: { gte: now }
            }
        });

        // filter và cảnh báo sp đã hết hàng hoặc ngừng kinh doanh
        const itemsWithTotal = cart.items.map(item => {
            const isAvailable =
                item.productVariant.isActive &&
                item.productVariant.product.isActive &&
                item.productVariant.stock > 0;

            const flashSale = activeFlashSales.find(fs => fs.productVariantId === item.productVariantId);
            const hasActiveFlashSale = flashSale && (flashSale.soldCount < flashSale.stockLimit);
            const price = hasActiveFlashSale ? Number(flashSale.flashPrice) : Number(item.productVariant.price);

            return {
                ...item,
                isAvailable,
                flashSale: hasActiveFlashSale ? {
                    id: flashSale.id,
                    flashPrice: Number(flashSale.flashPrice),
                    stockLimit: flashSale.stockLimit,
                    soldCount: flashSale.soldCount
                } : null,
                priceUsed: price,
                itemTotal: item.quantity * price
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

    /**
     * gợi ý sản phẩm cho người dùng dựa trên giỏ hàng hiện tại
     * 
     * đề xuất sản phẩm cùng danh mục cha hoặc cùng thương hiệu với sản phẩm đang có
     * fallback bằng top selling
     */
    async getCartRecommendations(userId: string, limit = 8) {
        // giới hạn 8 items gợi ý
        const safeLimit = this.normalizeRecommendationLimit(limit);
        const cart = await this.prisma.cart.findUnique({
            where: { userId },
            include: {
                items: {
                    include: {
                        productVariant: {
                            select: {
                                id: true,
                                productId: true,
                                product: {
                                    select: {
                                        id: true,
                                        brandId: true,
                                        categoryId: true,
                                        category: {
                                            select: {
                                                id: true,
                                                parentId: true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        });

        // nếu giỏ hàng trống thì lấy trực tiếp danh sách bán chạy
        if (!cart || cart.items.length === 0) {
            return this.getTopSellingRecommendations(new Set(), safeLimit);
        }

        // gom nhóm danh mục và thương hiệu của các sản phẩm có sẵn trong giỏ hàng
        const cartProductIds = new Set<string>();
        const cartBrandIds = new Set<string>();
        const cartCategoryIds = new Set<string>();
        const categoryGroups = new Map<string, Set<string>>();

        for (const item of cart.items) {
            const product = item.productVariant.product;
            cartProductIds.add(product.id);

            if (product.brandId) {
                cartBrandIds.add(product.brandId);
            }

            if (product.categoryId) {
                cartCategoryIds.add(product.categoryId);
            }

            const category = product.category;
            if (!category?.parentId || !product.categoryId) continue;

            const group = categoryGroups.get(category.parentId) ?? new Set<string>();
            group.add(product.categoryId);
            categoryGroups.set(category.parentId, group);
        }

        // tìm sản phẩm gợi ý thuộc các nhóm danh mục và thương hiệu tương ứng
        const groupRecommendations = await this.getSameParentRecommendations({
            categoryGroups,
            cartCategoryIds,
            excludedProductIds: cartProductIds,
            cartBrandIds,
            limit: safeLimit
        });

        // gộp các gợi ý và loại bỏ sản phẩm đã có trong giỏ hàng
        const merged = this.mergeRecommendationGroups(groupRecommendations, safeLimit);
        const selectedProductIds = new Set([...cartProductIds, ...merged.map((product) => product.id)]);

        // thêm top selling nếu chưa đủ item gợi ý
        if (merged.length < safeLimit) {
            const fallback = await this.getTopSellingRecommendations(
                selectedProductIds,
                safeLimit - merged.length
            );
            merged.push(...fallback);
        }

        return merged.slice(0, safeLimit);
    }

    /**
     * cập nhật số lượng của một sản phẩm trong giỏ hàng
     * 
     * kiểm tra sản phẩm có tồn tại trong giỏ hàng của người dùng hay không
     * không cho thêm quá stock trong kho
     */
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

    // xóa tất cả items trong cart
    async clearCart(userId: string) {
        const cart = await this.prisma.cart.findUnique({
            where: { userId }
        });
        if (!cart) return;

        return await this.prisma.cartItem.deleteMany({
            where: { cartId: cart.id }
        });
    }

    // xóa item được chọn
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

    /**
     * đồng bộ giỏ hàng từ local client lên server khi người dùng đăng nhập
     * 
     * gộp các sản phẩm trùng lặp, kiểm tra trạng thái hoạt động và giới hạn số lượng theo tồn kho thực tế
     */
    async syncCart(userId: string, data: SyncCartDto) {
        const cart = await this.getOrCreateCart(userId);

        // gộp các sản phẩm trùng mã biến thể gửi lên từ client
        const aggregatedItems = data.items.reduce((acc, item) => {
            const existing = acc.find(i => i.variantId === item.variantId);
            if (existing) {
                existing.quantity += item.quantity;
            } else {
                acc.push({ ...item });
            }
            return acc;
        }, [] as { variantId: string; quantity: number }[]);

        // lấy danh sách biến thể từ db để kiểm tra tồn kho và trạng thái hoạt động
        const variantIds = aggregatedItems.map(i => i.variantId);
        const variants = await this.prisma.productVariant.findMany({
            where: {
                id: { in: variantIds },
                isActive: true,
                product: { isActive: true }
            },
            select: { id: true, stock: true }
        });

        // tiến hành đồng bộ từng sản phẩm vào giỏ hàng
        await Promise.all(
            aggregatedItems.map(async (item) => {
                const v = variants.find(v => v.id === item.variantId);
                if (!v) return;

                // tìm sản phẩm này xem đã tồn tại trong giỏ hàng của người dùng hay chưa
                const existingInCart = cart.items.find(i => i.productVariantId === item.variantId);
                const currentInCart = existingInCart ? existingInCart.quantity : 0;

                // tính số lượng cuối cùng bằng tổng số lượng hiện tại và số lượng gửi lên nhưng không vượt quá tồn kho
                const finalQuantity = Math.min(currentInCart + item.quantity, v.stock);

                if (finalQuantity <= 0) return;

                // cập nhật hoặc thêm mới sản phẩm vào giỏ hàng với số lượng đã tính
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
        // trả về thông tin giỏ hàng sau khi đồng bộ để giao diện cập nhật
        return this.getCart(userId);
    }

    private normalizeRecommendationLimit(limit: number) {
        if (!Number.isFinite(limit)) return 8;
        return Math.min(Math.max(Math.trunc(limit), 1), 20);
    }

    /**
     * lấy sản phẩm gợi ý cùng danh mục cha với các sản phẩm đang có trong giỏ hàng
     * 
     * duyệt qua từng nhóm danh mục cha, tìm danh mục cùng cấp của các danh mục hiện tại
     * truy vấn các sản phẩm đang hoạt động thuộc danh mục cùng cấp để gợi ý cho user
     */
    private async getSameParentRecommendations(params: {
        categoryGroups: Map<string, Set<string>>;
        cartCategoryIds: Set<string>;
        excludedProductIds: Set<string>;
        cartBrandIds: Set<string>;
        limit: number;
    }) {
        const { categoryGroups, cartCategoryIds, excludedProductIds, cartBrandIds, limit } = params;
        const groups = Array.from(categoryGroups.entries());
        if (groups.length === 0) return [];

        // số lượng gợi ý cần lấy cho mỗi nhóm danh mục cha
        const perGroupTake = Math.max(2, Math.ceil(limit / groups.length));
        const excludedIds = Array.from(excludedProductIds);

        const recommendations = await Promise.all(
            groups.map(async ([parentId, currentCategoryIds]) => {
                // tìm các subcate chung parent & loại cate của item hiện tại trong giỏ
                const siblingCategories = await this.prisma.category.findMany({
                    where: {
                        parentId,
                        id: { notIn: Array.from(new Set([...cartCategoryIds, ...currentCategoryIds])) }
                    },
                    select: { id: true }
                });

                if (siblingCategories.length === 0) return [];

                // lấy các sản phẩm đang bán có tồn kho thuộc các danh mục này
                const products = await this.prisma.product.findMany({
                    where: {
                        id: excludedIds.length > 0 ? { notIn: excludedIds } : undefined,
                        categoryId: { in: siblingCategories.map((category) => category.id) },
                        isActive: true,
                        variants: {
                            some: {
                                isActive: true,
                                stock: { gt: 0 }
                            }
                        }
                    },
                    select: this.recommendationProductSelect,
                    orderBy: [
                        { soldCount: 'desc' },
                        { averageRating: 'desc' },
                        { createdAt: 'desc' }
                    ],
                    take: perGroupTake * 4
                });

                // ưu tiên xếp sản phẩm cùng thương hiệu lên trước và cắt đủ số lượng quy định
                return this.sortByCartContext(products, cartBrandIds).slice(0, perGroupTake);
            })
        );

        return recommendations.filter((group) => group.length > 0);
    }

    /**
     * sắp xếp sản phẩm gợi ý dựa trên ngữ cảnh giỏ hàng hiện tại
     * ưu tiên sản phẩm cùng thương hiệu với sản phẩm đang có trong giỏ hàng
     * thứ tự ưu tiên tiếp theo lần lượt là lượt bán, điểm đánh giá trung bình và số lượng đánh giá
     */
    private sortByCartContext<T extends { brandId: string | null; soldCount: number; averageRating: unknown; reviewCount: number }>(
        products: T[],
        cartBrandIds: Set<string>
    ) {
        return [...products].sort((a, b) => {
            // kiểm tra xem sản phẩm có cùng thương hiệu với sản phẩm trong giỏ không
            const sameBrandA = a.brandId ? cartBrandIds.has(a.brandId) : false;
            const sameBrandB = b.brandId ? cartBrandIds.has(b.brandId) : false;

            // ưu tiên hàng đầu cho sản phẩm cùng thương hiệu
            if (sameBrandA !== sameBrandB) return sameBrandA ? -1 : 1;

            // ưu tiên tiếp theo cho sản phẩm có lượt bán cao hơn
            if (b.soldCount !== a.soldCount) return b.soldCount - a.soldCount;

            // ưu tiên tiếp theo cho sản phẩm có điểm đánh giá trung bình cao hơn
            const ratingDiff = Number(b.averageRating || 0) - Number(a.averageRating || 0);
            if (ratingDiff !== 0) return ratingDiff;

            // cuối cùng ưu tiên sản phẩm có nhiều lượt đánh giá hơn
            return b.reviewCount - a.reviewCount;
        });
    }

    /**
     * gộp các nhóm sản phẩm gợi ý lại với nhau theo round-robin
     * đảm bảo sự đa dạng của các nhóm sản phẩm gợi ý bằng cách lấy xen kẽ từng sản phẩm từ mỗi nhóm
     * loại bỏ các sản phẩm bị trùng lặp và dừng lại khi đạt đủ giới hạn yêu cầu
     */
    private mergeRecommendationGroups<T extends { id: string }>(groups: T[][], limit: number) {
        const result: T[] = [];
        const seen = new Set<string>();
        let index = 0;

        while (result.length < limit) {
            let addedInRound = false;

            // duyệt qua từng nhóm gợi ý để lấy xen kẽ sản phẩm theo chỉ số hiện tại
            for (const group of groups) {
                const product = group[index];
                if (!product || seen.has(product.id)) continue;

                result.push(product);
                seen.add(product.id);
                addedInRound = true;

                if (result.length >= limit) break;
            }

            // dừng vòng lặp nếu không có sản phẩm mới nào được thêm vào trong lượt này
            if (!addedInRound) break;
            index += 1;
        }

        return result;
    }

    /**
     * lấy danh sách các sản phẩm bán chạy nhất làm fallback
     * loại trừ các sản phẩm đã được chỉ định để tránh trùng lặp
     * sắp xếp theo lượt bán giảm dần, điểm đánh giá trung bình và thời gian tạo mới nhất
     */
    private async getTopSellingRecommendations(excludedProductIds: Set<string>, limit: number) {
        if (limit <= 0) return [];

        const excludedIds = Array.from(excludedProductIds);

        return this.prisma.product.findMany({
            where: {
                id: excludedIds.length > 0 ? { notIn: excludedIds } : undefined,
                isActive: true,
                variants: {
                    some: {
                        isActive: true,
                        stock: { gt: 0 }
                    }
                }
            },
            select: this.recommendationProductSelect,
            orderBy: [
                { soldCount: 'desc' },
                { averageRating: 'desc' },
                { createdAt: 'desc' }
            ],
            take: limit
        });
    }
}
