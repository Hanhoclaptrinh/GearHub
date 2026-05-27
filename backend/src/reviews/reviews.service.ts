import { BadRequestException, ConflictException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateReviewDto } from './dto/create-review.dto';
import { OrderStatus, NotificationType } from '@prisma/client';
import { ReplyReviewDto } from './dto/reply-review.dto';
import { UpdateReviewDto } from './dto/update-review.dto';
import { NotificationService } from 'src/notification/notification.service';
import { ConfigService } from '@nestjs/config';
import { GoogleGenerativeAI } from '@google/generative-ai';

@Injectable()
export class ReviewsService {
    private readonly logger = new Logger(ReviewsService.name);

    constructor(
        private prisma: PrismaService,
        private cloudinaryService: CloudinaryService,
        private notificationService: NotificationService,
        private configService: ConfigService,
    ) { }

    /**
     * tạo đánh giá sản phẩm mới cho đơn hàng đã hoàn thành
     * 
     * xác thực thông tin đơn hàng và quyền sở hữu đơn hàng của user
     * kiểm tra trạng thái giao hàng và đơn hàng đã được đánh giá trước đó chưa
     * transaction:
     *    - tạo review
     *    - upload file (nếu có)
     *    - tính avg rating và rating count
     *    - cập nhật lại các chỉ số vào model prod
     */
    async createReview(userId: string, data: CreateReviewDto, files: Express.Multer.File[]) {
        const { orderItemId, rating, comment } = data;

        // thông tin order và quyền sở hữu
        const orderItem = await this.prisma.orderItem.findUnique({
            where: { id: orderItemId },
            include: {
                order: { select: { userId: true, status: true } },
                productVariant: { select: { productId: true } },
                review: { select: { id: true } }
            }
        });

        // validate
        if (!orderItem) {
            throw new NotFoundException('Không tìm thấy sản phẩm trong đơn hàng');
        }
        if (orderItem.order.userId !== userId) {
            throw new BadRequestException('Bạn không có quyền đánh giá sản phẩm này');
        }
        if (orderItem.order.status !== OrderStatus.COMPLETED) {
            throw new BadRequestException('Chỉ đánh giá được sau khi nhận hàng thành công');
        }
        if (orderItem.review) {
            throw new ConflictException('Bạn đã đánh giá sản phẩm này trong đơn hàng này rồi');
        }

        const productId = orderItem.productVariant.productId;

        // transaction
        return await this.prisma.$transaction(async (tx) => {
            // tạo review
            const review = await tx.review.create({
                data: {
                    userId,
                    productId,
                    orderItemId,
                    rating,
                    comment,
                    isVerifiedPurchase: true,
                    isAnonymous: data.isAnonymous ?? false
                }
            });

            // upload file 
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

            // re-calculate avg rating & rating count
            const stats = await tx.review.aggregate({
                where: { productId },
                _avg: { rating: true },
                _count: { id: true }
            });

            // update lại chỉ số vào bảng prod
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

    /**
     * lấy danh sách đánh giá của một sản phẩm cụ thể kèm phân trang và lọc nâng cao
     * 
     * lọc theo rating
     * lọc các review có ảnh
     * lọc trạng thái hidden của review (admin/staff có thể xem được đánh giá bị ẩn)
     */
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
            ...(isAdmin ? {} : { isHidden: false }), // ẩn các đánh giá bị kiểm duyệt nếu không phải là admin/staff
            ...(rating && { rating }),
            ...(hasImage && { assets: { some: {} } }) // lọc các đánh giá có chứa ít nhất 1 asset đính kèm
        };

        // thực hiện đồng thời truy vấn danh sách đánh giá phân trang và đếm tổng số bản ghi
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

        // định dạng lại danh sách đánh giá (biến thể)
        const formattedReviews = reviews.map(review => {
            const attrs = (review.orderItem?.productVariant as any)?.attributes;
            let variantInfo = '';
            if (attrs && typeof attrs === 'object') {
                variantInfo = Object.entries(attrs)
                    .map(([key, value]) => `${key}: ${value}`)
                    .join(', ');
            }

            // định dạng trạng thái tài khoản bình luận
            // ẩn danh / không ẩn danh
            const formattedUser = review.isAnonymous
                ? {
                    id: review.user.id,
                    profile: {
                        fullName: 'Người dùng ẩn danh',
                        avatarUrl: null
                    }
                }
                : review.user;

            return {
                ...review,
                user: formattedUser,
                variantName: (review.orderItem?.productVariant as any)?.attributes
                    ? Object.entries((review.orderItem?.productVariant as any).attributes)
                        .map(([key, value]) => `${key}: ${value}`)
                        .join(', ')
                    : review.orderItem?.variantName
            };
        });

        // trả về kết quả kèm metadata
        return {
            data: formattedReviews,
            meta: {
                total,
                page,
                lastPage: Math.ceil(total / limit)
            }
        };
    }

    /**
     * phản hồi đánh giá của khách hàng (admin/staff)
     *
     * kiểm tra sự tồn tại của đánh giá
     * cập nhật nội dung phản hồi vào db
     * gửi thông báo (push và in-app notification) cho khách hàng đã gửi đánh giá
     */
    async replyReview(id: string, data: ReplyReviewDto) {
        // tìm đánh giá và nạp thông tin tên sản phẩm, thông tin khách hàng để gửi thông báo
        const review = await this.prisma.review.findUnique({
            where: { id },
            include: {
                product: { select: { name: true } },
                user: { select: { id: true } }
            }
        });

        if (!review) {
            throw new NotFoundException('Không tìm thấy đánh giá');
        }

        // cập nhật nội dung phản hồi của cửa hàng
        const updatedReview = await this.prisma.review.update({
            where: { id },
            data: { reply: data.reply },
            include: {
                product: { select: { name: true } }
            }
        });

        // gửi thông báo đến khách hàng (chạy mode best-effort, lỗi gửi thông báo không block kết quả lưu DB)
        try {
            await this.notificationService.sendToUser(review.userId, {
                notification: {
                    title: 'Phản hồi đánh giá',
                    body: `GearHub đã phản hồi đánh giá của bạn về sản phẩm "${updatedReview.product.name}".`,
                },
                data: {
                    type: 'REVIEW_REPLY',
                    reviewId: review.id,
                    productId: review.productId,
                },
                type: NotificationType.SYSTEM
            });
        } catch (error) {
            this.logger.error(`Lỗi gửi thông báo khi phản hồi đánh giá: ${error.message}`);
        }

        return updatedReview;
    }

    /**
     * tính toán thống kê chi tiết đánh giá của một sản phẩm
     * 
     * đếm số lượt đánh giá tương ứng với từng mức điểm
     * tính tổng số lượt đánh giá
     * tính điểm đánh giá trung bình của sản phẩm
     */
    async getReviewSummary(productId: string) {
        // gom nhóm đánh giá theo số sao và đếm số lượng cho từng nhóm
        const counts = await this.prisma.review.groupBy({
            by: ['rating'],
            where: { productId },
            _count: { id: true }
        });

        // đối tượng thống kê
        // 5 nhóm sao
        const summary = {
            "1": 0, "2": 0, "3": 0, "4": 0, "5": 0, total: 0, average: 0
        };

        let totalStars = 0;

        // cộng dồn số lượng đánh giá cho từng mức sao
        counts.forEach(item => {
            const count = item._count.id;
            summary[item.rating.toString()] = count;
            summary.total += count;
            totalStars += item.rating * count;
        });

        // tính điểm trung bình
        if (summary.total > 0) {
            summary.average = Number((totalStars / summary.total).toFixed(1));
        }

        return summary;
    }

    // admin ẩn review
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

    // sửa review
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

            // nếu có update rating thì phải tính lại avg rating cho prod
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

    // xóa review
    // tính lại avg rating
    async deleteReview(id: string) {
        const review = await this.prisma.review.findUnique({ where: { id } });
        if (!review) throw new NotFoundException('Không tìm thấy đánh giá');

        return await this.prisma.$transaction(async (tx) => {
            await tx.review.delete({ where: { id } });

            // tính lại stats sau khi xóa
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
        // lấy các đơn hàng đã nhận nhưng chưa đánh giá
        const pendingItems = await this.prisma.orderItem.findMany({
            where: {
                order: {
                    userId,
                    status: OrderStatus.COMPLETED
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

    // bỏ qua đánh giá - client
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

    /**
     * lấy danh sách tất cả các đánh giá cho trang quản trị (admin/staff)
     * 
     * lọc theo số sao đánh giá
     * lọc theo trạng thái hidden
     * lọc theo trạng thái phản hồi của cửa hàng
     * tìm kiếm tương đối theo bình luận, phản hồi, tên sản phẩm hoặc tên khách hàng
     */
    async getAllReviews(
        page: number = 1,
        limit: number = 10,
        rating?: number,
        repliedStatus?: 'replied' | 'unreplied',
        isHidden?: boolean,
        search?: string,
    ) {
        const skip = (page - 1) * limit;

        // xây dựng điều kiện lọc linh hoạt dựa trên entry param
        const whereCondition: any = {
            ...(rating && { rating }),
            ...(isHidden !== undefined && { isHidden }),
            ...(repliedStatus === 'replied' && { reply: { not: null } }),
            ...(repliedStatus === 'unreplied' && { reply: null }),
            ...(search && {
                OR: [
                    { comment: { contains: search } },
                    { reply: { contains: search } },
                    { product: { name: { contains: search } } },
                    { user: { profile: { fullName: { contains: search } } } },
                ]
            })
        };

        // lấy danh sách đánh giá phân trang và đếm tổng số lượng bản ghi thỏa mãn
        const [reviews, total] = await Promise.all([
            this.prisma.review.findMany({
                where: whereCondition,
                include: {
                    user: {
                        select: {
                            id: true,
                            email: true,
                            profile: {
                                select: {
                                    fullName: true,
                                    avatarUrl: true
                                }
                            }
                        }
                    },
                    product: {
                        select: {
                            id: true,
                            name: true,
                            thumbnailUrl: true,
                            slug: true
                        }
                    },
                    assets: true,
                    orderItem: {
                        select: {
                            variantName: true,
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

        // định dạng lại thông tin thuộc tính biến thể của từng review
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
                variantName: variantInfo || review.orderItem?.variantName || null
            };
        });

        // trả về kết quả định dạng và siêu dữ liệu phân trang
        return {
            data: formattedReviews,
            meta: {
                total,
                page,
                lastPage: Math.ceil(total / limit)
            }
        };
    }

    /**
     * tạo bản nháp câu trả lời đánh giá KH bằng ai api
     * 
     * lấy thông tin chi tiết đánh giá (tên sản phẩm, rating, nội dung bình luận)
     * validate tồn tại của đánh giá và nội dung comment
     * gọi trực tiếp đến api để sinh phản hồi
     * cấu hình phản hồi phù hợp với tính chất đánh giá
     */
    async generateAiReplyDraft(id: string) {
        // tìm đánh giá và nạp tên sản phẩm để gửi vào prompt
        const review = await this.prisma.review.findUnique({
            where: { id },
            include: {
                product: { select: { name: true } }
            }
        });

        // kiểm tra sự tồn tại của review và nội dung bình luận của khách
        if (!review) {
            throw new NotFoundException('Không tìm thấy đánh giá');
        }
        if (!review.comment) {
            throw new BadRequestException('Đánh giá không có nội dung văn bản để AI trả lời');
        }

        const apiKey = this.configService.get<string>('GEMINI_API_KEY');
        if (!apiKey) {
            throw new BadRequestException('GEMINI_API_KEY chưa được cấu hình');
        }

        const modelName = this.configService.get<string>('GEMINI_CHAT_MODEL') || 'gemini-2.5-flash';

        // xây dựng prompt định hướng hành vi của AI
        const prompt = `Bạn là đại diện chăm sóc khách hàng của cửa hàng GearHub (chuyên bán các sản phẩm công nghệ như PC, laptop, điện thoại, gaming gear, linh kiện máy tính, bàn phím cơ, chuột gaming, tai nghe, ...).
                        Hãy viết một phản hồi lịch sự, thân thiện và chuyên nghiệp cho đánh giá của khách hàng sau đây:
                        - Tên sản phẩm khách đã mua: "${review.product.name}"
                        - Điểm đánh giá (Rating): ${review.rating}/5 sao
                        - Nội dung bình luận của khách hàng: "${review.comment}"

                        Yêu cầu về nội dung:
                        1. Nếu khách hàng đánh giá tích cực (4-5 sao): Hãy cảm ơn khách hàng nhiệt tình, bày tỏ niềm vui và khích lệ họ tiếp tục ủng hộ.
                        2. Nếu khách hàng đánh giá trung bình hoặc tiêu cực (1-3 sao): Hãy bắt đầu bằng lời xin lỗi chân thành về trải nghiệm chưa tốt, cam kết sẽ cải thiện chất lượng dịch vụ/sản phẩm và đề xuất khách hàng liên hệ hotline/chat trực tiếp nếu cần hỗ trợ kỹ thuật hoặc đổi trả.
                        3. Ngôn ngữ: Tiếng Việt chuẩn xác, thân thiện, lịch sự (xưng hô "GearHub" và "Dạ chào bạn / Cảm ơn bạn / Xin lỗi bạn").
                        4. Độ dài: Ngắn gọn, súc tích (khoảng 2-3 câu, tối đa 120 từ), đi thẳng vào vấn đề, không dài dòng. Không chứa bất kỳ placeholder (như [Tên khách hàng], [Ngày]) hay ký tự đặc biệt như dấu sao (*). Trả về trực tiếp văn bản phản hồi.`;

        // call api sinh phản hồi
        try {
            const genAi = new GoogleGenerativeAI(apiKey);
            const model = genAi.getGenerativeModel({ model: modelName });
            const result = await model.generateContent(prompt);
            const replyDraft = result.response.text().trim();
            return { replyDraft };
        } catch (error) {
            this.logger.error(`Lỗi gọi Gemini sinh câu trả lời đánh giá: ${error.message}`);
            throw new BadRequestException(`Không thể sinh câu trả lời tự động: ${error.message}`);
        }
    }

    // lấy thống kê đánh giá toàn hệ thống
    async getReviewStats() {
        const [total, avgRating, unreplied, hidden] = await Promise.all([
            this.prisma.review.count(),
            this.prisma.review.aggregate({
                _avg: { rating: true }
            }),
            this.prisma.review.count({
                where: { reply: null }
            }),
            this.prisma.review.count({
                where: { isHidden: true }
            })
        ]);

        return {
            total,
            average: Number((avgRating._avg.rating || 0).toFixed(1)),
            unreplied,
            hidden
        };
    }
}
