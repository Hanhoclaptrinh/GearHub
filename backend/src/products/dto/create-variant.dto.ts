import { IsNotEmpty, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class CreateVariantDto {
    @IsString()
    @IsNotEmpty({ message: 'Tên biến thể không được để trống' })
    name: string;

    @IsString()
    @IsNotEmpty({ message: 'SKU không được để trống' })
    sku: string;

    @IsNumber({}, { message: 'Giá phải là số' })
    @Min(0)
    price: number;

    @IsNumber({}, { message: 'Số lượng kho phải là số' })
    @Min(0)
    stock: number;

    @IsOptional()
    @IsString()
    attributes?: string;
}