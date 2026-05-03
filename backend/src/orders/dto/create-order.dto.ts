import { Type } from 'class-transformer';
import { IsNotEmpty, IsOptional, IsString, IsArray, IsInt, MIN, Min, ValidateNested } from 'class-validator';

class OrderItemDto {
    @IsString()
    @IsNotEmpty()
    variantId: string;

    @IsInt()
    @Min(1)
    @IsNotEmpty()
    quantity: number;
}

export class CreateOrderDto {
    @IsString()
    @IsNotEmpty()
    receiverName: string;

    @IsString()
    @IsNotEmpty()
    receiverPhone: string;

    @IsString()
    @IsNotEmpty()
    shippingAddress: string;

    @IsString()
    @IsOptional()
    note?: string;

    @IsString()
    @IsOptional()
    paymentMethod?: any;

    @IsArray()
    @ValidateNested({ each: true })
    @Type(() => OrderItemDto)
    items: OrderItemDto[];
}