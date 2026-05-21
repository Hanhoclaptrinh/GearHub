import { Controller, Get, Post, Patch, Delete, Body, Param, Query, UseGuards, Request } from '@nestjs/common';
import { PromotionService } from './promotion.service';
import { CreateVoucherDto } from './dto/create-voucher.dto';
import { UpdateVoucherDto } from './dto/update-voucher.dto';
import { UpdateVoucherStatusDto } from './dto/update-voucher-status.dto';
import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';
import { RolesGuard } from 'src/common/guards/roles.guard';
import { Roles } from 'src/common/decorators/roles.decorator';
import { Role } from '@prisma/client';

@Controller()
export class PromotionController {
    constructor(private readonly promotionService: PromotionService) { }

    // user
    @Get('promotions/available')
    @UseGuards(JwtAuthGuard)
    async getAvailableVouchers(@Request() req) {
        return this.promotionService.getAvailableVouchers(req.user.userId);
    }

    @Get('promotions/me/vouchers')
    @UseGuards(JwtAuthGuard)
    async getMyVouchers(@Request() req) {
        return this.promotionService.getMyVouchers(req.user.userId);
    }

    @Post('promotions/vouchers/:id/claim')
    @UseGuards(JwtAuthGuard)
    async claimVoucher(@Request() req, @Param('id') voucherId: string) {
        return this.promotionService.claimVoucher(req.user.userId, voucherId);
    }

    // admin
    @Post('admin/promotions/vouchers')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async createVoucher(@Body() dto: CreateVoucherDto) {
        return this.promotionService.createVoucher(dto);
    }

    @Get('admin/promotions/vouchers')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN, Role.STAFF)
    async findAllVouchers(
        @Query('page') page?: number,
        @Query('limit') limit?: number,
        @Query('search') search?: string
    ) {
        return this.promotionService.findAllVouchersAdmin({
            page: page ? Number(page) : 1,
            limit: limit ? Number(limit) : 10,
            search
        });
    }

    @Get('admin/promotions/vouchers/:id')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN, Role.STAFF)
    async findVoucherById(@Param('id') id: string) {
        return this.promotionService.findVoucherByIdAdmin(id);
    }

    @Patch('admin/promotions/vouchers/:id')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async updateVoucher(@Param('id') id: string, @Body() dto: UpdateVoucherDto) {
        return this.promotionService.updateVoucher(id, dto);
    }

    @Patch('admin/promotions/vouchers/:id/status')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async updateVoucherStatus(@Param('id') id: string, @Body() statusDto: UpdateVoucherStatusDto) {
        return this.promotionService.updateVoucherStatus(id, statusDto);
    }

    @Delete('admin/promotions/vouchers/:id')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async deleteVoucher(@Param('id') id: string) {
        return this.promotionService.deleteVoucher(id);
    }
}
