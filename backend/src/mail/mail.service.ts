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

    async sendOtp(email: string, otp: string) {
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
}