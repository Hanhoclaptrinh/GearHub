import { Injectable, InternalServerErrorException } from '@nestjs/common';
import * as nodemailer from 'nodemailer';

@Injectable()
export class MailService {
    private transporter;

    constructor() {
        this.transporter = nodemailer.createTransport({
            host: 'smtp.gmail.com',
            port: 465,
            secure: true,
            auth: {
                user: process.env.SMTP_USER,
                pass: process.env.SMTP_PASS,
            },
        });
    }

    async sendForgotPasswordOtp(email: string, otp: string) {
        if (!process.env.SMTP_USER || !process.env.SMTP_PASS) {
            console.log(`[Mock Mail] To: ${email}, OTP: ${otp}`);
            return;
        }

        try {
            await this.transporter.sendMail({
                from: '"GearHub Support Center" <no-reply@gearhub.com>',
                to: email,
                subject: 'Mã xác thực khôi phục mật khẩu - GearHub',
                html: `
                    <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #eee;">
                        <h2 style="color: #333;">Xác thực tài khoản</h2>
                        <p>Chào bạn, mã OTP để đặt lại mật khẩu của bạn là:</p>
                        <h1 style="color: #007bff; letter-spacing: 5px;">${otp}</h1>
                        <p style="font-size: 12px; color: #888;">Mã này sẽ hết hạn sau 5 phút.</p>
                    </div>
                `,
            });
            return true;
        } catch (error) {
            console.error('Lỗi gửi mail:', error);
            throw new InternalServerErrorException('Không thể gửi mã OTP, vui lòng thử lại sau');
        }
    }

    async sendRegisterOtp(email: string, otp: string) {
        if (!process.env.SMTP_USER || !process.env.SMTP_PASS) {
            console.log(`[Mock Mail - Register] To: ${email}, OTP: ${otp}`);
            return;
        }

        try {
            await this.transporter.sendMail({
                from: '"GearHub Support Center" <no-reply@gearhub.com>',
                to: email,
                subject: 'Mã xác thực đăng ký tài khoản - GearHub',
                html: `
                    <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 8px; max-width: 500px; margin: 0 auto;">
                        <h2 style="color: #333; text-align: center;">Xác thực đăng ký tài khoản</h2>
                        <p>Chào mừng bạn đến với <strong>GearHub</strong>!</p>
                        <p>Bạn đã yêu cầu đăng ký tài khoản mới. Vui lòng sử dụng mã OTP dưới đây để hoàn tất quá trình:</p>
                        <div style="background-color: #f8f9fa; padding: 20px; text-align: center; border-radius: 4px; margin: 20px 0;">
                            <h1 style="color: #28a745; letter-spacing: 10px; margin: 0; font-size: 32px;">${otp}</h1>
                        </div>
                        <p style="font-size: 14px; color: #666;">Mã này có hiệu lực trong <strong>5 phút</strong>. Nếu bạn không yêu cầu đăng ký này, vui lòng bỏ qua email này.</p>
                        <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;" />
                        <p style="font-size: 12px; color: #888; text-align: center;">Đây là email tự động, vui lòng không phản hồi.</p>
                    </div>
                `,
            });
            return true;
        } catch (error) {
            console.error('Lỗi gửi mail đăng ký:', error);
            throw new InternalServerErrorException('Không thể gửi mã OTP đăng ký, vui lòng thử lại sau');
        }
    }
}
