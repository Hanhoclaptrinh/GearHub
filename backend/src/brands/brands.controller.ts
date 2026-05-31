import {
  Controller, Get, Post, Body, Patch, Param, Delete,
  UseGuards, UseInterceptors, UploadedFile, ParseFilePipe,
  MaxFileSizeValidator, FileTypeValidator, Query, UploadedFiles
} from '@nestjs/common';
import { BrandsService } from './brands.service';
import { CreateBrandDto } from './dto/create-brand.dto';
import { UpdateBrandDto } from './dto/update-brand.dto';
import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';
import { RolesGuard } from 'src/common/guards/roles.guard';
import { Roles } from 'src/common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { FileInterceptor, FileFieldsInterceptor } from '@nestjs/platform-express';
import { LogActivity } from 'src/common/decorators/log-activity.decorator';
import { ActivityAction } from 'src/common/constants/activity-log.constants';

@Controller('brands')
export class BrandsController {
  constructor(private brandsService: BrandsService) { }

  @Get()
  async getAllBrands(
    @Query('page') page?: string,
    @Query('limit') limit?: string,
    @Query('search') search?: string,
  ) {
    const pageNum = page ? parseInt(page, 10) : undefined;
    const limitNum = limit ? parseInt(limit, 10) : undefined;
    return this.brandsService.getAllBrands(pageNum, limitNum, search);
  }

  @Get('top-brands')
  async getTopBrands() {
    return this.brandsService.getTopBrands(8);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN, Role.STAFF)
  @UseInterceptors(FileFieldsInterceptor([
    { name: 'logo', maxCount: 1 },
    { name: 'banner', maxCount: 1 }
  ]))
  @LogActivity(ActivityAction.BRAND_CREATED)
  async createBrand(
    @Body() data: CreateBrandDto,
    @UploadedFiles() files?: { logo?: Express.Multer.File[], banner?: Express.Multer.File[] },
  ) {
    const logoFile = files?.logo?.[0];
    const bannerFile = files?.banner?.[0];
    return this.brandsService.createBrand(data, logoFile, bannerFile);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN, Role.STAFF)
  @UseInterceptors(FileFieldsInterceptor([
    { name: 'logo', maxCount: 1 },
    { name: 'banner', maxCount: 1 }
  ]))
  @LogActivity(ActivityAction.BRAND_UPDATED)
  async updateBrand(
    @Param('id') id: string,
    @Body() data: UpdateBrandDto,
    @UploadedFiles() files?: { logo?: Express.Multer.File[], banner?: Express.Multer.File[] },
  ) {
    const logoFile = files?.logo?.[0];
    const bannerFile = files?.banner?.[0];
    return this.brandsService.updateBrand(id, data, logoFile, bannerFile);
  }

  @Patch(':id/toggle')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN, Role.STAFF)
  @LogActivity(ActivityAction.BRAND_TOGGLED)
  async toggleStatus(@Param('id') id: string) {
    return this.brandsService.toggleStatus(id);
  }

  @Patch(':id/featured')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN, Role.STAFF)
  @LogActivity(ActivityAction.BRAND_UPDATED)
  async toggleFeatured(@Param('id') id: string) {
    return this.brandsService.toggleFeatured(id);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN, Role.STAFF)
  @LogActivity(ActivityAction.BRAND_DELETED)
  async removeBrand(@Param('id') id: string) {
    return this.brandsService.removeBrand(id);
  }
}
