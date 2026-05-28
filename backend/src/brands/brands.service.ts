import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';
import { PrismaService } from 'src/prisma/prisma.service';
import slugify from 'slugify';
import { CreateBrandDto } from './dto/create-brand.dto';
import { UpdateBrandDto } from './dto/update-brand.dto';
import { Cron, CronExpression } from '@nestjs/schedule';

@Injectable()
export class BrandsService {
  constructor(
    private prisma: PrismaService,
    private cloudinaryService: CloudinaryService
  ) { }

  // tạo mới một brand
  async createBrand(data: CreateBrandDto, logoFile?: Express.Multer.File, bannerFile?: Express.Multer.File) {
    // slug dùng cho deeplink hoặc seo
    // được tạo từ tên viết thường, phân cách bởi '-'
    const slug = slugify(data.name, { lower: true, strict: true });

    const existingSlug = await this.prisma.brand.findUnique({ where: { slug } });
    if (existingSlug) throw new ConflictException('Thương hiệu này đã tồn tại');

    let finalLogoUrl: string | null = null;
    let finalBannerUrl: string | null = null;

    // upload logo brand lên cld
    if (logoFile) {
      try {
        const uploadResult = await this.cloudinaryService.uploadFile(logoFile);

        if (uploadResult && uploadResult.secure_url) {
          finalLogoUrl = uploadResult.secure_url;
        }
      } catch (error) {
        throw new BadRequestException('Không thể tải logo lên Cloud');
      }
    }

    // upload banner brand lên cld
    if (bannerFile) {
      try {
        const uploadResult = await this.cloudinaryService.uploadFile(bannerFile);

        if (uploadResult && uploadResult.secure_url) {
          finalBannerUrl = uploadResult.secure_url;
        }
      } catch (error) {
        throw new BadRequestException('Không thể tải banner lên Cloud');
      }
    }

    return this.prisma.brand.create({
      data: {
        name: data.name,
        slug: slug,
        logoUrl: finalLogoUrl,
        bannerUrl: finalBannerUrl,
        quote: data.quote,
        philosophy: data.philosophy,
      },
    });
  }

  /**
   * lấy danh sách thương hiệu
   * 
   * chế độ tương thích ngược (backward-compatible): nếu cả page và limit đều không được truyền vào 
   * hệ thống sẽ trả về một mảng phẳng các thương hiệu brand[] 
   * tránh gây lỗi cho các tính năng khác trên hệ thống (dropdowns, bộ lọc sản phẩm...)
   */
  async getAllBrands(page?: number, limit?: number, search?: string) {
    const where: any = {};

    // áp dụng bộ lọc tìm kiếm theo tên thương hiệu nếu có từ khóa search
    if (search) {
      where.name = {
        contains: search,
      };
    }

    // không có phân trang thì trả về toàn bộ mảng phẳng tránh crash
    if (page === undefined && limit === undefined) {
      return this.prisma.brand.findMany({
        where,
        select: {
          id: true,
          name: true,
          slug: true,
          logoUrl: true,
          bannerUrl: true,
          isActive: true,
          quote: true,
          philosophy: true,
          _count: { select: { products: true } }
        },
        orderBy: { name: 'asc' }
      });
    }

    // có phân trang
    const pageNum = page || 1;
    const limitNum = limit || 10;
    const skip = (pageNum - 1) * limitNum;

    const [total, data] = await Promise.all([
      this.prisma.brand.count({ where }),
      this.prisma.brand.findMany({
        where,
        select: {
          id: true,
          name: true,
          slug: true,
          logoUrl: true,
          bannerUrl: true,
          isActive: true,
          quote: true,
          philosophy: true,
          _count: { select: { products: true } }
        },
        orderBy: { name: 'asc' },
        skip,
        take: limitNum,
      }),
    ]);

    return {
      data,
      meta: {
        total,
        page: pageNum,
        limit: limitNum,
        totalPages: Math.ceil(total / limitNum),
      },
    };
  }

  async getTopBrands(limit: number = 8) {
    await this.updateBrandScores();
    return this.prisma.brand.findMany({
      where: {
        isActive: true,
      },
      orderBy: [
        { isFeatured: 'desc' },
        { score: 'desc' }
      ],
      take: limit,
      select: {
        id: true,
        name: true,
        slug: true,
        logoUrl: true,
        bannerUrl: true,
        quote: true,
        philosophy: true,
      }
    });
  }

  // auto chạy cron job mỗi 6 tiếng
  // thực hiện cập nhật điểm số của brand dựa trên tổng bán, tổng view & trung bình rate
  // hiển thị cho top brands
  @Cron(CronExpression.EVERY_6_HOURS)
  async updateBrandScores() {
    // nhóm theo brand id để thực hiện tính toán điểm dưới db
    const aggregations = await this.prisma.product.groupBy({
      by: ['brandId'],
      _sum: {
        soldCount: true,
        viewsCount: true,
      },
      _avg: {
        averageRating: true,
      },
      where: {
        brandId: { not: null },
      },
    });

    // map data
    const statsMap = new Map<string, { totalSold: number; totalViews: number; avgRating: number }>();
    for (const agg of aggregations) {
      if (agg.brandId) {
        statsMap.set(agg.brandId, {
          totalSold: agg._sum.soldCount || 0,
          totalViews: agg._sum.viewsCount || 0,
          avgRating: agg._avg.averageRating || 0,
        });
      }
    }

    // lấy tất cả brand để tính toán điểm - kể cả brand chưa có sản phẩm nào
    const brands = await this.prisma.brand.findMany({
      select: { id: true }
    });

    // update score cho từng brand
    const updatePromises = brands.map((b) => {
      const stats = statsMap.get(b.id) || { totalSold: 0, totalViews: 0, avgRating: 0 };
      const sc = (stats.totalSold * 5) + (stats.avgRating * 10) + (stats.totalViews * 0.1);

      return this.prisma.brand.update({
        where: { id: b.id },
        data: {
          score: sc,
          lastScoredAt: new Date()
        }
      });
    });

    await Promise.all(updatePromises);
  }

  // cập nhật thông tin brand
  async updateBrand(id: string, data: UpdateBrandDto, logoFile?: Express.Multer.File, bannerFile?: Express.Multer.File) {
    const brand = await this.prisma.brand.findUnique({ where: { id } });
    if (!brand) throw new NotFoundException('Thương hiệu không tồn tại');

    const { logoUrl, bannerUrl, ...restData } = data;
    const updateData: any = { ...restData };

    if (data.name) {
      const newSlug = slugify(data.name, { lower: true, strict: true });
      const dup = await this.prisma.brand.findFirst({
        where: { slug: newSlug, NOT: { id } }
      });
      if (dup) throw new ConflictException('Tên thương hiệu đã bị trùng');
      updateData.slug = newSlug;
    }

    if (logoFile) {
      try {
        // xóa ảnh cũ ở cld
        if (brand.logoUrl) {
          try {
            const publicId = brand.logoUrl.split('/').pop()?.split('.')[0];
            if (publicId) await this.cloudinaryService.deleteFile(`gearhub/media/${publicId}`);
          } catch (cloudinaryError) {
            console.error('Không thể xóa logo cũ trên Cloudinary:', cloudinaryError);
          }
        }

        // upload ảnh mới
        const uploadResult = await this.cloudinaryService.uploadFile(logoFile);
        updateData.logoUrl = uploadResult.secure_url;
      } catch (error) {
        console.log(error);
        throw new BadRequestException('Không thể tải logo mới lên Cloud');
      }
    }

    if (bannerFile) {
      try {
        // xóa ảnh cũ ở cld
        if (brand.bannerUrl) {
          try {
            const publicId = brand.bannerUrl.split('/').pop()?.split('.')[0];
            if (publicId) await this.cloudinaryService.deleteFile(`gearhub/media/${publicId}`);
          } catch (cloudinaryError) {
            console.error('Không thể xóa banner cũ trên Cloudinary:', cloudinaryError);
          }
        }

        // upload ảnh mới
        const uploadResult = await this.cloudinaryService.uploadFile(bannerFile);
        updateData.bannerUrl = uploadResult.secure_url;
      } catch (error) {
        console.log(error);
        throw new BadRequestException('Không thể tải banner mới lên Cloud');
      }
    }

    return this.prisma.brand.update({ where: { id }, data: updateData });
  }

  async toggleStatus(id: string) {
    const brand = await this.prisma.brand.findUnique({ where: { id } });
    if (!brand) throw new NotFoundException('Thương hiệu không tồn tại');

    const nextActiveState = !brand.isActive;

    // nếu brand ngưng hoạt động thì ngưng toàn sản phẩm liên quan
    if (!nextActiveState) {
      await this.prisma.$transaction([
        this.prisma.brand.update({
          where: { id },
          data: { isActive: false }
        }),
        this.prisma.product.updateMany({
          where: { brandId: id },
          data: { isActive: false }
        })
      ]);
      return {
        message: `Đã tạm ngưng thương hiệu '${brand.name}' và tự động ẩn các sản phẩm liên quan`,
        isActive: false
      };
    }

    const updated = await this.prisma.brand.update({
      where: { id },
      data: { isActive: true }
    });

    return {
      message: `Đã kích hoạt thương hiệu '${brand.name}'`,
      isActive: true
    };
  }

  async removeBrand(id: string) {
    const brand = await this.prisma.brand.findUnique({
      where: { id },
      include: { _count: { select: { products: true } } }
    });
    if (!brand) throw new NotFoundException('Thương hiệu không tồn tại');

    // soft delete nếu có sản phẩm: tạm ngưng kinh doanh brand và ẩn toàn bộ sản phẩm
    if (brand._count.products > 0) {
      await this.prisma.$transaction([
        this.prisma.brand.update({
          where: { id },
          data: { isActive: false }
        }),
        this.prisma.product.updateMany({
          where: { brandId: id },
          data: { isActive: false }
        })
      ]);
      return { message: `Đã ngưng kinh doanh thương hiệu '${brand.name}' và tạm ẩn ${brand._count.products} sản phẩm liên kết` };
    }

    // hard delete nếu không có sản phẩm
    if (brand.logoUrl) {
      try {
        const publicId = brand.logoUrl.split('/').pop()?.split('.')[0];
        if (publicId) await this.cloudinaryService.deleteFile(`gearhub/media/${publicId}`);
      } catch (cloudinaryError) {
        console.error('Không thể xóa logo cũ trên Cloudinary:', cloudinaryError);
      }
    }
    if (brand.bannerUrl) {
      try {
        const publicId = brand.bannerUrl.split('/').pop()?.split('.')[0];
        if (publicId) await this.cloudinaryService.deleteFile(`gearhub/media/${publicId}`);
      } catch (cloudinaryError) {
        console.error('Không thể xóa banner cũ trên Cloudinary:', cloudinaryError);
      }
    }

    await this.prisma.brand.delete({ where: { id } });
    return { message: 'Đã xóa vĩnh viễn thương hiệu thành công' };
  }
}
