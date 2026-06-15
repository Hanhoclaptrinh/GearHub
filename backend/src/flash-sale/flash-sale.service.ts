import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateFlashSaleProductDto } from './dto/create-flash-sale-product.dto';
import { UpdateFlashSaleTimeBulkDto } from './dto/update-flash-sale-time-bulk.dto';
import { Prisma } from '@prisma/client';

@Injectable()
export class FlashSaleService {
    constructor(private readonly prisma: PrismaService) { }

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
            where: { id: productVariantId }
        });
        if (!variant) {
            throw new NotFoundException('Không tìm thấy biến thể sản phẩm này');
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

        return this.prisma.flashSaleProduct.create({
            data: {
                productVariantId,
                flashPrice: new Prisma.Decimal(flashPrice),
                stockLimit,
                startsAt: starts,
                expiresAt: expires,
                soldCount: 0
            }
        });
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

        return this.prisma.flashSaleProduct.delete({
            where: { id }
        });
    }

    // helper
    // xác thực và lấy giá flash sale trong flow đặt hàng
    async validateAndGetFlashSale(productVariantId: string, quantity: number, tx: Prisma.TransactionClient) {
        const now = new Date();

        /**
         * lock dòng dữ liệu tránh race-condition
         * 
         * tránh vấn đề mua lố trong fs
         * 
         * thực hiện tìm chính xác biến thể mà người dùng muốn mua
         * đảm bảo thời điểm user nhấn mua phải nằm trong khoảng thời gian fs đang chạy
         * nếu chưa tới (click sớm) hoặc hết giờ (click trễ) thì skip
         * đảm bảo tại một thời điểm chỉ có tối đa một đợt fs hoạt động
        */
        const flashSales = await tx.$queryRaw<any[]>`
            SELECT id, flash_price as flashPrice, stock_limit as stockLimit, sold_count as soldCount 
            FROM flash_sale_products
            WHERE product_variant_id = ${productVariantId}
              AND starts_at <= ${now}
              AND expires_at >= ${now}
            LIMIT 1
            FOR UPDATE;
        `;

        if (!flashSales || flashSales.length === 0) {
            return null; // không có flash sale đang diễn ra cho sản phẩm này
        }

        const flashSale = flashSales[0];

        // kiểm tra xem lượng mua có vượt quá stock giới hạn không
        if (Number(flashSale.soldCount) + quantity > Number(flashSale.stockLimit)) {
            throw new BadRequestException('Sản phẩm Flash Sale đã hết hàng trong khung giờ này!');
        }

        // thực hiện trừ kho fs
        // hạn mức khuyến mãi
        await tx.flashSaleProduct.update({
            where: { id: flashSale.id },
            data: {
                soldCount: { increment: quantity } // tăng sold count
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
            // giảm sold count đi, giới hạn tối thiểu là 0
            const newSoldCount = Math.max(0, flashSale.soldCount - quantity);
            await tx.flashSaleProduct.update({
                where: { id: flashSale.id },
                data: { soldCount: newSoldCount }
            });
        }
    }
}
