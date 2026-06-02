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

    /**
     * tạo danh mục mới
     * hỗ trợ tự động tạo slug từ tên danh mục, kiểm tra tính hợp lệ của danh mục cha,
     * và upload icon đại diện lên cloudinary
     */
    async createCategory(data: CreateCategoryDto, file?: Express.Multer.File) {
        const slug = slugify(data.name, { strict: true, lower: true });

        const existingSlug = await this.prisma.category.findUnique({ where: { slug } });
        if (existingSlug) throw new ConflictException('Danh mục này đã tồn tại');

        // kiểm tra danh mục cha tồn tại trước khi gán cha
        if (data.parentId) {
            const parent = await this.prisma.category.findUnique({ where: { id: data.parentId } });
            if (!parent) throw new NotFoundException('Danh mục cha không tồn tại');
        }

        // upload ảnh icon đại diện lên cloudinary
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

    async getAllCategories() {
        return this.prisma.category.findMany({
            where: { parentId: null },
            include: {
                _count: { select: { products: true, children: true } },
                children: {
                    select: {
                        id: true,
                        name: true,
                        slug: true,
                        description: true,
                        parentId: true,
                        iconUrl: true,
                        createdAt: true,
                        updatedAt: true,
                        _count: { select: { products: true } }
                    }
                }
            },
            orderBy: { name: 'asc' }
        });
    }

    // lấy cây danh mục theo từng cấp
    async getCategoryTree() {
        return this.prisma.category.findMany({
            where: { parentId: null }, // chỉ lấy danh mục cha
            include: {
                children: {
                    include: {
                        _count: {
                            select: { products: true } // đếm số lượng sp trong mỗi subcate
                        },
                    },
                },
                _count: {
                    select: { products: true } // đếm tổng sp cate cha
                },
            },
            orderBy: {
                name: 'asc'
            }
        })
    }

    async getCategoryBySlug(slug: string) {
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

    // cập nhật thông tin danh mục
    async updateCategory(id: string, data: UpdateCategoryDto, file?: Express.Multer.File) {
        const category = await this.prisma.category.findUnique({ where: { id } });
        if (!category) throw new NotFoundException('Danh mục không tồn tại');

        const { iconUrl, ...restData } = data;
        const updateData: any = { ...data };

        if (data.parentId === id) {
            throw new BadRequestException('Danh mục không thể làm cha của chính nó');
        }

        // nếu cập nhật name - check slug
        if (data.name) {
            const newSlug = slugify(data.name, { lower: true, strict: true });
            const duplicate = await this.prisma.category.findFirst({
                where: { slug: newSlug, NOT: { id } }
            });
            if (duplicate) throw new ConflictException('Tên danh mục đã tồn tại');
            updateData.slug = newSlug;
        }

        // thực hiện xóa file cũ và upload file mới lên cld
        if (file) {
            if (category.iconUrl) {
                try {
                    const publicId = category.iconUrl.split('/').pop()?.split('.')[0];
                    if (publicId) await this.cloudinaryService.deleteFile(`gearhub/media/${publicId}`);
                } catch (cloudinaryError) {
                    console.error('Không thể xóa icon cũ trên Cloudinary:', cloudinaryError);
                }
            }

            const uploadResult = await this.cloudinaryService.uploadFile(file);
            updateData.iconUrl = uploadResult.secure_url;
        }

        return this.prisma.category.update({
            where: { id },
            data: updateData,
        });
    }

    async removeCategory(id: string) {
        const category = await this.prisma.category.findUnique({
            where: { id },
            include: { _count: { select: { children: true, products: true } } }
        });

        if (!category) throw new NotFoundException('Danh mục không tồn tại');

        if (category._count.children > 0) {
            throw new BadRequestException(`Không thể xóa vì danh mục này đang có ${category._count.children} danh mục con`);
        }

        if (category._count.products > 0) {
            throw new BadRequestException(`Không thể xóa vì danh mục này đang có ${category._count.products} sản phẩm`);
        }

        if (category.iconUrl) {
            try {
                const publicId = category.iconUrl.split('/').pop()?.split('.')[0];
                if (publicId) await this.cloudinaryService.deleteFile(`gearhub/media/${publicId}`);
            } catch (cloudinaryError) {
                console.error('Không thể xóa icon cũ trên Cloudinary:', cloudinaryError);
            }
        }

        return this.prisma.category.delete({ where: { id } });
    }

    /**
     * lấy danh sách các danh mục bán chạy nhất dựa trên tổng số lượng sản phẩm đã bán
     * hiển thị cho client
     */
    async getTopCategories(limit = 4) {
        // gom nhóm sản phẩm theo categoryId và tính tổng soldCount của từng nhóm
        const grouped = await this.prisma.product.groupBy({
            by: ['categoryId'],
            where: {
                isActive: true, // chỉ tính các sản phẩm đang hoạt động
                categoryId: { not: null } // bỏ qua các sản phẩm chưa phân loại danh mục
            },
            _sum: { soldCount: true }, // tính tổng soldCount
            orderBy: {
                _sum: { soldCount: 'desc' }
            },
            take: limit
        });

        if (grouped.length === 0) return [];

        // trích xuất mảng cateid từ kết quả gom nhóm trên
        const categoryIds = grouped
            .map(g => g.categoryId)
            .filter((id): id is string => id !== null);

        // truy vấn thông tin theo cateid thu được
        const categories = await this.prisma.category.findMany({
            where: { id: { in: categoryIds } },
            select: {
                id: true,
                name: true,
                slug: true,
                iconUrl: true,
                description: true,
            },
        });

        // map lưu trữ thông tin - tối ưu tốc độ tìm kiếm
        const map = new Map(categories.map(c => [c.id, c]));

        // ánh xạ
        return grouped.map(g => {
            if (!g.categoryId) return null;

            const c = map.get(g.categoryId);
            if (!c) return null;

            return {
                id: c.id,
                name: c.name,
                slug: c.slug,
                iconUrl: c.iconUrl,
                description: c.description,
                totalSold: g._sum.soldCount ?? 0,
            };
        }).filter(Boolean);
    }

}
