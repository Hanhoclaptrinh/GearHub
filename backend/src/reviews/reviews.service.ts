import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateReviewDto } from './dto/create-review.dto';
import { OrderStatus } from '@prisma/client';
import { ReplyReviewDto } from './dto/reply-review.dto';
import { UpdateReviewDto } from './dto/update-review.dto';

@Injectable()
export class ReviewsService {
    constructor(
        private prisma: PrismaService,
        private cloudinaryService: CloudinaryService
    ) { }

    // tao danh gia
    async createReview(userId: string, data: CreateReviewDto, files: Express.Multer.File[]) {
        const { orderItemId, rating, comment } = data;

        // tim order item va xac thuc quyen so huu
        const orderItem = await this.prisma.orderItem.findUnique({
            where: { id: orderItemId },
            include: {
                order: { select: { userId: true, status: true } },
                productVariant: { select: { productId: true } },
                review: { select: { id: true } }
            }
        });

        if (!orderItem) throw new NotFoundException('Không tìm thấy sản phẩm trong đơn hàng');
        if (orderItem.order.userId !== userId) throw new BadRequestException('Bạn không có quyền đánh giá sản phẩm này');
        if (orderItem.order.status !== OrderStatus.DELIVERED) throw new BadRequestException('Chỉ đánh giá được sau khi nhận hàng thành công');
        if (orderItem.review) throw new ConflictException('Bạn đã đánh giá sản phẩm này trong đơn hàng này rồi');

        const productId = orderItem.productVariant.productId;

        return await this.prisma.$transaction(async (tx) => {
            // tao review
            const review = await tx.review.create({
                data: {
                    userId,
                    productId,
                    orderItemId,
                    rating,
                    comment,
                    isVerifiedPurchase: true
                }
            });

            // xu ly file (cmt anh hoac video)
            if (files && files.length > 0) {
                const uploadResult = await Promise.all(
                    files.map(file => this.cloudinaryService.uploadFile(file))
                );

                await tx.reviewAsset.createMany({
                    data: uploadResult.map((res) => ({
                        reviewId: review.id,
                        url: res.secure_url,
                        type: res.resource_type.toUpperCase()
                    }))
                });
            }

            // cap nhat rating va review count cho prod
            const stats = await tx.review.aggregate({
                where: { productId },
                _avg: { rating: true },
                _count: { id: true }
            });

            await tx.product.update({
                where: { id: productId },
                data: {
                    averageRating: stats._avg.rating || 0,
                    reviewCount: stats._count.id || 0
                }
            });

            return review;
        });
    }

    // get danh sach review cua 1 prod
    async getProductReviews(
        productId: string,
        page: number = 1,
        limit: number = 10,
        isAdmin: boolean = false,
        rating?: number,
        hasImage?: boolean
    ) {
        const skip = (page - 1) * limit;

        const whereCondition: any = {
            productId,
            ...(isAdmin ? {} : { isHidden: false }),
            ...(rating && { rating }),
            ...(hasImage && { assets: { some: {} } })
        };

        const [reviews, total] = await Promise.all([
            this.prisma.review.findMany({
                where: whereCondition,
                include: {
                    user: {
                        select: {
                            id: true,
                            profile: {
                                select: {
                                    fullName: true,
                                    avatarUrl: true
                                }
                            }
                        }
                    },
                    assets: true,
                    orderItem: {
                        include: {
                            productVariant: {
                                select: {
                                    attributes: true
                                }
                            }
                        }
                    }
                },
                orderBy: { createdAt: 'desc' },
                skip,
                take: limit
            }),
            this.prisma.review.count({
                where: whereCondition
            })
        ]);

        const formattedReviews = reviews.map(review => {
            const attrs = (review.orderItem?.productVariant as any)?.attributes;
            let variantInfo = '';
            if (attrs && typeof attrs === 'object') {
                variantInfo = Object.entries(attrs)
                    .map(([key, value]) => `${key}: ${value}`)
                    .join(', ');
            }

            return {
                ...review,
                variantName: (review.orderItem?.productVariant as any)?.attributes
                    ? Object.entries((review.orderItem?.productVariant as any).attributes)
                        .map(([key, value]) => `${key}: ${value}`)
                        .join(', ')
                    : review.orderItem?.variantName
            };
        });

        return {
            data: formattedReviews,
            meta: {
                total,
                page,
                lastPage: Math.ceil(total / limit)
            }
        };
    }

    // admin reply to customer
    async replyReview(id: string, data: ReplyReviewDto) {
        const review = await this.prisma.review.findUnique({ where: { id } });
        if (!review) throw new NotFoundException('Không tìm thấy đánh giá');

        return this.prisma.review.update({
            where: { id },
            data: { reply: data.reply }
        })
    }

    // for ai review & rcm
    async getReviewSummary(productId: string) {
        // dem so luong rating trong prod
        const counts = await this.prisma.review.groupBy({
            by: ['rating'],
            where: { productId },
            _count: { id: true }
        });

        // khoi tao defaut obj
        const summary = {
            "1": 0, "2": 0, "3": 0, "4": 0, "5": 0, total: 0, average: 0
        };

        let totalStars = 0;

        // cong don
        counts.forEach(item => {
            const count = item._count.id;
            summary[item.rating.toString()] = count;
            summary.total += count;
            totalStars += item.rating * count;
        });

        if (summary.total > 0) {
            summary.average = Number((totalStars / summary.total).toFixed(1));
        }

        return summary;
    }

    // admin an review
    async toggleVisibility(id: string) {
        const review = await this.prisma.review.findUnique({ where: { id } });
        if (!review) throw new NotFoundException('Không tìm thấy đánh giá');

        const updatedReview = await this.prisma.review.update({
            where: { id },
            data: { isHidden: !review.isHidden }
        });

        return {
            message: `Đã ${(updatedReview).isHidden ? 'ẩn' : 'hiển thị'} đánh giá`,
            isHidden: updatedReview.isHidden
        };
    }

    // sua review
    async updateReview(userId: string, id: string, data: UpdateReviewDto) {
        const review = await this.prisma.review.findUnique({ where: { id } });
        if (!review) throw new NotFoundException('Không tìm thấy đánh giá');
        if (review.userId !== userId) throw new BadRequestException('Bạn không có quyền sửa đánh giá này');

        return await this.prisma.$transaction(async (tx) => {
            const updated = await tx.review.update({
                where: { id },
                data: {
                    rating: data.rating,
                    comment: data.comment
                }
            });

            // neu co update rating thi phai tinh lai avg rating cho prod
            if (data.rating !== undefined) {
                const stats = await tx.review.aggregate({
                    where: { productId: review.productId },
                    _avg: { rating: true },
                    _count: { id: true }
                });

                await tx.product.update({
                    where: { id: review.productId },
                    data: {
                        averageRating: stats._avg.rating || 0,
                        reviewCount: stats._count.id || 0
                    }
                });
            }

            return updated;
        });
    }

    // xoa review
    // tinh lai avg rating
    async deleteReview(id: string) {
        const review = await this.prisma.review.findUnique({ where: { id } });
        if (!review) throw new NotFoundException('Không tìm thấy đánh giá');

        return await this.prisma.$transaction(async (tx) => {
            await tx.review.delete({ where: { id } });

            // tinh lai stats sau khi xoa
            const stats = await tx.review.aggregate({
                where: { productId: review.productId },
                _avg: { rating: true },
                _count: { id: true }
            });

            await tx.product.update({
                where: { id: review.productId },
                data: {
                    averageRating: stats._avg.rating || 0,
                    reviewCount: stats._count.id || 0
                }
            });
        });
    }

    async getPendingReviews(userId: string) {
        // lay truc tiep cac order item chua co review
        const pendingItems = await this.prisma.orderItem.findMany({
            where: {
                order: {
                    userId,
                    status: OrderStatus.DELIVERED
                },
                review: null,
                isReviewedSkipped: false
            },
            include: {
                productVariant: {
                    include: {
                        product: { select: { id: true, name: true, thumbnailUrl: true } }
                    }
                },
                order: { select: { id: true } }
            }
        });

        return pendingItems.map(item => ({
            orderItemId: item.id,
            productId: item.productVariant.product.id,
            name: `${item.productVariant.product.name} (${item.variantName})`,
            image: item.productVariant.imageUrl || item.productVariant.product.thumbnailUrl,
            orderId: item.order.id
        }));
    }

    async skipReview(userId: string, orderItemId: string) {
        const item = await this.prisma.orderItem.findFirst({
            where: {
                id: orderItemId,
                order: { userId }
            }
        });

        if (!item) throw new NotFoundException('Không tìm thấy sản phẩm này trong đơn hàng của bạn');

        return this.prisma.orderItem.update({
            where: { id: orderItemId },
            data: { isReviewedSkipped: true }
        });
    }

    async getUserReviews(userId: string) {
        const reviews = await this.prisma.review.findMany({
            where: { userId },
            include: {
                assets: true,
                user: {
                    select: {
                        id: true,
                        profile: {
                            select: {
                                fullName: true,
                                avatarUrl: true
                            }
                        }
                    }
                },
                orderItem: {
                    include: {
                        productVariant: {
                            select: {
                                attributes: true
                            }
                        }
                    }
                }
            },
            orderBy: { createdAt: 'desc' }
        });

        return reviews.map(review => {
            const attrs = (review.orderItem?.productVariant as any)?.attributes;
            let variantInfo = '';
            if (attrs && typeof attrs === 'object') {
                variantInfo = Object.entries(attrs)
                    .map(([key, value]) => `${key}: ${value}`)
                    .join(', ');
            }

            return {
                ...review,
                variantName: variantInfo || review.orderItem?.variantName || null
            };
        });
    }
}
