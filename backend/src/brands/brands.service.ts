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

  async createBrand(data: CreateBrandDto, file?: Express.Multer.File) {
    const slug = slugify(data.name, { lower: true, strict: true });

    const existingSlug = await this.prisma.brand.findUnique({ where: { slug } });
    if (existingSlug) throw new ConflictException('Thương hiệu này đã tồn tại');

    let finalLogoUrl: string | null = null;

    if (file) {
      try {
        const uploadResult = await this.cloudinaryService.uploadFile(file);

        if (uploadResult && uploadResult.secure_url) {
          finalLogoUrl = uploadResult.secure_url;
        }
      } catch (error) {
        throw new BadRequestException('Không thể tải logo lên Cloud');
      }
    }

    return this.prisma.brand.create({
      data: {
        name: data.name,
        slug: slug,
        logoUrl: finalLogoUrl,
        quote: data.quote,
        philosophy: data.philosophy,
      },
    });
  }

  async getAllBrands() {
    return this.prisma.brand.findMany({
      select: {
        id: true,
        name: true,
        slug: true,
        logoUrl: true,
        isActive: true,
        quote: true,
        philosophy: true,
        _count: { select: { products: true } }
      },
      orderBy: { name: 'asc' }
    });
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
        quote: true,
        philosophy: true,
      }
    });
  }

  @Cron(CronExpression.EVERY_6_HOURS) /// auto chay job moi 6 tieng
  async updateBrandScores() {
    /// lay tat ca brand va data thong ke tu prod
    const brands = await this.prisma.brand.findMany({
      include: {
        products: {
          select: {
            soldCount: true,
            viewsCount: true,
            averageRating: true
          }
        }
      }
    });

    for (const b of brands) {
      /// chi so tong hop
      const tSold = b.products.reduce((s, p) => s += p.soldCount, 0); /// tong sp ban duoc theo brand
      const tViews = b.products.reduce((s, p) => s += p.viewsCount, 0); /// tong luot xem sp theo brand
      const aRating = b.products.length > 0 ?
        b.products.reduce((s, p) => s += p.averageRating, 0) / b.products.length :
        0; /// trung binh diem danh gia sp theo brand

      const sc = (tSold * 5) + (aRating * 10) + (tViews * 0.1);

      await this.prisma.brand.update({
        where: { id: b.id },
        data: {
          score: sc,
          lastScoredAt: new Date()
        }
      });
    }
  }

  async updateBrand(id: string, data: UpdateBrandDto, file?: Express.Multer.File) {
    const brand = await this.prisma.brand.findUnique({ where: { id } });
    if (!brand) throw new NotFoundException('Thương hiệu không tồn tại');

    const { logoUrl, ...restData } = data;
    const updateData: any = { ...restData };

    if (data.name) {
      const newSlug = slugify(data.name, { lower: true, strict: true });
      const dup = await this.prisma.brand.findFirst({
        where: { slug: newSlug, NOT: { id } }
      });
      if (dup) throw new ConflictException('Tên thương hiệu đã bị trùng');
      updateData.slug = newSlug;
    }

    if (file) {
      try {
        /// xoa anh cu
        if (brand.logoUrl) {
          const publicId = brand.logoUrl.split('/').pop()?.split('.')[0];
          if (publicId) await this.cloudinaryService.deleteFile(`gearhub/media/${publicId}`);
        }

        /// upload anh moi
        const uploadResult = await this.cloudinaryService.uploadFile(file);
        updateData.logoUrl = uploadResult.secure_url;
      } catch (error) {
        console.log(error);
        throw new BadRequestException('Không thể tải logo mới lên Cloud');
      }
    }

    return this.prisma.brand.update({ where: { id }, data: updateData });
  }

  async toggleStatus(id: string) {
    const brand = await this.prisma.brand.findUnique({ where: { id } });
    if (!brand) throw new NotFoundException('Thương hiệu không tồn tại');

    const updated = await this.prisma.brand.update({
      where: { id },
      data: { isActive: !brand.isActive }
    });

    return {
      message: `Đã ${updated.isActive ? 'kích hoạt' : 'tạm ngưng'} thương hiệu '${brand.name}'`,
      isActive: updated.isActive
    };
  }

  async removeBrand(id: string) {
    const brand = await this.prisma.brand.findUnique({
      where: { id },
      include: { _count: { select: { products: true } } }
    });
    if (!brand) throw new NotFoundException('Thương hiệu không tồn tại');

    /// soft delete neu co san pham
    if (brand._count.products > 0) {
      await this.prisma.brand.update({
        where: { id },
        data: { isActive: false }
      });
      return { message: `Đã ngưng kinh doanh thương hiệu '${brand.name}' do đang có ${brand._count.products} sản phẩm` };
    }

    /// hard delete neu khong co san pham
    if (brand.logoUrl) {
      const publicId = brand.logoUrl.split('/').pop()?.split('.')[0];
      if (publicId) await this.cloudinaryService.deleteFile(`gearhub/media/${publicId}`);
    }

    await this.prisma.brand.delete({ where: { id } });
    return { message: 'Đã xóa vĩnh viễn thương hiệu thành công' };
  }
}
