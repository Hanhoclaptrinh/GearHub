import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateProductDto } from './dto/create-product.dto';
import slugify from 'slugify';
import { AssetType } from '@prisma/client';
import { UpdateProductDto } from './dto/update-product.dto';

@Injectable()
export class ProductsService {
    constructor(
        private prisma: PrismaService,
        private cloudinaryService: CloudinaryService
    ) { }

    // ADMIN
    async createProduct(data: CreateProductDto, files: Express.Multer.File[]) {
        const existingProduct = await this.prisma.product.findFirst({
            where: { name: data.name }
        });
        if (existingProduct) {
            throw new BadRequestException(`Sản phẩm với tên '${data.name}' đã tồn tại`);
        }

        const slug = slugify(data.name, { lower: true, strict: true });

        // parse dinh dang truoc khi gui 
        const parsedMetadata = data.metadata ? JSON.parse(data.metadata) : {};
        const parsedAttributes = data.attributes ? JSON.parse(data.attributes) : {};

        return await this.prisma.$transaction(async (tx) => {
            // parent prod
            const product = await tx.product.create({
                data: {
                    name: data.name,
                    slug: slug,
                    description: data.description,
                    categoryId: data.categoryId,
                    brandId: data.brandId,
                    metadata: parsedMetadata,
                    thumbnailUrl: data.thumbnailUrl || null,
                }
            });

            // tao variant
            await tx.productVariant.create({
                data: {
                    productId: product.id,
                    sku: `${slug}-default`,
                    name: `${data.name} - Standard`,
                    price: parseFloat(data.price),
                    stock: parseInt(data.stock || '0'),
                    attributes: parsedAttributes
                }
            });

            // xu ly upload file
            let finalThumbnailUrl = product.thumbnailUrl;

            if (files && files.length > 0) {
                const assetPromises = files.map(async (file) => {
                    const upload = await this.cloudinaryService.uploadFile(file);
                    const fileName = file.originalname.toLowerCase();

                    let type: AssetType = AssetType.IMAGE;
                    if (fileName.endsWith('.glb')) type = AssetType.GLB;
                    else if (fileName.endsWith('.usdz')) type = AssetType.USDZ;

                    return tx.productAsset.create({
                        data: {
                            productId: product.id,
                            url: upload.secure_url,
                            type: type,
                            isPrimary: false,
                        },
                    });
                });

                const assets = await Promise.all(assetPromises);

                if (!finalThumbnailUrl) {
                    const firstImageAsset = assets.find((a) => a.type === AssetType.IMAGE);
                    if (firstImageAsset) {
                        finalThumbnailUrl = firstImageAsset.url;
                        await tx.product.update({
                            where: { id: product.id },
                            data: { thumbnailUrl: finalThumbnailUrl },
                        });
                    }
                }
            }

            return tx.product.findUnique({
                where: { id: product.id },
                include: {
                    variants: true, // tra prod info kem variant
                    assets: true,
                    category: true,
                    brand: true
                },
            });
        });
    }

    async updateProduct(id: string, data: UpdateProductDto, files?: Express.Multer.File[]) {
        const product = await this.prisma.product.findUnique({
            where: { id },
            include: { variants: { take: 1 } } // lay variant dau tien
        });
        if (!product) throw new NotFoundException('Sản phẩm không tồn tại');

        // neu update name thi check slug
        if (data.name) {
            const newSlug = slugify(data.name, { lower: true, strict: true });

            const duplicateSlug = await this.prisma.product.findFirst({
                where: {
                    slug: newSlug,
                    id: { not: id }
                }
            });

            if (duplicateSlug) {
                throw new BadRequestException(`Tên sản phẩm '${data.name}' gây trùng lặp đường dẫn với sản phẩm khác`);
            }
        }

        return await this.prisma.$transaction(async (tx) => {
            // chuan bi data cho parent prod
            const updateData: any = {};
            if (data.name) updateData.name = data.name;
            if (data.name) {
                updateData.name = data.name;
                updateData.slug = slugify(data.name, { lower: true, strict: true });
            }
            if (data.description) updateData.description = data.description;
            if (data.categoryId) updateData.categoryId = data.categoryId;
            if (data.brandId) updateData.brandId = data.brandId;
            if (data.thumbnailUrl) updateData.thumbnailUrl = data.thumbnailUrl;

            if (data.isFeatured !== undefined) updateData.isFeatured = data.isFeatured === 'true';
            if (data.isActive !== undefined) updateData.isActive = data.isActive === 'true';

            if (data.metadata) {
                try {
                    updateData.metadata = JSON.parse(data.metadata);
                } catch (e) {
                    throw new BadRequestException('Metadata JSON không hợp lệ');
                }
            }

            // cap nhat thong tin prod cha
            const updatedProduct = await tx.product.update({
                where: { id },
                data: updateData
            });

            // cap nhat lai variant
            if (data.price || data.stock || data.sku || data.attributes) {
                const variantId = product.variants[0]?.id;

                if (variantId) {
                    const variantUpdate: any = {};
                    if (data.price) variantUpdate.price = parseFloat(data.price);
                    if (data.stock) variantUpdate.stock = parseInt(data.stock);
                    if (data.sku) variantUpdate.sku = data.sku;
                    if (data.attributes) {
                        try {
                            variantUpdate.attributes = JSON.parse(data.attributes);
                        } catch (e) {
                            throw new BadRequestException('Attributes JSON không hợp lệ');
                        }
                    }

                    await tx.productVariant.update({
                        where: { id: variantId },
                        data: variantUpdate,
                    });
                }
            }

            return tx.product.findUnique({
                where: { id: updatedProduct.id },
                include: { assets: true, variants: true }
            });
        });
    }

    async addAssets(id: string, files: Express.Multer.File[]) {
        const product = await this.prisma.product.findUnique({
            where: { id },
            select: { id: true, thumbnailUrl: true }
        });
        if (!product) throw new NotFoundException('Không tìm thấy sản phẩm');

        const assetPromises = files.map(async (file) => {
            const upload = await this.cloudinaryService.uploadFile(file);
            const fileName = file.originalname.toLowerCase();

            let type: AssetType = AssetType.IMAGE;
            if (fileName.endsWith('.glb')) type = AssetType.GLB;
            else if (fileName.endsWith('.usdz')) type = AssetType.USDZ;

            return this.prisma.productAsset.create({
                data: {
                    productId: id,
                    url: upload.secure_url,
                    type: type,
                    isPrimary: false,
                },
            });
        });

        const newAssets = await Promise.all(assetPromises);

        // neu chua co anh thumnail - lay anh dau tien upload
        if (!product.thumbnailUrl) {
            const firstImageAsset = newAssets.find(a => a.type === AssetType.IMAGE);
            if (firstImageAsset) {
                await this.prisma.product.update({
                    where: { id },
                    data: { thumbnailUrl: firstImageAsset.url }
                });
            }
        }

        return newAssets;
    }

    async removeAsset(assetId: string) {
        const asset = await this.prisma.productAsset.findUnique({ where: { id: assetId } });
        if (!asset) throw new NotFoundException('Không tìm thấy asset');

        return this.prisma.productAsset.delete({ where: { id: assetId } });
    }

    async inActiveProduct(id: string) {
        const product = await this.prisma.product.findUnique({
            where: { id },
            select: { id: true, name: true, isActive: true }
        });

        if (!product) {
            throw new NotFoundException('Không tìm thấy sản phẩm');
        }

        if (!product.isActive) {
            return { message: `Sản phẩm '${product.name}' đã ở trạng thái ẩn` };
        }

        await this.prisma.product.update({
            where: { id },
            data: { isActive: false },
        });

        return {
            message: `Đã ẩn sản phẩm '${product.name}' thành công`,
            productId: id
        };
    }

    async removeProduct(id: string) {
        // tim san pham bao gom bien the va so luong don hang cua tung bien the
        const product = await this.prisma.product.findUnique({
            where: { id },
            include: {
                variants: {
                    include: {
                        _count: {
                            select: { orderItems: true }
                        }
                    }
                }
            }
        });

        if (!product) throw new NotFoundException('Không tìm thấy sản phẩm để xóa');

        // tong so don hang cua tat ca bien the
        // bien the da co don hang khong xoa prod cha
        const totalOrders = product.variants.reduce((sum, variant) => sum + variant._count.orderItems, 0);

        if (totalOrders > 0) {
            // neu co nguoi mua chi an san pham
            return this.prisma.product.update({
                where: { id },
                data: { isActive: false }
            });
        }

        return this.prisma.product.delete({
            where: { id },
        });
    }

    async restore(id: string) {
        return this.prisma.product.update({
            where: { id },
            data: { isActive: true },
        });
    }

    // CLIENT
    async getAllProducts(
        query: {
            page?: number;
            limit?: number;
            search?: string;
            categoryId?: string;
            brandId?: string;
            minPrice?: number;
            maxPrice?: number;
        }
    ) {
        const {
            page = 1,
            limit = 10,
            search,
            categoryId,
            brandId,
            minPrice,
            maxPrice
        } = query;

        const skip = (page - 1) * limit;

        // de quy qua category
        let categoryIds: string[] | undefined = undefined;
        if (categoryId) {
            // tim cate hien tai va tat ca cac con cua no
            const currentCategory = await this.prisma.category.findUnique({
                where: { id: categoryId },
                include: { children: { select: { id: true } } }
            });

            // gom id chinh no va id cua cac con vao chung
            categoryIds = currentCategory ? [currentCategory.id, ...currentCategory.children.map(c => c.id)] : [categoryId];
        }

        // dieu kien loc
        const whereCondition: any = {
            isActive: true,
            categoryId: categoryIds ? { in: categoryIds } : undefined,
            brandId: brandId || undefined,
            OR: search ? [
                { name: { contains: search } },
                { description: { contains: search } },
            ] : undefined,
            // loc gia thong qua variant
            variants: (minPrice || maxPrice) ? {
                some: {
                    price: {
                        gte: minPrice ? Number(minPrice) : undefined,
                        lte: maxPrice ? Number(maxPrice) : undefined,
                    }
                }
            } : undefined,
        };

        // query db
        const [items, total] = await Promise.all([
            this.prisma.product.findMany({
                where: whereCondition,
                include: {
                    brand: { select: { name: true, logoUrl: true } },
                    category: { select: { name: true } },
                    variants: {
                        orderBy: { price: "asc" }, // gia tang dan
                        take: 1
                    },
                    assets: {
                        where: { isPrimary: true },
                        take: 1
                    }
                },
                orderBy: { createdAt: 'desc' },
                skip: skip,
                take: Number(limit),
            }),
            this.prisma.product.count({
                where: whereCondition
            }),
        ]);

        return {
            data: items,
            meta: {
                total,
                page: Number(page),
                limit: Number(limit),
                lastPage: Math.ceil(total / Number(limit)),
            },
        };
    }


    async getFeaturedProducts() {
        const limit = 8;
        return await this.prisma.product.findMany({
            where: {
                isActive: true,
                isFeatured: true,
                variants: { some: {} }
            },
            take: Number(limit),
            include: {
                brand: { select: { name: true, logoUrl: true } },
                variants: { orderBy: { price: 'asc' }, take: 1 },
                assets: { where: { isPrimary: true }, take: 1 }
            },
            orderBy: {
                createdAt: 'desc' // dua prod moi set featured len truoc
            }
        });
    }

    async getProductBySlug(slug: string) {
        const product = await this.prisma.product.findFirst({
            where: { slug, isActive: true },
            include: {
                assets: { orderBy: { isPrimary: 'desc' } },
                brand: true,
                category: true,
                variants: { orderBy: { price: 'asc' } }
            },
        });

        if (!product) throw new NotFoundException('Sản phẩm không tồn tại');

        await this.prisma.product.update({
            where: { id: product.id },
            data: { viewsCount: { increment: 1 } }
        });

        return product;
    }

    async getRelatedProducts(id: string) {
        const currentProduct = await this.prisma.product.findUnique({
            where: { id },
            select: { categoryId: true }
        });

        if (!currentProduct) throw new NotFoundException('Sản phẩm không tồn tại');

        return await this.prisma.product.findMany({
            where: {
                categoryId: currentProduct.categoryId,
                id: { not: id }, // khong lay chinh no
                isActive: true,
                variants: {
                    some: {}
                }
            },
            take: 4,
            include: {
                brand: { select: { name: true, logoUrl: true } },
                variants: {
                    orderBy: { price: 'asc' },
                    take: 1
                },
                assets: {
                    where: { isPrimary: true },
                    take: 1
                }
            }
        });
    }
}
