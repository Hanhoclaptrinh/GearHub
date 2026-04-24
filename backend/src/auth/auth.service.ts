import { BadRequestException, ForbiddenException, Injectable, NotFoundException, UnauthorizedException } from '@nestjs/common';
import { UsersService } from 'src/users/users.service';
import { JwtService } from '@nestjs/jwt';
import { RedisService } from 'src/redis/redis.service';
import { v4 as uuidv4 } from 'uuid';
import { RegisterDto } from './dto/register.dto';
import * as bcrypt from 'bcrypt';
import { LoginDto } from './dto/login.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { MailService } from 'src/mail/mail.service';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { UserStatus } from '@prisma/client';

@Injectable()
export class AuthService {
  constructor(
    private userService: UsersService,
    private jwtService: JwtService,
    private redisService: RedisService,
    private mailService: MailService
  ) { }

  private async signAccessToken(userId: string, email: string, role: string) {
    return this.jwtService.sign({
      sub: userId,
      email: email,
      role: role
    }, { expiresIn: '20m' });
  }

  private async generateRefreshToken(userId: string, deviceId: string = 'default') {
    const refreshToken = uuidv4();
    const key = `refresh_token:${userId}:${deviceId}`;
    const REFRESH_TTL = 7 * 24 * 60 * 60;

    await this.redisService.set(key, refreshToken, 'EX', REFRESH_TTL);

    return refreshToken;
  }

  async requestRegister(data: RegisterDto) {
    const userByEmail = await this.userService.findByEmailOrPhone(data.email);
    if (userByEmail) {
      throw new BadRequestException('Email đã tồn tại trong hệ thống');
    }

    const userByPhone = await this.userService.findByEmailOrPhone(data.phone);
    if (userByPhone) {
      throw new BadRequestException('Số điện thoại đã tồn tại trong hệ thống');
    }

    const hashedPassword = await bcrypt.hash(data.password, 10);
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // luu thong tin dang ky trong redis trong 10 phut
    const pendingData = { ...data, password: hashedPassword, otp };
    await this.redisService.set(
      `pending_user:${data.email}`,
      JSON.stringify(pendingData),
      'EX', 600
    );

    await this.mailService.sendRegisterOtp(data.email, otp);

    return { message: 'Mã OTP đăng ký đã được gửi về email của bạn' };
  }

  async verifyRegister(email: string, otp: string) {
    const key = `pending_user:${email}`;
    const rawData = await this.redisService.get(key);
    if (!rawData) throw new BadRequestException('Yêu cầu hết hạn, vui lòng đăng ký lại');

    const userData = JSON.parse(rawData);

    if (userData.otp !== otp) throw new BadRequestException('Mã OTP không đúng');

    const newUser = await this.userService.createNewUser({
      email: userData.email,
      password: userData.password,
      fullName: userData.fullName,
      phone: userData.phone
    });

    await this.redisService.del(key);

    const [at, rt] = await Promise.all([
      this.signAccessToken(newUser.id, newUser.email, newUser.role),
      this.generateRefreshToken(newUser.id, userData.deviceId)
    ]);

    return {
      message: 'Đăng ký thành công',
      data: {
        user: newUser,
        tokens: { accessToken: at, refreshToken: rt }
      }
    };
  }

  async login(data: LoginDto) {
    const user = await this.userService.findByEmailOrPhone(data.identifier);
    if (!user) {
      throw new UnauthorizedException('Thông tin đăng nhập không chính xác');
    }

    if (user.status === UserStatus.BANNED) {
      throw new ForbiddenException('Tài khoản đã bị khóa! Vui lòng liên hệ quản trị viên để biết thêm chi tiết.');
    }

    const isMatch = await bcrypt.compare(data.password, user.password);
    if (!isMatch) {
      throw new UnauthorizedException('Thông tin đăng nhập không chính xác');
    }

    const [at, rt] = await Promise.all([
      this.signAccessToken(user.id, user.email, user.role),
      this.generateRefreshToken(user.id, data.deviceId)
    ]);

    return {
      message: 'Đăng nhập thành công',
      data: {
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          fullName: user.profile?.fullName,
          avatarUrl: user.profile?.avatarUrl
        },
        tokens: { accessToken: at, refreshToken: rt }
      }
    };
  }

  async changePassword(userId: string, data: ChangePasswordDto) {
    if (data.newPassword === data.oldPassword) {
      throw new BadRequestException('Mật khẩu mới phải khác mật khẩu cũ');
    }

    const user = await this.userService.findByUserId(userId);
    if (!user) throw new UnauthorizedException('Người dùng không tồn tại');

    const isMatch = await bcrypt.compare(data.oldPassword, user.password);
    if (!isMatch) {
      throw new BadRequestException('Mật khẩu cũ không chính xác');
    }

    const salt = 10;
    const newHashedPassword = await bcrypt.hash(data.newPassword, salt);

    await this.userService.updatePassword(userId, newHashedPassword);

    const pattern = `refresh_token:${userId}:*`;
    const keys = await this.redisService.keys(pattern);
    if (keys.length > 0) {
      await this.redisService.del(...keys);
    }

    const [at, rt] = await Promise.all([
      this.signAccessToken(
        user.id,
        user.email,
        user.role
      ),
      this.generateRefreshToken(user.id, data.deviceId || 'current-session')
    ]);

    return {
      message: 'Đổi mật khẩu thành công và đã đăng xuất khỏi các thiết bị khác',
      data: {
        user: {
          id: user.id,
          email: user.email,
          fullName: user.profile?.fullName
        },
        tokens: {
          accessToken: at,
          refreshToken: rt
        }
      }
    };
  }

  async refresh(userId: string, oldToken: string, deviceId: string = 'default') {
    const key = `refresh_token:${userId}:${deviceId}`;
    const savedToken = await this.redisService.get(key);

    if (!savedToken || savedToken !== oldToken) {
      throw new UnauthorizedException('Phiên làm việc hết hạn, vui lòng đăng nhập lại');
    }

    const user = await this.userService.findByUserId(userId);
    if (!user) throw new UnauthorizedException('Người dùng không tồn tại');

    const [nat, nrt] = await Promise.all([
      this.signAccessToken(
        user.id,
        user.email,
        user.role
      ),
      this.generateRefreshToken(user.id, deviceId)
    ]);

    return {
      accessToken: nat,
      refreshToken: nrt
    };
  }

  async forgotPassword(email: string) {
    const user = await this.userService.findByEmailOrPhone(email);
    if (!user) throw new NotFoundException('Email không tồn tại trên hệ thống');

    const key = `otp:forgot_password:${email}`;

    const isSent = await this.redisService.get(key);
    if (isSent) {
      throw new BadRequestException('Mã OTP đã được gửi, vui lòng thử lại sau 1-2 phút');
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString(); // otp 6 chu so

    await this.redisService.set(key, otp, 'EX', 300); // luu otp vao redis 5 phut
    await this.mailService.sendForgotPasswordOtp(email, otp);

    return { message: 'Mã OTP đã được gửi về email của bạn' };
  }

  async verifyForgotPasswordOtp(email: string, otp: string) {
    const key = `otp:forgot_password:${email}`;
    const savedOtp = await this.redisService.get(key);

    if (!savedOtp || savedOtp !== otp) {
      throw new BadRequestException('Mã OTP không chính xác hoặc đã hết hạn');
    }

    return { message: 'Xác thực mã OTP thành công' };
  }

  async resetPassword(data: ResetPasswordDto) {
    const key = `otp:forgot_password:${data.email}`;
    const savedOtp = await this.redisService.get(key);

    if (!savedOtp || savedOtp !== data.otp) {
      throw new BadRequestException('Mã OTP không chính xác hoặc đã hết hạn');
    }

    await this.redisService.del(key); // xoa otp de khong bi re-use

    const salt = 10;
    const hashedPassword = await bcrypt.hash(data.newPassword, salt);

    const user = await this.userService.findByEmailOrPhone(data.email);
    if (!user) throw new NotFoundException('Người dùng không tồn tại');

    await this.userService.updatePassword(user.id, hashedPassword);

    await this.redisService.del(key);
    const pattern = `refresh_token:${user.id}:*`;
    const keys = await this.redisService.keys(pattern);
    if (keys.length > 0) await this.redisService.del(...keys);

    return { message: 'Đặt lại mật khẩu thành công' };
  }

  async logout(userId: string, deviceId: string = 'default') {
    await this.redisService.del(`refresh_token:${userId}:${deviceId}`);
    return { message: 'Đăng xuất thành công' };
  }

  async getMe(userId: string) {
    const user = await this.userService.findByUserId(userId);

    if (!user) throw new UnauthorizedException('Không tìm thấy người dùng');

    return {
      id: user.id,
      email: user.email,
      role: user.role,
      fullName: user.profile?.fullName,
      avatarUrl: user.profile?.avatarUrl,
      phone: user.profile?.phone
    }
  }
}
