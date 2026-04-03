import { Injectable } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';

@Injectable()
export class ActivityLogService {
    constructor(private prisma: PrismaService) { }

    async createLog(userId: string | null, action: string, metadata: any) {
        return this.prisma.activityLog.create({
            data: {
                userId,
                action,
                metadata: metadata || {}
            }
        });
    }

    // co the dung de hien len admin dashboard
    async findAll(page: number = 1, limit: number = 20) {
        const skip = (page - 1) * limit;

        const [data, total] = await Promise.all([
            this.prisma.activityLog.findMany({
                include: {
                    user: {
                        select: {
                            id: true,
                            email: true,
                            profile: { select: { fullName: true } }
                        }
                    }
                },
                orderBy: { createdAt: 'desc' },
                skip,
                take: limit
            }),
            this.prisma.activityLog.count()
        ]);

        return { data, total, page, lastPage: Math.ceil(total / limit) };
    }
}
