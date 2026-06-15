import { Type } from 'class-transformer';
import { IsNotEmpty, IsNumber, IsUUID, Min, IsDate } from 'class-validator';

export class CreateFlashSaleProductDto {
    @IsUUID('4', { message: 'ID biến thể sản phẩm không hợp lệ' })
    @IsNotEmpty({ message: 'ID biến thể sản phẩm không được để trống' })
    productVariantId: string;

    @IsNumber({}, { message: 'Giá flash sale phải là số' })
    @Min(0, { message: 'Giá flash sale không được nhỏ hơn 0' })
    @IsNotEmpty({ message: 'Giá flash sale không được để trống' })
    flashPrice: number;

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
