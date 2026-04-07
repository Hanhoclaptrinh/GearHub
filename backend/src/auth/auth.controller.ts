import { Controller, Get, Post, Body, Patch, UseGuards, Request } from '@nestjs/common';
import { AuthService } from './auth.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { ChangePasswordDto } from './dto/change-password.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { LogActivity } from 'src/common/decorators/log-activity.decorator';
import { ActivityAction } from 'src/common/constants/activity-log.constants';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) { }

  @Post('register/request')
  async registerRequest(@Body() data: RegisterDto) {
    return this.authService.requestRegister(data);
  }

  @Post('register/verify')
  @LogActivity(ActivityAction.USER_REGISTER)
  async registerVerify(@Body() data: { email: string, otp: string, deviceId: string }) {
    return this.authService.verifyRegister(data.email, data.otp);
  }

  // @Post('register')
  // @LogActivity(ActivityAction.USER_REGISTER)
  // async register(@Body() data: RegisterDto) {
  //   return this.authService.register(data);
  // }

  // @Post('register/send-otp')
  // async sendRegisterOtp(@Body('email') email: string) {
  //   return this.authService.sendRegisterOtp(email);
  // }

  @Post('login')
  @LogActivity(ActivityAction.USER_LOGIN)
  async login(@Body() data: LoginDto) {
    return this.authService.login(data);
  }

  @UseGuards(JwtAuthGuard)
  @Patch('change-password')
  @LogActivity(ActivityAction.USER_CHANGE_PASSWORD)
  async changePassword(@Request() req, @Body() data: ChangePasswordDto) {
    return this.authService.changePassword(req.user.userId, data);
  }

  @Post('refresh')
  async refresh(@Body() body: { refreshToken: string, userId: string, deviceId: string }) {
    return this.authService.refresh(
      body.userId,
      body.refreshToken,
      body.deviceId
    );
  }

  @Post('forgot-password')
  @LogActivity(ActivityAction.USER_FORGOT_PASSWORD)
  async forgotPassword(@Body('email') email: string) {
    return this.authService.forgotPassword(email);
  }

  @Post('reset-password')
  @LogActivity(ActivityAction.USER_RESET_PASSWORD)
  async resetPassword(@Body() data: ResetPasswordDto) {
    return this.authService.resetPassword(data);
  }

  @UseGuards(JwtAuthGuard)
  @Post('logout')
  @LogActivity(ActivityAction.USER_LOGOUT)
  async logout(@Request() req) {
    return this.authService.logout(req.user.userId);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  async getMe(@Request() req) {
    return this.authService.getMe(req.user.userId);
  }
}
