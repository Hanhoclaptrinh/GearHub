import { IsOptional, IsString, IsUrl, IsObject, MaxLength, Matches, IsEmail } from "class-validator";

export class UpdateProfileDto {
    @IsEmail({}, { message: 'Email không hợp lệ' })
    @IsOptional()
    email?: string;

    @IsString()
    @IsOptional()
    @MaxLength(50, { message: 'Họ tên tối đa 50 ký tự' })
    fullName?: string;

    @IsString()
    @IsOptional()
    @Matches(/(84|0[3|5|7|8|9])+([0-9]{8})\b/g, { message: 'Số điện thoại không hợp lệ' })
    phone?: string;

    @IsString()
    @IsOptional()
    address?: string;

    @IsUrl({}, { message: 'Avatar phải là một đường dẫn URL hợp lệ' })
    @IsOptional()
    avatarUrl?: string;

    @IsObject()
    @IsOptional()
    preferences?: any;
}