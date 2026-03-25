import { ConflictException, Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateCategoryDto } from './dto/create-category.dto';
import slugify from 'slugify';
import { UpdateCategoryDto } from './dto/update-category.dto';

@Injectable()
export class CategoriesService {
    constructor(
        private prisma: PrismaService,
        private cloudinaryService: CloudinaryService
    ) { }

    async createCategory(data: CreateCategoryDto, file?: Express.Multer.File) {
        const slug = slugify(data.name, { strict: true, lower: true });

        const existingSlug = await this.prisma.category.findUnique({ where: { slug } });
        if (existingSlug) throw new ConflictException('Danh mục này đã tồn tại');

        if (data.parentId) {
            const parent = await this.prisma.category.findUnique({ where: { id: data.parentId } });
            if (!parent) throw new NotFoundException('Danh mục cha không tồn tại');
        }

        let iconUrl = null;
        if (file) {
            const uploadResult = await this.cloudinaryService.uploadFile(file);
            iconUrl = uploadResult.secure_url;
        }

        return this.prisma.category.create({
            data: {
                ...data,
                slug,
                iconUrl,
            },
        });
    }

    async findAllCategories() {
        return this.prisma.category.findMany({
            where: { parentId: null },
            include: {
                children: {
                    select: {
                        id: true,
                        name: true,
                        slug: true,
                        iconUrl: true,
                        _count: { select: { products: true } }
                    }
                }
            },
            orderBy: { name: 'asc' }
        });
    }

    async findBySlug(slug: string) {
        const category = await this.prisma.category.findUnique({
            where: { slug },
            include: {
                parent: { select: { name: true, slug: true } },
                children: true,
                products: {
                    take: 10,
                    orderBy: { createdAt: 'desc' }
                }
            }
        });
        if (!category) throw new NotFoundException('Không tìm thấy danh mục');
        return category;
    }

    async updateCategory(cateId: string, data: UpdateCategoryDto, file?: Express.Multer.File) {
        const category = await this.prisma.category.findUnique({ where: { id: cateId } });
        if (!category) throw new NotFoundException('Danh mục không tồn tại');

        const updateData: any = { ...data };

        if (data.parentId === cateId) {
            throw new BadRequestException('Danh mục không thể làm cha của chính nó');
        }

        if (data.name) {
            const newSlug = slugify(data.name, { lower: true, strict: true });
            const duplicate = await this.prisma.category.findFirst({
                where: { slug: newSlug, NOT: { id: cateId } }
            });
            if (duplicate) throw new ConflictException('Tên danh mục đã tồn tại');
            updateData.slug = newSlug;
        }

        if (file) {
            const uploadResult = await this.cloudinaryService.uploadFile(file);
            updateData.iconUrl = uploadResult.secure_url;
        }

        return this.prisma.category.update({
            where: { id: cateId },
            data: updateData,
        });
    }

    async removeCategory(cateId: string) {
        const category = await this.prisma.category.findUnique({
            where: { id: cateId },
            include: { _count: { select: { children: true } } }
        });

        if (!category) throw new NotFoundException('Danh mục không tồn tại');

        if (category._count.children > 0) {
            throw new BadRequestException(`Không thể xóa vì danh mục này đang có ${category._count.children} danh mục con.`);
        }

        return this.prisma.category.delete({ where: { id: cateId } });
    }
}