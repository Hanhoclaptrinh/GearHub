import { Type } from 'class-transformer';
import { IsArray, IsNotEmpty, IsUUID, IsDate } from 'class-validator';

export class UpdateFlashSaleTimeBulkDto {
    @IsArray({ message: 'Danh sách ID phải là một mảng' })
    @IsUUID('4', { each: true, message: 'ID không hợp lệ' })
    @IsNotEmpty({ message: 'Danh sách ID không được để trống' })
    ids: string[];

    @IsDate({ message: 'Thời gian bắt đầu không hợp lệ' })
    @Type(() => Date)
    @IsNotEmpty({ message: 'Thời gian bắt đầu không được để trống' })
    startsAt: Date;

    @IsDate({ message: 'Thời gian kết thúc không hợp lệ' })
    @Type(() => Date)
    @IsNotEmpty({ message: 'Thời gian kết thúc không được để trống' })
    expiresAt: Date;
}
