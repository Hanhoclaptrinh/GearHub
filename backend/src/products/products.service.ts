import { BadRequestException, Injectable } from '@nestjs/common';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateProductDto } from './dto/create-product.dto';
import slugify from 'slugify';
import { AssetType } from '@prisma/client';

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
}
