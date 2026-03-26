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
        private cloudinary: CloudinaryService
    ) { }

    async createProduct(data: CreateProductDto, files: Express.Multer.File[]) {
        const baseSlug = slugify(data.name, { lower: true, strict: true });
        const slug = `${baseSlug}-${Date.now()}`;

        let parsedMetadata = {};
        if (data.metadata) {
            try {
                parsedMetadata = JSON.parse(data.metadata);
            } catch (e) {
                throw new BadRequestException('Metadata phải là định dạng JSON hợp lệ');
            }
        }

        const product = await this.prisma.product.create({
            data: {
                name: data.name,
                slug: slug,
                description: data.description,
                price: parseFloat(data.price),
                stock: parseInt(data.stock || '0'),
                categoryId: data.categoryId,
                brandId: data.brandId,
                metadata: parsedMetadata,
                thumbnailUrl: data.thumbnailUrl || null,
            },
        });

        // xu ly mang files (anh va model 3d)
        if (files && files.length > 0) {
            const assetPromises = files.map(async (file) => {
                const upload = await this.cloudinary.uploadFile(file);

                // phan loai dua tren ext
                const fileName = file.originalname.toLocaleLowerCase();
                let type: AssetType = AssetType.IMAGE;

                if (fileName.endsWith('.glb')) type = AssetType.GLB;
                else if (fileName.endsWith('.usdz')) type = AssetType.USDZ;

                return this.prisma.productAsset.create({
                    data: {
                        productId: product.id,
                        url: upload.secure_url,
                        type: type,
                        isPrimary: false,
                    },
                });
            });

            const assets = await Promise.all(assetPromises);

            // tu dong cap nhat thumbnail
            if (!product.thumbnailUrl) {
                const firstImageAsset = assets.find(a => a.type === AssetType.IMAGE);
                if (firstImageAsset) {
                    await this.prisma.product.update({
                        where: { id: product.id },
                        data: { thumbnailUrl: firstImageAsset.url },
                    });
                }
            }
        }

        return this.prisma.product.findUnique({
            where: { id: product.id },
            include: { assets: true, category: true, brand: true },
        });
    }

    async updateProduct(id: string, data: UpdateProductDto, files?: Express.Multer.File[]) {
        const product = await this.prisma.product.findUnique({ where: { id } });
        if (!product) throw new NotFoundException('Sản phẩm không tồn tại');

        const updateData: any = {};

        if (data.name) updateData.name = data.name;
        if (data.description) updateData.description = data.description;

        if (data.price) updateData.price = parseFloat(data.price);
        if (data.stock) updateData.stock = parseInt(data.stock);

        if (data.categoryId) updateData.categoryId = data.categoryId;
        if (data.brandId) updateData.brandId = data.brandId;

        if (data.isFeatured !== undefined) {
            updateData.isFeatured = data.isFeatured === 'true';
        }
        if (data.isActive !== undefined) {
            updateData.isActive = data.isActive === 'true';
        }

        if (data.metadata) {
            try {
                updateData.metadata = JSON.parse(data.metadata);
            } catch (e) {
                throw new BadRequestException('Metadata JSON không hợp lệ');
            }
        }

        return this.prisma.product.update({
            where: { id },
            data: updateData,
            include: { assets: true }
        });
    }

    async addAssets(productId: string, files: Express.Multer.File[]) {
        const product = await this.prisma.product.findUnique({
            where: { id: productId }
        });
        if (!product) throw new NotFoundException('Không tìm thấy sản phẩm');

        const assetPromises = files.map(async (file) => {
            const upload = await this.cloudinary.uploadFile(file);

            const fileName = file.originalname.toLowerCase();
            let type: AssetType = AssetType.IMAGE;
            if (fileName.endsWith('.glb')) type = AssetType.GLB;
            else if (fileName.endsWith('.usdz')) type = AssetType.USDZ;

            return this.prisma.productAsset.create({
                data: {
                    productId: productId,
                    url: upload.secure_url,
                    type: type,
                    isPrimary: false,
                },
            });
        });

        const newAssets = await Promise.all(assetPromises);

        if (!product.thumbnailUrl) {
            const firstImage = newAssets.find(a => a.type === AssetType.IMAGE);
            if (firstImage) {
                await this.prisma.product.update({
                    where: { id: productId },
                    data: { thumbnailUrl: firstImage.url }
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
        const product = await this.prisma.product.findUnique({
            where: { id },
            include: { assets: true, _count: { select: { orderItems: true } } }
        });

        if (!product) throw new NotFoundException('Không tìm thấy sản phẩm để xóa');

        // khong xoa san pham trong don hang cua nguoi mua
        if (product._count.orderItems > 0) {
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
}
