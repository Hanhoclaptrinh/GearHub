import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateReviewDto } from './dto/create-review.dto';
import { OrderStatus } from '@prisma/client';
import { ReplyReviewDto } from './dto/reply-review.dto';

@Injectable()
export class ReviewsService {
    constructor(
        private prisma: PrismaService,
        private cloudinaryService: CloudinaryService
    ) { }

    // tao danh gia
    async createReview(userId: string, data: CreateReviewDto, files: Express.Multer.File[]) {
        const { productId, rating, comment, orderId } = data;

        // kiem tra sp ton tai
        const prod = await this.prisma.product.findUnique({
            where: { id: productId }
        });
        if (!prod) throw new NotFoundException('Sản phẩm không tồn tại');

        // check user da tung review san pham chua
        const existingReview = await this.prisma.review.findUnique({
            where: { userId_productId: { userId, productId } }
        });
        if (existingReview) throw new ConflictException('Bạn đã đánh giá sản phẩm này rồi');

        // xac nhan da mua hang
        const orderItem = await this.prisma.orderItem.findFirst({
            where: {
                productVariant: {
                    productId
                },
                order: {
                    userId,
                    status: OrderStatus.DELIVERED
                }
            },
            select: {
                id: true
            }
        });
        if (!orderItem) {
            throw new BadRequestException('Bạn chỉ có thể đánh giá sản phẩm sau khi đã mua và nhận hàng thành công');
        }

        return await this.prisma.$transaction(async (tx) => {
            // tao review
            const review = await tx.review.create({
                data: {
                    userId,
                    productId,
                    orderId,
                    rating,
                    comment,
                    isVerifiedPurchase: !!orderItem
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
    async getProductReviews(productId: string, page: number = 1, limit: number = 10) {
        const skip = (page - 1) * limit;

        const [reviews, total] = await Promise.all([
            this.prisma.review.findMany({
                where: { productId },
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
                    assets: true
                },
                orderBy: { createdAt: 'desc' },
                skip,
                take: limit
            }),
            this.prisma.review.count({ where: { productId } })
        ]);

        return {
            data: reviews,
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
}
