import { Body, Controller, Get, Param, Patch, Post, Query, Request, UseGuards } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { JwtAuthGuard } from 'src/auth/guards/jwt-auth.guard';
import { CreateOrderDto } from './dto/create-order.dto';
import { RolesGuard } from 'src/auth/guards/roles.guard';
import { Roles } from 'src/common/decorators/roles.decorator';
import { OrderStatus, Role } from '@prisma/client';
import { UpdateOrderStatusDto } from './dto/update-order-status.dto';

@Controller('orders')
export class OrdersController {
    constructor(private orderService: OrdersService) { }

    @Post()
    @UseGuards(JwtAuthGuard)
    async createOrder(@Request() req, @Body() data: CreateOrderDto) {
        return this.orderService.createOrder(req.user.userId, data);
    }

    @Get('my-orders')
    @UseGuards(JwtAuthGuard)
    async getMyOrders(
        @Request() req,
        @Query('page') page?: number,
        @Query('limit') limit?: number,
        @Query('status') status?: OrderStatus,
    ) {
        return this.orderService.getMyOrders(req.user.userId, {
            page: page ? Number(page) : 1,
            limit: limit ? Number(limit) : 10,
            status
        });
    }

    @Get('admin/dashboard')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async getDashboard() {
        const stats = await this.orderService.getAdminStats();
        const topProducts = await this.orderService.getTopSellingProducts();

        return {
            stats,
            topProducts
        }
    }

    @Get('top-products')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async getTopProducts(@Query('limit') limit?: number) {
        return this.orderService.getTopSellingProducts(limit ? Number(limit) : 5);
    }

    @Get('admin')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async getAllOrders(
        @Query('page') page?: number,
        @Query('limit') limit?: number,
        @Query('status') status?: OrderStatus,
        @Query('search') search?: string
    ) {
        return this.orderService.getAllOrders({
            page: page ? Number(page) : 1,
            limit: limit ? Number(limit) : 10,
            status,
            search
        });
    }

    @Get(':id')
    @UseGuards(JwtAuthGuard)
    async getOrderDetail(@Request() req, @Param('id') id: string) {
        return this.orderService.getOrderDetail(req.user.userId, id);
    }

    @Patch(':id')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async updateOrderStatus(@Param('id') id: string, @Body() data: UpdateOrderStatusDto) {
        return this.orderService.updateOrderStatus(id, data);
    }

    @Patch(':id/cancel')
    @UseGuards(JwtAuthGuard)
    async cancelOrder(@Request() req, @Param('id') id: string) {
        return this.orderService.cancelOrder(req.user.userId, id);
    }

    @Post(':id/re-order')
    @UseGuards(JwtAuthGuard)
    async reOrder(@Request() req, @Param('id') id: string) {
        return this.orderService.reOrder(req.user.userId, id);
    }
}
