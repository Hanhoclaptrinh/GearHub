import { BadRequestException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateProductDto } from './dto/create-product.dto';
import slugify from 'slugify';
import { AssetType, InventoryTransactionType, Prisma } from '@prisma/client';
import { UpdateProductDto } from './dto/update-product.dto';
import { CreateVariantDto } from './dto/create-variant.dto';
import { UpdateVariantDto } from './dto/update-variant.dto';
import { RedisService } from 'src/redis/redis.service';
import { Cron, CronExpression } from '@nestjs/schedule';
import { InventoriesService } from 'src/inventories/inventories.service';
import { EmbeddingService } from 'src/ai/embedding.service';
import { ProductImageEmbeddingService } from 'src/ai/product-image-embedding.service';
import { ConfigService } from '@nestjs/config';

type CompareCategoryNode = {
    id: string;
    name: string;
    slug: string;
    parentId: string | null;
};

type CompareKey = {
    id: string;
    name: string;
    slug: string;
    strategy: 'standalone-category' | 'strict-subcategory' | 'category-family';
    path: { id: string; name: string; slug: string }[];
};

// alias gợi ý sản phẩm dựa trên sở thích mua sắm của người dùng (preferences)
type ProductRecommendationPreferences = {
    categoryIds: string[];
    brandIds: string[];
    styleTags: string[];
    useCases: string[];
    budgetRange: { min: number | null; max: number | null } | null;
    preferenceVector?: number[];
};

@Injectable()
export class ProductsService {
    private readonly logger = new Logger(ProductsService.name);

    constructor(
        private redisService: RedisService,
        private prisma: PrismaService,
        private cloudinaryService: CloudinaryService,
        private inventoriesService: InventoriesService,
        private embeddingService: EmbeddingService,
        private configService: ConfigService,
        private productImageEmbeddingService: ProductImageEmbeddingService,
    ) { }

    // ADMIN
    /**
     * tạo mới sản phẩm cùng toàn bộ dữ liệu phụ thuộc trong một luồng
     *
     * flow:
     * - tạo bản ghi sản phẩm cha
     * - tạo các biến thể từ dữ liệu gửi lên
     * - gắn asset ở cấp sản phẩm và cấp biến thể
     * - khởi tạo tồn kho ban đầu thông qua inventory transaction
     * - đồng bộ dữ liệu phục vụ embedding sau khi ghi thành công
     */
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

        // tách file upload theo phạm vi sở hữu để phía dưới có thể ghi đúng
        // asset cho sản phẩm cha hoặc cho từng biến thể tương ứng
        // các file assets dùng chung cho toàn bộ các biến thể trong sp
        const generalFiles = (files || []).filter(f => f.fieldname === 'files' || !f.fieldname);
        // các file riêng từng biến thể
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


                // upload assets lên cld
                // xác định ảnh primary
                uploadedAssets.push({
                    url: upload.secure_url,
                    type,
                    isPrimary: i === primaryIndex && type === AssetType.IMAGE
                });
            }
        }

        /**
         * upload media files của variant lên cloudinary
         * thực hiện ngoài db transaction để tránh block connection
         */
        const uploadedVariantAssetsMap: Record<number, { url: string; type: AssetType }[]> = {};
        const uploadedVariantFilesCache: Record<string, string> = {};

        for (const idxStr of Object.keys(variantFilesMap)) {
            const idx = parseInt(idxStr, 10);
            uploadedVariantAssetsMap[idx] = [];
            for (const vf of variantFilesMap[idx]) {
                // tạo cache key từ tên và dung lượng file để tránh upload trùng
                const cacheKey = `${vf.originalname}_${vf.size}`;
                let secure_url: string;
                if (uploadedVariantFilesCache[cacheKey]) {
                    secure_url = uploadedVariantFilesCache[cacheKey];
                } else {
                    const upload = await this.cloudinaryService.uploadFile(vf);
                    secure_url = upload.secure_url;
                    uploadedVariantFilesCache[cacheKey] = secure_url;
                }

                // xác định loại asset dựa trên đuôi file để hỗ trợ ar/3d
                const fName = vf.originalname.toLowerCase();
                let type: AssetType = AssetType.IMAGE;
                if (fName.endsWith('.glb')) type = AssetType.GLB;
                else if (fName.endsWith('.usdz')) type = AssetType.USDZ;

                uploadedVariantAssetsMap[idx].push({ url: secure_url, type });
            }
        }

        // toàn bộ thao tác ghi product, variant, asset và inventory phải
        // là một khối atomic để tránh sinh dữ liệu rác
        try {
            const result = await this.prisma.$transaction(async (tx) => {
                // build metadata with common_specs namespace
                const finalMetadata = { ...parsedMetadata };
                if (data.commonSpecs) {
                    try {
                        finalMetadata.common_specs = JSON.parse(data.commonSpecs);
                    } catch (e) {
                        throw new BadRequestException('Common Specs JSON không hợp lệ');
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
                    }
                });

                // handle variants
                if (data.variants) {
                    const variantList = JSON.parse(data.variants);

                    for (let idx = 0; idx < variantList.length; idx++) {
                        const v = variantList[idx];
                        // tự động tạo mã sku từ slug và thuộc tính nếu chưa có sku
                        const sku = v.sku || this.generateSKU(slug, v.attributes);

                        let variantImageUrl = v.imageUrl || null;
                        const variantAssetUrls: { url: string; type: AssetType }[] = [];

                        // đồng bộ danh sách asset đã upload lên cloudinary với variant tương ứng
                        if (uploadedVariantAssetsMap[idx] && uploadedVariantAssetsMap[idx].length > 0) {
                            for (let i = 0; i < uploadedVariantAssetsMap[idx].length; i++) {
                                const va = uploadedVariantAssetsMap[idx][i];
                                // gán ảnh đầu tiên tìm thấy làm ảnh đại diện cho variant nếu chưa thiết lập
                                if (i === 0 && va.type === AssetType.IMAGE && !variantImageUrl) {
                                    variantImageUrl = va.url;
                                }
                                variantAssetUrls.push(va);
                            }
                        }

                        const initialStock = parseInt(v.stock || '0');

                        // tạo bản ghi variant mới trong db
                        const createdVariant = await tx.productVariant.create({
                            data: {
                                productId: product.id,
                                sku,
                                name: `${data.name} - ${sku}`,
                                price: parseFloat(v.price),
                                stock: 0,
                                attributes: v.attributes || {},
                                imageUrl: variantImageUrl,
                                barcode: v.barcode || null,
                            }
                        });

                        // tạo lịch sử nhập kho ban đầu cho variant nếu tồn kho lớn hơn 0
                        if (initialStock > 0) {
                            await this.inventoriesService.adjustStock({
                                variantId: createdVariant.id,
                                type: InventoryTransactionType.INITIAL_IMPORT,
                                quantity: initialStock,
                                reason: 'Stock khởi tạo khi tạo sản phẩm',
                                createdById: undefined,
                                tx,
                            });
                        }

                        // lưu trữ toàn bộ thông tin asset đi kèm của variant vào cơ sở dữ liệu
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
                    const fallbackStock = parseInt(data.stock || '0');
                    const fallbackVariant = await tx.productVariant.create({
                        data: {
                            productId: product.id,
                            sku: data.sku || `${slug}-default`,
                            name: `${data.name} - Standard`,
                            price: parseFloat(data.price || '0'),
                            stock: 0,
                            attributes: data.attributes ? JSON.parse(data.attributes) : {},
                        }
                    });

                    if (fallbackStock > 0) {
                        await this.inventoriesService.adjustStock({
                            variantId: fallbackVariant.id,
                            type: InventoryTransactionType.INITIAL_IMPORT,
                            quantity: fallbackStock,
                            reason: 'Stock khởi tạo khi tạo sản phẩm',
                            createdById: undefined,
                            tx,
                        });
                    }
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

                    // auto chọn hình ảnh đầu tiên làm thumbnail nếu không set primary
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

                await this.syncSingleFeatured(tx);

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
            this.queueProductEmbeddingSync(result?.id);
            return result;
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

    /**
     * cập nhật sản phẩm cha và đồng bộ lại toàn bộ cấu phần liên quan nếu có
     * dữ liệu đi kèm trong request
     *
     * flow:
     * - cập nhật thông tin sản phẩm cha
     * - cập nhật hoặc tạo mới biến thể từ danh sách gửi lên
     * - thêm asset mới ở cấp sản phẩm hoặc cấp biến thể
     * - đổi primary asset và đồng bộ thumbnail
     * - cập nhật lại embedding sau khi ghi xong
     *
     * không cho phép chỉnh sửa tồn kho qua flow cập nhật sản phẩm
     */
    async updateProduct(id: string, data: UpdateProductDto, files?: Express.Multer.File[]) {
        const product = await this.prisma.product.findUnique({
            where: { id },
            include: { variants: { take: 1 }, assets: { orderBy: { createdAt: 'asc' } } }
        });
        if (!product) throw new NotFoundException('Sản phẩm không tồn tại');

        // nếu update name thì check slug
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

        // lọc danh sách file chung của sản phẩm (không thuộc về variant cụ thể nào)
        const generalFiles = (files || []).filter(f => f.fieldname === 'files' || !f.fieldname);
        // lưu trữ danh sách file tương ứng với từng variant theo index
        const variantFilesMap: Record<number, Express.Multer.File[]> = {};

        // phân loại và gom nhóm file của variant dựa trên tên fieldname truyền lên
        (files || []).forEach(f => {
            if (f.fieldname && f.fieldname.startsWith('variant_files_')) {
                const idx = parseInt(f.fieldname.replace('variant_files_', ''), 10);
                if (!isNaN(idx)) {
                    if (!variantFilesMap[idx]) variantFilesMap[idx] = [];
                    variantFilesMap[idx].push(f);
                }
            }
        });

        // upload các file chung lên cloudinary ngoài db transaction để tối ưu hiệu năng
        const uploadedGeneralAssets: { url: string; type: AssetType }[] = [];
        if (generalFiles && generalFiles.length > 0) {
            for (const file of generalFiles) {
                const upload = await this.cloudinaryService.uploadFile(file);
                const fileName = file.originalname.toLowerCase();
                let type: AssetType = AssetType.IMAGE;
                if (fileName.endsWith('.glb')) type = AssetType.GLB;
                else if (fileName.endsWith('.usdz')) type = AssetType.USDZ;

                uploadedGeneralAssets.push({ url: upload.secure_url, type });
            }
        }

        // upload các file của từng variant lên cloudinary kèm cơ chế cache trùng lặp
        const uploadedVariantAssetsMap: Record<number, { url: string; type: AssetType }[]> = {};
        const uploadedVariantFilesCache: Record<string, string> = {};

        for (const idxStr of Object.keys(variantFilesMap)) {
            const idx = parseInt(idxStr, 10);
            uploadedVariantAssetsMap[idx] = [];
            for (const vf of variantFilesMap[idx]) {
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

                uploadedVariantAssetsMap[idx].push({ url: secure_url, type });
            }
        }

        const result = await this.prisma.$transaction(async (tx) => {
            // chuẩn bị dữ liệu patch cho sản phẩm cha trước, sau đó mới đồng bộ
            // lại các biến thể phụ thuộc theo trạng thái mới của sản phẩm
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

            if (data.metadata) {
                try {
                    updateData.metadata = JSON.parse(data.metadata);
                } catch (e) {
                    throw new BadRequestException('Metadata JSON không hợp lệ');
                }
            }

            // merge common_specs vào metadata
            if (data.commonSpecs) {
                try {
                    const existingMeta = updateData.metadata || (product.metadata as any) || {};
                    existingMeta.common_specs = JSON.parse(data.commonSpecs);
                    updateData.metadata = existingMeta;
                } catch (e) {
                    throw new BadRequestException('Common Specs JSON không hợp lệ');
                }
            }

            // cập nhật sản phẩm cha
            const updatedProduct = await tx.product.update({
                where: { id },
                data: updateData
            });

            // có thể xử lý cả 2 flow:
            // - cập nhật biến thể đã có
            // - tạo biến thể mới nếu dữ liệu gửi lên chưa tồn tại trong db
            // nếu có danh sách variant truyền lên thì xử lý cập nhật hoặc tạo mới
            if (data.variants) {
                const variants = JSON.parse(data.variants);
                const existingVariants = await tx.productVariant.findMany({
                    where: { productId: id }
                });

                for (let idx = 0; idx < variants.length; idx++) {
                    const vData = variants[idx];
                    const price = parseFloat(vData.price?.toString() || '0');
                    const stock = parseInt(vData.stock?.toString() || '0');
                    const sku = vData.sku || this.generateSKU(updatedProduct.slug, vData.attributes);

                    let variantImageUrl = vData.imageUrl || null;
                    const variantAssetUrls: { url: string; type: AssetType }[] = [];

                    // xử lý gán ảnh đại diện và gom nhóm danh sách asset đã upload cho variant
                    if (uploadedVariantAssetsMap[idx] && uploadedVariantAssetsMap[idx].length > 0) {
                        for (let i = 0; i < uploadedVariantAssetsMap[idx].length; i++) {
                            const va = uploadedVariantAssetsMap[idx][i];
                            if (i === 0 && va.type === AssetType.IMAGE && !variantImageUrl) {
                                variantImageUrl = va.url;
                            }
                            variantAssetUrls.push(va);
                        }
                    }

                    // tìm kiếm xem variant đã tồn tại trong db dựa trên id hoặc sku chưa
                    const existing = existingVariants.find(ev => (vData.id && ev.id === vData.id) || ev.sku === sku);
                    let finalVariantId = existing ? existing.id : null;

                    if (existing) {
                        // cập nhật thông tin cho variant đã tồn tại
                        await tx.productVariant.update({
                            where: { id: existing.id },
                            data: {
                                sku: sku,
                                name: `${updatedProduct.name} - ${sku}`,
                                price: price,
                                attributes: vData.attributes || {},
                                imageUrl: uploadedVariantAssetsMap[idx]?.length ? variantImageUrl : (vData.imageUrl || null),
                                barcode: vData.barcode ?? existing.barcode,
                            }
                        });
                    } else {
                        // tạo variant mới nếu chưa tồn tại
                        const createdVariant = await tx.productVariant.create({
                            data: {
                                productId: updatedProduct.id,
                                sku: sku,
                                name: `${updatedProduct.name} - ${sku}`,
                                price: price,
                                stock: 0,
                                attributes: vData.attributes || {},
                                imageUrl: variantImageUrl || null,
                                barcode: vData.barcode || null,
                            }
                        });
                        finalVariantId = createdVariant.id;

                        // tạo giao dịch nhập kho ban đầu cho variant mới tạo
                        if (stock > 0) {
                            await this.inventoriesService.adjustStock({
                                variantId: createdVariant.id,
                                type: InventoryTransactionType.INITIAL_IMPORT,
                                quantity: stock,
                                reason: 'Stock khởi tạo khi thêm biến thể mới',
                                createdById: undefined,
                                tx,
                            });
                        }
                    }

                    if (existing) {
                        // xóa bỏ các asset cũ của variant không nằm trong danh sách giữ lại
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

                    // lưu thêm các asset mới đã upload của variant vào db
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
            } else if (data.price || data.sku || data.attributes) {
                // fallback nếu chỉ truyền lên 1 biến thể
                const firstVariant = await tx.productVariant.findFirst({
                    where: { productId: id }
                });

                if (firstVariant) {
                    const variantUpdate: any = {};
                    if (data.price) variantUpdate.price = parseFloat(data.price);
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

            // xử lý new assets
            if (uploadedGeneralAssets.length > 0) {
                for (const asset of uploadedGeneralAssets) {
                    await tx.productAsset.create({
                        data: {
                            productId: id,
                            url: asset.url,
                            type: asset.type,
                            isPrimary: false
                        }
                    });
                }
            }

            // xử lý primary asset
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

            // xử lý đánh dấu featured cho một sản phẩm tại một thời điểm duy nhất
            // nếu set prod này làm featured thì tắt featured sản phẩm đang được mark trước đó
            const shouldSkipUpdatedProduct = data.isFeatured === 'false' || data.isActive === 'false';
            let featuredProduct = await this.syncSingleFeatured(
                tx,
                shouldSkipUpdatedProduct ? id : undefined,
                data.isFeatured === 'true' ? id : undefined,
            );
            if (!featuredProduct && data.isFeatured === 'false' && data.isActive !== 'false') {
                featuredProduct = await this.syncSingleFeatured(tx);
            }

            return tx.product.findUnique({
                where: { id: updatedProduct.id },
                include: { assets: true, variants: true }
            });
        }, {
            timeout: 20000 // 20s
        });
        this.queueProductEmbeddingSync(id);
        return result;
    }

    /**
     * thêm asset mới cho sản phẩm ở cấp product
     * dùng ảnh đầu tiên upload làm thumbnail mặc định nếu không có thumbnail
     */
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

    /**
     * xóa một asset đã lưu của sản phẩm
     *
     * flow:
     * - xóa asset trong db
     * - xóa file tương ứng trên cloudinary
     * - nếu asset bị xóa đang là ảnh primary thì chọn ảnh thay thế và đồng bộ lại thumbnail
     */
    async removeAsset(assetId: string) {
        // tiến hành tìm kiếm assets tương ứng trên cld và xóa
        const asset = await this.prisma.productAsset.findUnique({
            where: { id: assetId }
        });
        if (!asset) throw new NotFoundException('Không tìm thấy asset');

        const publicId = asset.url.split('/').pop()?.split('.')[0];
        if (publicId) {
            try {
                await this.cloudinaryService.deleteFile(`gearhub/media/${publicId}`);
            } catch (cloudinaryError) {
                console.error('Không thể xóa file asset trên Cloudinary:', cloudinaryError);
            }
        }

        const productId = asset.productId;

        // thực hiện xóa assets tương ứng trong db
        return await this.prisma.$transaction(async (tx) => {
            await tx.productAsset.delete({ where: { id: assetId } });

            // tìm ảnh khác trhay thế nếu primary bị xóa
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
                    // không còn ảnh nào -> null
                    await tx.product.update({
                        where: { id: productId },
                        data: { thumbnailUrl: null }
                    });
                }
            }
            return { message: 'Xóa asset thành công' };
        });
    }

    // set primary
    async setPrimaryAsset(productId: string, assetId: string) {
        const asset = await this.prisma.productAsset.findFirst({
            where: { id: assetId, productId }
        });
        if (!asset) throw new NotFoundException('Asset không tồn tại hoặc không thuộc sản phẩm này');

        return await this.prisma.$transaction(async (tx) => {
            // tắt tất cả primary hiện tại của sản phẩm
            await tx.productAsset.updateMany({
                where: { productId },
                data: { isPrimary: false }
            })

            // set primary cho asset được chọn
            const updatedAsset = await tx.productAsset.update({
                where: { id: assetId },
                data: { isPrimary: true }
            });

            // đồng bộ làm thumbnail
            await tx.product.update({
                where: { id: productId },
                data: { thumbnailUrl: updatedAsset.url }
            });

            return updatedAsset;
        });
    }

    /**
     * toggle trạng thái kinh doanh của sản phẩm
     *
     * khi sản phẩm cha bị tắt, toàn bộ biến thể cũng bị tắt theo để đảm bảo
     * không còn biến thể nào ở trạng thái có thể bán trong khi sản phẩm cha bị ẩn
     */
    async toggleStatus(id: string) {
        const product = await this.prisma.product.findUnique({
            where: { id },
            select: { id: true, name: true, isActive: true }
        });

        if (!product) throw new NotFoundException('Sản phẩm không tồn tại');

        return await this.prisma.$transaction(async (tx) => {
            // toggle trạng thái kinh doanh (isActive)
            const updatedProduct = await tx.product.update({
                where: { id },
                data: {
                    isActive: !product.isActive,
                    ...(product.isActive ? { isFeatured: false } : {}),
                }
            });

            // ẩn toàn bộ biến thể nếu sản phẩm cha ngừng kinh doanh
            if (!updatedProduct.isActive) {
                await tx.productVariant.updateMany({
                    where: { productId: id },
                    data: { isActive: false }
                });
            }

            const featuredProduct = await this.syncSingleFeatured(
                tx,
                updatedProduct.isActive ? undefined : id,
            );

            return {
                message: `Đã ${updatedProduct.isActive ? 'hiển thị' : 'ẩn'} sản phẩm '${product.name}'`,
                isActive: updatedProduct.isActive,
                featuredProduct,
            };
        });
    }

    /**
     * toggle trạng thái nổi bật của sản phẩm
     * chỉ sản phẩm đang hoạt động mới được phép là sản phẩm nổi bật
     * hệ thống chỉ duy trì duy nhất một sản phẩm nổi bật tại một thời điểm
     * khi đánh dấu nổi bật, tất cả sản phẩm nổi bật khác sẽ bị gỡ
     * khi gỡ nổi bật, hệ thống sẽ tự động chọn sản phẩm phù hợp khác nếu cần
     */
    async toggleFeatured(id: string) {
        const product = await this.prisma.product.findUnique({
            where: { id },
            select: {
                id: true,
                name: true,
                isActive: true,
                isFeatured: true
            }
        });

        if (!product) {
            throw new NotFoundException('Sản phẩm không tồn tại');
        }

        // không cho phép sản phẩm ngưng kinh doanh trở thành sản phẩm nổi bật
        if (!product.isActive) {
            throw new BadRequestException(
                'Không thể đánh dấu nổi bật sản phẩm đang ngưng kinh doanh'
            );
        }

        const result = await this.prisma.$transaction(async (tx) => {
            // đảo trạng thái nổi bật hiện tại
            const nextFeatured = !product.isFeatured;

            const updatedProduct = await tx.product.update({
                where: { id },
                data: {
                    isFeatured: nextFeatured
                }
            });

            // đồng bộ lại hệ thống để đảm bảo chỉ tồn tại duy nhất 1 sản phẩm nổi bật
            let featuredProduct = await this.syncSingleFeatured(
                tx,
                nextFeatured ? undefined : id,
                nextFeatured ? id : undefined,
            );

            // nếu vừa gỡ nổi bật và chưa tìm được sản phẩm thay thế
            // thì tự động chọn một sản phẩm phù hợp khác
            if (!featuredProduct && !nextFeatured) {
                featuredProduct = await this.syncSingleFeatured(tx);
            }

            return {
                message: nextFeatured
                    ? `Đã đặt '${product.name}' làm sản phẩm nổi bật duy nhất`
                    : featuredProduct?.id === id
                        ? `Không có sản phẩm hoạt động khác nên '${product.name}' vẫn là sản phẩm nổi bật`
                        : `Đã gỡ '${product.name}' khỏi mục nổi bật${featuredProduct ? ` và chuyển sang '${featuredProduct.name}'` : ''}`,

                // trạng thái nổi bật thực tế sau khi đồng bộ
                isFeatured: featuredProduct?.id === updatedProduct.id,
                featuredProduct,
            };
        });

        return result;
    }

    /**
     * xóa sản phẩm an toàn
     *
     * nếu chưa từng phát sinh order item trên bất kỳ biến thể nào thì được phép
     * xóa cứng
     * hoặc chỉ chuyển sản phẩm sang trạng thái inactive để giữ
     * nguyên tính toàn vẹn cho lịch sử đơn hàng
     */
    async removeProduct(id: string) {
        // tìm sản phẩm và biến thể liên quan (bao gồm số lượng đơn hàng của từng biến thể)
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

        // tổng số đơn hàng của tất cả biến thể
        // không được xóa cứng sp cha nếu biến thể có đơn hàng
        const totalOrders = product.variants.reduce((sum, variant) => sum + variant._count.orderItems, 0);

        return this.prisma.$transaction(async (tx) => {
            if (totalOrders > 0) {
                // ẩn sản phẩm
                const updatedProduct = await tx.product.update({
                    where: { id },
                    data: { isActive: false, isFeatured: false }
                });

                await this.syncSingleFeatured(tx, id);
                return updatedProduct;
            }

            const deletedProduct = await tx.product.delete({
                where: { id },
            });

            await this.syncSingleFeatured(tx, id);
            return deletedProduct;
        });
    }

    async restore(id: string) {
        return this.prisma.$transaction(async (tx) => {
            const restoredProduct = await tx.product.update({
                where: { id },
                data: { isActive: true },
            });

            await this.syncSingleFeatured(tx);
            return tx.product.findUnique({
                where: { id: restoredProduct.id },
            });
        });
    }

    private toVector(value: Prisma.JsonValue): number[] {
        if (!Array.isArray(value)) return [];
        return value
            .map((item) => (typeof item === 'number' ? item : Number(item)))
            .filter((item) => Number.isFinite(item));
    }

    // CLIENT
    /**
     * lấy danh sách sản phẩm có phân trang và áp dụng đầy đủ các điều kiện lọc (admin + client)
     *
     * điều kiện:
     * - phân trang
     * - tìm kiếm lai (vector embedding / keyword fallback)
     * - lọc theo category, brand, khoảng giá
     * - lọc theo trạng thái hiển thị và trạng thái hoạt động của biến thể
     * - lọc theo tồn kho
     * - lọc theo loại asset (2D hoặc 3D)
     */
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
            sortBy?: string;
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
            showActiveOnly = false,
            sortBy
        } = query;

        const pageNumber = Number(page);
        const limitNumber = Number(limit);
        const skip = (pageNumber - 1) * limitNumber;

        let categoryIds: string[] | undefined = undefined;

        if (categoryId) {
            const currentCategory = await this.prisma.category.findUnique({
                where: { id: categoryId },
                include: {
                    children: {
                        select: { id: true }
                    }
                }
            });

            categoryIds = currentCategory
                ? [currentCategory.id, ...currentCategory.children.map(c => c.id)]
                : [categoryId];
        }

        const variantConditions: any[] = [];

        if (showActiveOnly) {
            variantConditions.push({ isActive: true });
        }

        if (minPrice !== undefined || maxPrice !== undefined) {
            variantConditions.push({
                price: {
                    gte: minPrice !== undefined ? Number(minPrice) : undefined,
                    lte: maxPrice !== undefined ? Number(maxPrice) : undefined,
                }
            });
        }

        if (inventoryStatus && inventoryStatus !== 'all') {
            if (inventoryStatus === 'out_of_stock') {
                variantConditions.push({ stock: 0 });
            } else if (inventoryStatus === 'low_stock') {
                variantConditions.push({ stock: { gt: 0, lte: 10 } });
            } else if (inventoryStatus === 'in_stock') {
                variantConditions.push({ stock: { gt: 10 } });
            }
        }

        let whereCondition: any = {
            ...(categoryIds && { categoryId: { in: categoryIds } }),
            ...(brandId && { brandId }),
        };

        if (showInactiveOnly) {
            whereCondition.OR = [
                { isActive: false },
                { variants: { some: { isActive: false } } }
            ];
        } else if (showActiveOnly) {
            whereCondition.isActive = true;

            whereCondition.variants = {
                some: variantConditions.length > 0
                    ? { AND: variantConditions }
                    : { isActive: true }
            };
        } else {
            if (!isAdmin) {
                whereCondition.isActive = true;
            }

            if (variantConditions.length > 0) {
                whereCondition.variants = {
                    some: {
                        AND: variantConditions
                    }
                };
            }
        }

        // tích hợp tìm kiếm lai
        let semanticProductIds: string[] | null = null;
        const scoresMap = new Map<string, number>();

        if (search) {
            try {
                // vector hóa từ khóa tìm kiếm của người dùng
                const queryEmbedding = await this.embeddingService.embedText(search);

                // lấy danh sách vector và id của tất cả sản phẩm đang kinh doanh
                const embeddings = await this.prisma.productEmbedding.findMany({
                    where: {
                        product: {
                            isActive: true,
                            variants: { some: { isActive: true } },
                        },
                    },
                    select: {
                        productId: true,
                        embedding: true,
                    },
                });

                // tính điểm tương đồng cosine trên RAM
                const scoredRows = embeddings.map((row) => {
                    const vec = this.toVector(row.embedding);
                    const score = this.cosineSimilarity(queryEmbedding, vec);
                    return { productId: row.productId, score };
                });

                // lọc kết quả theo ngưỡng tương đồng
                const threshold = Number(
                    this.configService.get<string>('AI_RAG_SIMILARITY_THRESHOLD') ?? '0.50',
                );
                let filtered = scoredRows.filter((item) => item.score >= threshold);

                // hạ ngưỡng khi không có sản phẩm đạt yêu cầu
                if (filtered.length === 0) {
                    filtered = scoredRows.filter((item) => item.score >= 0.45);
                }

                if (filtered.length > 0) {
                    filtered.sort((a, b) => b.score - a.score);
                    semanticProductIds = filtered.map((item) => item.productId);
                    filtered.forEach((item) => scoresMap.set(item.productId, item.score));
                    this.logger.log(`Semantic Search tìm thấy ${semanticProductIds.length} sản phẩm phù hợp.`);
                }
            } catch (error) {
                this.logger.error(`Lỗi tìm kiếm AI, tự động chuyển đổi sang tìm kiếm từ khóa truyền thống: ${error.message}`);
            }
        }

        if (semanticProductIds !== null) {
            // sử dụng các sản phẩm tìm kiếm được từ AI
            whereCondition.id = { in: semanticProductIds };
        } else if (search) {
            // fallback tìm kiếm bằng keyword
            const words = search.trim().split(/\s+/).filter(w => w.length > 0);

            if (words.length > 0) {
                const searchConditions = words.map(word => ({
                    OR: [
                        { name: { contains: word } },
                        { brand: { name: { contains: word } } },
                        { category: { name: { contains: word } } },
                        { category: { parent: { name: { contains: word } } } },
                    ],
                }));

                if (whereCondition.OR) {
                    whereCondition.AND = [
                        { OR: whereCondition.OR },
                        ...searchConditions
                    ];
                    delete whereCondition.OR;
                } else {
                    whereCondition.AND = [
                        ...(whereCondition.AND ?? []),
                        ...searchConditions
                    ];
                }
            }
        }

        if (assetType && assetType !== 'all') {
            if (assetType === 'has_3d') {
                whereCondition.assets = {
                    some: {
                        type: {
                            in: ['GLB', 'USDZ']
                        }
                    }
                };
            } else if (assetType === 'only_2d') {
                whereCondition.assets = {
                    every: {
                        type: 'IMAGE'
                    }
                };
            }
        }

        let orderByObj: any = { createdAt: 'desc' };

        if (sortBy === 'popular') {
            orderByObj = { soldCount: 'desc' };
        } else if (sortBy === 'newest') {
            orderByObj = { createdAt: 'desc' };
        }

        const paginateOnRam = semanticProductIds !== null;

        let [items, total] = await Promise.all([
            this.prisma.product.findMany({
                where: whereCondition,
                include: {
                    brand: {
                        select: {
                            name: true,
                            logoUrl: true
                        }
                    },
                    category: {
                        include: {
                            parent: {
                                select: {
                                    id: true,
                                    name: true
                                }
                            }
                        }
                    },
                    variants: {
                        where: showInactiveOnly
                            ? { isActive: false }
                            : showActiveOnly
                                ? { isActive: true }
                                : undefined,
                        orderBy: {
                            price: 'asc'
                        },
                        include: {
                            flashSaleProducts: {
                                where: {
                                    startsAt: { lte: new Date() },
                                    expiresAt: { gte: new Date() }
                                }
                            }
                        }
                    },
                    assets: true
                },
                orderBy: orderByObj,
                ...(!paginateOnRam ? { skip, take: limitNumber } : {}),
            }),

            this.prisma.product.count({
                where: whereCondition
            }),
        ]);

        // sắp xếp kết quả
        if (paginateOnRam && !sortBy) {
            // sort theo điểm cosine giảm dần
            items = items.sort((a, b) => {
                const scoreA = scoresMap.get(a.id) ?? 0;
                const scoreB = scoresMap.get(b.id) ?? 0;
                return scoreB - scoreA;
            });
        } else if (sortBy === 'price_asc') {
            items = items.sort((a, b) => {
                const priceA = Number(a.variants?.[0]?.price ?? 0);
                const priceB = Number(b.variants?.[0]?.price ?? 0);
                return priceA - priceB;
            });
        } else if (sortBy === 'price_desc') {
            items = items.sort((a, b) => {
                const priceA = Number(a.variants?.[0]?.price ?? 0);
                const priceB = Number(b.variants?.[0]?.price ?? 0);
                return priceB - priceA;
            });
        }
        // cắt mảng để phân trang
        const resultItems = paginateOnRam
            ? items.slice(skip, skip + limitNumber)
            : items;

        return {
            data: resultItems,
            meta: {
                total,
                page: pageNumber,
                limit: limitNumber,
                lastPage: Math.ceil(total / limitNumber),
            },
        };
    }

    async getProductById(idOrSlug: string) {
        // regex uuid hợp lệ
        const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(idOrSlug);
        const now = new Date();

        const product = await this.prisma.product.findUnique({
            where: isUuid ? { id: idOrSlug } : { slug: idOrSlug },
            include: {
                brand: { select: { name: true, logoUrl: true } },
                category: { include: { parent: { select: { id: true, name: true } } } },
                variants: {
                    orderBy: { price: "asc" },
                    include: {
                        assets: true,
                        flashSaleProducts: {
                            where: {
                                startsAt: { lte: now },
                                expiresAt: { gte: now }
                            }
                        }
                    }
                },
                assets: true
            }
        });

        if (!product) throw new NotFoundException('Sản phẩm không tồn tại');
        return product;
    }

    /**
     * thực hiện so sánh tối đa 3 sản phẩm đang hoạt động trong cùng một nhóm compare
     *
     * flow:
     * - kiểm tra list id
     * - lấy sản phẩm và chỉ giữ lại biến thể được chọn nếu có id biến thể (chỉ chọn biến thể để so sánh)
     * - chặn việc so sánh khác nhóm danh mục
     *
     * so sánh dựa trên thông số và chi tiết của biến thể được chọn thay vì dùng sản phẩm cha
     */
    async compareProducts(productIds: string[], variantIds?: string[]) {
        if (!Array.isArray(productIds) || productIds.length === 0) {
            throw new BadRequestException('productIds không được rỗng');
        }

        if (productIds.length < 2) {
            throw new BadRequestException('Cần ít nhất 2 sản phẩm để tiến hành so sánh');
        }

        if (productIds.length > 3) {
            throw new BadRequestException('Chỉ được so sánh tối đa 3 sản phẩm');
        }

        const normalizedProductIds = productIds.map((id) => id.trim()).filter(Boolean);
        if (normalizedProductIds.length !== productIds.length) {
            throw new BadRequestException('productId không hợp lệ');
        }

        const uniqueProductIds = new Set(normalizedProductIds);
        if (uniqueProductIds.size !== normalizedProductIds.length) {
            throw new BadRequestException('Không được so sánh chung loại sản phẩm');
        }

        const products = await this.prisma.product.findMany({
            where: { id: { in: normalizedProductIds }, isActive: true },
            include: {
                brand: { select: { name: true, logoUrl: true } },
                category: { include: { parent: { select: { id: true, name: true } } } },
                variants: {
                    where: { isActive: true },
                    orderBy: { price: 'asc' },
                    include: { assets: true },
                },
                assets: true,
            },
        });

        if (products.length !== normalizedProductIds.length) {
            const foundIds = new Set(products.map((product) => product.id));
            const missingIds = normalizedProductIds.filter((id) => !foundIds.has(id));
            throw new NotFoundException(`Không tìm thấy productId: ${missingIds.join(', ')}`);
        }

        // thu hẹp mỗi sản phẩm về đúng biến thể người gọi chọn để giá và
        // thông số trả về phản ánh đúng cấu hình đang được so sánh
        const variantIdSet = new Set(variantIds ?? []);
        products.forEach((product) => {
            const selectedVariant = product.variants.find((v) => variantIdSet.has(v.id));
            if (selectedVariant) {
                product.variants = [selectedVariant];
            } else {
                if (product.variants.length > 0) {
                    product.variants = [product.variants[0]];
                }
            }
        });

        const categories = await this.prisma.category.findMany({
            select: {
                id: true,
                name: true,
                slug: true,
                parentId: true,
            },
        });
        const categoryById = new Map(categories.map((category) => [category.id, category]));
        const childrenByParentId = categories.reduce((acc, category) => {
            if (!category.parentId) return acc;
            const children = acc.get(category.parentId) ?? [];
            children.push(category);
            acc.set(category.parentId, children);
            return acc;
        }, new Map<string, CompareCategoryNode[]>());

        const compareKeys = products.map((product) => ({
            productId: product.id,
            productName: product.name,
            key: this.resolveCompareKey(
                product.name,
                product.categoryId,
                categoryById,
                childrenByParentId,
            ),
        }));

        const firstCompareKey = compareKeys[0].key;
        const mismatched = compareKeys.filter(({ key }) => key.id !== firstCompareKey.id);

        if (mismatched.length > 0) {
            throw new BadRequestException({
                message: 'Các sản phẩm không cùng danh mục',
                compareKey: firstCompareKey,
                products: compareKeys.map(({ productId, productName, key }) => ({
                    productId,
                    productName,
                    compareKey: key,
                })),
            });
        }

        const productById = new Map(products.map((product) => [product.id, product]));
        const orderedProducts = normalizedProductIds.map((id) => productById.get(id)!);

        return {
            compareKey: firstCompareKey,
            products: orderedProducts,
            specRows: this.buildCompareSpecRows(orderedProducts),
        };
    }

    // lấy danh sách sản phẩm nổi bật
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
                attributeConfig: true,
                assets: {
                    select: {
                        id: true,
                        type: true,
                        url: true,
                    }
                },
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
            },
            orderBy: {
                createdAt: 'desc'
            }
        });
    }

    /**
     * lấy sản phẩm liên quan theo ngữ cảnh mua hàng
     * ưu tiên sản phẩm cùng danh mục gần nhất
     * nếu chưa đủ số lượng, mở rộng sang cate cùng cấp trong cùng nhánh cha
     */
    async getRelatedProducts(id: string) {
        const currentProduct = await this.prisma.product.findUnique({
            where: { id },
            select: {
                categoryId: true,
                category: { select: { parentId: true } }
            }
        });

        if (!currentProduct) throw new NotFoundException('Sản phẩm không tồn tại');
        if (!currentProduct.categoryId) return [];

        const limit = 4;
        const productInclude = {
            brand: { select: { name: true, logoUrl: true } },
            variants: {
                where: {
                    isActive: true,
                    stock: { gt: 0 }
                },
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
        } satisfies Prisma.ProductInclude;

        const productOrderBy: Prisma.ProductOrderByWithRelationInput[] = [
            { averageRating: 'desc' },
            { reviewCount: 'desc' },
            { soldCount: 'desc' },
            { viewsCount: 'desc' }
        ];

        const inStockVariantCondition = {
            some: {
                isActive: true,
                stock: { gt: 0 }
            }
        } satisfies Prisma.ProductVariantListRelationFilter;

        const exactMatchProducts = await this.prisma.product.findMany({
            where: {
                categoryId: currentProduct.categoryId,
                id: { not: id }, // không lấy chính nó
                isActive: true,
                variants: inStockVariantCondition
            },
            take: limit,
            include: productInclude,
            orderBy: productOrderBy
        });

        if (exactMatchProducts.length >= limit) {
            return exactMatchProducts;
        }

        const parentId = currentProduct.category?.parentId;
        if (!parentId) {
            return exactMatchProducts;
        }

        const siblingCategories = await this.prisma.category.findMany({
            where: {
                parentId,
                id: { not: currentProduct.categoryId }
            },
            select: { id: true }
        });
        const siblingCategoryIds = siblingCategories.map((category) => category.id);

        if (siblingCategoryIds.length === 0) {
            return exactMatchProducts;
        }

        const fallbackProducts = await this.prisma.product.findMany({
            where: {
                categoryId: { in: siblingCategoryIds },
                id: { notIn: [id, ...exactMatchProducts.map((product) => product.id)] },
                isActive: true,
                variants: inStockVariantCondition
            },
            take: limit - exactMatchProducts.length,
            include: productInclude,
            orderBy: productOrderBy
        });

        return [...exactMatchProducts, ...fallbackProducts];
    }

    /**
     * lấy danh sách sản phẩm đánh giá cao
     *
     * ưu tiên đầu tiên là điểm rating và số lượng review đủ lớn
     * nếu dữ liệu review chưa đủ lớn thì dùng top bán chạy và độ mới thay thế
     */
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

        // layer 1: lấy sp theo top rating & review cnt
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
                    { soldCount: 'desc' }, // l2 : lấy các sp có lượt bán cao nhất
                    { createdAt: 'desc' } // l3: lây theo độ mới
                ],
                take: limit
            });
        }

        return products;
    }

    /**
     * tạo danh sách sản phẩm đề xuất cá nhân hóa cho người dùng
     *
     * ưu tiên recommendation bằng vector embedding
     * nếu không có embedding hoặc xảy ra lỗi thì fallback sang rule-based recommendation
     * nếu vẫn chưa đủ số lượng sản phẩm thì bổ sung bằng danh sách fallback sản phẩm phổ biến
     */
    async getPersonalizedRecommendations(
        userId: string,
        limit: number = 8
    ) {
        const safeLimit = this.normalizeRecommendationLimit(limit);

        // sở thích mua sắm của user dựa trên khảo sát
        const preferences = await this.getUserRecommendationPreferences(userId);

        const productSelect = this.getRecommendationProductSelect();

        // lọc sản phẩm theo ngân sách ưa thích của người dùng
        const variantPriceFilter = this.getBudgetVariantFilter(
            preferences.budgetRange
        );

        // vector rcm
        // nếu đã có vector sở thích thì ưu tiên recommendation bằng cosine similarity
        if (
            preferences.preferenceVector &&
            preferences.preferenceVector.length > 0
        ) {
            try {
                // lấy embedding của các sản phẩm đang hoạt động và còn hàng
                const rows = await this.prisma.productEmbedding.findMany({
                    where: {
                        product: {
                            isActive: true,
                            variants: {
                                some: {
                                    isActive: true,
                                    stock: { gt: 0 },
                                    ...(variantPriceFilter ?? {})
                                }
                            }
                        }
                    },
                    select: {
                        productId: true,
                        embedding: true
                    }
                });

                // tính độ tương đồng cosine giữa vector sở thích của user và vector sản phẩm
                const queryEmbedding = preferences.preferenceVector;

                const scoredRows = rows
                    .map((row) => {
                        const embedding = Array.isArray(row.embedding)
                            ? row.embedding
                                .map(v => typeof v === 'number' ? v : Number(v))
                                .filter(Number.isFinite)
                            : [];

                        return {
                            productId: row.productId,
                            score: this.cosineSimilarity(
                                queryEmbedding,
                                embedding
                            )
                        };
                    })
                    .filter((item) => item.score > 0)
                    .sort((a, b) => b.score - a.score);

                // lấy top sản phẩm có điểm tương đồng cao nhất
                const targetIds = scoredRows
                    .slice(0, safeLimit)
                    .map((item) => item.productId);

                if (targetIds.length > 0) {
                    const products = await this.prisma.product.findMany({
                        where: {
                            id: { in: targetIds }
                        },
                        select: productSelect
                    });

                    // giữ nguyên thứ tự đã được xếp hạng bởi cosine sml
                    const productMap = new Map(
                        products.map((p) => [p.id, p])
                    );

                    const sortedProducts: typeof products = [];

                    for (const id of targetIds) {
                        const p = productMap.get(id);
                        if (p) {
                            sortedProducts.push(p);
                        }
                    }

                    // trả đủ 8 items
                    if (sortedProducts.length >= safeLimit) {
                        return sortedProducts;
                    }

                    // bổ sung sản phẩm fallback nếu thiếu
                    const excludedIds = new Set(
                        sortedProducts.map((p) => p.id)
                    );

                    const fallback =
                        await this.getFallbackRecommendations(
                            excludedIds,
                            safeLimit - sortedProducts.length,
                            productSelect
                        );

                    return [...sortedProducts, ...fallback];
                }
            } catch (err) {
                this.logger.error(
                    `Vector personalized recommendations failed, falling back: ${err.message}`
                );
            }
        }

        // rule base rcm
        // fallback dựa trên category, brand và ngân sách
        const preferenceOr: Prisma.ProductWhereInput[] = [];

        if (preferences.categoryIds.length > 0) {
            preferenceOr.push({
                categoryId: {
                    in: preferences.categoryIds
                }
            });
        }

        if (preferences.brandIds.length > 0) {
            preferenceOr.push({
                brandId: {
                    in: preferences.brandIds
                }
            });
        }

        if (variantPriceFilter) {
            preferenceOr.push({
                variants: {
                    some: variantPriceFilter
                }
            });
        }

        // sản phẩm phải hoạt động và đang còn hàng
        const baseWhere: Prisma.ProductWhereInput = {
            isActive: true,
            variants: {
                some: {
                    isActive: true,
                    stock: { gt: 0 },
                    ...(variantPriceFilter ?? {})
                }
            }
        };

        const preferenceProducts =
            preferenceOr.length > 0
                ? await this.prisma.product.findMany({
                    where: {
                        ...baseWhere,
                        OR: preferenceOr
                    },
                    select: productSelect,

                    // lấy dư dữ liệu để phục vụ bước chấm điểm
                    take: safeLimit * 3,

                    orderBy: [
                        { averageRating: 'desc' },
                        { soldCount: 'desc' },
                        { createdAt: 'desc' }
                    ]
                })
                : [];

        // chấm điểm sản phẩm theo hồ sơ sở thích người dùng
        const scoredProducts = preferenceProducts
            .map((product) => ({
                product,
                score: this.scoreRecommendedProduct(
                    product,
                    preferences
                )
            }))
            .sort((a, b) => b.score - a.score)
            .map((item) => item.product);

        const merged = this.uniqueProducts(scoredProducts)
            .slice(0, safeLimit);

        // nếu chưa đủ số lượng thì lấy thêm sản phẩm phổ biến
        if (merged.length < safeLimit) {
            const fallback =
                await this.getFallbackRecommendations(
                    new Set(merged.map((product) => product.id)),
                    safeLimit - merged.length,
                    productSelect
                );

            merged.push(...fallback);
        }

        return merged;
    }

    private cosineSimilarity(a: number[], b: number[]): number {
        if (a.length === 0 || b.length === 0 || a.length !== b.length) return 0;

        let dot = 0;
        let aMagnitude = 0;
        let bMagnitude = 0;
        for (let i = 0; i < a.length; i += 1) {
            dot += a[i] * b[i];
            aMagnitude += a[i] * a[i];
            bMagnitude += b[i] * b[i];
        }

        if (aMagnitude === 0 || bMagnitude === 0) return 0;
        return dot / (Math.sqrt(aMagnitude) * Math.sqrt(bMagnitude));
    }

    private normalizeRecommendationLimit(limit: number) {
        if (!Number.isFinite(limit)) return 8;
        return Math.min(Math.max(Math.trunc(limit), 1), 20);
    }

    private getRecommendationProductSelect() {
        return {
            id: true,
            categoryId: true,
            brandId: true,
            name: true,
            slug: true,
            thumbnailUrl: true,
            tagline: true,
            description: true,
            averageRating: true,
            reviewCount: true,
            soldCount: true,
            metadata: true,
            attributeConfig: true,
            brand: { select: { id: true, name: true } },
            category: { select: { id: true, name: true } },
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
    }

    /**
 * lấy và chuẩn hóa hồ sơ sở thích của người dùng phục vụ hệ thống recommendation
 * đọc preferences từ db
 * validate kiểu dữ liệu
 * loại bỏ dữ liệu không hợp lệ
 * trả về cấu trúc an toàn để sử dụng trong recommendation engine
 */
    private async getUserRecommendationPreferences(
        userId: string
    ): Promise<ProductRecommendationPreferences> {

        const profile = await this.prisma.profile.findUnique({
            where: { userId },
            select: {
                preferences: true
            }
        });

        const preferences = profile?.preferences;

        // trường hợp chưa thiết lập preferences hoặc dữ liệu bị lỗi
        if (
            !preferences ||
            typeof preferences !== 'object' ||
            Array.isArray(preferences)
        ) {
            return {
                categoryIds: [],
                brandIds: [],
                styleTags: [],
                useCases: [],
                budgetRange: null,
                preferenceVector: []
            };
        }

        const data = preferences as Record<string, unknown>;

        const budgetRange =
            data.budgetRange as
            | Record<string, unknown>
            | null
            | undefined;

        return {
            // danh mục sản phẩm yêu thích
            categoryIds: Array.isArray(data.categoryIds)
                ? data.categoryIds.filter(
                    (id): id is string => typeof id === 'string'
                )
                : [],

            // thương hiệu yêu thích
            brandIds: Array.isArray(data.brandIds)
                ? data.brandIds.filter(
                    (id): id is string => typeof id === 'string'
                )
                : [],

            // phong cách sản phẩm quan tâm
            styleTags: Array.isArray(data.styleTags)
                ? data.styleTags.filter(
                    (tag): tag is string => typeof tag === 'string'
                )
                : [],

            // mục đích sử dụng sản phẩm
            useCases: Array.isArray(data.useCases)
                ? data.useCases.filter(
                    (useCase): useCase is string =>
                        typeof useCase === 'string'
                )
                : [],

            // khoảng ngân sách mong muốn
            budgetRange:
                budgetRange &&
                    typeof budgetRange === 'object'
                    ? {
                        min:
                            typeof budgetRange.min === 'number'
                                ? budgetRange.min
                                : null,

                        max:
                            typeof budgetRange.max === 'number'
                                ? budgetRange.max
                                : null
                    }
                    : null,

            // vector embedding đại diện cho sở thích người dùng
            preferenceVector: Array.isArray(data.preferenceVector)
                ? data.preferenceVector.filter(
                    (v): v is number => typeof v === 'number'
                )
                : []
        };
    }

    private getBudgetVariantFilter(budgetRange: ProductRecommendationPreferences['budgetRange']) {
        if (!budgetRange) return null;
        const price: Prisma.DecimalFilter = {};
        if (budgetRange.min !== null) price.gte = budgetRange.min;
        if (budgetRange.max !== null) price.lte = budgetRange.max;
        if (Object.keys(price).length === 0) return null;
        return { isActive: true, stock: { gt: 0 }, price } satisfies Prisma.ProductVariantWhereInput;
    }

    private scoreRecommendedProduct(
        product: Prisma.ProductGetPayload<{ select: ReturnType<ProductsService['getRecommendationProductSelect']> }>,
        preferences: ProductRecommendationPreferences
    ) {
        let score = 0;

        if (product.categoryId && preferences.categoryIds.includes(product.categoryId)) score += 50;
        if (product.brandId && preferences.brandIds.includes(product.brandId)) score += 35;

        const lowestPrice = product.variants[0]?.price ? Number(product.variants[0].price) : null;
        if (lowestPrice !== null && preferences.budgetRange) {
            const { min, max } = preferences.budgetRange;
            if ((min === null || lowestPrice >= min) && (max === null || lowestPrice <= max)) {
                score += 20;
            }
        }

        const searchableText = [
            product.name,
            product.tagline,
            product.description,
            product.brand?.name,
            product.category?.name,
            product.metadata ? JSON.stringify(product.metadata) : ''
        ].join(' ').toLowerCase();

        for (const tag of preferences.styleTags) {
            if (searchableText.includes(tag.toLowerCase())) score += 8;
        }

        for (const useCase of preferences.useCases) {
            if (searchableText.includes(useCase.toLowerCase())) score += 8;
        }

        score += Math.min(product.averageRating * 3, 15);
        score += Math.min(product.reviewCount, 20) * 0.5;
        score += Math.min(product.soldCount, 100) * 0.1;

        return score;
    }

    private async getFallbackRecommendations(
        excludedProductIds: Set<string>,
        limit: number,
        select: ReturnType<ProductsService['getRecommendationProductSelect']>
    ) {
        if (limit <= 0) return [];

        return this.prisma.product.findMany({
            where: {
                id: { notIn: Array.from(excludedProductIds) },
                isActive: true,
                variants: { some: { isActive: true, stock: { gt: 0 } } }
            },
            select,
            take: limit,
            orderBy: [
                { averageRating: 'desc' },
                { soldCount: 'desc' },
                { createdAt: 'desc' }
            ]
        });
    }

    private uniqueProducts<T extends { id: string }>(products: T[]) {
        const seen = new Set<string>();
        return products.filter((product) => {
            if (seen.has(product.id)) return false;
            seen.add(product.id);
            return true;
        });
    }

    // thêm biến thể mới cho sp cha đã tồn tại
    async addVariant(id: string, data: CreateVariantDto) {
        const product = await this.prisma.product.findUnique({
            where: { id }
        });
        if (!product) throw new NotFoundException('Sản phẩm cha không tồn tại');

        // đảm bảo biến thể chưa có trong db
        const existingSku = await this.prisma.productVariant.findUnique({
            where: { sku: data.sku }
        })
        if (existingSku) {
            throw new BadRequestException(`Mã SKU '${data.sku}' đã tồn tại`);
        }

        const parsedAttributes = data.attributes ? JSON.parse(data.attributes) : {};

        // thêm mới biến thể
        const variant = await this.prisma.productVariant.create({
            data: {
                productId: id,
                sku: data.sku,
                name: data.name,
                price: data.price,
                stock: data.stock,
                attributes: parsedAttributes
            }
        });
        this.queueProductEmbeddingSync(id);
        return variant;
    }

    /**
     * tổng hợp các chỉ số tồn kho cho dashboard
     *
     * bao gồm:
     * - tổng số SKU
     * - tổng tồn kho
     * - số SKU sắp hết hàng
     * - working capital
     * - thống kê trạng thái đang hoạt động và ngừng hoạt động ở cả mức variant và product
     */
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
            // các biến thể đang hoạt động của những sản phẩm đang hoạt động
            this.prisma.productVariant.findMany({
                where: {
                    isActive: true,
                    product: { isActive: true }
                },
                select: { price: true, stock: true }
            }),
            // các biến thể đang bị tắt
            this.prisma.productVariant.findMany({
                where: { isActive: false },
                include: { product: { select: { name: true } } }
            }),
            // các sản phẩm đang bị tắt
            this.prisma.product.findMany({
                where: { isActive: false },
                select: { id: true, name: true, slug: true }
            })
        ]);

        const capitalValue = workingCapital.reduce((acc, curr) => {
            return acc + (Number(curr.price) * curr.stock);
        }, 0);

        // giá trị thực tế chỉ tính trên phần đang hoạt động
        const actualStock = activeVariants.reduce((acc, curr) => acc + curr.stock, 0);
        const actualCapital = activeVariants.reduce((acc, curr) => {
            return acc + (Number(curr.price) * curr.stock);
        }, 0);

        return {
            // total SKUs
            totalSKUs,
            totalStock: totalStock._sum.stock || 0,
            lowStockCount,
            workingCapital: capitalValue,

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

    // cập nhật biến thể và đồng bộ lại embedding
    async updateVariant(variantId: string, data: UpdateVariantDto) {
        const variant = await this.prisma.productVariant.findUnique({
            where: { id: variantId }
        });
        if (!variant) throw new NotFoundException('Biến thể không tồn tại');

        const parsedAttributes = data.attributes ? JSON.parse(data.attributes) : {};

        // update biến thể
        const updatedVariant = await this.prisma.productVariant.update({
            where: { id: variantId },
            data: {
                ...data,
                price: data.price,
                stock: data.stock,
                attributes: parsedAttributes
            }
        });
        // đồng bộ lại vector embedding
        this.queueProductEmbeddingSync(variant.productId);
        return updatedVariant;
    }

    /**
     * toggle trạng thái kinh doanh của một biến thể
     *
     * nếu biến thể vẫn đang nằm trong các đơn hàng chưa hoàn tất thì thao tác
     * bị từ chối để tránh làm hỏng luồng xử lý đơn
     */
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

        // không được ngưng kinh doanh biến thể khi vẫn còn nằm trong luồng order chưa hoàn tất
        const activeOrders = variant.orderItems.filter(oi =>
            !['DELIVERED', 'CANCELLED', 'RETURNED', 'FAILED', 'COMPLETED'].includes(oi.order.status)
        );

        if (activeOrders.length > 0) {
            throw new BadRequestException('Không thể thay đổi trạng thái biến thể vì có đơn hàng chưa hoàn tất');
        }

        const result = await this.prisma.$transaction(async (tx) => {
            // toggle isActive
            const updatedVariant = await tx.productVariant.update({
                where: { id: variantId },
                data: { isActive: !variant.isActive }
            });

            // ngưng kinh doanh -> xóa khỏi giỏ hàng
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
        this.queueProductEmbeddingSync(variant.productId);
        return result;
    }

    // giảm stock khi đơn hàng dược chốt
    async decreaseStock(variantId: string, quantity: number) {
        const variant = await this.prisma.productVariant.findUnique({ where: { id: variantId } });
        if (!variant) throw new NotFoundException('Biến thể không tồn tại');

        if (variant.stock < quantity) {
            throw new BadRequestException(`Sản phẩm ${variant.name} không đủ hàng trong kho`);
        }

        const updatedVariant = await this.prisma.productVariant.update({
            where: { id: variantId },
            data: { stock: { decrement: quantity } }
        });
        this.queueProductEmbeddingSync(variant.productId);
        return updatedVariant;
    }

    // hoàn trả stock khi đơn hàng bị hủy, hoàn trả hoặc thanh toán thất bại
    async increaseStock(variantId: string, quantity: number) {
        const variant = await this.prisma.productVariant.findUnique({
            where: { id: variantId },
            select: { id: true, productId: true }
        });

        if (!variant) throw new NotFoundException('Biến thể không tồn tại');

        const updatedVariant = await this.prisma.productVariant.update({
            where: { id: variantId },
            data: {
                stock: { increment: quantity }
            }
        });
        this.queueProductEmbeddingSync(variant.productId);
        return updatedVariant;
    }

    // tăng view sản phẩm
    async incrementView(id: string, deviceId: string = 'default') {
        const cacheKey = `view_check:${id}:${deviceId}`;
        const isViewed = await this.redisService.get(cacheKey);

        if (!isViewed) {
            // đánh dấu đã xem tránh spam view
            await this.redisService.set(cacheKey, '1', 'EX', 1800);
            // tổng view mới chưa được thêm vào db
            await this.redisService.incr(`product_views_buffer:${id}`);
        }
    }

    // cron job thực hiện cộng dồn view vào db sau mỗi 10 phút
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

    // auto sinh sku
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

    /**
     * xác định category node nào sẽ đóng vai trò compareKey của sản phẩm
     *
     * gói toàn bộ quy tắc phân nhóm compare theo cây danh mục, bao gồm
     * cả trường hợp so sánh theo category gốc của một family
     */
    private resolveCompareKey(
        productName: string,
        categoryId: string | null,
        categoryById: Map<string, CompareCategoryNode>,
        childrenByParentId: Map<string, CompareCategoryNode[]>,
    ): CompareKey {
        if (!categoryId) {
            throw new BadRequestException(`Sản phẩm "${productName}" chưa có danh mục để so sánh`);
        }

        const path = this.buildCategoryPath(categoryId, categoryById);
        if (path.length === 0) {
            throw new BadRequestException(`Không tìm thấy danh mục của sản phẩm "${productName}"`);
        }

        // cate hiện tại - cate cha
        const currentCategory = path[path.length - 1];
        // subcate
        const currentChildren = childrenByParentId.get(currentCategory.id) ?? [];

        if (path.length === 1) {
            if (currentChildren.length > 0) {
                throw new BadRequestException(
                    `Sản phẩm "${productName}" đang ở danh mục cha "${currentCategory.name}". ` +
                    'Cần gán danh mục con trước khi so sánh',
                );
            }

            return {
                ...this.toCompareKeyNode(currentCategory),
                strategy: 'standalone-category',
                path: path.map((category) => this.toCompareKeyNode(category)),
            };
        }

        // luôn sử dụng danh mục gốc làm khóa so sánh để cho phép so sánh giữa các subcate
        const keyCategory = path[0];

        return {
            ...this.toCompareKeyNode(keyCategory),
            strategy: 'category-family',
            path: path.map((category) => this.toCompareKeyNode(category)),
        };
    }

    /**
     * dựng đầy đủ đường đi của một cate từ node hiện tại lên gốc
     *
     * chặn trường hợp dữ liệu cate bị lỗi vòng lặp
     */
    private buildCategoryPath(
        categoryId: string,
        categoryById: Map<string, CompareCategoryNode>,
    ): CompareCategoryNode[] {
        const path: CompareCategoryNode[] = [];
        const visited = new Set<string>();
        let current = categoryById.get(categoryId);

        while (current) {
            // loop
            if (visited.has(current.id)) {
                throw new BadRequestException('Cây danh mục không hợp lệ');
            }

            visited.add(current.id);
            path.unshift(current);
            current = current.parentId ? categoryById.get(current.parentId) : undefined;
        }

        return path;
    }

    // nguồn dữ liệu so sánh được lấy từ common specs và attribute config
    private buildCompareSpecRows(products: any[]) {
        const labels = new Set<string>();
        const valueByProductId: Record<string, Record<string, string>> = {};

        for (const product of products) {
            const values: Record<string, string> = {};
            const metadata = product.metadata as Record<string, any> | null;
            const commonSpecs = metadata?.common_specs;

            // lấy common_specs từ metadata
            if (commonSpecs && typeof commonSpecs === 'object' && !Array.isArray(commonSpecs)) {
                for (const [key, value] of Object.entries(commonSpecs)) {
                    const label = String(key);
                    labels.add(label);
                    values[label] = this.formatCompareValue(value);
                }
            }

            // lấy attributes từ các variant
            if (product.variants && Array.isArray(product.variants)) {
                product.variants.forEach((variant: any) => {
                    if (variant.attributes && typeof variant.attributes === 'object') {
                        for (const [key, value] of Object.entries(variant.attributes)) {
                            const label = String(key);
                            labels.add(label);

                            const strVal = this.formatCompareValue(value);
                            if (strVal) {
                                if (values[label]) {
                                    const vals = new Set(values[label].split(' / ').map(v => v.trim()));
                                    vals.add(strVal);
                                    values[label] = Array.from(vals).join(' / ');
                                } else {
                                    values[label] = strVal;
                                }
                            }
                        }
                    }
                });
            }

            valueByProductId[product.id] = values;
        }

        return [...labels].map((label) => {
            const values = products.reduce((acc, product) => {
                acc[product.id] = valueByProductId[product.id]?.[label] ?? null;
                return acc;
            }, {} as Record<string, string | null>);
            const uniqueValues = new Set(Object.values(values).filter((value) => value !== null && value !== ''));

            return {
                label,
                values,
                isDifferent: uniqueValues.size > 1,
            };
        });
    }

    private formatCompareValue(value: unknown): string {
        if (value === null || value === undefined) return '';
        if (typeof value === 'string') return value;
        if (typeof value === 'number' || typeof value === 'boolean') return String(value);
        return JSON.stringify(value);
    }

    private toCompareKeyNode(category: CompareCategoryNode) {
        return {
            id: category.id,
            name: category.name,
            slug: category.slug,
        };
    }

    /**
     * đồng bộ trạng thái sản phẩm nổi bật trong hệ thống
     * chỉ sản phẩm đang hoạt động mới được phép là sản phẩm nổi bật
     * hệ thống chỉ được tồn tại duy nhất một sản phẩm nổi bật
     * ưu tiên sử dụng sản phẩm được chỉ định qua preferredProductId
     * nếu không có, giữ lại featured hiện tại nếu hợp lệ
     * nếu vẫn không có, tự động chọn một sản phẩm active khác
     * nếu không còn sản phẩm active nào, gỡ toàn bộ trạng thái nổi bật
     */
    private async syncSingleFeatured(
        tx: Prisma.TransactionClient,
        skipProductId?: string,
        preferredProductId?: string,
    ) {
        const skipProductWhere = skipProductId
            ? { id: { not: skipProductId } }
            : {};

        const productIdentitySelect = {
            id: true,
            name: true,
        } satisfies Prisma.ProductSelect;

        // ưu tiên sử dụng sản phẩm được chỉ định làm featured
        let selectedProduct =
            preferredProductId &&
                preferredProductId !== skipProductId
                ? await tx.product.findFirst({
                    where: {
                        id: preferredProductId,
                        isActive: true,
                    },
                    select: productIdentitySelect,
                })
                : null;

        let selectedFromExistingFeatured = false;

        // nếu không có preferred product hợp lệ
        // thử giữ lại featured hiện tại
        if (!selectedProduct) {
            selectedProduct = await tx.product.findFirst({
                where: {
                    isFeatured: true,
                    isActive: true,
                    ...skipProductWhere,
                },
                orderBy: [
                    { createdAt: 'desc' },
                ],
                select: productIdentitySelect,
            });

            selectedFromExistingFeatured = Boolean(selectedProduct);
        }

        // nếu chưa có featured phù hợp
        // chọn một sản phẩm active khác để thay thế
        if (!selectedProduct) {
            selectedProduct = await tx.product.findFirst({
                where: {
                    isActive: true,
                    ...skipProductWhere,
                },
                orderBy: [
                    { createdAt: 'desc' },
                ],
                select: productIdentitySelect,
            });
        }

        // không còn sản phẩm active nào trong hệ thống
        if (!selectedProduct) {
            await tx.product.updateMany({
                where: {
                    isFeatured: true
                },
                data: {
                    isFeatured: false
                },
            });

            return null;
        }

        // đánh dấu sản phẩm mới thành featured nếu cần
        if (!selectedFromExistingFeatured) {
            await tx.product.update({
                where: {
                    id: selectedProduct.id
                },
                data: {
                    isFeatured: true
                },
            });
        }

        // gỡ trạng thái featured khỏi toàn bộ sản phẩm còn lại
        await tx.product.updateMany({
            where: {
                isFeatured: true,
                id: {
                    not: selectedProduct.id
                },
            },
            data: {
                isFeatured: false
            },
        });

        return selectedProduct;
    }

    // gọi đồng bộ embedding theo kiểu bất đồng bộ, không chặn request hiện tại
    private queueProductEmbeddingSync(productId?: string | null) {
        if (!productId) return;
        void this.embeddingService.syncProductEmbeddingBestEffort(productId);
        void this.productImageEmbeddingService.syncProductImageEmbeddingBestEffort(productId);
    }

    // tạo ma trận biến thể từ các trục thuộc tính theo tích descartes (ma trậ: m * n)
    async generateVariantMatrix(axes: Record<string, string[]>, productSlug?: string) {
        // trục thuộc tính dùng để tạo combo biến thể
        const keys = Object.keys(axes);
        if (keys.length === 0) return [];

        // tích đề-các (cartesian product)
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
