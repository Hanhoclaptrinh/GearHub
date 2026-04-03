import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { ActivityLogService } from "src/activity-log/activity-log.service";

@Injectable()
export class ActivityLogInterceptor implements NestInterceptor {
    constructor(private activityLogService: ActivityLogService) { }

    intercept(context: ExecutionContext, next: CallHandler<any>): Observable<any> | Promise<Observable<any>> {
        const req = context.switchToHttp().getRequest();
        const { method, url, user, body } = req;

        // log cac hanh dong lam thay doi du lieu
        const logMethods = ['POST', 'PATCH', 'DELETE'];
        if (!logMethods.includes(method)) {
            return next.handle();
        }

        return next.handle().pipe(
            tap(async () => {
                // userid
                const userId = user?.userId || user?.id || null;

                // tao ten hanh dong
                const resource = url.split('/')[2]?.toUpperCase() || 'SYSTEM';
                const actionMap = { POST: 'CREATE', PATCH: 'UPDATE', DELETE: 'DELETE' };
                const action = `${actionMap[method]}_${resource}`;

                // loai bo cac field khong can xuat hien tren log
                const safeBody = { ...body };
                const sensitiveFields = ['password', 'confirmPassword', 'oldPassword', 'newPassword'];
                sensitiveFields.forEach(field => delete safeBody[field]);

                // ghi vao db
                await this.activityLogService.createLog(userId, action, {
                    url,
                    method,
                    payload: safeBody,
                    ip: req.ip
                });
            })
        );
    }
}