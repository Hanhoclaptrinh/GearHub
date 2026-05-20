import { Transform, Type } from 'class-transformer';
import { IsEnum, IsInt, IsNotEmpty, IsNumber, IsOptional, IsString, Min, IsDate, IsBoolean } from 'class-validator';
import { VoucherType } from '@prisma/client';

export class CreateVoucherDto {
    @IsString()
    @IsNotEmpty()
    @Transform(({ value }) => (typeof value === 'string' ? value.trim().toUpperCase() : value))
    code: string;

    @IsString()
    @IsNotEmpty()
    name: string;

    @IsString()
    @IsOptional()
    description?: string;

    @IsEnum(VoucherType, { message: 'Loại ưu đãi phải là PERCENT hoặc FIXED_AMOUNT' })
    @IsNotEmpty()
    type: VoucherType;

    @IsNumber()
    @Min(1, { message: 'Giá trị ưu đãi phải lớn hơn hoặc bằng 1' })
    @IsNotEmpty()
    value: number;

    @IsNumber()
    @Min(0, { message: 'Giá trị đơn hàng tối thiểu phải lớn hơn hoặc bằng 0' })
    @IsOptional()
    minOrderAmount?: number = 0;

    @IsNumber()
    @Min(1, { message: 'Giá trị giảm tối đa phải lớn hơn 0' })
    @IsOptional()
    maxDiscountAmount?: number;

    @IsInt()
    @Min(1, { message: 'Số lượng phát hành phải lớn hơn 0' })
    @IsNotEmpty()
    quantity: number;

    @IsDate()
    @Type(() => Date)
    @IsOptional()
    startsAt?: Date;

    @IsDate()
    @Type(() => Date)
    @IsOptional()
    expiresAt?: Date;
}
