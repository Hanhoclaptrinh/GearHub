import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';
import { PrismaService } from 'src/prisma/prisma.service';
import slugify from 'slugify';
import { CreateBrandDto } from './dto/create-brand.dto';
import { UpdateBrandDto } from './dto/update-brand.dto';

@Injectable()
export class BrandsService {
  constructor(
    private prisma: PrismaService,
    private cloudinary: CloudinaryService
  ) { }

  async createBrand(data: CreateBrandDto, file?: Express.Multer.File) {
    const slug = slugify(data.name, { lower: true, strict: true });

    const existing = await this.prisma.brand.findUnique({ where: { slug } });
    if (existing) throw new ConflictException('Thương hiệu này đã tồn tại');

    let finalLogoUrl = data.logoUrl || null;

    if (file) {
      const uploadResult = await this.cloudinary.uploadFile(file);
      finalLogoUrl = uploadResult.secure_url;
    }

    return this.prisma.brand.create({
      data: { ...data, slug, logoUrl: finalLogoUrl },
    });
  }

  async findAllBrands() {
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

  async updateBrand(brandId: string, data: UpdateBrandDto, file?: Express.Multer.File) {
    const brand = await this.prisma.brand.findUnique({ where: { id: brandId } });
    if (!brand) throw new NotFoundException('Thương hiệu không tồn tại');

    const updateData: any = { ...data };

    if (data.name) {
      const newSlug = slugify(data.name, { lower: true, strict: true });
      const dup = await this.prisma.brand.findFirst({
        where: { slug: newSlug, NOT: { id: brandId } }
      });
      if (dup) throw new ConflictException('Tên thương hiệu đã bị trùng');
      updateData.slug = newSlug;
    }

    if (file) {
      const uploadResult = await this.cloudinary.uploadFile(file);
      updateData.logoUrl = uploadResult.secure_url;
    }

    return this.prisma.brand.update({ where: { id: brandId }, data: updateData });
  }

  async removeBrand(brandId: string) {
    const brand = await this.prisma.brand.findUnique({ where: { id: brandId } });
    if (!brand) throw new NotFoundException('Thương hiệu không tồn tại');
    return this.prisma.brand.delete({ where: { id: brandId } });
  }
}
