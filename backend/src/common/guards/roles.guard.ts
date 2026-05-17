import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Role } from '@prisma/client';
import { ROLES_KEY } from 'src/common/decorators/roles.decorator';

@Injectable()
export class RolesGuard implements CanActivate {
    constructor(private reflector: Reflector) { }

    canActivate(context: ExecutionContext): boolean {
        /// lay cac roles Decorator @Roles()
        const requiredRoles = this.reflector.getAllAndOverride<Role[]>(ROLES_KEY, [
            context.getHandler(),
            context.getClass(),
        ]);

        /// cho phep truy cap neu khong yeu cau role
        if (!requiredRoles) {
            return true;
        }

        /// get thong tin user tu req
        const { user } = context.switchToHttp().getRequest();

        /// check quyen user
        const hasRole = requiredRoles.some((role) => user.role === role);

        if (!hasRole) {
            throw new ForbiddenException('Bạn không có quyền truy cập tính năng này');
        }

        return true;
    }
}