import { IsOptional, IsString, IsUrl, MaxLength, Matches, IsEmail, IsDateString, IsEnum } from "class-validator";
import { Gender } from "@prisma/client";

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
    @Matches(/^(84|0[35789])([0-9]{8})$/, { message: 'Số điện thoại không hợp lệ' })
    phone?: string;

    @IsUrl({}, { message: 'Avatar phải là một đường dẫn URL hợp lệ' })
    @IsOptional()
    avatarUrl?: string;

    @IsDateString({}, { message: 'Ngày sinh không hợp lệ' })
    @IsOptional()
    dateOfBirth?: string;

    @IsEnum(Gender, { message: 'Giới tính không hợp lệ' })
    @IsOptional()
    gender?: Gender;

}
