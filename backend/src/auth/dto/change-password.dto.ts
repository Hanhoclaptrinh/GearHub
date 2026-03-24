import { IsNotEmpty, IsString, MinLength } from 'class-validator';

export class ChangePasswordDto {
    @IsNotEmpty({ message: 'Mật khẩu cũ không được để trống' })
    oldPassword: string;

    @IsNotEmpty({ message: 'Mật khẩu mới không được để trống' })
    @MinLength(6, { message: 'Mật khẩu mới phải từ 6 ký tự trở lên' })
    newPassword: string;

    @IsNotEmpty({ message: 'DeviceId là bắt buộc để quản lý phiên' })
    @IsString()
    deviceId: string;
}