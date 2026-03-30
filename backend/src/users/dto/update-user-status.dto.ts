import { IsEnum, IsNotEmpty } from 'class-validator';
import { UserStatus } from '@prisma/client';

export class UpdateUserStatusDto {
    @IsEnum(UserStatus, { message: 'Trạng thái không hợp lệ. Chỉ hỗ trợ: ACTIVE, BANNED, INACTIVE' })
    @IsNotEmpty({ message: 'Trạng thái là bắt buộc' })
    status: UserStatus;
}
