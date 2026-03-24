import { IsNotEmpty, IsString, MinLength } from 'class-validator';

export class LoginDto {
    @IsNotEmpty({ message: 'Email hoặc Số điện thoại không được để trống' })
    @IsString()
    identifier: string;

    @IsNotEmpty({ message: 'Mật khẩu không được để trống' })
    @IsString()
    @MinLength(6, { message: 'Mật khẩu phải từ 6 ký tự trở lên' })
    password: string;

    @IsNotEmpty({ message: 'DeviceId là bắt buộc để quản lý phiên' })
    @IsString()
    deviceId: string;
}