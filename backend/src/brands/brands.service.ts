import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';
import { PrismaService } from 'src/prisma/prisma.service';
import slugify from 'slugify';
import { CreateBrandDto } from './dto/create-brand.dto';
import { UpdateBrandDto } from './dto/update-brand.dto';

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
      data: { name: data.name, slug: slug, logoUrl: finalLogoUrl },
    });
  }

  async getAllBrands() {
    return this.prisma.brand.findMany({
      select: {
        id: true,
        name: true,
        slug: true,
        logoUrl: true,
        _count: { select: { products: true } }
      },
      orderBy: { name: 'asc' }
    });
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
        // xoa anh cu
        if (brand.logoUrl) {
          const publicId = brand.logoUrl.split('/').pop()?.split('.')[0];
          if (publicId) await this.cloudinaryService.deleteFile(`gearhub/media/${publicId}`);
        }

        // upload anh moi
        const uploadResult = await this.cloudinaryService.uploadFile(file);
        updateData.logoUrl = uploadResult.secure_url;
      } catch (error) {
        console.log(error);
        throw new BadRequestException('Không thể tải logo mới lên Cloud');
      }
    }

    return this.prisma.brand.update({ where: { id }, data: updateData });
  }

  async removeBrand(id: string) {
    const brand = await this.prisma.brand.findUnique({
      where: { id },
      include: { _count: { select: { products: true } } }
    });
    if (!brand) throw new NotFoundException('Thương hiệu không tồn tại');

    if (brand._count.products > 0) {
      throw new BadRequestException(`Không thể xóa thương hiệu này vì đang có ${brand._count.products} sản phẩm`);
    }

    if (brand.logoUrl) {
      const publicId = brand.logoUrl.split('/').pop()?.split('.')[0];
      if (publicId) await this.cloudinaryService.deleteFile(`gearhub/media/${publicId}`);
    }

    return this.prisma.brand.delete({ where: { id } });
  }
}
