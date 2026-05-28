import { IsInt, IsNotEmpty, IsString, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class AddToCartDto {
    @IsString()
    @IsNotEmpty({ message: 'variantId không được để trống' })
    variantId: string;

    @IsInt({ message: 'Số lượng phải là số nguyên' })
    @Min(1, { message: 'Số lượng tối thiểu là 1' })
    @Type(() => Number)
    quantity: number;
}