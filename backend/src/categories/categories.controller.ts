import { Body, Controller, Delete, FileTypeValidator, Get, MaxFileSizeValidator, Param, ParseFilePipe, Patch, Post, UploadedFile, UseGuards, UseInterceptors } from '@nestjs/common';
import { CategoriesService } from './categories.service';
import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';
import { RolesGuard } from 'src/common/guards/roles.guard';
import { Roles } from 'src/common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { FileInterceptor } from '@nestjs/platform-express';
import { CreateCategoryDto } from './dto/create-category.dto';
import { UpdateCategoryDto } from './dto/update-category.dto';

@Controller('categories')
export class CategoriesController {
    constructor(private categoriesService: CategoriesService) { }

    @Get()
    async getAllCategories() {
        return this.categoriesService.getAllCategories();
    }

    @Get('tree')
    async getCategoryTree() {
        return this.categoriesService.getCategoryTree();
    }

    @Get('slug/:slug')
    async getCategoryBySlug(@Param('slug') slug: string) {
        return this.categoriesService.getCategoryBySlug(slug);
    }

    @Post()
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    @UseInterceptors(FileInterceptor('file'))
    async createCategory(
        @Body() data: CreateCategoryDto,
        @UploadedFile(
            new ParseFilePipe({
                validators: [
                    new MaxFileSizeValidator({ maxSize: 1024 * 1024 * 2 }),
                ],
                fileIsRequired: false,
            }),
        ) file?: Express.Multer.File
    ) {
        return this.categoriesService.createCategory(data, file);
    }

    @Patch(':id')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    @UseInterceptors(FileInterceptor('file'))
    async updateCategory(
        @Param('id') id: string,
        @Body() data: UpdateCategoryDto,
        @UploadedFile(
            new ParseFilePipe({
                validators: [
                    new MaxFileSizeValidator({ maxSize: 1024 * 1024 * 2 }),
                ],
                fileIsRequired: false,
            }),
        ) file?: Express.Multer.File
    ) {
        return this.categoriesService.updateCategory(id, data, file);
    }

    @Delete(':id')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async removeCategory(@Param('id') id: string) {
        return this.categoriesService.removeCategory(id);
    }
}
