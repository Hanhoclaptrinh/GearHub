import {
  Controller, Get, Post, Body, Patch, Param, Delete,
  UseGuards, UseInterceptors, UploadedFile, ParseFilePipe,
  MaxFileSizeValidator, FileTypeValidator
} from '@nestjs/common';
import { BrandsService } from './brands.service';
import { CreateBrandDto } from './dto/create-brand.dto';
import { UpdateBrandDto } from './dto/update-brand.dto';
import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';
import { RolesGuard } from 'src/common/guards/roles.guard';
import { Roles } from 'src/common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { FileInterceptor } from '@nestjs/platform-express';
import { LogActivity } from 'src/common/decorators/log-activity.decorator';
import { ActivityAction } from 'src/common/constants/activity-log.constants';

@Controller('brands')
export class BrandsController {
  constructor(private brandsService: BrandsService) { }

  @Get()
  async getAllBrands() {
    return this.brandsService.getAllBrands();
  }

  @Get('top-brands')
  async getTopBrands() {
    return this.brandsService.getTopBrands(8);
  }

  @Post()
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @UseInterceptors(FileInterceptor('file'))
  @LogActivity(ActivityAction.BRAND_CREATED)
  async createBrand(
    @Body() data: CreateBrandDto,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 1024 * 1024 * 2 }), // logo 2mb limit
        ],
        fileIsRequired: false,
      }),
    ) file?: Express.Multer.File,
  ) {
    return this.brandsService.createBrand(data, file);
  }

  @Patch(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @UseInterceptors(FileInterceptor('file'))
  @LogActivity(ActivityAction.BRAND_UPDATED)
  async updateBrand(
    @Param('id') id: string,
    @Body() data: UpdateBrandDto,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 1024 * 1024 * 2 }),
        ],
        fileIsRequired: false,
      }),
    ) file?: Express.Multer.File,
  ) {
    return this.brandsService.updateBrand(id, data, file);
  }

  @Patch(':id/toggle')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @LogActivity(ActivityAction.BRAND_TOGGLED)
  async toggleStatus(@Param('id') id: string) {
    return this.brandsService.toggleStatus(id);
  }

  @Delete(':id')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @LogActivity(ActivityAction.BRAND_DELETED)
  async removeBrand(@Param('id') id: string) {
    return this.brandsService.removeBrand(id);
  }
}
