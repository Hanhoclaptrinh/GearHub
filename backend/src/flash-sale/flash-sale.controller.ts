import { Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { FlashSaleService } from './flash-sale.service';
import { CreateFlashSaleProductDto } from './dto/create-flash-sale-product.dto';
import { UpdateFlashSaleTimeBulkDto } from './dto/update-flash-sale-time-bulk.dto';
import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';
import { RolesGuard } from 'src/common/guards/roles.guard';
import { Roles } from 'src/common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller()
export class FlashSaleController {
    constructor(private readonly flashSaleService: FlashSaleService) {}

    // API public cho mobile/web client lấy danh sách flash sale
    @Get('flash-sale/active')
    async getActiveFlashSales(@Query('status') status?: 'active' | 'upcoming' | 'all') {
        const safeStatus = (status === 'active' || status === 'upcoming') ? status : 'all';
        return this.flashSaleService.getClientFlashSales(safeStatus);
    }

    // Admin: Thêm sản phẩm vào Flash Sale
    @Post('admin/flash-sale')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN, Role.STAFF)
    async create(@Body() dto: CreateFlashSaleProductDto) {
        return this.flashSaleService.createFlashSaleProduct(dto);
    }

    // Admin: Cập nhật thời gian hàng loạt
    @Patch('admin/flash-sale/bulk-time')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN, Role.STAFF)
    async updateTimeBulk(@Body() dto: UpdateFlashSaleTimeBulkDto) {
        return this.flashSaleService.updateFlashSaleTimeBulk(dto);
    }

    // Admin: Lấy danh sách phân trang tất cả Flash Sale
    @Get('admin/flash-sale')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN, Role.STAFF)
    async findAll(
        @Query('page') page?: number,
        @Query('limit') limit?: number,
        @Query('search') search?: string
    ) {
        const safePage = page ? Number(page) : 1;
        const safeLimit = limit ? Number(limit) : 10;
        return this.flashSaleService.findAllAdmin(safePage, safeLimit, search);
    }

    // Admin: Xoá sản phẩm khỏi Flash Sale
    @Delete('admin/flash-sale/:id')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN, Role.STAFF)
    async remove(@Param('id') id: string) {
        return this.flashSaleService.remove(id);
    }
}
