import { IsBooleanString, IsNotEmpty, IsNumberString, IsOptional, IsString, IsUUID } from 'class-validator';

export class UpdateProductDto {
    @IsString()
    @IsOptional()
    name?: string;

    @IsString()
    @IsOptional()
    description?: string;

    @IsString()
    @IsOptional()
    tagline?: string;

    @IsNumberString({}, { message: 'Giá phải là một dãy số' })
    @IsOptional()
    price?: string;

    @IsNumberString()
    @IsOptional()
    stock?: string;

    @IsUUID('4', { message: 'CategoryId không hợp lệ' })
    @IsOptional()
    categoryId?: string;

    @IsUUID('4', { message: 'BrandId không hợp lệ' })
    @IsOptional()
    brandId?: string;

    @IsString()
    @IsOptional()
    metadata?: string;

    @IsString()
    @IsOptional()
    thumbnailUrl?: string;

    @IsOptional()
    @IsBooleanString()
    isFeatured?: string;

    @IsOptional()
    @IsBooleanString()
    isActive?: string;

    @IsString()
    @IsOptional()
    sku?: string;

    @IsString()
    @IsOptional()
    attributes?: string;

    @IsString()
    @IsOptional()
    variants?: string;

    @IsString()
    @IsOptional()
    primaryIndex?: string;

    @IsString()
    @IsOptional()
    attributeConfig?: string;
}