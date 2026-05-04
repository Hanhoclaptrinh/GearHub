import { IsArray, IsInt, IsNotEmpty, IsString, Min, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class SyncCartItemDto {
    @IsString()
    @IsNotEmpty()
    variantId: string;

    @IsInt()
    @Min(1)
    quantity: number;
}

export class SyncCartDto {
    @IsArray()
    @ValidateNested({ each: true })
    @Type(() => SyncCartItemDto)
    items: SyncCartItemDto[];
}