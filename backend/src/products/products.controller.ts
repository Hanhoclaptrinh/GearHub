import { BadRequestException, Body, Controller, Delete, Get, Param, Patch, Post, Query, UploadedFiles, UseGuards, UseInterceptors } from '@nestjs/common';
import { ProductsService } from './products.service';
import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';
import { RolesGuard } from 'src/common/guards/roles.guard';
import { Roles } from 'src/common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { FilesInterceptor, AnyFilesInterceptor } from '@nestjs/platform-express';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';
import { CreateVariantDto } from './dto/create-variant.dto';
import { UpdateVariantDto } from './dto/update-variant.dto';
import { LogActivity } from 'src/common/decorators/log-activity.decorator';
import { ActivityAction } from 'src/common/constants/activity-log.constants';

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
        @Query('inventoryStatus') inventoryStatus?: 'all' | 'in_stock' | 'low_stock' | 'out_of_stock',
        @Query('assetType') assetType?: 'all' | 'has_3d' | 'only_2d',
        @Query('showInactiveOnly') showInactiveOnly?: string,
        @Query('showActiveOnly') showActiveOnly?: string,
    ) {
        return this.productsService.getAllProducts({
            page: page ? Number(page) : undefined,
            limit: limit ? Number(limit) : undefined,
            search,
            categoryId,
            brandId,
            minPrice: minPrice ? Number(minPrice) : undefined,
            maxPrice: maxPrice ? Number(maxPrice) : undefined,
            isAdmin: isAdmin === 'true',
            inventoryStatus,
            assetType,
            showInactiveOnly: showInactiveOnly === 'true',
            showActiveOnly: showActiveOnly === 'true',
        });
    }

    @Get('featured')
    async getFeaturedProducts() {
        return this.productsService.getFeaturedProducts();
    }

    @Get('top-rated')
    async getTopRatedProducts() {
        return this.productsService.getTopRatedProducts(5);
    }

    @Get('vault')
    async getVaultProducts() {
        return this.productsService.getVaultProducts();
    }

    @Get(':id')
    async getProduct(@Param('id') id: string) {
        return this.productsService.getProductById(id);
    }

    @Get(':id/related')
    async getRelatedProducts(@Param('id') id: string) {
        return this.productsService.getRelatedProducts(id);
    }

    @Post(':id/view')
    async incrementView(
        @Param('id') id: string,
        @Body('deviceId') deviceId?: string
    ) {
        await this.productsService.incrementView(id, deviceId);
        return { message: 'View incremented' };
    }

    @Post('generate-variants')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async generateVariants(@Body() body: { axes: Record<string, string[]>; productSlug?: string }) {
        if (!body.axes || Object.keys(body.axes).length === 0) {
            throw new BadRequestException('Vui lòng cung cấp ít nhất 1 trục thuộc tính');
        }
        return this.productsService.generateVariantMatrix(body.axes, body.productSlug);
    }

    @Post()
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    @UseInterceptors(AnyFilesInterceptor())
    @LogActivity(ActivityAction.PRODUCT_CREATED)
    async createProduct(@Body() data: CreateProductDto, @UploadedFiles() files: Express.Multer.File[]) {
        return this.productsService.createProduct(data, files);
    }

    @Post(':id/assets')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    @UseInterceptors(FilesInterceptor('files', 10))
    @LogActivity(ActivityAction.ASSET_UPLOADED)
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
    @LogActivity(ActivityAction.ASSET_DELETED)
    async removeAsset(@Param('assetId') assetId: string) {
        return this.productsService.removeAsset(assetId);
    }

    @Patch(':productId/assets/:assetId/primary')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    @LogActivity(ActivityAction.ASSET_SET_PRIMARY)
    async setPrimaryAsset(
        @Param('productId') productId: string,
        @Param('assetId') assetId: string,
    ) {
        return this.productsService.setPrimaryAsset(productId, assetId);
    }

    @Patch(':id')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    @UseInterceptors(AnyFilesInterceptor())
    @LogActivity(ActivityAction.PRODUCT_UPDATED)
    async updateProduct(@Param('id') id: string, @Body() data: UpdateProductDto, @UploadedFiles() files: Express.Multer.File[]) {
        return this.productsService.updateProduct(id, data, files);
    }

    @Delete(':id/hard-delete')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    @LogActivity(ActivityAction.PRODUCT_DELETED)
    async removeProduct(@Param('id') id: string) {
        return this.productsService.removeProduct(id);
    }

    @Delete(':id')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    @LogActivity(ActivityAction.PRODUCT_TOGGLED)
    async toggleStatus(@Param('id') id: string) {
        return this.productsService.toggleStatus(id);
    }

    @Patch(':id/featured')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async toggleFeatured(@Param('id') id: string) {
        return this.productsService.toggleFeatured(id);
    }

    @Patch(':id/restore')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    @LogActivity(ActivityAction.PRODUCT_RESTORED)
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

    @Patch('variant/:variantId/toggle')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async toggleVariant(@Param('variantId') variantId: string) {
        return this.productsService.toggleVariant(variantId);
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

    @Get('inventory/stats')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async getInventoryStats() {
        return this.productsService.getInventoryStats();
    }
}
