import { IsArray, IsOptional, IsString } from 'class-validator';

export class CompareProductsDto {
    @IsArray()
    @IsString({ each: true })
    productIds!: string[];

    @IsArray()
    @IsOptional()
    @IsString({ each: true })
    variantIds?: string[];
}
