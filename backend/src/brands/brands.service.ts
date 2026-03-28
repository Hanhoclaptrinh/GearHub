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
    private cloudinaryService: CloudinaryService
  ) { }

  async createBrand(data: CreateBrandDto, file?: Express.Multer.File) {
    const slug = slugify(data.name, { lower: true, strict: true });

    const existingSlug = await this.prisma.brand.findUnique({ where: { slug } });
    if (existingSlug) throw new ConflictException('Thương hiệu này đã tồn tại');

    let finalLogoUrl = data.logoUrl || null;

    if (file) {
      const uploadResult = await this.cloudinaryService.uploadFile(file);
      finalLogoUrl = uploadResult.secure_url;
    }

    return this.prisma.brand.create({
      data: { ...data, slug, logoUrl: finalLogoUrl },
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

    const updateData: any = { ...data };

    if (data.name) {
      const newSlug = slugify(data.name, { lower: true, strict: true });
      const dup = await this.prisma.brand.findFirst({
        where: { slug: newSlug, NOT: { id } }
      });
      if (dup) throw new ConflictException('Tên thương hiệu đã bị trùng');
      updateData.slug = newSlug;
    }

    if (file) {
      const uploadResult = await this.cloudinaryService.uploadFile(file);
      updateData.logoUrl = uploadResult.secure_url;
    }

    return this.prisma.brand.update({ where: { id }, data: updateData });
  }

  async removeBrand(id: string) {
    const brand = await this.prisma.brand.findUnique({ where: { id } });
    if (!brand) throw new NotFoundException('Thương hiệu không tồn tại');
    return this.prisma.brand.delete({ where: { id } });
  }
}
