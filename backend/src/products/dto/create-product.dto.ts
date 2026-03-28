import { IsNotEmpty, IsNumberString, IsOptional, IsString, IsUUID, IsJSON } from 'class-validator';

export class CreateProductDto {
    @IsString()
    @IsNotEmpty({ message: 'Tên sản phẩm không được để trống' })
    name: string;

    @IsString()
    @IsOptional()
    description?: string;

    @IsString()
    @IsNotEmpty({ message: 'Mã SKU không được để trống' })
    sku: string;

    @IsNumberString({}, { message: 'Giá phải là một dãy số' })
    @IsNotEmpty()
    price: string;

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
}