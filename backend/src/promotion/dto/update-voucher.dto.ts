import { Transform, Type } from 'class-transformer';
import { IsEnum, IsInt, IsNumber, IsOptional, IsString, Min, IsDate, IsBoolean } from 'class-validator';
import { VoucherType } from '@prisma/client';

export class UpdateVoucherDto {
    @IsString()
    @IsOptional()
    @Transform(({ value }) => (typeof value === 'string' ? value.trim().toUpperCase() : value))
    code?: string;

    @IsString()
    @IsOptional()
    name?: string;

    @IsString()
    @IsOptional()
    description?: string;

    @IsEnum(VoucherType, { message: 'Loại ưu đãi phải là PERCENT hoặc FIXED_AMOUNT' })
    @IsOptional()
    type?: VoucherType;

    @IsNumber()
    @Min(1, { message: 'Giá trị ưu đãi phải lớn hơn hoặc bằng 1' })
    @IsOptional()
    value?: number;

    @IsNumber()
    @Min(0, { message: 'Giá trị đơn hàng tối thiểu phải lớn hơn hoặc bằng 0' })
    @IsOptional()
    minOrderAmount?: number;

    @IsNumber()
    @Min(1, { message: 'Giá trị giảm tối đa phải lớn hơn 0' })
    @IsOptional()
    maxDiscountAmount?: number;

    @IsInt()
    @Min(1, { message: 'Số lượng phát hành phải lớn hơn 0' })
    @IsOptional()
    quantity?: number;

    @IsDate()
    @Type(() => Date)
    @IsOptional()
    startsAt?: Date;

    @IsDate()
    @Type(() => Date)
    @IsOptional()
    expiresAt?: Date;

    @IsBoolean()
    @IsOptional()
    isActive?: boolean;
}
