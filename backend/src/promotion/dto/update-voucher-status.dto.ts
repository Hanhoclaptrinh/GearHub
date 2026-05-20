import { IsBoolean, IsNotEmpty } from 'class-validator';

export class UpdateVoucherStatusDto {
    @IsBoolean({ message: 'Trạng thái hoạt động phải là boolean' })
    @IsNotEmpty()
    isActive: boolean;
}
