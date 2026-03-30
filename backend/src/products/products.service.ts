import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateProductDto } from './dto/create-product.dto';
import slugify from 'slugify';
import { AssetType } from '@prisma/client';
import { UpdateProductDto } from './dto/update-product.dto';
import { CreateVariantDto } from './dto/create-variant.dto';
import { UpdateVariantDto } from './dto/update-variant.dto';

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

        // parse metadata/attributes
        const parsedMetadata = data.metadata ? JSON.parse(data.metadata) : {};

        // upload cloudinary
        const uploadedAssets: { url: string; type: AssetType; isPrimary: boolean }[] = [];
        const primaryIndex = parseInt(data.primaryIndex || '0');

        if (files && files.length > 0) {
            for (let i = 0; i < files.length; i++) {
                const file = files[i];
                const upload = await this.cloudinaryService.uploadFile(file);
                const fileName = file.originalname.toLowerCase();

                let type: AssetType = AssetType.IMAGE;
                if (fileName.endsWith('.glb')) type = AssetType.GLB;
                else if (fileName.endsWith('.usdz')) type = AssetType.USDZ;

                uploadedAssets.push({
                    url: upload.secure_url,
                    type,
                    isPrimary: i === primaryIndex && type === AssetType.IMAGE
                });
            }
        }

        // mo transaction cho database operations
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

            // handle variants
            if (data.variants) {
                const variantList = JSON.parse(data.variants);
                for (const v of variantList) {
                    await tx.productVariant.create({
                        data: {
                            productId: product.id,
                            sku: v.sku,
                            name: `${data.name} - ${v.sku}`,
                            price: parseFloat(v.price),
                            stock: parseInt(v.stock || '0'),
                            attributes: v.attributes || {}
                        }
                    });
                }
            } else {
                // fallback
                await tx.productVariant.create({
                    data: {
                        productId: product.id,
                        sku: data.sku || `${slug}-default`,
                        name: `${data.name} - Standard`,
                        price: parseFloat(data.price || '0'),
                        stock: parseInt(data.stock || '0'),
                        attributes: data.attributes ? JSON.parse(data.attributes) : {}
                    }
                });
            }

            // handle assets
            let finalThumbnailUrl = product.thumbnailUrl;

            if (uploadedAssets.length > 0) {
                const assets = await Promise.all(
                    uploadedAssets.map((asset) =>
                        tx.productAsset.create({
                            data: {
                                productId: product.id,
                                url: asset.url,
                                type: asset.type,
                                isPrimary: asset.isPrimary,
                            },
                        })
                    )
                );

                // auto-select thumbnail neu khong set
                if (!finalThumbnailUrl) {
                    const primaryAsset = assets.find(a => a.isPrimary);
                    const firstImageAsset = assets.find(a => a.type === AssetType.IMAGE);

                    if (primaryAsset) {
                        finalThumbnailUrl = primaryAsset.url;
                    } else if (firstImageAsset) {
                        finalThumbnailUrl = firstImageAsset.url;
                    }

                    if (finalThumbnailUrl) {
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
                    variants: true,
                    assets: true,
                    category: true,
                    brand: true
                },
            });
        }, {
            timeout: 20000 // 20s
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
            // chuan bi data cho san pham cha
            const updateData: any = {};
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

            // cap nhat san pham cha
            const updatedProduct = await tx.product.update({
                where: { id },
                data: updateData
            });

            // cap nhat thong tin bien the
            if (data.variants) {
                const variants = JSON.parse(data.variants);
                const existingVariants = await tx.productVariant.findMany({
                    where: { productId: id }
                });

                for (const vData of variants) {
                    const price = parseFloat(vData.price?.toString() || '0');
                    const stock = parseInt(vData.stock?.toString() || '0');
                    const sku = vData.sku;

                    const existing = existingVariants.find(ev => (vData.id && ev.id === vData.id) || ev.sku === sku);

                    if (existing) {
                        await tx.productVariant.update({
                            where: { id: existing.id },
                            data: {
                                sku: sku,
                                name: `${updatedProduct.name} - ${sku}`,
                                price: price,
                                stock: stock,
                                attributes: vData.attributes || {}
                            }
                        });
                    } else {
                        await tx.productVariant.create({
                            data: {
                                productId: updatedProduct.id,
                                sku: sku,
                                name: `${updatedProduct.name} - ${sku}`,
                                price: price,
                                stock: stock,
                                attributes: vData.attributes || {}
                            }
                        });
                    }
                }
            } else if (data.price || data.stock || data.sku || data.attributes) {
                // fallback neu chi truyen le 1 variant (lay variant dau tien)
                const firstVariant = await tx.productVariant.findFirst({
                    where: { productId: id }
                });

                if (firstVariant) {
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
                        where: { id: firstVariant.id },
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
        const asset = await this.prisma.productAsset.findUnique({
            where: { id: assetId }
        });
        if (!asset) throw new NotFoundException('Không tìm thấy asset');

        const publicId = asset.url.split('/').pop()?.split('.')[0];
        if (publicId) {
            await this.cloudinaryService.deleteFile(`gearhub/media/${publicId}`);
        }

        const productId = asset.productId;

        return await this.prisma.$transaction(async (tx) => {
            // xoa asset
            await tx.productAsset.delete({ where: { id: assetId } });

            // neu anh primary bi xoa - tim anh khac thay the
            if (asset.isPrimary) {
                const nextAsset = await tx.productAsset.findFirst({
                    where: { productId, type: AssetType.IMAGE },
                    orderBy: { createdAt: 'asc' }
                });

                if (nextAsset) {
                    await tx.productAsset.update({
                        where: { id: nextAsset.id },
                        data: { isPrimary: true }
                    });
                    await tx.product.update({
                        where: { id: productId },
                        data: { thumbnailUrl: nextAsset.url }
                    });
                } else {
                    // set null neu khong con anh
                    await tx.product.update({
                        where: { id: productId },
                        data: { thumbnailUrl: null }
                    });
                }
            }
            return { message: 'Xóa asset thành công' };
        });
    }

    async setPrimaryAsset(productId: string, assetId: string) {
        const asset = await this.prisma.productAsset.findFirst({
            where: { id: assetId, productId }
        });
        if (!asset) throw new NotFoundException('Asset không tồn tại hoặc không thuộc sản phẩm này');

        return await this.prisma.$transaction(async (tx) => {
            // tat tat ca primary hien tai cua prod
            await tx.productAsset.updateMany({
                where: { productId },
                data: { isPrimary: false }
            })

            // bat primary duoc chon
            const updatedAsset = await tx.productAsset.update({
                where: { id: assetId },
                data: { isPrimary: true }
            });

            // dong bo lam thumbail
            await tx.product.update({
                where: { id: productId },
                data: { thumbnailUrl: updatedAsset.url }
            });

            return updatedAsset;
        });
    }

    async toggleStatus(id: string) {
        const product = await this.prisma.product.findUnique({
            where: { id },
            select: { id: true, name: true, isActive: true }
        });

        if (!product) throw new NotFoundException('Sản phẩm không tồn tại');

        const updatedProduct = await this.prisma.product.update({
            where: { id },
            data: { isActive: !product.isActive }
        });

        return {
            message: `Đã ${updatedProduct.isActive ? 'hiển thị' : 'ẩn'} sản phẩm '${product.name}'`,
            isActive: updatedProduct.isActive
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
            isAdmin?: boolean;
        }
    ) {
        const {
            page = 1,
            limit = 10,
            search,
            categoryId,
            brandId,
            minPrice,
            maxPrice,
            isAdmin = false
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
            isActive: isAdmin ? undefined : true,
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
                        orderBy: { price: "asc" },
                    },
                    assets: true
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

    async addVariant(id: string, data: CreateVariantDto) {
        const product = await this.prisma.product.findUnique({
            where: { id }
        });
        if (!product) throw new NotFoundException('Sản phẩm cha không tồn tại');

        const existingSku = await this.prisma.productVariant.findUnique({
            where: { sku: data.sku }
        })
        if (existingSku) {
            throw new BadRequestException(`Mã SKU '${data.sku}' đã tồn tại`);
        }

        const parsedAttributes = data.attributes ? JSON.parse(data.attributes) : {};

        return await this.prisma.productVariant.create({
            data: {
                productId: id,
                sku: data.sku,
                name: data.name,
                price: data.price,
                stock: data.stock,
                attributes: parsedAttributes
            }
        });
    }

    async updateVariant(variantId: string, data: UpdateVariantDto) {
        const variant = await this.prisma.productVariant.findUnique({
            where: { id: variantId }
        });
        if (!variant) throw new NotFoundException('Biến thể không tồn tại');

        const parsedAttributes = data.attributes ? JSON.parse(data.attributes) : {};

        return await this.prisma.productVariant.update({
            where: { id: variantId },
            data: {
                ...data,
                price: data.price,
                stock: data.stock,
                attributes: parsedAttributes
            }
        });
    }

    async removeVariant(variantId: string) {
        const variant = await this.prisma.productVariant.findUnique({
            where: { id: variantId },
            include: { _count: { select: { orderItems: true } } }
        });

        if (!variant) throw new NotFoundException('Biến thể không tồn tại');

        if (variant._count.orderItems > 0) {
            throw new BadRequestException('Không thể xóa biến thể đã có trong đơn hàng');
        }

        return this.prisma.productVariant.delete({ where: { id: variantId } });
    }

    // giam stock khi khach hang chot don
    async decreaseStock(variantId: string, quantity: number) {
        const variant = await this.prisma.productVariant.findUnique({ where: { id: variantId } });
        if (!variant) throw new NotFoundException('Biến thể không tồn tại');

        if (variant.stock < quantity) {
            throw new BadRequestException(`Sản phẩm ${variant.name} không đủ hàng trong kho`);
        }

        return this.prisma.productVariant.update({
            where: { id: variantId },
            data: { stock: { decrement: quantity } }
        });
    }

    // khach hang huy don hoac thanh toan that bai
    // tra lai stock cho don hang
    async increaseStock(variantId: string, quantity: number) {
        const variant = await this.prisma.productVariant.findUnique({
            where: { id: variantId },
            select: { id: true }
        });

        if (!variant) throw new NotFoundException('Biến thể không tồn tại');

        return this.prisma.productVariant.update({
            where: { id: variantId },
            data: {
                stock: { increment: quantity }
            }
        });
    }
}
