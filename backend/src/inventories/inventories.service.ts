import { BadRequestException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { InventoryTransactionType, Prisma } from '@prisma/client';
import { AdjustmentMode } from './dto/adjust-stock.dto';

interface AdjustStockParams {
    variantId: string;
    type: InventoryTransactionType;
    quantity: number;
    reason?: string;
    referenceId?: string;
    createdById?: string;
    mode?: AdjustmentMode;
    tx?: Prisma.TransactionClient;
}

const DEDUCT_TYPES: InventoryTransactionType[] = [
    InventoryTransactionType.SALE,
    InventoryTransactionType.DAMAGED,
];

const ADD_TYPES: InventoryTransactionType[] = [
    InventoryTransactionType.INITIAL_IMPORT,
    InventoryTransactionType.IMPORT,
    InventoryTransactionType.ORDER_CANCEL,
    InventoryTransactionType.RETURN,
];

@Injectable()
export class InventoriesService {
    private readonly logger = new Logger(InventoriesService.name);

    constructor(private prisma: PrismaService) { }

    async adjustStock(params: AdjustStockParams) {
        const { variantId, type, quantity, reason, referenceId, createdById, mode, tx } = params;

        if (quantity <= 0) {
            throw new BadRequestException('Số lượng phải lớn hơn 0');
        }

        const execute = async (client: Prisma.TransactionClient) => {
            const variant = await client.productVariant.findUnique({
                where: { id: variantId },
            });

            if (!variant) {
                throw new NotFoundException(`Biến thể ${variantId} không tồn tại`);
            }

            const beforeStock = variant.stock;
            let afterStock: number;

            if (type === InventoryTransactionType.ADJUSTMENT) {
                if (!mode) {
                    throw new BadRequestException('ADJUSTMENT cần có mode INCREASE hoặc DECREASE');
                }
                afterStock = mode === AdjustmentMode.INCREASE
                    ? beforeStock + quantity
                    : beforeStock - quantity;
            } else if (DEDUCT_TYPES.includes(type)) {
                afterStock = beforeStock - quantity;
            } else if (ADD_TYPES.includes(type)) {
                afterStock = beforeStock + quantity;
            } else {
                throw new BadRequestException(`Loại giao dịch không hợp lệ: ${type}`);
            }

            if (afterStock < 0) {
                throw new BadRequestException(
                    `Không đủ tồn kho. Hiện tại: ${beforeStock}, yêu cầu giảm: ${quantity}`,
                );
            }

            const updatedVariant = await client.productVariant.update({
                where: { id: variantId },
                data: { stock: afterStock },
            });

            const transaction = await client.inventoryTransaction.create({
                data: {
                    variantId,
                    type,
                    quantity,
                    beforeStock,
                    afterStock,
                    reason: reason || null,
                    referenceId: referenceId || null,
                    createdById: createdById || null,
                },
            });

            this.logger.log(
                `Stock adjusted: variant=${variantId} type=${type} qty=${quantity} before=${beforeStock} after=${afterStock}`,
            );

            return { variant: updatedVariant, transaction };
        };

        if (tx) {
            return execute(tx);
        }

        return this.prisma.$transaction(async (txClient) => {
            return execute(txClient);
        });
    }

    private async getAllCategoryIds(categoryId: string): Promise<string[]> {
        const ids = [categoryId];
        const children = await this.prisma.category.findMany({
            where: { parentId: categoryId },
            select: { id: true },
        });

        for (const child of children) {
            const childIds = await this.getAllCategoryIds(child.id);
            ids.push(...childIds);
        }

        return ids;
    }

    async getInventoryList(query: {
        search?: string;
        categoryId?: string;
        brandId?: string;
        stockFilter?: 'all' | 'low_stock' | 'out_of_stock';
        page?: number;
        limit?: number;
    }) {
        const { search, categoryId, brandId, stockFilter = 'all', page = 1, limit = 20 } = query;
        const skip = (page - 1) * limit;
        const LOW_STOCK_THRESHOLD = 10;

        // filter cate cha
        let categoryIds: string[] | undefined;
        if (categoryId) {
            categoryIds = await this.getAllCategoryIds(categoryId);
        }

        // filter prod
        const productWhere: Prisma.ProductWhereInput = {
            isActive: true,
        };

        if (categoryIds) {
            productWhere.categoryId = { in: categoryIds };
        }

        if (brandId) {
            productWhere.brandId = brandId;
        }

        if (search) {
            productWhere.OR = [
                { name: { contains: search } },
                { slug: { contains: search } },
                { variants: { some: { OR: [{ sku: { contains: search } }, { name: { contains: search } }] } } },
            ];
        }

        // filter variant
        const variantWhere: Prisma.ProductVariantWhereInput = {};
        if (stockFilter === 'low_stock') {
            variantWhere.stock = { gt: 0, lte: LOW_STOCK_THRESHOLD };
        } else if (stockFilter === 'out_of_stock') {
            variantWhere.stock = 0;
        }

        if (search) {
            variantWhere.OR = [
                { sku: { contains: search } },
                { name: { contains: search } },
            ];
        }
        if (stockFilter !== 'all') {
            productWhere.variants = {
                some: variantWhere
            };
        }

        const [products, total] = await Promise.all([
            this.prisma.product.findMany({
                where: productWhere,
                include: {
                    category: { select: { id: true, name: true } },
                    brand: { select: { id: true, name: true } },
                    variants: {
                        where: variantWhere,
                        orderBy: { sku: 'asc' },
                    },
                },
                orderBy: { createdAt: 'desc' },
                skip,
                take: Number(limit),
            }),
            this.prisma.product.count({ where: productWhere }),
        ]);

        const data = products.map((product) => {
            const totalStock = product.variants.reduce((sum, v) => sum + v.stock, 0);

            return {
                productId: product.id,
                productName: product.name,
                thumbnailUrl: product.thumbnailUrl,
                category: product.category,
                brand: product.brand,
                totalStock,
                variants: product.variants.map((v) => ({
                    variantId: v.id,
                    sku: v.sku,
                    variantName: v.name,
                    attributes: v.attributes,
                    currentStock: v.stock,
                    price: v.price,
                    imageUrl: v.imageUrl,
                    isActive: v.isActive,
                    stockStatus:
                        v.stock === 0
                            ? 'OUT_OF_STOCK'
                            : v.stock <= LOW_STOCK_THRESHOLD
                                ? 'LOW_STOCK'
                                : 'IN_STOCK',
                })),
            };
        });

        return {
            data,
            meta: {
                total,
                page: Number(page),
                limit: Number(limit),
                lastPage: Math.ceil(total / Number(limit)),
            },
        };
    }

    async getTransactionHistory(
        variantId: string,
        query: { page?: number; limit?: number },
    ) {
        const { page = 1, limit = 20 } = query;
        const skip = (page - 1) * limit;

        const variant = await this.prisma.productVariant.findUnique({
            where: { id: variantId },
            select: { id: true, sku: true, name: true, stock: true },
        });

        if (!variant) {
            throw new NotFoundException('Biến thể không tồn tại');
        }

        const [transactions, total] = await Promise.all([
            this.prisma.inventoryTransaction.findMany({
                where: { variantId },
                include: {
                    createdBy: {
                        select: {
                            id: true,
                            email: true,
                            profile: { select: { fullName: true } },
                        },
                    },
                },
                orderBy: { createdAt: 'desc' },
                skip,
                take: Number(limit),
            }),
            this.prisma.inventoryTransaction.count({ where: { variantId } }),
        ]);

        return {
            variant,
            data: transactions,
            meta: {
                total,
                page: Number(page),
                limit: Number(limit),
                lastPage: Math.ceil(total / Number(limit)),
            },
        };
    }
}
