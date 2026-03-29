import { IsOptional, IsString, IsUrl, MaxLength } from 'class-validator';

export class UpdateBrandDto {
    @IsString()
    @IsOptional()
    @MaxLength(100, { message: 'Tên thương hiệu tối đa 100 ký tự' })
    name?: string;

    @IsUrl({}, { message: 'Logo URL phải là một đường dẫn URL hợp lệ' })
    @IsOptional()
    logoUrl?: string;

    @IsOptional()
    file?: any;
}