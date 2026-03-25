import { Controller, Patch, UseGuards, Request, Get, Query, UseInterceptors, Body, UploadedFile } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from 'src/auth/guards/jwt-auth.guard';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { RolesGuard } from 'src/auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';
import { FileInterceptor } from '@nestjs/platform-express';

@Controller('users')
export class UsersController {
  constructor(
    private userService: UsersService,
    private cloudinaryService: CloudinaryService
  ) { }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @Get('all-users')
  async getAllUsers(@Query() query: any) {
    return this.userService.getAllUsers(query);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('update-profile')
  @UseInterceptors(FileInterceptor('file'))
  async updateProfile(
    @Request() req,
    @Body() data: UpdateProfileDto,
    @UploadedFile() file?: Express.Multer.File
  ) {
    const userId = req.user.userId;

    if (file) {
      const uploadResult = await this.cloudinaryService.uploadFile(file);

      data.avatarUrl = uploadResult.secure_url;
    }

    return this.userService.updateProfile(userId, data);
  }
}
