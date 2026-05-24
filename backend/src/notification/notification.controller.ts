import { Body, Controller, Delete, Get, Param, Patch, Post, Query, Request, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';
import { DeregisterFcmTokenDto } from './dto/deregister-fcm-token.dto';
import { RegisterFcmTokenDto } from './dto/register-fcm-token.dto';
import { NotificationService } from './notification.service';
import { NotificationType } from '@prisma/client';

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationController {
  constructor(private readonly notificationService: NotificationService) { }

  @Post('register-token')
  registerToken(@Request() req, @Body() data: RegisterFcmTokenDto) {
    return this.notificationService.registerToken(req.user.userId, data);
  }

  @Post('deregister-token')
  deregisterToken(@Request() req, @Body() data: DeregisterFcmTokenDto) {
    return this.notificationService.deregisterToken(
      req.user.userId,
      data.token,
    );
  }

  @Get()
  getNotifications(
    @Request() req,
    @Query('page') page?: number,
    @Query('limit') limit?: number,
    @Query('type') type?: NotificationType,
  ) {
    return this.notificationService.getUserNotifications(req.user.userId, {
      page,
      limit,
      type,
    });
  }

  @Patch('read-all')
  markAllAsRead(@Request() req) {
    return this.notificationService.markAllAsRead(req.user.userId);
  }

  @Patch(':id/read')
  markAsRead(@Request() req, @Param('id') id: string) {
    return this.notificationService.markAsRead(req.user.userId, id);
  }

  @Delete('clear-all')
  clearAllNotifications(@Request() req) {
    return this.notificationService.clearAllNotifications(req.user.userId);
  }

  @Delete(':id')
  deleteNotification(@Request() req, @Param('id') id: string) {
    return this.notificationService.deleteNotification(req.user.userId, id);
  }
}
