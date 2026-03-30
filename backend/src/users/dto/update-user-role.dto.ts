import { IsEnum, IsNotEmpty } from 'class-validator';
import { Role } from '@prisma/client';

export class UpdateUserRoleDto {
    @IsEnum(Role, { message: 'Vai trò không hợp lệ. Chỉ hỗ trợ: ADMIN, STAFF, USER' })
    @IsNotEmpty({ message: 'Vai trò là bắt buộc' })
    role: Role;
}
