import {
    ArrayNotEmpty,
    IsArray,
    IsString,
} from 'class-validator';

export class ReorderToCartDto {
    @IsArray()
    @ArrayNotEmpty()
    @IsString({ each: true })
    orderItemIds: string[];
}