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

  private readonly brandSelect = {
    id: true,
    name: true,
    slug: true,
    logoUrl: true,
    bannerUrl: true,
    isActive: true,
    isFeatured: true,
    score: true,
    createdAt: true,
    updatedAt: true,
    quote: true,
    philosophy: true,
    _count: { select: { products: true } }
  };

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
        select: this.brandSelect,
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
        select: this.brandSelect,
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

  // hiển thị top 5 thương hiệu dựa trên số điểm
  async getTopBrands(limit: number = 5) {
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
        _count: { select: { products: true } }
      }
    });
  }

  // auto chạy cron job mỗi 6 tiếng
  // thực hiện cập nhật điểm số của brand dựa trên doanh thu 30 ngày qua và đánh giá trung bình bayes
  @Cron(CronExpression.EVERY_6_HOURS)
  async updateBrandScores() {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    // lấy tất cả order item trong 30 ngày qua để tính doanh số cho từng brand
    const orderItems = await this.prisma.orderItem.findMany({
      where: {
        order: {
          createdAt: { gte: thirtyDaysAgo },
          status: { notIn: ['CANCELLED', 'FAILED', 'RETURNED'] } // chỉ lấy các đơn hàng ok
        },
        productVariant: {
          product: {
            brandId: { not: null }
          }
        }
      },
      select: {
        quantity: true,
        productVariant: {
          select: {
            product: {
              select: {
                brandId: true
              }
            }
          }
        }
      }
    });

    const brandSales = new Map<string, number>();
    for (const item of orderItems) {
      const bId = item.productVariant?.product?.brandId;
      if (bId) {
        brandSales.set(bId, (brandSales.get(bId) || 0) + item.quantity);
      }
    }

    // lấy tất cả review để tính điểm trung bình bayes
    const reviews = await this.prisma.review.findMany({
      where: {
        product: {
          brandId: { not: null },
          isActive: true
        }
      },
      select: {
        rating: true,
        product: {
          select: {
            brandId: true
          }
        }
      }
    });

    const brandReviews = new Map<string, { totalStars: number; count: number }>();
    for (const r of reviews) {
      const bId = r.product?.brandId;
      if (bId) {
        const stats = brandReviews.get(bId) || { totalStars: 0, count: 0 };
        stats.totalStars += r.rating;
        stats.count += 1;
        brandReviews.set(bId, stats);
      }
    }

    // view count
    const products = await this.prisma.product.findMany({
      where: {
        brandId: { not: null },
        isActive: true
      },
      select: {
        viewsCount: true,
        brandId: true
      }
    });

    const brandViews = new Map<string, number>();
    for (const p of products) {
      if (p.brandId) {
        brandViews.set(p.brandId, (brandViews.get(p.brandId) || 0) + p.viewsCount);
      }
    }

    // lấy tất cả brands
    const brands = await this.prisma.brand.findMany({
      select: { id: true }
    });

    // cập nhật score cho từng brand
    const updatePromises = brands.map((b) => {
      const sales = brandSales.get(b.id) || 0;
      const views = brandViews.get(b.id) || 0;
      const reviewStats = brandReviews.get(b.id) || { totalStars: 0, count: 0 };

      // làm mượt bayes
      // kéo điểm về 4.0 khi chưa có hoặc ít reviews
      const bayesianRating = (reviewStats.totalStars + 20) / (reviewStats.count + 5);

      // hệ số nhân
      const score = (sales + (views * 0.01)) * bayesianRating;

      return this.prisma.brand.update({
        where: { id: b.id },
        data: {
          score,
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

  async toggleFeatured(id: string) {
    const brand = await this.prisma.brand.findUnique({ where: { id } });
    if (!brand) throw new NotFoundException('Thương hiệu không tồn tại');

    const updated = await this.prisma.brand.update({
      where: { id },
      data: { isFeatured: !brand.isFeatured },
      select: this.brandSelect
    });

    return {
      message: updated.isFeatured
        ? `Đã đánh dấu '${updated.name}' là thương hiệu nổi bật`
        : `Đã gỡ '${updated.name}' khỏi nhóm nổi bật`,
      brand: updated
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
