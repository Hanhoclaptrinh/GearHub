import { Injectable, NotFoundException, BadRequestException, Logger } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateFlashSaleProductDto } from './dto/create-flash-sale-product.dto';
import { UpdateFlashSaleTimeBulkDto } from './dto/update-flash-sale-time-bulk.dto';
import { Prisma, NotificationType } from '@prisma/client';
import { RedisService } from 'src/redis/redis.service';
import { NotificationService } from 'src/notification/notification.service';
import { Cron, CronExpression } from '@nestjs/schedule';

@Injectable()
export class FlashSaleService {
    private readonly logger = new Logger(FlashSaleService.name);

    constructor(
        private readonly prisma: PrismaService,
        private readonly redisService: RedisService,
        private readonly notificationService: NotificationService,
    ) { }

    // lấy danh sách các sản phẩm đang chạy chương trình fs
    async getClientFlashSales(status: 'active' | 'upcoming' | 'all' = 'all') {
        const now = new Date();
        const where: Prisma.FlashSaleProductWhereInput = {};

        // chỉ lấy các sản phẩm đang được giảm giá
        if (status === 'active') {
            where.startsAt = { lte: now };
            where.expiresAt = { gte: now };
        } else if (status === 'upcoming') { // sắp diễn ra
            where.startsAt = { gt: now };
            where.expiresAt = { gte: now };
        } else {
            where.expiresAt = { gte: now };
        }

        return this.prisma.flashSaleProduct.findMany({
            where,
            include: {
                productVariant: {
                    include: {
                        product: {
                            select: {
                                id: true,
                                name: true,
                                slug: true,
                                thumbnailUrl: true,
                            }
                        }
                    }
                }
            },
            orderBy: [
                { startsAt: 'asc' },
                { createdAt: 'desc' }
            ]
        });
    }

    // thêm sản phẩm vào danh sách fs - admin flow
    async createFlashSaleProduct(dto: CreateFlashSaleProductDto) {
        const { productVariantId, flashPrice, stockLimit, startsAt, expiresAt } = dto;

        // kiểm tra biến thể tồn tại
        const variant = await this.prisma.productVariant.findUnique({
            where: { id: productVariantId },
            include: { product: true }
        });
        if (!variant) {
            throw new NotFoundException('Không tìm thấy biến thể sản phẩm này');
        }

        // kiểm tra số lượng limit so với tồn kho thực tế
        if (stockLimit > variant.stock) {
            throw new BadRequestException(
                `Số lượng giới hạn Flash Sale (${stockLimit}) không được vượt quá số lượng tồn kho thực tế của sản phẩm (Hiện có: ${variant.stock})`
            );
        }

        // time validate
        const starts = new Date(startsAt);
        const expires = new Date(expiresAt);
        const now = new Date();

        if (starts >= expires) {
            throw new BadRequestException('Thời gian bắt đầu phải trước thời gian kết thúc');
        }
        if (expires <= now) {
            throw new BadRequestException('Thời gian kết thúc phải lớn hơn thời gian hiện tại');
        }

        /**
         * check trùng lịch cho cùng một biến thể sp
         * chặn không cho admin tạo thêm đợt fs mới cho sp A
         * trùng khung giờ mà sp A đang được lên lịch chạy một đợt fs
         * khác đã có trong db
         * 
         * eg: sp A đã được lên lịch fs từ 9-12h
         * - case 1: sale mới bao trùm đợt cũ: 10h-12h
         * - case 2: đợt mới bị chèn start vào expire của đợt cũ: 11h-14h
         * - case 3: đợt mới bị chèn expire vào start của đợt cũ: 7h-10h 
        */
        const overlap = await this.prisma.flashSaleProduct.findFirst({
            where: {
                productVariantId,
                OR: [
                    {
                        // đợt sale mới bao trùm đợt sale cũ
                        startsAt: { lte: starts },
                        expiresAt: { gte: expires }
                    },
                    {
                        // đợt sale mới bắt đầu nằm trong đợt sale cũ
                        startsAt: { lte: starts },
                        expiresAt: { gt: starts }
                    },
                    {
                        // đợt sale mới kết thúc nằm trong đợt sale cũ
                        startsAt: { lt: expires },
                        expiresAt: { gte: expires }
                    }
                ]
            }
        });
        // không cho tạo trùng lịch :))
        if (overlap) {
            throw new BadRequestException('Sản phẩm đã có lịch tham gia Flash Sale khác trùng thời gian này');
        }

        const newFsProduct = await this.prisma.flashSaleProduct.create({
            data: {
                productVariantId,
                flashPrice: new Prisma.Decimal(flashPrice),
                stockLimit,
                startsAt: starts,
                expiresAt: expires,
                soldCount: 0
            }
        });

        /**
         * đồng bộ tồn kho flashsale từ db lên redis
         * xử lý chịu tải cao
         * hạn chế nghẽn cổ chai - nhiều user truy cập cùng lúc
        */
        // key định danh
        const redisKey = `flash_sale:stock:${productVariantId}`;
        // thời gian hết hạn key - milisecond
        const ttlMs = expires.getTime() - Date.now();
        if (ttlMs > 0) {
            await this.redisService.set(redisKey, stockLimit, 'PX', ttlMs);
        }

        // gửi thông báo đẩy đến tất cả user
        try {
            const formattedPrice = new Intl.NumberFormat('vi-VN', {
                style: 'currency',
                currency: 'VND',
                maximumFractionDigits: 0,
            }).format(flashPrice);

            await this.notificationService.sendToAll({
                notification: {
                    title: '🔥 SIÊU KHUYẾN MÃI! 🔥',
                    body: `Sản phẩm "${variant.product.name}" sẽ được mở bán Flash Sale với giá cực sốc ${formattedPrice} vào lúc ${starts.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })} ngày ${starts.toLocaleDateString('vi-VN')}!`,
                },
                data: {
                    type: 'flash_sale',
                    productVariantId,
                },
                type: NotificationType.SYSTEM,
            });
        } catch (err) { }

        return newFsProduct;
    }

    // thêm sản phẩm vào danh sách fs hàng loạt - admin flow
    async createFlashSaleBulk(dto: any) {
        const { productVariantIds, discountType, discountValue, stockLimit, startsAt, expiresAt } = dto;
        const starts = new Date(startsAt);
        const expires = new Date(expiresAt);
        const now = new Date();

        if (starts >= expires) {
            throw new BadRequestException('Thời gian bắt đầu phải trước thời gian kết thúc');
        }
        if (expires <= now) {
            throw new BadRequestException('Thời gian kết thúc phải lớn hơn thời gian hiện tại');
        }

        // lấy tất cả thông tin biến thể
        const variants = await this.prisma.productVariant.findMany({
            where: { id: { in: productVariantIds } }
        });

        if (variants.length !== productVariantIds.length) {
            throw new NotFoundException('Một hoặc nhiều biến thể sản phẩm không được tìm thấy');
        }

        // kiểm tra số lượng limit so với tồn kho thực tế của từng sản phẩm trước khi tạo
        for (const variant of variants) {
            if (stockLimit > variant.stock) {
                throw new BadRequestException(
                    `Sản phẩm SKU ${variant.sku} chỉ còn ${variant.stock} sản phẩm trong kho, không thể thiết lập giới hạn Flash Sale là ${stockLimit}`
                );
            }
        }

        const result = await this.prisma.$transaction(async (tx) => {
            const createdProducts: any[] = [];

            for (const variant of variants) {
                // tính toán giá flash sale
                let flashPrice = 0;
                const basePrice = Number(variant.price); // giá ban đầu

                // thực hiện cập nhật giá fs dựa trên loại giảm giá
                // theo %, fix cứng giá được giảm hoặc niêm yết giá cuối (giá fs)
                if (discountType === 'PERCENT') {
                    flashPrice = basePrice * (1 - discountValue / 100);
                } else if (discountType === 'FIXED_AMOUNT') {
                    flashPrice = Math.max(0, basePrice - discountValue);
                } else if (discountType === 'PRICE') {
                    flashPrice = discountValue;
                }

                // kiểm tra trùng lịch
                const overlap = await tx.flashSaleProduct.findFirst({
                    where: {
                        productVariantId: variant.id,
                        OR: [
                            {
                                startsAt: { lte: starts },
                                expiresAt: { gte: expires }
                            },
                            {
                                startsAt: { lte: starts },
                                expiresAt: { gt: starts }
                            },
                            {
                                startsAt: { lt: expires },
                                expiresAt: { gte: expires }
                            }
                        ]
                    }
                });

                if (overlap) {
                    throw new BadRequestException(
                        `Sản phẩm SKU ${variant.sku} đã có lịch tham gia Flash Sale khác trùng thời gian này`
                    );
                }

                const newFsProduct = await tx.flashSaleProduct.create({
                    data: {
                        productVariantId: variant.id,
                        flashPrice: new Prisma.Decimal(flashPrice),
                        stockLimit,
                        startsAt: starts,
                        expiresAt: expires,
                        soldCount: 0
                    }
                });
                createdProducts.push(newFsProduct);

                // đồng bộ tồn kho lên redis
                const redisKey = `flash_sale:stock:${variant.id}`;
                const ttlMs = expires.getTime() - Date.now();
                if (ttlMs > 0) {
                    await this.redisService.set(redisKey, stockLimit, 'PX', ttlMs);
                }
            }

            return {
                message: `Đã lên lịch thành công cho ${createdProducts.length} sản phẩm Flash Sale`,
                count: createdProducts.length
            };
        });

        // gửi thông báo đẩy đến tất cả user
        try {
            await this.notificationService.sendToAll({
                notification: {
                    title: '🔥 ĐẠI TIỆC FLASH SALE GIỜ VÀNG! 🔥',
                    body: `Có thêm ${variants.length} sản phẩm cực hot vừa được lên lịch mở bán Flash Sale vào lúc ${starts.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })} ngày ${starts.toLocaleDateString('vi-VN')}! Đừng bỏ lỡ!`,
                },
                data: {
                    type: 'flash_sale',
                },
                type: NotificationType.SYSTEM,
            });
        } catch (err) { }

        return result;
    }

    // cập nhật thời gian hàng loạt
    async updateFlashSaleTimeBulk(dto: UpdateFlashSaleTimeBulkDto) {
        const { ids, startsAt, expiresAt } = dto;
        const starts = new Date(startsAt);
        const expires = new Date(expiresAt);

        if (starts >= expires) {
            throw new BadRequestException('Thời gian bắt đầu phải trước thời gian kết thúc');
        }

        // lấy thông tin các sản phẩm tham gia để có productVariantId
        const flashSaleProducts = await this.prisma.flashSaleProduct.findMany({
            where: { id: { in: ids } },
            select: { id: true, productVariantId: true }
        });

        const variantIds = flashSaleProducts.map(fp => fp.productVariantId);

        // kiểm tra trùng lịch với các đợt sale khác (không nằm trong danh sách đang sửa)
        const overlap = await this.prisma.flashSaleProduct.findFirst({
            where: {
                productVariantId: { in: variantIds },
                id: { notIn: ids }, // bỏ qua chính những bản ghi đang sửa giờ
                OR: [
                    {
                        startsAt: { lte: starts },
                        expiresAt: { gte: expires }
                    },
                    {
                        startsAt: { lte: starts },
                        expiresAt: { gt: starts }
                    },
                    {
                        startsAt: { lt: expires },
                        expiresAt: { gte: expires }
                    }
                ]
            },
            include: {
                productVariant: true
            }
        });

        if (overlap) {
            throw new BadRequestException(
                `Sản phẩm với SKU ${overlap.productVariant.sku} bị trùng lịch với một chương trình Flash Sale khác trong khoảng thời gian này!`
            );
        }

        const result = await this.prisma.flashSaleProduct.updateMany({
            where: {
                id: { in: ids }
            },
            data: {
                startsAt: starts,
                expiresAt: expires
            }
        });

        // lấy thông tin mới nhất từ db của các sp fs vừa được update thời gian
        const updatedProducts = await this.prisma.flashSaleProduct.findMany({
            where: { id: { in: ids } }
        });
        // duyệt từng sp để update lại cấu hình trên redis
        for (const fp of updatedProducts) {
            const redisKey = `flash_sale:stock:${fp.productVariantId}`;
            // tính lại thời gian hết hạn mới dựa trên thời gian expire mới vừa được update
            const ttlMs = fp.expiresAt.getTime() - Date.now();
            if (ttlMs > 0) {
                const remaining = fp.stockLimit - fp.soldCount;
                await this.redisService.set(redisKey, remaining, 'PX', ttlMs);
            } else {
                await this.redisService.del(redisKey);
            }
        }

        return {
            message: `Đã cập nhật thời gian thành công cho ${result.count} sản phẩm Flash Sale`,
            count: result.count
        };
    }

    // danh sách tất cả flash sale - admin flow
    async findAllAdmin(page = 1, limit = 10, search?: string) {
        const skip = (page - 1) * limit;
        const where: Prisma.FlashSaleProductWhereInput = {};

        if (search) {
            where.productVariant = {
                OR: [
                    { name: { contains: search } },
                    { sku: { contains: search } },
                    { product: { name: { contains: search } } }
                ]
            };
        }

        const [data, total] = await Promise.all([
            this.prisma.flashSaleProduct.findMany({
                where,
                skip,
                take: limit,
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
                },
                orderBy: { startsAt: 'desc' }
            }),
            this.prisma.flashSaleProduct.count({ where })
        ]);

        return {
            data,
            meta: {
                total,
                page,
                limit,
                lastPage: Math.ceil(total / limit)
            }
        };
    }

    // xóa sp khỏi fs
    async remove(id: string) {
        const exist = await this.prisma.flashSaleProduct.findUnique({
            where: { id }
        });
        if (!exist) {
            throw new NotFoundException('Không tìm thấy bản ghi Flash Sale này');
        }

        const deleted = await this.prisma.flashSaleProduct.delete({
            where: { id }
        });

        // xóa khỏi Redis
        const redisKey = `flash_sale:stock:${deleted.productVariantId}`;
        await this.redisService.del(redisKey);

        return deleted;
    }

    // helper
    // xác thực và lấy giá flash sale trong flow đặt hàng
    async validateAndGetFlashSale(productVariantId: string, quantity: number, tx: Prisma.TransactionClient) {
        const now = new Date();
        // kiểm tra có chương trình fs nào đang hoạt động không
        const flashSale = await tx.flashSaleProduct.findFirst({
            where: {
                productVariantId,
                startsAt: { lte: now },
                expiresAt: { gte: now }
            }
        });

        if (!flashSale) {
            return null; // không có flash sale đang diễn ra cho sản phẩm này
        }

        // tự động nạp tồn kho vào redis nếu bị mất cache
        const redisKey = `flash_sale:stock:${productVariantId}`;
        let redisStock = await this.redisService.get(redisKey);
        if (redisStock === null) {
            const remaining = flashSale.stockLimit - flashSale.soldCount;
            const ttlMs = flashSale.expiresAt.getTime() - now.getTime();
            if (ttlMs > 0) {
                await this.redisService.set(redisKey, remaining, 'PX', ttlMs);
                redisStock = remaining.toString();
            } else {
                return null;
            }
        }

        // dùng decrby trừ đi số lượng user muốn mua trực tiếp trên RAM
        const remaining = await this.redisService.decrby(redisKey, quantity);

        if (remaining < 0) {
            // nếu mua lố, rollback cộng lại số lượng đã trừ
            await this.redisService.incrby(redisKey, quantity);
            throw new BadRequestException('Sản phẩm Flash Sale đã hết hàng trong khung giờ này!');
        }

        // bán sp fs thành công
        // đồng bộ số lượng bán vào db
        await tx.flashSaleProduct.update({
            where: { id: flashSale.id },
            data: {
                soldCount: { increment: quantity }
            }
        });

        return {
            id: flashSale.id,
            flashPrice: Number(flashSale.flashPrice)
        };
    }

    // helper
    // hoàn trả lại số lượng bán fs khi đơn hàng bị huỷ/trả
    async rollbackFlashSaleStock(productVariantId: string, quantity: number, orderCreatedAt: Date, tx: Prisma.TransactionClient) {
        // tìm xem sản phẩm có tham gia đợt flash sale nào tại thời điểm tạo đơn hàng không
        const flashSale = await tx.flashSaleProduct.findFirst({
            where: {
                productVariantId,
                startsAt: { lte: orderCreatedAt },
                expiresAt: { gte: orderCreatedAt }
            }
        });

        if (flashSale) {
            const newSoldCount = Math.max(0, flashSale.soldCount - quantity);
            await tx.flashSaleProduct.update({
                where: { id: flashSale.id },
                data: { soldCount: newSoldCount }
            });

            // Cập nhật lại kho trên Redis
            await this.incrbyRedisStock(productVariantId, quantity);
        }
    }

    // helper để hoàn trả kho Redis trực tiếp
    async incrbyRedisStock(productVariantId: string, quantity: number) {
        const redisKey = `flash_sale:stock:${productVariantId}`;
        const exists = await this.redisService.exists(redisKey);
        if (exists) {
            await this.redisService.incrby(redisKey, quantity);
        }
    }

    // cronjob chạy mỗi phút quét các chương trình fs chuẩn bị bắt đầu
    @Cron(CronExpression.EVERY_MINUTE)
    async handleFlashSaleStartNotifications() {
        const now = new Date();
        // lấy thời gian của phút hiện tại
        // có thể trễ/sớm vài giây
        const currentMinuteStart = new Date(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours(), now.getMinutes(), 0);
        const currentMinuteEnd = new Date(now.getFullYear(), now.getMonth(), now.getDate(), now.getHours(), now.getMinutes(), 59, 999);

        try {
            // lấy danh sách sản phẩm fs bắt đầu trong phút này
            const startingFlashSales = await this.prisma.flashSaleProduct.findMany({
                where: {
                    startsAt: {
                        gte: currentMinuteStart,
                        lte: currentMinuteEnd,
                    },
                },
                include: {
                    productVariant: {
                        include: {
                            product: {
                                select: {
                                    id: true,
                                    name: true,
                                },
                            },
                        },
                    },
                },
            });

            if (startingFlashSales.length === 0) return;

            // nhóm các fs prod theo productId của sản phẩm gốc
            const groupedByProduct: Record<string, typeof startingFlashSales> = {};
            for (const fs of startingFlashSales) {
                const productId = fs.productVariant.product.id;
                if (!groupedByProduct[productId]) {
                    groupedByProduct[productId] = [];
                }
                groupedByProduct[productId].push(fs);
            }

            // duyệt qua từng sản phẩm gốc để gửi thông báo
            for (const productId of Object.keys(groupedByProduct)) {
                const group = groupedByProduct[productId];
                // biến thể đầu tiên cho deeplink
                const representative = group[0];

                // tìm giá fs thấp nhất trong nhóm để hiển thị
                const prices = group.map(fs => Number(fs.flashPrice));
                const minPrice = Math.min(...prices);

                // lock theo productId để tránh gửi trùng lặp cho sản phẩm
                const notificationKey = `flash_sale:start_notified:product:${productId}:${representative.startsAt.getTime()}`;
                const alreadyNotified = await this.redisService.get(notificationKey);
                if (alreadyNotified) continue;

                // set lock tồn tại trong 2 phút
                await this.redisService.set(notificationKey, 'true', 'EX', 120);

                const productName = representative.productVariant.product.name;
                const formattedPrice = new Intl.NumberFormat('vi-VN', {
                    style: 'currency',
                    currency: 'VND',
                    maximumFractionDigits: 0,
                }).format(minPrice);

                const countText = group.length > 1 ? ` (${group.length} phiên bản)` : '';
                this.logger.log(`Broadcasting Flash Sale start notification for product: ${productName}${countText} (Product ID: ${productId})`);

                // gửi thông báo cho toàn bộ thiết bị
                await this.notificationService.sendToAll({
                    notification: {
                        title: '⚡ CHÍNH THỨC MỞ BÁN FLASH SALE! ⚡',
                        body: `Sản phẩm "${productName}"${countText} đã chính thức mở bán Flash Sale với mức giá chỉ từ ${formattedPrice}! Săn ngay kẻo lỡ!`,
                    },
                    data: {
                        type: 'flash_sale',
                        productVariantId: representative.productVariantId,
                    },
                    type: NotificationType.PROMOTION,
                });
            }
        } catch (error) {
            this.logger.error(`Failed to handle flash sale start notifications: ${error instanceof Error ? error.message : error}`);
        }
    }
}
