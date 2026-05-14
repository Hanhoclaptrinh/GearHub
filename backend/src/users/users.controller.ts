import { Controller, Patch, UseGuards, Request, Get, Query, UseInterceptors, Body, UploadedFile, FileTypeValidator, MaxFileSizeValidator, ParseFilePipe, Param, NotFoundException, Post } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { UpdateUserStatusDto } from './dto/update-user-status.dto';
import { UpdateUserRoleDto } from './dto/update-user-role.dto';
import { RolesGuard } from 'src/common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { CloudinaryService } from 'src/cloudinary/cloudinary.service';
import { FileInterceptor } from '@nestjs/platform-express';
import { CreateUserDto } from './dto/create-user.dto';


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

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @Post('admin/create')
  async createStaff(@Body() data: CreateUserDto) {
    return this.userService.createNewUser(data);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @Get('admin/stats')
  async getUserStats() {
    return this.userService.getUserStats();
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @Get(':id/detail')
  async getDetailedUser(@Param('id') id: string) {
    return this.userService.getDetailedUser(id);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('update-profile')
  @UseInterceptors(FileInterceptor('file'))
  async updateProfile(
    @Request() req,
    @Body() data: UpdateProfileDto,
    @UploadedFile(
      new ParseFilePipe({
        validators: [
          new MaxFileSizeValidator({ maxSize: 1024 * 1024 * 2 }),
          new FileTypeValidator({ fileType: '.(png|jpg|jpeg|webp|svg)' }),
        ],
        fileIsRequired: false,
      }),
    ) file?: Express.Multer.File
  ) {
    const userId = req.user.userId;

    if (file) {
      const uploadResult = await this.cloudinaryService.uploadFile(file);

      data.avatarUrl = uploadResult.secure_url;
    }

    return this.userService.updateProfile(userId, data);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @Patch(':id/status')
  async updateUserStatus(
    @Param('id') id: string,
    @Body() data: UpdateUserStatusDto,
    @Request() req
  ) {
    return this.userService.updateUserStatus(id, data, req.user.userId);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN)
  @Patch(':id/role')
  async updateUserRole(
    @Param('id') id: string,
    @Body() data: UpdateUserRoleDto,
    @Request() req
  ) {
    return this.userService.updateUserRole(id, data, req.user.userId);
  }
}
