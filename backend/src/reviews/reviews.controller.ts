import { Body, Controller, DefaultValuePipe, Get, Param, ParseIntPipe, ParseUUIDPipe, Patch, Post, Query, Request, UploadedFiles, UseGuards, UseInterceptors } from '@nestjs/common';
import { ReviewsService } from './reviews.service';
import { JwtAuthGuard } from 'src/auth/guards/jwt-auth.guard';
import { FilesInterceptor } from '@nestjs/platform-express';
import { CreateReviewDto } from './dto/create-review.dto';
import { RolesGuard } from 'src/auth/guards/roles.guard';
import { Roles } from 'src/common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { ReplyReviewDto } from './dto/reply-review.dto';

@Controller('reviews')
export class ReviewsController {
    constructor(private reviewService: ReviewsService) { }

    @Post()
    @UseGuards(JwtAuthGuard)
    @UseInterceptors(FilesInterceptor('files', 5))
    async create(
        @Request() req,
        @Body() data: CreateReviewDto,
        @UploadedFiles() files: Express.Multer.File[]
    ) {
        return this.reviewService.createReview(req.user.userId, data, files);
    }

    @Get('products/:productId')
    async getProductReviews(
        @Param('productId', ParseUUIDPipe) productId: string,
        @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
        @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number,
    ) {
        return this.reviewService.getProductReviews(productId, page, limit);
    }

    @Patch(':id/reply')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async reply(
        @Param('id', ParseUUIDPipe) id: string,
        @Body() data: ReplyReviewDto,
    ) {
        return this.reviewService.replyReview(id, data);
    }
}
