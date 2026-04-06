import { Injectable, Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from 'src/prisma/prisma.service';
import { ActivityActionType } from 'src/common/constants/activity-log.constants';
import { QueryActivityLogDto } from './dto/query-activity-log.dto';
import { Cron, CronExpression } from '@nestjs/schedule';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class ActivityLogService {
    private readonly logger = new Logger(ActivityLogService.name);
    constructor(
        private readonly prisma: PrismaService,
        private readonly configService: ConfigService
    ) { }

    // ghi log hanh dong cua user
    // userId = null neu la hanh dong he thong hoac chua dang nhap
    async createLog(
        userId: string | null,
        action: ActivityActionType,
        metadata?: Record<string, any>,
    ) {
        return this.prisma.activityLog.create({
            data: {
                userId,
                action,
                metadata: metadata ?? {},
            },
        });
    }

    // lay danh sach log cho admin dashboard
    // ho tro filter theo userId, action, khoang thoi gian va phan trang
    async findAll(query: QueryActivityLogDto) {
        const { page = 1, limit = 20, userId, action, from, to } = query;
        const skip = (page - 1) * limit;

        const where: Prisma.ActivityLogWhereInput = {
            ...(userId && { userId }),
            ...(action && { action }),
            ...(from || to
                ? {
                    createdAt: {
                        ...(from && { gte: new Date(from) }),
                        ...(to && { lte: new Date(to) }),
                    },
                }
                : {}),
        };

        const [data, total] = await Promise.all([
            this.prisma.activityLog.findMany({
                where,
                include: {
                    user: {
                        select: {
                            id: true,
                            email: true,
                            role: true,
                            profile: {
                                select: { fullName: true, avatarUrl: true },
                            },
                        },
                    },
                },
                orderBy: { createdAt: 'desc' },
                skip,
                take: limit,
            }),
            this.prisma.activityLog.count({ where }),
        ]);

        return {
            data,
            meta: {
                total,
                page,
                limit,
                lastPage: Math.ceil(total / limit),
            },
        };
    }

    // lay lich su hoat dong cua user
    async findByUser(userId: string, page: number = 1, limit: number = 20) {
        const skip = (page - 1) * limit;

        const [data, total] = await Promise.all([
            this.prisma.activityLog.findMany({
                where: { userId },
                orderBy: { createdAt: 'desc' },
                skip,
                take: limit,
            }),
            this.prisma.activityLog.count({ where: { userId } }),
        ]);

        return {
            data,
            meta: { total, page, limit, lastPage: Math.ceil(total / limit) },
        };
    }

    @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
    async handleLogCleanup() {
        const retentionDays = Number(this.configService.get<number>('ACTIVITY_LOG_RETENTION_DAYS', 90));

        const result = await this.deleteOldLogs(retentionDays);
        if (result.count > 0) {
            this.logger.log(`[Scheduled Task] Đã dọn dẹp ${result.count} bản ghi log cũ (>${retentionDays} ngày)`);
        }
    }

    // xoa log cu hon N ngay
    async deleteOldLogs(olderThanDays: number = 90) {
        const cutoff = new Date();
        const olderThanMs = olderThanDays * 24 * 60 * 60 * 1000;
        cutoff.setTime(cutoff.getTime() - olderThanMs);

        return this.prisma.activityLog.deleteMany({
            where: { createdAt: { lt: cutoff } },
        });
    }
}
