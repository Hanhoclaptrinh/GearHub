import { IsNotEmpty, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class UpdateVariantDto {
    @IsString()
    @IsOptional()
    name?: string;

    @IsString()
    @IsOptional()
    sku?: string;

    @IsOptional()
    @Min(0)
    price?: number;

    @IsOptional()
    @Min(0)
    stock?: number;

    @IsOptional()
    @IsString()
    attributes?: string;
}