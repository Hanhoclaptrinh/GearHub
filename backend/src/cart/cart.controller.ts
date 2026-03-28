import { Body, Controller, Delete, Get, Param, Patch, Post, Request, UseGuards } from '@nestjs/common';
import { CartService } from './cart.service';
import { JwtAuthGuard } from 'src/auth/guards/jwt-auth.guard';
import { AddToCartDto } from './dto/add-to-cart.dto';
import { UpdateCartItemDto } from './dto/update-cart-item.dto';
import { ClearSelectedDto } from './dto/clear-selected.dto';
import { SyncCartDto } from './dto/sync-cart.dto';

@Controller('cart')
export class CartController {
    constructor(private cartService: CartService) { }

    @Post()
    @UseGuards(JwtAuthGuard)
    async addToCart(@Request() req, @Body() data: AddToCartDto) {
        return this.cartService.addToCart(req.user.userId, data);
    }

    @Get()
    @UseGuards(JwtAuthGuard)
    async getCart(@Request() req) {
        return this.cartService.getCart(req.user.userId);
    }

    @Get('count')
    @UseGuards(JwtAuthGuard)
    async getCartCount(@Request() req) {
        return this.cartService.getCartCount(req.user.userId);
    }

    @Patch('item/:id')
    @UseGuards(JwtAuthGuard)
    async updateQuantity(
        @Request() req,
        @Param('id') id: string,
        @Body() data: UpdateCartItemDto,
    ) {
        return this.cartService.updateQuantity(req.user.userId, id, data);
    }

    @Delete('item/:id')
    @UseGuards(JwtAuthGuard)
    async removeItem(
        @Request() req,
        @Param('id') id: string
    ) {
        return this.cartService.removeItem(req.user.userId, id);
    }

    @Delete('clear-all')
    async clearAll(@Request() req) {
        await this.cartService.clearCart(req.user.userId);
        return { message: 'Giỏ hàng đã được dọn sạch' };
    }

    @Delete('clear-selected')
    async clearSelected(
        @Request() req,
        @Body() data: ClearSelectedDto
    ) {
        return this.cartService.clearSelectedItems(req.user.userId, data);
    }

    @Post('sync')
    @UseGuards(JwtAuthGuard)
    async sync(@Request() req, @Body() data: SyncCartDto) {
        return this.cartService.syncCart(req.user.userId, data);
    }
}
