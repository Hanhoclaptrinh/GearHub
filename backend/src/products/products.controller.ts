import { BadRequestException, Body, Controller, Delete, Get, Param, Patch, Post, Query, UploadedFiles, UseGuards, UseInterceptors } from '@nestjs/common';
import { ProductsService } from './products.service';
import { JwtAuthGuard } from 'src/auth/guards/jwt-auth.guard';
import { RolesGuard } from 'src/auth/guards/roles.guard';
import { Roles } from 'src/common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { FilesInterceptor } from '@nestjs/platform-express';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';

@Controller('products')
export class ProductsController {
    constructor(private productsService: ProductsService) { }

    @Get()
    async getAllProducts(
        @Query('page') page?: number,
        @Query('limit') limit?: number,
        @Query('search') search?: string,
        @Query('categoryId') categoryId?: string,
        @Query('brandId') brandId?: string,
        @Query('minPrice') minPrice?: number,
        @Query('maxPrice') maxPrice?: number,
    ) {
        return this.productsService.getAllProducts({
            page,
            limit,
            search,
            categoryId,
            brandId,
            minPrice,
            maxPrice,
        });
    }

    @Get('featured')
    async getFeaturedProducts() {
        return this.productsService.getFeaturedProducts();
    }

    @Get(':slug')
    async getProductBySlug(@Param('slug') slug: string) {
        return this.productsService.getProductBySlug(slug);
    }

    @Get(':id/related')
    async getRelatedProducts(@Param('id') id: string,) {
        return this.productsService.getRelatedProducts(id);
    }

    @Post()
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    @UseInterceptors(FilesInterceptor('files', 10))
    async createProduct(@Body() data: CreateProductDto, @UploadedFiles() files: Express.Multer.File[]) {
        return this.productsService.createProduct(data, files);
    }

    @Post(':id/assets')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    @UseInterceptors(FilesInterceptor('files', 10))
    async addAssets(
        @Param('id') id: string,
        @UploadedFiles() files: Express.Multer.File[]
    ) {
        if (!files || files.length === 0) {
            throw new BadRequestException('Vui lòng chọn ít nhất một file để upload');
        }
        return this.productsService.addAssets(id, files);
    }

    @Delete('assets/:assetId')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async removeAsset(@Param('assetId') assetId: string) {
        return this.productsService.removeAsset(assetId);
    }

    @Patch(':id')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    @UseInterceptors(FilesInterceptor('files', 10))
    async updateProduct(@Param('id') id: string, @Body() data: UpdateProductDto, @UploadedFiles() files: Express.Multer.File[]) {
        return this.productsService.updateProduct(id, data, files);
    }

    @Delete(':id/hard-delete')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async removeProduct(@Param('id') id: string) {
        await this.productsService.removeProduct(id);
        return {
            statusCode: 200,
            message: 'Xóa sản phẩm thành công',
        };
    }

    @Delete(':id')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async inActiveProduct(@Param('id') id: string) {
        return this.productsService.inActiveProduct(id);
    }

    @Patch(':id/restore')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async restore(@Param('id') id: string) {
        return this.productsService.restore(id);
    }
}
