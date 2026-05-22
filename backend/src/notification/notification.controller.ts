import { Body, Controller, Post, Request, UseGuards } from '@nestjs/common';
import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';
import { DeregisterFcmTokenDto } from './dto/deregister-fcm-token.dto';
import { RegisterFcmTokenDto } from './dto/register-fcm-token.dto';
import { NotificationService } from './notification.service';

@Controller('notifications')
@UseGuards(JwtAuthGuard)
export class NotificationController {
  constructor(private readonly notificationService: NotificationService) {}

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
}
