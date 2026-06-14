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
import * as admin from 'firebase-admin';
import { GoogleLoginDto } from './dto/google-login.dto';

@Injectable()
export class AuthService {
  constructor(
    private userService: UsersService,
    private jwtService: JwtService,
    private redisService: RedisService,
    private mailService: MailService
  ) { }

  /**
   * ký access token cho người dùng
   * bao gồm userid, email, phân quyền rbac và id thiết bị
   * đảm bảo at cần sống được trong 1 giờ
   */
  private async signAccessToken(userId: string, email: string, role: string, deviceId: string = 'default') {
    return this.jwtService.sign({
      sub: userId,
      email: email,
      role: role,
      deviceId: deviceId
    }, { expiresIn: '1h' });
  }

  /**
   * tạo refresh token mới và lưu vào redis
   */
  private async generateRefreshToken(userId: string, deviceId: string = 'default') {
    const refreshToken = uuidv4();
    const key = `refresh_token:${userId}:${deviceId}`;
    const REFRESH_TTL = 30 * 24 * 60 * 60; // 30 ngày tính bằng giây

    await this.redisService.set(key, refreshToken, 'EX', REFRESH_TTL);

    return refreshToken;
  }

  /**
   * xử lý yêu cầu đăng ký tài khoản mới bằng cách kiểm tra email, số điện thoại và gửi otp
   */
  async requestRegister(data: RegisterDto) {
    // kiểm tra xem email đã tồn tại hay chưa
    const userByEmail = await this.userService.findByEmailOrPhone(data.email);
    if (userByEmail) {
      throw new BadRequestException('Email đã tồn tại trong hệ thống');
    }

    // kiểm tra xem số điện thoại đã tồn tại hay chưa
    const userByPhone = await this.userService.findByEmailOrPhone(data.phone);
    if (userByPhone) {
      throw new BadRequestException('Số điện thoại đã tồn tại trong hệ thống');
    }

    // mã hóa pass trước khi lưu
    const hashedPassword = await bcrypt.hash(data.password, 10);
    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // lưu thông tin đăng ký tạm thời vào redis trong 10 phút
    const pendingData = { ...data, password: hashedPassword, otp };
    await this.redisService.set(
      `pending_user:${data.email}`,
      JSON.stringify(pendingData),
      'EX', 600
    );

    // gửi mã otp qua email của người dùng
    await this.mailService.sendRegisterOtp(data.email, otp);

    return { message: 'Mã OTP đăng ký đã được gửi về email của bạn' };
  }

  /**
   * xác thực mã otp đăng ký và tiến hành tạo tài khoản chính thức
   */
  async verifyRegister(email: string, otp: string) {
    const key = `pending_user:${email}`;
    // lấy dữ liệu đăng ký tạm thời từ redis
    const rawData = await this.redisService.get(key);
    if (!rawData) throw new BadRequestException('Yêu cầu hết hạn, vui lòng đăng ký lại');

    const userData = JSON.parse(rawData);

    // so khớp mã otp người dùng gửi lên
    if (userData.otp !== otp) throw new BadRequestException('Mã OTP không đúng');

    const newUser = await this.userService.createNewUser({
      email: userData.email,
      password: userData.password,
      fullName: userData.fullName,
      phone: userData.phone
    });

    // xóa dữ liệu đăng ký tạm thời sau khi tạo tài khoản thành công
    // tránh re-use đăng ký 2 lần cùng 1 otp
    await this.redisService.del(key);

    // tạo cặp access token và refresh token mới
    const [at, rt] = await Promise.all([
      this.signAccessToken(newUser.id, newUser.email, newUser.role, userData.deviceId),
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

  /**
   * xác thực thông tin đăng nhập bằng email hoặc số điện thoại và cấp token
   */
  async login(data: LoginDto) {
    // tìm người dùng theo email hoặc số điện thoại
    const user = await this.userService.findByEmailOrPhone(data.identifier);
    if (!user) {
      throw new UnauthorizedException('Thông tin đăng nhập không chính xác');
    }

    // kiểm tra trạng thái hoạt động của tài khoản
    if (user.status === UserStatus.BANNED) {
      throw new ForbiddenException('Tài khoản đã bị khóa! Vui lòng liên hệ quản trị viên để biết thêm chi tiết.');
    }

    const isMatch = await bcrypt.compare(data.password, user.password);
    if (!isMatch) {
      throw new UnauthorizedException('Thông tin đăng nhập không chính xác');
    }

    // tạo cặp token mới cho phiên đăng nhập hiện tại
    const [at, rt] = await Promise.all([
      this.signAccessToken(user.id, user.email, user.role, data.deviceId),
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
          avatarUrl: user.profile?.avatarUrl,
          phone: user.profile?.phone,
          dateOfBirth: user.profile?.dateOfBirth,
          gender: user.profile?.gender,
          preferences: user.profile?.preferences
        },
        tokens: { accessToken: at, refreshToken: rt }
      }
    };
  }

  /**
   * đăng nhập hoặc đăng ký tự động bằng google token
   */
  async googleLogin(data: GoogleLoginDto) {
    // kiểm tra cấu hình firebase admin
    if (admin.apps.length === 0) {
      throw new BadRequestException('Firebase Admin SDK chưa được cấu hình hoặc khởi tạo.');
    }

    let decodedToken: admin.auth.DecodedIdToken;
    try {
      // xác thực token gửi lên từ google
      decodedToken = await admin.auth().verifyIdToken(data.idToken);
    } catch (error) {
      throw new UnauthorizedException('Token Google không hợp lệ hoặc đã hết hạn: ' + (error instanceof Error ? error.message : String(error)));
    }

    const { email, name, picture } = decodedToken;

    if (!email) {
      throw new BadRequestException('Không lấy được email từ token Google');
    }

    // tìm kiếm tài khoản người dùng theo email google
    let user = await this.userService.findByEmailOrPhone(email);

    // tạo tài khoản mới nếu email google chưa tồn tại trong hệ thống
    if (!user) {
      const randomPassword = uuidv4();
      const hashedPassword = await bcrypt.hash(randomPassword, 10);
      await this.userService.createNewUser({
        email,
        password: hashedPassword,
        fullName: name || 'Google User',
        phone: undefined,
        avatarUrl: picture || undefined,
      });

      user = await this.userService.findByEmailOrPhone(email);
      if (!user) {
        throw new BadRequestException('Lỗi tạo tài khoản mới từ Google Sign-In');
      }
    }

    // kiểm tra xem người dùng có bị khóa tài khoản không
    if (user.status === UserStatus.BANNED) {
      throw new ForbiddenException('Tài khoản đã bị khóa! Vui lòng liên hệ quản trị viên để biết thêm chi tiết.');
    }

    // tạo token cho thiết bị đăng nhập bằng google
    const [at, rt] = await Promise.all([
      this.signAccessToken(user.id, user.email, user.role, data.deviceId || 'google-device'),
      this.generateRefreshToken(user.id, data.deviceId || 'google-device')
    ]);

    return {
      message: 'Đăng nhập bằng Google thành công',
      data: {
        user: {
          id: user.id,
          email: user.email,
          role: user.role,
          fullName: user.profile?.fullName,
          avatarUrl: user.profile?.avatarUrl,
          phone: user.profile?.phone,
          dateOfBirth: user.profile?.dateOfBirth,
          gender: user.profile?.gender,
          preferences: user.profile?.preferences
        },
        tokens: { accessToken: at, refreshToken: rt }
      }
    };
  }

  /**
   * thay đổi mật khẩu của người dùng và thu hồi mọi phiên đăng nhập khác
   */
  async changePassword(userId: string, data: ChangePasswordDto) {
    // kiểm tra mật khẩu mới trùng mật khẩu cũ
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

    // cập nhật mật khẩu
    await this.userService.updatePassword(userId, newHashedPassword);

    // thu hồi toàn bộ refresh token cũ của người dùng trên mọi thiết bị trong redis
    // cho đăng nhập lại với mật khẩu mới
    const pattern = `refresh_token:${userId}:*`;
    const keys = await this.redisService.keys(pattern);
    if (keys.length > 0) {
      await this.redisService.del(...keys);
    }

    // cấp token mới cho phiên đổi mật khẩu hiện tại
    const [at, rt] = await Promise.all([
      this.signAccessToken(user.id, user.email, user.role, data.deviceId || 'current-session'),
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

  /**
   * làm mới access token khi hết hạn bằng refresh token
   */
  async refresh(userId: string, oldToken: string, deviceId: string = 'default') {
    const key = `refresh_token:${userId}:${deviceId}`;
    const savedToken = await this.redisService.get(key);

    // so khớp refresh token gửi lên với token lưu trong redis
    if (!savedToken || savedToken !== oldToken) {
      throw new UnauthorizedException('Phiên làm việc hết hạn, vui lòng đăng nhập lại');
    }

    const user = await this.userService.findByUserId(userId);
    if (!user) throw new UnauthorizedException('Người dùng không tồn tại');
    if (user.status === UserStatus.BANNED) {
      throw new ForbiddenException('Tài khoản đã bị khóa! Vui lòng liên hệ quản trị viên để biết thêm chi tiết.');
    }

    // tạo cặp token mới thay thế token cũ
    const [nat, nrt] = await Promise.all([
      this.signAccessToken(user.id, user.email, user.role, deviceId),
      this.generateRefreshToken(user.id, deviceId)
    ]);

    return {
      accessToken: nat,
      refreshToken: nrt
    };
  }

  /**
   * gửi mã otp yêu cầu khôi phục mật khẩu qua email
   */
  async forgotPassword(email: string) {
    const user = await this.userService.findByEmailOrPhone(email);
    if (!user) throw new NotFoundException('Email không tồn tại trên hệ thống');

    const key = `otp:forgot_password:${email}`;

    // kiểm tra key trong redis
    // hạn chế gửi otp liên tục
    const isSent = await this.redisService.get(key);
    if (isSent) {
      throw new BadRequestException('Mã OTP đã được gửi, vui lòng thử lại sau 1-2 phút');
    }

    const otp = Math.floor(100000 + Math.random() * 900000).toString();

    // lưu mã otp khôi phục mật khẩu vào redis trong 5 phút
    await this.redisService.set(key, otp, 'EX', 300);
    await this.mailService.sendForgotPasswordOtp(email, otp);

    return { message: 'Mã OTP đã được gửi về email của bạn' };
  }

  /**
   * xác thực mã otp khôi phục mật khẩu
   */
  async verifyForgotPasswordOtp(email: string, otp: string) {
    const key = `otp:forgot_password:${email}`;
    const savedOtp = await this.redisService.get(key);

    // kiểm tra tính hợp lệ của mã otp
    if (!savedOtp || savedOtp !== otp) {
      throw new BadRequestException('Mã OTP không chính xác hoặc đã hết hạn');
    }

    return { message: 'Xác thực mã OTP thành công' };
  }

  /**
   * đặt lại mật khẩu mới cho tài khoản sau khi xác thực otp thành công
   */
  async resetPassword(data: ResetPasswordDto) {
    const key = `otp:forgot_password:${data.email}`;
    const savedOtp = await this.redisService.get(key);

    // kiểm tra lại otp một lần nữa trước khi đổi mật khẩu
    if (!savedOtp || savedOtp !== data.otp) {
      throw new BadRequestException('Mã OTP không chính xác hoặc đã hết hạn');
    }

    // xóa otp ngay lập tức để tránh tái sử dụng
    await this.redisService.del(key);

    const salt = 10;
    const hashedPassword = await bcrypt.hash(data.newPassword, salt);

    const user = await this.userService.findByEmailOrPhone(data.email);
    if (!user) throw new NotFoundException('Người dùng không tồn tại');

    // cập nhật mật khẩu mới
    await this.userService.updatePassword(user.id, hashedPassword);

    // thu hồi toàn bộ refresh token cũ của người dùng trên mọi thiết bị
    const pattern = `refresh_token:${user.id}:*`;
    const keys = await this.redisService.keys(pattern);
    if (keys.length > 0) await this.redisService.del(...keys);

    return { message: 'Đặt lại mật khẩu thành công! Vui lòng đăng nhập lại với mật khẩu mới' };
  }

  /**
   * đăng xuất người dùng bằng cách xóa refresh token lưu trong redis
   */
  async logout(userId: string, deviceId: string = 'default') {
    // xóa token tương ứng của thiết bị trong redis
    await this.redisService.del(`refresh_token:${userId}:${deviceId}`);
    return { message: 'Đăng xuất thành công' };
  }

  /**
   * lấy thông tin chi tiết của người dùng đang đăng nhập
   */
  async getMe(userId: string) {
    const user = await this.userService.findByUserId(userId);

    if (!user) throw new UnauthorizedException('Không tìm thấy người dùng');

    return {
      id: user.id,
      email: user.email,
      role: user.role,
      fullName: user.profile?.fullName,
      avatarUrl: user.profile?.avatarUrl,
      phone: user.profile?.phone,
      dateOfBirth: user.profile?.dateOfBirth,
      gender: user.profile?.gender,
      preferences: user.profile?.preferences
    }
  }
}
