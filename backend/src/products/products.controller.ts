import { BadRequestException, Body, Controller, Delete, Get, Param, Patch, Post, Query, UploadedFiles, UseGuards, UseInterceptors } from '@nestjs/common';
import { ProductsService } from './products.service';
import { JwtAuthGuard } from 'src/auth/guards/jwt-auth.guard';
import { RolesGuard } from 'src/auth/guards/roles.guard';
import { Roles } from 'src/common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { FilesInterceptor } from '@nestjs/platform-express';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { CreateVariantDto } from './dto/create-variant.dto';
import { UpdateVariantDto } from './dto/update-variant.dto';

@Controller('products')
export class ProductsController {
    constructor(private productsService: ProductsService) { }

    @Get()
    async getAllProducts(
        @Query('page') page?: string,
        @Query('limit') limit?: string,
        @Query('search') search?: string,
        @Query('categoryId') categoryId?: string,
        @Query('brandId') brandId?: string,
        @Query('minPrice') minPrice?: string,
        @Query('maxPrice') maxPrice?: string,
        @Query('isAdmin') isAdmin?: string,
    ) {
        return this.productsService.getAllProducts({
            page: page ? Number(page) : undefined,
            limit: limit ? Number(limit) : undefined,
            search,
            categoryId,
            brandId,
            minPrice: minPrice ? Number(minPrice) : undefined,
            maxPrice: maxPrice ? Number(maxPrice) : undefined,
            isAdmin: isAdmin === 'true'
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
    async getRelatedProducts(@Param('id') id: string) {
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

    @Patch(':productId/assets/:assetId/primary')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async setPrimaryAsset(
        @Param('productId') productId: string,
        @Param('assetId') assetId: string,
    ) {
        return this.productsService.setPrimaryAsset(productId, assetId);
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
        return this.productsService.removeProduct(id);
    }

    @Delete(':id')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async toggleStatus(@Param('id') id: string) {
        return this.productsService.toggleStatus(id);
    }

    @Patch(':id/restore')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async restore(@Param('id') id: string) {
        return this.productsService.restore(id);
    }

    @Post(':id/variant')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async addVariant(@Param('id') id: string, @Body() data: CreateVariantDto) {
        return this.productsService.addVariant(id, data);
    }

    @Patch('variant/:variantId')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async updateVariant(@Param('variantId') variantId: string, @Body() data: UpdateVariantDto) {
        return this.productsService.updateVariant(variantId, data);
    }

    @Delete('variant/:variantId')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async removeVariant(@Param('variantId') variantId: string) {
        return this.productsService.removeVariant(variantId);
    }

    @Patch('variants/:variantId/destock')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async decreaseStock(@Param('variantId') variantId: string, @Body('quantity') quantity: number) {
        return this.productsService.decreaseStock(variantId, quantity);
    }

    @Patch('variants/:variantId/instock')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async increaseStock(@Param('variantId') variantId: string, @Body('quantity') quantity: number) {
        return this.productsService.increaseStock(variantId, quantity);
    }
}
