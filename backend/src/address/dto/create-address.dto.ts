import {
    IsBoolean,
    IsNotEmpty,
    IsOptional,
    IsString,
    Length,
    Matches,
    MaxLength,
} from 'class-validator';

export class CreateAddressDto {
    @IsString()
    @IsNotEmpty({ message: 'Họ tên không được để trống' })
    @MaxLength(50, { message: 'Họ tên tối đa 50 ký tự' })
    fullName: string;

    @IsString()
    @IsNotEmpty({ message: 'Số điện thoại không được để trống' })
    @Matches(/(84|0[3|5|7|8|9])+([0-9]{8})\b/g, { message: 'Số điện thoại không hợp lệ' })
    phone: string;

    @IsString({ message: 'Tỉnh thành không được để trống' })
    @MaxLength(100)
    province: string;

    @IsString({ message: 'Quận/Huyện không được để trống' })
    @MaxLength(100)
    district: string;

    @IsString({ message: 'Xã/Phường không được để trống' })
    @MaxLength(100)
    ward: string;

    @IsString({ message: 'Vui lòng điền đầy đủ địa chỉ chi tiết' })
    @Length(5, 1000)
    detail: string;

    @IsOptional()
    @IsBoolean()
    isDefault?: boolean;
}