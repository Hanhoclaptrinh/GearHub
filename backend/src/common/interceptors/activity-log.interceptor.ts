import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { ActivityLogService } from "src/activity-log/activity-log.service";
import { ActivityActionType } from "src/common/constants/activity-log.constants";
import { LOG_ACTIVITY_KEY } from '../decorators/log-activity.decorator';

@Injectable()
export class ActivityLogInterceptor implements NestInterceptor {
    constructor(
        private activityLogService: ActivityLogService,
        private reflector: Reflector
    ) { }

    intercept(context: ExecutionContext, next: CallHandler<any>): Observable<any> | Promise<Observable<any>> {
        const action = this.reflector.getAllAndOverride<ActivityActionType>(LOG_ACTIVITY_KEY, [
            context.getHandler(),
            context.getClass(),
        ]);

        /// neu khong co decorator thi bo qua khong log
        /// tiep can theo huong explicit
        if (!action) {
            return next.handle();
        }

        const req = context.switchToHttp().getRequest();
        const { method, url, user, body } = req;

        return next.handle().pipe(
            tap(async () => {
                try {
                    const userId = user?.userId || user?.id || null;

                    /// loai bo field nhay cam
                    const safeBody = { ...body };
                    const sensitiveFields = ['password', 'confirmPassword', 'oldPassword', 'newPassword', 'token'];
                    sensitiveFields.forEach(field => delete safeBody[field]);

                    /// ghi log
                    await this.activityLogService.createLog(userId, action, {
                        url,
                        method,
                        payload: safeBody,
                        ip: req.ip || req.headers['x-forwarded-for']
                    });
                } catch (error) {
                    console.error('ActivityLogInterceptor Error:', error.message);
                }
            })
        );
    }
}
