import { Body, Controller, DefaultValuePipe, Delete, Get, Param, ParseIntPipe, ParseUUIDPipe, Patch, Post, Query, Request, UploadedFiles, UseGuards, UseInterceptors } from '@nestjs/common';
import { ReviewsService } from './reviews.service';
import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';
import { FilesInterceptor } from '@nestjs/platform-express';
import { CreateReviewDto } from './dto/create-review.dto';
import { RolesGuard } from 'src/common/guards/roles.guard';
import { Roles } from 'src/common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { ReplyReviewDto } from './dto/reply-review.dto';
import { UpdateReviewDto } from './dto/update-review.dto';

@Controller('reviews')
export class ReviewsController {
    constructor(private reviewService: ReviewsService) { }

    @Get()
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN, Role.STAFF)
    async getAllReviews(
        @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
        @Query('limit', new DefaultValuePipe(10), ParseIntPipe) limit: number,
        @Query('rating') rating?: string,
        @Query('repliedStatus') repliedStatus?: 'replied' | 'unreplied',
        @Query('isHidden') isHidden?: string,
        @Query('search') search?: string,
    ) {
        return this.reviewService.getAllReviews(
            page,
            limit,
            rating ? parseInt(rating) : undefined,
            repliedStatus,
            isHidden === 'true' ? true : isHidden === 'false' ? false : undefined,
            search,
        );
    }

    @Get('stats')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN, Role.STAFF)
    async getReviewStats() {
        return this.reviewService.getReviewStats();
    }

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
        @Query('rating') rating?: string,
        @Query('hasImage') hasImage?: string,
    ) {
        return this.reviewService.getProductReviews(
            productId, 
            page, 
            limit, 
            false, 
            rating ? parseInt(rating) : undefined, 
            hasImage === 'true'
        );
    }

    @Get('product/:productId/summary')
    async getReviewSummary(@Param('productId', ParseUUIDPipe) productId: string) {
        return this.reviewService.getReviewSummary(productId);
    }

    @Patch(':id/reply')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN, Role.STAFF)
    async reply(
        @Param('id', ParseUUIDPipe) id: string,
        @Body() data: ReplyReviewDto,
    ) {
        return this.reviewService.replyReview(id, data);
    }

    @Post(':id/ai-reply')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN, Role.STAFF)
    async generateAiReply(@Param('id', ParseUUIDPipe) id: string) {
        return this.reviewService.generateAiReplyDraft(id);
    }

    @Patch(':id')
    @UseGuards(JwtAuthGuard)
    async update(
        @Request() req,
        @Param('id', ParseUUIDPipe) id: string,
        @Body() data: UpdateReviewDto,
    ) {
        return this.reviewService.updateReview(req.user.userId, id, data);
    }

    @Get('my-reviews')
    @UseGuards(JwtAuthGuard)
    getMyReviews(@Request() req) {
        return this.reviewService.getUserReviews(req.user.userId);
    }

    @Get('pending')
    @UseGuards(JwtAuthGuard)
    getPendingReviews(@Request() req) {
        return this.reviewService.getPendingReviews(req.user.userId);
    }

    @Patch('skip/:orderItemId')
    @UseGuards(JwtAuthGuard)
    skipReview(
        @Request() req,
        @Param('orderItemId', ParseUUIDPipe) orderItemId: string
    ) {
        return this.reviewService.skipReview(req.user.userId, orderItemId);
    }
    @Patch(':id/toggle-visibility')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN, Role.STAFF)
    async toggleVisibility(@Param('id', ParseUUIDPipe) id: string) {
        return this.reviewService.toggleVisibility(id);
    }

    @Delete(':id')
    @UseGuards(JwtAuthGuard)
    async delete(@Param('id', ParseUUIDPipe) id: string) {
        return this.reviewService.deleteReview(id);
    }
}
