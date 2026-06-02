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

    // ghi một hành động mới vào nhật ký hoạt động
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

    /**
     * lấy danh sách các tiền tố hành động tương ứng với từng nhóm chức năng
     * dùng để gom nhóm các log liên quan lại với nhau để lọc
     */
    private getActionGroupPrefixes(actionGroup?: string) {
        const groups: Record<string, string[]> = {
            // nhóm tài khoản & hồ sơ cá nhân
            account: ['USER_', 'PROFILE_'],
            // nhóm danh mục sản phẩm, biến thể, tài nguyên, thương hiệu, phân loại
            catalog: ['PRODUCT_', 'VARIANT_', 'ASSET_', 'BRAND_', 'CATEGORY_'],
            // nhóm đơn hàng, giỏ hàng, danh sách yêu thích
            order: ['ORDER_', 'CART_', 'WISHLIST_'],
            // nhóm thanh toán
            payment: ['PAYMENT_'],
            // nhóm bảo mật
            security: ['USER_', 'PROFILE_', 'PRODUCT_', 'VARIANT_', 'ASSET_', 'BRAND_', 'CATEGORY_', 'ORDER_', 'CART_', 'WISHLIST_', 'PAYMENT_'],
        };

        return actionGroup ? groups[actionGroup] : undefined;
    }

    /**
     * xây dựng điều kiện lọc dựa trên các tham số truy vấn nhận được từ client
     * xử lý các logic tìm kiếm phức tạp: lọc theo thời gian, theo nhóm hành động, và tìm kiếm từ khóa trong metadata
     */
    private buildWhere(query: QueryActivityLogDto): Prisma.ActivityLogWhereInput {
        const { userId, search, action, actionGroup, from, to } = query;
        const actionPrefixes = this.getActionGroupPrefixes(actionGroup);
        const andConditions: Prisma.ActivityLogWhereInput[] = [];

        // lọc theo id người dùng cụ thể
        if (userId) andConditions.push({ userId });

        // lọc theo hành động
        if (action) andConditions.push({ action });

        // lọc theo nhóm hành động
        if (actionGroup === 'security' && actionPrefixes?.length) {
            andConditions.push({
                NOT: {
                    OR: actionPrefixes.map((prefix) => ({ action: { startsWith: prefix } })),
                },
            });
        } else if (actionPrefixes?.length) {
            andConditions.push({
                OR: actionPrefixes.map((prefix) => ({ action: { startsWith: prefix } })),
            });
        }

        // lọc theo khoảng thời gian
        if (from || to) {
            andConditions.push({
                createdAt: {
                    ...(from && { gte: new Date(from) }),
                    ...(to && { lte: new Date(to) }),
                },
            });
        }

        // tìm kiếm nâng cao
        if (search?.trim()) {
            const keyword = search.trim();
            andConditions.push({
                OR: [
                    { action: { contains: keyword } },

                    { metadata: { path: '$.ip', string_contains: keyword } as any },
                    { metadata: { path: '$.userAgent', string_contains: keyword } as any },

                    {
                        user: {
                            is: {
                                OR: [
                                    { email: { contains: keyword } },
                                    { role: { equals: keyword as any } },
                                    {
                                        profile: {
                                            is: {
                                                fullName: { contains: keyword },
                                            },
                                        },
                                    },
                                ],
                            },
                        },
                    },
                ],
            });
        }

        return andConditions.length ? { AND: andConditions } : {};
    }

    /**
     * truy vấn danh sách nhật ký hoạt động có phân trang và nạp kèm thông tin người dùng
     * phục vụ cho trang quản trị
     */
    async findAll(query: QueryActivityLogDto) {
        const { page = 1, limit = 20 } = query;
        const skip = (page - 1) * limit;
        const where = this.buildWhere(query);

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

    // thống kê log
    async getStats(query: QueryActivityLogDto) {
        const where = this.buildWhere(query);
        const now = new Date();
        const startOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);

        const [
            totalLogs,
            todayLogs,
            highRiskLogs,
            adminLogs,
        ] = await Promise.all([
            // Ttổng log thỏa mãn filter
            this.prisma.activityLog.count({ where }),

            // số lượng log phát sinh trong ngày hôm nay (từ 00:00:00 đến 23:59:59)
            this.prisma.activityLog.count({
                where: {
                    AND: [
                        where,
                        { createdAt: { gte: startOfToday, lte: endOfToday } },
                    ],
                },
            }),

            // số lượng log được gắn nhãn "nguy cơ cao" (hành động xóa dữ liệu, lỗi hệ thống, hoặc hủy bỏ)
            this.prisma.activityLog.count({
                where: {
                    AND: [
                        where,
                        {
                            OR: [
                                { action: { contains: 'DELETED' } },
                                { action: { contains: 'FAILED' } },
                                { action: { contains: 'CANCELLED' } },
                            ],
                        },
                    ],
                },
            }),

            // số log được admin thực hiện
            this.prisma.activityLog.count({
                where: {
                    AND: [
                        where,
                        { user: { is: { role: 'ADMIN' } } },
                    ],
                },
            }),
        ]);

        return {
            totalLogs,
            todayLogs,
            highRiskLogs,
            adminLogs,
        };
    }

    // lịch sử hoạt động của một user
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

    // cron job auto dọn các log theo định kỳ vào mỗi giữa đêm
    @Cron(CronExpression.EVERY_DAY_AT_MIDNIGHT)
    async handleLogCleanup() {
        const retentionDays = 90; // 90 ngày

        const result = await this.deleteOldLogs(retentionDays);
        if (result.count > 0) {
            this.logger.log(`[Scheduled Task] Đã dọn dẹp ${result.count} bản ghi log cũ (>${retentionDays} ngày)`);
        }
    }

    async deleteOldLogs(olderThanDays: number = 90) {
        const cutoff = new Date();
        const olderThanMs = olderThanDays * 24 * 60 * 60 * 1000;
        cutoff.setTime(cutoff.getTime() - olderThanMs);

        return this.prisma.activityLog.deleteMany({
            where: { createdAt: { lt: cutoff } },
        });
    }
}
