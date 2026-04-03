import { Body, Controller, DefaultValuePipe, Get, Param, ParseIntPipe, ParseUUIDPipe, Post, Query, Request, UseGuards } from '@nestjs/common';
import { WishlistService } from './wishlist.service';
import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';

@Controller('wishlist')
export class WishlistController {
    constructor(private wishlistService: WishlistService) { }

    @Post('toggle/:productId')
    @UseGuards(JwtAuthGuard)
    async toggleWishlist(@Request() req, @Param('productId', ParseUUIDPipe) productId: string) {
        return this.wishlistService.toggleWishlist(req.user.userId, productId);
    }

    @Get()
    @UseGuards(JwtAuthGuard)
    async getWishlist(
        @Request() req,
        @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
        @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number,
    ) {
        return this.wishlistService.getMyWishlist(req.user.userId, page, limit);
    }

    @Get('check/:productId')
    @UseGuards(JwtAuthGuard)
    @UseGuards(JwtAuthGuard)
    async checkIsFavorite(
        @Request() req,
        @Param('productId', ParseUUIDPipe) productId: string
    ) {
        return this.wishlistService.checkIsFavorite(req.user.userId, productId);
    }

    @Get('trending')
    async getTrending(
        @Query('limit', new DefaultValuePipe(5), ParseIntPipe) limit: number
    ) {
        return this.wishlistService.getMostWishlisted(limit);
    }
}
