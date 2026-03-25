import { IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateBrandDto {
    @IsString()
    @IsOptional()
    @MaxLength(100, { message: 'Tên thương hiệu tối đa 100 ký tự' })
    name?: string;

    @IsString()
    @IsOptional()
    description?: string;
}