import { BadRequestException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateProductDto } from './dto/create-product.dto';
import slugify from 'slugify';
import { AssetType, Prisma } from '@prisma/client';
import { UpdateProductDto } from './dto/update-product.dto';
import { CreateVariantDto } from './dto/create-variant.dto';
import { UpdateVariantDto } from './dto/update-variant.dto';
import { RedisService } from 'src/redis/redis.service';
import { Cron, CronExpression } from '@nestjs/schedule';

@Injectable()
export class ProductsService {
    private readonly logger = new Logger(ProductsService.name);

    constructor(
        private redisService: RedisService,
        private prisma: PrismaService,
        private cloudinaryService: CloudinaryService,
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

        // cac file chung cho san pham
        const generalFiles = (files || []).filter(f => f.fieldname === 'files' || !f.fieldname);
        // gom nhom cac file thuoc tung bien the
        const variantFilesMap: Record<number, Express.Multer.File[]> = {};

        (files || []).forEach(f => {
            if (f.fieldname && f.fieldname.startsWith('variant_files_')) {
                const idx = parseInt(f.fieldname.replace('variant_files_', ''), 10);
                if (!isNaN(idx)) {
                    if (!variantFilesMap[idx]) variantFilesMap[idx] = [];
                    variantFilesMap[idx].push(f);
                }
            }
        });

        if (generalFiles && generalFiles.length > 0) {
            for (let i = 0; i < generalFiles.length; i++) {
                const file = generalFiles[i];
                const upload = await this.cloudinaryService.uploadFile(file);
                const fileName = file.originalname.toLowerCase();

                let type: AssetType = AssetType.IMAGE;
                if (fileName.endsWith('.glb')) type = AssetType.GLB;
                else if (fileName.endsWith('.usdz')) type = AssetType.USDZ;


                // upload assets len cld
                // xac dinh anh primary
                uploadedAssets.push({
                    url: upload.secure_url,
                    type,
                    isPrimary: i === primaryIndex && type === AssetType.IMAGE
                });
            }
        }

        // mo transaction cho database operations
        try {
            return await this.prisma.$transaction(async (tx) => {
                // build metadata with common_specs namespace
                const finalMetadata = { ...parsedMetadata };
                if (data.commonSpecs) {
                    try {
                        finalMetadata.common_specs = JSON.parse(data.commonSpecs);
                    } catch (e) {
                        throw new BadRequestException('Common Specs JSON không hợp lệ');
                    }
                }

                // parse vault specs
                let parsedVaultSpecs = null;
                if (data.vaultSpecs) {
                    try {
                        parsedVaultSpecs = JSON.parse(data.vaultSpecs);
                    } catch (e) {
                        throw new BadRequestException('Vault Specs JSON không hợp lệ');
                    }
                }

                // parent prod
                const product = await tx.product.create({
                    data: {
                        name: data.name,
                        slug: slug,
                        description: data.description,
                        categoryId: data.categoryId,
                        brandId: data.brandId,
                        metadata: finalMetadata,
                        thumbnailUrl: data.thumbnailUrl || null,
                        tagline: data.tagline || null,
                        attributeConfig: data.attributeConfig ? JSON.parse(data.attributeConfig) : [],
                        isVault: data.isVault === 'true',
                        vaultSpecs: parsedVaultSpecs ?? undefined,
                    }
                });

                // handle variants
                if (data.variants) {
                    const variantList = JSON.parse(data.variants);
                    // dung cache tranh upload nhieu file vao cung 1 bien the
                    const uploadedVariantFilesCache: Record<string, string> = {};

                    for (let idx = 0; idx < variantList.length; idx++) {
                        const v = variantList[idx];
                        const sku = v.sku || this.generateSKU(slug, v.attributes);

                        let variantImageUrl = v.imageUrl || null;
                        const variantAssetUrls: { url: string; type: AssetType }[] = [];

                        if (variantFilesMap[idx] && variantFilesMap[idx].length > 0) {
                            for (let i = 0; i < variantFilesMap[idx].length; i++) {
                                const vf = variantFilesMap[idx][i];
                                const cacheKey = `${vf.originalname}_${vf.size}`;

                                let secure_url: string;
                                if (uploadedVariantFilesCache[cacheKey]) {
                                    secure_url = uploadedVariantFilesCache[cacheKey];
                                } else {
                                    const upload = await this.cloudinaryService.uploadFile(vf);
                                    secure_url = upload.secure_url;
                                    uploadedVariantFilesCache[cacheKey] = secure_url;
                                }

                                const fName = vf.originalname.toLowerCase();

                                let type: AssetType = AssetType.IMAGE;
                                if (fName.endsWith('.glb')) type = AssetType.GLB;
                                else if (fName.endsWith('.usdz')) type = AssetType.USDZ;

                                if (i === 0 && type === AssetType.IMAGE && !variantImageUrl) {
                                    variantImageUrl = secure_url;
                                }
                                variantAssetUrls.push({ url: secure_url, type });
                            }
                        }

                        const createdVariant = await tx.productVariant.create({
                            data: {
                                productId: product.id,
                                sku,
                                name: `${data.name} - ${sku}`,
                                price: parseFloat(v.price),
                                stock: parseInt(v.stock || '0'),
                                attributes: v.attributes || {},
                                imageUrl: variantImageUrl,
                                barcode: v.barcode || null,
                            }
                        });

                        if (variantAssetUrls.length > 0) {
                            await Promise.all(
                                variantAssetUrls.map(va =>
                                    tx.productAsset.create({
                                        data: {
                                            productId: product.id,
                                            variantId: createdVariant.id,
                                            url: va.url,
                                            type: va.type,
                                            isPrimary: false
                                        }
                                    })
                                )
                            );
                        }
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
                            attributes: data.attributes ? JSON.parse(data.attributes) : {},
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
        } catch (error) {
            if (error instanceof Prisma.PrismaClientKnownRequestError) {
                if (error.code === 'P2002') {
                    const target = (error.meta?.target as string[]) || [];
                    if (target.includes('product_variants_sku_key') || target.includes('sku')) {
                        throw new BadRequestException('Mã SKU đã tồn tại, vui lòng kiểm tra lại');
                    }
                }
            }
            throw error;
        }
    }

    async updateProduct(id: string, data: UpdateProductDto, files?: Express.Multer.File[]) {
        const product = await this.prisma.product.findUnique({
            where: { id },
            include: { variants: { take: 1 }, assets: { orderBy: { createdAt: 'asc' } } }
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
            if (data.tagline) updateData.tagline = data.tagline;
            if (data.attributeConfig) {
                try {
                    updateData.attributeConfig = JSON.parse(data.attributeConfig);
                } catch (e) {
                    throw new BadRequestException('AttributeConfig JSON không hợp lệ');
                }
            }

            if (data.isFeatured !== undefined) updateData.isFeatured = data.isFeatured === 'true';
            if (data.isActive !== undefined) updateData.isActive = data.isActive === 'true';
            if (data.isVault !== undefined) updateData.isVault = data.isVault === 'true';

            if (data.metadata) {
                try {
                    updateData.metadata = JSON.parse(data.metadata);
                } catch (e) {
                    throw new BadRequestException('Metadata JSON không hợp lệ');
                }
            }

            // merge common_specs vao metadata
            if (data.commonSpecs) {
                try {
                    const existingMeta = updateData.metadata || (product.metadata as any) || {};
                    existingMeta.common_specs = JSON.parse(data.commonSpecs);
                    updateData.metadata = existingMeta;
                } catch (e) {
                    throw new BadRequestException('Common Specs JSON không hợp lệ');
                }
            }

            // vault specs
            if (data.vaultSpecs) {
                try {
                    updateData.vaultSpecs = JSON.parse(data.vaultSpecs);
                } catch (e) {
                    throw new BadRequestException('Vault Specs JSON không hợp lệ');
                }
            }

            // cap nhat san pham cha
            const updatedProduct = await tx.product.update({
                where: { id },
                data: updateData
            });

            const generalFiles = (files || []).filter(f => f.fieldname === 'files' || !f.fieldname);
            const variantFilesMap: Record<number, Express.Multer.File[]> = {};

            (files || []).forEach(f => {
                if (f.fieldname && f.fieldname.startsWith('variant_files_')) {
                    const idx = parseInt(f.fieldname.replace('variant_files_', ''), 10);
                    if (!isNaN(idx)) {
                        if (!variantFilesMap[idx]) variantFilesMap[idx] = [];
                        variantFilesMap[idx].push(f);
                    }
                }
            });

            // cap nhat thong tin bien the
            if (data.variants) {
                const variants = JSON.parse(data.variants);
                const existingVariants = await tx.productVariant.findMany({
                    where: { productId: id }
                });

                const uploadedVariantFilesCache: Record<string, string> = {};

                for (let idx = 0; idx < variants.length; idx++) {
                    const vData = variants[idx];
                    const price = parseFloat(vData.price?.toString() || '0');
                    const stock = parseInt(vData.stock?.toString() || '0');
                    const sku = vData.sku || this.generateSKU(updatedProduct.slug, vData.attributes);

                    let variantImageUrl = vData.imageUrl || null;
                    const variantAssetUrls: { url: string; type: AssetType }[] = [];

                    if (variantFilesMap[idx] && variantFilesMap[idx].length > 0) {
                        for (let i = 0; i < variantFilesMap[idx].length; i++) {
                            const vf = variantFilesMap[idx][i];
                            const cacheKey = `${vf.originalname}_${vf.size}`;

                            let secure_url: string;
                            if (uploadedVariantFilesCache[cacheKey]) {
                                secure_url = uploadedVariantFilesCache[cacheKey];
                            } else {
                                const upload = await this.cloudinaryService.uploadFile(vf);
                                secure_url = upload.secure_url;
                                uploadedVariantFilesCache[cacheKey] = secure_url;
                            }

                            const fName = vf.originalname.toLowerCase();

                            let type: AssetType = AssetType.IMAGE;
                            if (fName.endsWith('.glb')) type = AssetType.GLB;
                            else if (fName.endsWith('.usdz')) type = AssetType.USDZ;

                            if (i === 0 && type === AssetType.IMAGE && !variantImageUrl) {
                                variantImageUrl = secure_url;
                            }
                            variantAssetUrls.push({ url: secure_url, type });
                        }
                    }

                    const existing = existingVariants.find(ev => (vData.id && ev.id === vData.id) || ev.sku === sku);
                    let finalVariantId = existing ? existing.id : null;

                    if (existing) {
                        await tx.productVariant.update({
                            where: { id: existing.id },
                            data: {
                                sku: sku,
                                name: `${updatedProduct.name} - ${sku}`,
                                price: price,
                                stock: stock,
                                attributes: vData.attributes || {},
                                imageUrl: variantFilesMap[idx]?.length ? variantImageUrl : (vData.imageUrl || null),
                                barcode: vData.barcode ?? existing.barcode,
                            }
                        });
                    } else {
                        const createdVariant = await tx.productVariant.create({
                            data: {
                                productId: updatedProduct.id,
                                sku: sku,
                                name: `${updatedProduct.name} - ${sku}`,
                                price: price,
                                stock: stock,
                                attributes: vData.attributes || {},
                                imageUrl: variantImageUrl || null,
                                barcode: vData.barcode || null,
                            }
                        });
                        finalVariantId = createdVariant.id;
                    }

                    if (existing) {
                        const keptAssetIds = (vData.assets || [])
                            .map((a: any) => a.id)
                            .filter(Boolean);

                        await tx.productAsset.deleteMany({
                            where: {
                                variantId: existing.id,
                                id: { notIn: keptAssetIds }
                            }
                        });
                    }

                    if (finalVariantId && variantAssetUrls.length > 0) {
                        await Promise.all(
                            variantAssetUrls.map(va =>
                                tx.productAsset.create({
                                    data: {
                                        productId: updatedProduct.id,
                                        variantId: finalVariantId,
                                        url: va.url,
                                        type: va.type,
                                        isPrimary: false
                                    }
                                })
                            )
                        );
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

            // xu ly new assets
            if (generalFiles && generalFiles.length > 0) {
                for (const file of generalFiles) {
                    const upload = await this.cloudinaryService.uploadFile(file);
                    const fileName = file.originalname.toLowerCase();
                    let type: AssetType = AssetType.IMAGE;
                    if (fileName.endsWith('.glb')) type = AssetType.GLB;
                    else if (fileName.endsWith('.usdz')) type = AssetType.USDZ;

                    await tx.productAsset.create({
                        data: {
                            productId: id,
                            url: upload.secure_url,
                            type: type,
                            isPrimary: false
                        }
                    });
                }
            }

            // xu ly primary asset
            if (data.primaryIndex !== undefined) {
                const pIdx = parseInt(data.primaryIndex);
                const allAssets = await tx.productAsset.findMany({
                    where: { productId: id },
                    orderBy: { createdAt: 'asc' }
                });

                if (allAssets.length > 0) {
                    const targetIdx = Math.min(Math.max(0, pIdx), allAssets.length - 1);
                    const primaryAsset = allAssets[targetIdx];

                    await tx.productAsset.updateMany({
                        where: { productId: id },
                        data: { isPrimary: false }
                    });

                    await tx.productAsset.update({
                        where: { id: primaryAsset.id },
                        data: { isPrimary: true }
                    });

                    await tx.product.update({
                        where: { id },
                        data: { thumbnailUrl: primaryAsset.url }
                    });
                }
            }

            return tx.product.findUnique({
                where: { id: updatedProduct.id },
                include: { assets: true, variants: true }
            });
        }, {
            timeout: 20000 // 20s
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

        return await this.prisma.$transaction(async (tx) => {
            // toggle product
            const updatedProduct = await tx.product.update({
                where: { id },
                data: { isActive: !product.isActive }
            });

            // an toan bo bien the neu sp cha ngung kinh doanh
            if (!updatedProduct.isActive) {
                await tx.productVariant.updateMany({
                    where: { productId: id },
                    data: { isActive: false }
                });
            }

            return {
                message: `Đã ${updatedProduct.isActive ? 'hiển thị' : 'ẩn'} sản phẩm '${product.name}'`,
                isActive: updatedProduct.isActive
            };
        });
    }

    async toggleFeatured(id: string) {
        const product = await this.prisma.product.findUnique({
            where: { id },
            select: { id: true, name: true, isFeatured: true }
        });

        if (!product) throw new NotFoundException('Sản phẩm không tồn tại');

        const updatedProduct = await this.prisma.product.update({
            where: { id },
            data: { isFeatured: !product.isFeatured }
        });

        return {
            message: `Đã ${updatedProduct.isFeatured ? 'đưa' : 'gỡ'} sản phẩm '${product.name}' ${updatedProduct.isFeatured ? 'vào mục' : 'khỏi mục'} nổi bật`,
            isFeatured: updatedProduct.isFeatured
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
            inventoryStatus?: 'all' | 'in_stock' | 'low_stock' | 'out_of_stock';
            assetType?: 'all' | 'has_3d' | 'only_2d';
            showInactiveOnly?: boolean;
            showActiveOnly?: boolean;
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
            isAdmin = false,
            inventoryStatus = 'all',
            assetType = 'all',
            showInactiveOnly = false,
            showActiveOnly = false
        } = query;

        const skip = (page - 1) * limit;

        // de quy qua category
        let categoryIds: string[] | undefined = undefined;
        if (categoryId) {
            const currentCategory = await this.prisma.category.findUnique({
                where: { id: categoryId },
                include: { children: { select: { id: true } } }
            });
            categoryIds = currentCategory ? [currentCategory.id, ...currentCategory.children.map(c => c.id)] : [categoryId];
        }

        // dieu kien loc
        let whereCondition: any = {
            categoryId: categoryIds ? { in: categoryIds } : undefined,
            brandId: brandId || undefined,
        };

        // xu ly logic isActive vs showInactiveOnly vs showActiveOnly
        if (showInactiveOnly) {
            // hien thi san pham inactive hoac san pham active co variants inactive
            whereCondition.OR = [
                { isActive: false },
                { variants: { some: { isActive: false } } }
            ];
        } else if (showActiveOnly) {
            // hien thi san pham dang kinh doanh
            whereCondition.isActive = true;
            whereCondition.variants = {
                some: { isActive: true }
            };
        } else {
            // hien thi san pham active cho client
            whereCondition.isActive = isAdmin ? undefined : true;
        }

        if (search) {
            const searchConditions = [
                { name: { contains: search } },
                { description: { contains: search } },
            ];

            if (showInactiveOnly && whereCondition.OR) {
                // merge search conditions vao OR da co san pham inactive
                whereCondition.AND = [
                    { OR: whereCondition.OR },
                    { OR: searchConditions }
                ];
                delete whereCondition.OR;
            } else {
                whereCondition.OR = searchConditions;
            }
        }

        // loc gia qua variant
        if (minPrice || maxPrice) {
            whereCondition.variants = {
                some: {
                    price: {
                        gte: minPrice ? Number(minPrice) : undefined,
                        lte: maxPrice ? Number(maxPrice) : undefined,
                    }
                }
            };
        }

        // loc theo ton kho
        if (inventoryStatus && inventoryStatus !== 'all') {
            if (inventoryStatus === 'out_of_stock') {
                whereCondition.variants = {
                    ...whereCondition.variants,
                    every: { stock: 0 }
                };
            } else if (inventoryStatus === 'low_stock') {
                whereCondition.variants = {
                    ...whereCondition.variants,
                    some: { stock: { gt: 0, lte: 10 } }
                };
            } else if (inventoryStatus === 'in_stock') {
                whereCondition.variants = {
                    ...whereCondition.variants,
                    some: { stock: { gt: 10 } }
                };
            }
        }

        // loc theo loai asset
        if (assetType && assetType !== 'all') {
            if (assetType === 'has_3d') {
                whereCondition.assets = {
                    some: { type: { in: ['GLB', 'USDZ'] } }
                };
            } else if (assetType === 'only_2d') {
                whereCondition.assets = {
                    every: { type: 'IMAGE' }
                };
            }
        }

        // query db
        const [items, total] = await Promise.all([
            this.prisma.product.findMany({
                where: whereCondition,
                include: {
                    brand: { select: { name: true, logoUrl: true } },
                    category: { select: { name: true } },
                    variants: {
                        where: showInactiveOnly ? { isActive: false } : (showActiveOnly ? { isActive: true } : undefined),
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

    async getProductById(idOrSlug: string) {
        // regex uuid hop le
        const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(idOrSlug);

        const product = await this.prisma.product.findUnique({
            where: isUuid ? { id: idOrSlug } : { slug: idOrSlug },
            include: {
                brand: { select: { name: true, logoUrl: true } },
                category: { select: { name: true } },
                variants: {
                    orderBy: { price: "asc" },
                    include: { assets: true }
                },
                assets: true
            }
        });

        if (!product) throw new NotFoundException('Sản phẩm không tồn tại');
        return product;
    }

    async getFeaturedProducts() {
        const limit = 5;
        return await this.prisma.product.findMany({
            where: {
                isActive: true,
                isFeatured: true,
                variants: {
                    some: {
                        isActive: true,
                        stock: { gt: 0 }
                    }
                }
            },
            take: Number(limit),
            select: {
                id: true,
                name: true,
                thumbnailUrl: true,
                tagline: true,
                description: true,
                viewsCount: true,
                vaultSpecs: true,
                attributeConfig: true,
                variants: {
                    where: { isActive: true },
                    orderBy: { price: 'asc' },
                    select: {
                        id: true,
                        sku: true,
                        name: true,
                        price: true,
                        stock: true,
                        attributes: true,
                        imageUrl: true,
                        isActive: true,
                    }
                }
            },
            orderBy: {
                createdAt: 'desc'
            }
        });
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
                    where: { isActive: true },
                    orderBy: { price: 'asc' },
                    select: {
                        id: true,
                        sku: true,
                        name: true,
                        price: true,
                        stock: true,
                        attributes: true,
                        imageUrl: true,
                        isActive: true,
                    }
                },
                assets: {
                    where: { isPrimary: true },
                    take: 1
                }
            }
        });
    }

    // lay nhung sp duoc danh gia cao
    // fallback khi chua co review -> lay sp theo sold cnt
    // debug -> lay sp vua duoc tao
    async getTopRatedProducts(limit: number = 5) {
        const productSelect = {
            id: true,
            name: true,
            slug: true,
            thumbnailUrl: true,
            tagline: true,
            averageRating: true,
            reviewCount: true,
            soldCount: true,
            description: true,
            vaultSpecs: true,
            attributeConfig: true,
            brand: { select: { name: true } },
            variants: {
                where: { isActive: true },
                orderBy: { price: 'asc' },
                select: {
                    id: true,
                    sku: true,
                    name: true,
                    price: true,
                    stock: true,
                    attributes: true,
                    imageUrl: true,
                    isActive: true,
                }
            }
        } satisfies Prisma.ProductSelect;

        // layer 1: lay sp theo top rating & review cnt
        let products = await this.prisma.product.findMany({
            where: {
                isActive: true,
                averageRating: { gte: 4.5 },
                reviewCount: { gt: 10 },
                variants: { some: { stock: { gt: 0 }, isActive: true } }
            },
            select: productSelect,
            orderBy: [{ averageRating: 'desc' }, { reviewCount: 'desc' }],
            take: limit
        });

        // layer 2 & 3
        if (products.length === 0) {
            products = await this.prisma.product.findMany({
                where: {
                    isActive: true,
                    variants: { some: { stock: { gt: 0 }, isActive: true } }
                },
                select: productSelect,
                orderBy: [
                    { soldCount: 'desc' }, // l2
                    { createdAt: 'desc' } // l3: debug
                ],
                take: limit
            });
        }

        return products;
    }

    // lay cac san pham provip
    async getVaultProducts() {
        const products = await this.prisma.product.findMany({
            where: {
                isVault: true,
                isActive: true,
            },
            select: {
                id: true,
                name: true,
                thumbnailUrl: true,
                tagline: true,
                vaultSpecs: true,
                description: true,
                variants: {
                    where: { isActive: true },
                    orderBy: { price: 'asc' },
                    select: {
                        id: true,
                        sku: true,
                        name: true,
                        price: true,
                        stock: true,
                        attributes: true,
                        imageUrl: true,
                        isActive: true,
                    }
                }
            },
            orderBy: {
                createdAt: 'desc'
            }
        });

        return products;
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

    async getInventoryStats() {
        const [totalSKUs, totalStock, lowStockCount, workingCapital, activeVariants, inactiveVariants, inactiveProducts] = await Promise.all([
            this.prisma.productVariant.count(),
            this.prisma.productVariant.aggregate({
                _sum: { stock: true }
            }),
            this.prisma.productVariant.count({
                where: { stock: { lte: 10, gt: 0 } }
            }),
            this.prisma.productVariant.findMany({
                select: { price: true, stock: true }
            }),
            // active variants (of active products)
            this.prisma.productVariant.findMany({
                where: {
                    isActive: true,
                    product: { isActive: true }
                },
                select: { price: true, stock: true }
            }),
            // inactive variants
            this.prisma.productVariant.findMany({
                where: { isActive: false },
                include: { product: { select: { name: true } } }
            }),
            // inactive products
            this.prisma.product.findMany({
                where: { isActive: false },
                select: { id: true, name: true, slug: true }
            })
        ]);

        const capitalValue = workingCapital.reduce((acc, curr) => {
            return acc + (Number(curr.price) * curr.stock);
        }, 0);

        // actual (active only)
        const actualStock = activeVariants.reduce((acc, curr) => acc + curr.stock, 0);
        const actualCapital = activeVariants.reduce((acc, curr) => {
            return acc + (Number(curr.price) * curr.stock);
        }, 0);

        return {
            // totalSKUs
            totalSKUs,
            totalStock: totalStock._sum.stock || 0,
            lowStockCount,
            workingCapital: capitalValue,

            // actual (active only)
            activeSKUs: activeVariants.length,
            actualStock,
            actualCapital,

            // inactive
            inactiveSKUs: inactiveVariants.length,
            inactiveVariants: inactiveVariants.map(v => ({
                id: v.id,
                sku: v.sku,
                name: v.name,
                productName: v.product.name,
                price: v.price,
                stock: v.stock
            })),
            inactiveProducts: inactiveProducts.map(p => ({
                id: p.id,
                name: p.name,
                slug: p.slug
            }))
        };
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

    async toggleVariant(variantId: string) {
        const variant = await this.prisma.productVariant.findUnique({
            where: { id: variantId },
            include: {
                orderItems: {
                    include: {
                        order: { select: { status: true } }
                    }
                }
            }
        });

        if (!variant) throw new NotFoundException('Biến thể không tồn tại');

        // khong duoc ngung kinh doanh san pham trong dno hang chua hoan tat
        const activeOrders = variant.orderItems.filter(oi =>
            !['DELIVERED', 'CANCELLED', 'RETURNED', 'FAILED'].includes(oi.order.status)
        );

        if (activeOrders.length > 0) {
            throw new BadRequestException('Không thể thay đổi trạng thái biến thể vì có đơn hàng chưa hoàn tất');
        }

        return await this.prisma.$transaction(async (tx) => {
            // toggle isActive
            const updatedVariant = await tx.productVariant.update({
                where: { id: variantId },
                data: { isActive: !variant.isActive }
            });

            // ngung kinh doanh -> xoa khoi gio hang
            if (!updatedVariant.isActive) {
                await tx.cartItem.deleteMany({
                    where: { productVariantId: variantId }
                });
            }

            return {
                ...updatedVariant,
                message: `Biến thể ${updatedVariant.isActive ? 'đã được kích hoạt' : 'đã được tắt'}`
            };
        });
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

    // tang view san pham
    async incrementView(id: string, deviceId: string = 'default') {
        const cacheKey = `view_check:${id}:${deviceId}`;
        const isViewed = await this.redisService.get(cacheKey);

        if (!isViewed) {
            // danh dau key tranh spam trong 30p
            await this.redisService.set(cacheKey, '1', 'EX', 1800);
            // tong view moi chua luu vao db
            await this.redisService.incr(`product_views_buffer:${id}`);
        }
    }

    // su dung cron auto cong don view sau moi 10 phutt
    // tranh nghen co chai neu co nhieu user truy cap dong thoi vao 1 item
    @Cron(CronExpression.EVERY_10_MINUTES)
    async syncViewsToDb() {
        const keys = await this.redisService.keys('product_views_buffer:*');
        for (const key of keys) {
            const productId = key.split(':')[1];
            const viewsToAdd = await this.redisService.get(key);

            if (viewsToAdd) {
                try {
                    await this.prisma.product.update({
                        where: { id: productId },
                        data: { viewsCount: { increment: parseInt(viewsToAdd) } }
                    });
                } catch (err) {
                    this.logger.error(`Failed to sync views for product ${productId}: ${err.message}`);
                }
                await this.redisService.del(key); // reset buffer
            }
        }
    }

    // SKU engine
    private generateSKU(slug: string, attributes?: Record<string, any>): string {
        const slugPart = slug
            .split('-')
            .map(word => word.substring(0, 4).toUpperCase())
            .slice(0, 3)
            .join('-');

        if (!attributes || Object.keys(attributes).length === 0) {
            return `${slugPart}-STD`;
        }

        const attrPart = Object.values(attributes)
            .map(val => {
                const str = String(val).toUpperCase().replace(/[^A-Z0-9]/g, '');
                return str.substring(0, 5);
            })
            .join('-');

        return `${slugPart}-${attrPart}`;
    }

    // tao ma tran bien the
    async generateVariantMatrix(axes: Record<string, string[]>, productSlug?: string) {
        // truc thuoc tinh
        // dung de tao combo bien the
        const keys = Object.keys(axes);
        if (keys.length === 0) return [];

        // tich de-cac (cartesian product)
        const combinations: Record<string, string>[] = keys.reduce(
            (acc, key) => {
                const newCombos: Record<string, string>[] = [];
                for (const combo of acc) {
                    for (const value of axes[key]) {
                        newCombos.push({ ...combo, [key]: value });
                    }
                }
                return newCombos;
            },
            [{}] as Record<string, string>[]
        );

        return combinations.map(attrs => ({
            sku: productSlug ? this.generateSKU(productSlug, attrs) : '',
            name: '',
            price: 0,
            stock: 0,
            attributes: attrs,
            imageUrl: null,
            barcode: null,
        }));
    }
}
