import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';

@Injectable()
export class WishlistService {
    constructor(private prisma: PrismaService) { }

    /// toggle wishlist
    async toggleWishlist(userId: string, productId: string) {
        const existingItem = await this.prisma.wishlist.findUnique({
            where: { userId_productId: { userId, productId } }
        });

        if (existingItem) {
            await this.prisma.wishlist.delete({ where: { id: existingItem.id } });
            return { isFavorite: false, message: 'Đã xóa khỏi danh sách yêu thích' };
        }

        await this.prisma.wishlist.create({
            data: { userId, productId }
        });
        return { isFavorite: true, message: 'Đã thêm vào danh sách yêu thích' };
    }

    /// get wishlist
    async getMyWishlist(userId: string, page: number = 1, limit: number = 10) {
        const skip = (page - 1) * limit;

        const [data, total] = await Promise.all([
            this.prisma.wishlist.findMany({
                where: { userId },
                skip,
                take: limit,
                orderBy: { createdAt: 'desc' },
                include: {
                    product: {
                        include: {
                            assets: { where: { isPrimary: true } },
                            variants: {
                                select: { price: true },
                                take: 1
                            },
                            brand: { select: { name: true } }
                        }
                    }
                }
            }),
            this.prisma.wishlist.count({ where: { userId } })
        ]);

        return {
            data,
            meta: {
                total,
                page,
                lastPage: Math.ceil(total / limit)
            }
        }
    }

    /// fast api for ui
    /// api nhanh de ui hien trai tim do hay xam
    async checkIsFavorite(userId: string, productId: string) {
        const favorite = await this.prisma.wishlist.findUnique({
            where: { userId_productId: { userId, productId } }
        });

        return { isFavorite: !!favorite };
    }

    /// data for ai
    /// prod duoc yeu thich nhieu nhat
    async getMostWishlisted(limit: number = 5) {
        return this.prisma.wishlist.groupBy({
            by: ['productId'],
            _count: {
                productId: true
            },
            orderBy: {
                _count: {
                    productId: 'desc'
                }
            },
            take: limit
        });
    }
}
