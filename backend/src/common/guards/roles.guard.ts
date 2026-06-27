import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Role } from '@prisma/client';
import { ROLES_KEY } from 'src/common/decorators/roles.decorator';

@Injectable()
export class RolesGuard implements CanActivate {
    constructor(private reflector: Reflector) { }

    canActivate(context: ExecutionContext): boolean {
        // trích xuất danh sách các role được yêu cầu từ Decorator @Roles()
        const requiredRoles = this.reflector.getAllAndOverride<Role[]>(ROLES_KEY, [
            context.getHandler(),
            context.getClass(),
        ]);
        // cho phép truy cập nếu API không yêu cầu phân quyền cụ thể
        if (!requiredRoles) {
            return true;
        }
        // lấy thông tin người dùng đã được xác thực từ HTTP Request
        const { user } = context.switchToHttp().getRequest();
        // kiểm tra role của người dùng có trùng khớp với role được yêu cầu không
        const hasRole = requiredRoles.some((role) => user.role === role);
        if (!hasRole) {
            throw new ForbiddenException('Bạn không có quyền truy cập tính năng này');
        }
        return true;
    }
}