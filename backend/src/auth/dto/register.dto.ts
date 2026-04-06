import { IsEmail, IsNotEmpty, IsString, MinLength, IsOptional, Matches, Length, MaxLength } from 'class-validator';

export class RegisterDto {
    @IsEmail({}, { message: 'Email không hợp lệ' })
    @IsNotEmpty({ message: 'Email không được để trống' })
    email: string;

    @IsString()
    @MinLength(6, { message: 'Mật khẩu phải từ 6 ký tự trở lên' })
    password: string;

    @IsString()
    @IsNotEmpty({ message: 'Họ tên không được để trống' })
    @MaxLength(50, { message: 'Họ tên tối đa 50 ký tự' })
    fullName: string;

    @IsString()
    @IsNotEmpty({ message: 'Số điện thoại không được để trống' })
    @Matches(/(84|0[3|5|7|8|9])+([0-9]{8})\b/g, { message: 'Số điện thoại không hợp lệ' })
    phone: string;

    @IsNotEmpty({ message: 'DeviceId là bắt buộc để quản lý phiên' })
    @IsString()
    deviceId: string;

    @IsOptional()
    @IsString()
    @Length(6, 6, { message: 'Mã OTP phải có 6 ký tự' })
    otp?: string;
}