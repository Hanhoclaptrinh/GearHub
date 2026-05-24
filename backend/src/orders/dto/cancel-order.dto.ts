import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class CancelOrderDto {
    @IsString()
    @IsNotEmpty({ message: 'Lý do hủy đơn không được để trống' })
    @MaxLength(150, { message: 'Lý do hủy đơn tối đa 150 ký tự' })
    reason: string;
}
