import { Body, Controller, Get, Param, Patch, Post, Request, UseGuards } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { JwtAuthGuard } from 'src/auth/guards/jwt-auth.guard';
import { CreateOrderDto } from './dto/create-order.dto';
import { RolesGuard } from 'src/auth/guards/roles.guard';
import { Roles } from 'src/common/decorators/roles.decorator';
import { Role } from '@prisma/client';
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
    async getMyOrders(@Request() req) {
        return this.orderService.getMyOrders(req.user.userId);
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
}
