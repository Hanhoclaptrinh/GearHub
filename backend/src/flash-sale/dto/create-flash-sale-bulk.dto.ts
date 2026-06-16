import { IsNotEmpty, IsNumber, IsUUID, Min, IsDate, IsArray, IsEnum, ArrayNotEmpty } from 'class-validator';
import { Type } from 'class-transformer';

export enum DiscountType {
    PERCENT = 'PERCENT',
    FIXED_AMOUNT = 'FIXED_AMOUNT',
    PRICE = 'PRICE'
}

export class CreateFlashSaleBulkDto {
    @IsArray({ message: 'Danh sách ID biến thể phải là mảng' })
    @ArrayNotEmpty({ message: 'Vui lòng chọn ít nhất một biến thể sản phẩm' })
    @IsUUID('4', { each: true, message: 'ID biến thể sản phẩm không hợp lệ' })
    productVariantIds: string[];

    @IsEnum(DiscountType, { message: 'Hình thức giảm giá không hợp lệ' })
    @IsNotEmpty({ message: 'Hình thức giảm giá không được để trống' })
    discountType: DiscountType;

    @IsNumber({}, { message: 'Giá trị giảm giá phải là số' })
    @Min(0, { message: 'Giá trị giảm giá không được nhỏ hơn 0' })
    @IsNotEmpty({ message: 'Giá trị giảm giá không được để trống' })
    discountValue: number;

    @IsNumber({}, { message: 'Giới hạn tồn kho phải là số' })
    @Min(1, { message: 'Giới hạn tồn kho phải lớn hơn hoặc bằng 1' })
    @IsNotEmpty({ message: 'Giới hạn tồn kho không được để trống' })
    stockLimit: number;

    @IsDate({ message: 'Thời gian bắt đầu không hợp lệ' })
    @Type(() => Date)
    @IsNotEmpty({ message: 'Thời gian bắt đầu không được để trống' })
    startsAt: Date;

    @IsDate({ message: 'Thời gian kết thúc không hợp lệ' })
    @Type(() => Date)
    @IsNotEmpty({ message: 'Thời gian kết thúc không được để trống' })
    expiresAt: Date;
}
