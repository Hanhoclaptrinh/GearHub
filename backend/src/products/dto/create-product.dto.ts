import { IsNotEmpty, IsNumberString, IsOptional, IsString, IsUUID, IsBooleanString } from 'class-validator';

export class CreateProductDto {
    @IsString()
    @IsNotEmpty({ message: 'Tên sản phẩm không được để trống' })
    name: string;

    @IsOptional()
    description?: string;

    @IsString()
    @IsOptional()
    tagline?: string;

    @IsString()
    @IsOptional()
    sku?: string;

    @IsNumberString({}, { message: 'Giá phải là một dãy số' })
    @IsOptional()
    price?: string;

    @IsNumberString()
    @IsOptional()
    stock?: string;

    @IsOptional()
    @IsString()
    attributes?: string;

    @IsUUID('4', { message: 'CategoryId không hợp lệ' })
    @IsNotEmpty()
    categoryId: string;

    @IsUUID('4', { message: 'BrandId không hợp lệ' })
    @IsNotEmpty()
    brandId: string;

    @IsString()
    @IsOptional()
    metadata?: string;

    @IsString()
    @IsOptional()
    thumbnailUrl?: string;

    @IsOptional()
    @IsString()
    variants?: string;

    @IsOptional()
    primaryIndex?: string;

    @IsOptional()
    @IsString()
    attributeConfig?: string;

    @IsOptional()
    @IsBooleanString()
    isVault?: string;

    @IsOptional()
    @IsString()
    vaultSpecs?: string;

    @IsOptional()
    @IsString()
    commonSpecs?: string;
}