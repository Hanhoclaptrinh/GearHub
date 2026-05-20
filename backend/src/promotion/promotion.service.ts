import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';
import { CreateVoucherDto } from './dto/create-voucher.dto';
import { UpdateVoucherDto } from './dto/update-voucher.dto';
import { UpdateVoucherStatusDto } from './dto/update-voucher-status.dto';
import { VoucherType, PointTransactionType, Prisma } from '@prisma/client';

@Injectable()
export class PromotionService {
    constructor(private prisma: PrismaService) { }

    // quản lý vouchers
    async createVoucher(dto: CreateVoucherDto) {
        const existing = await this.prisma.voucher.findUnique({
            where: { code: dto.code }
        });
        if (existing) {
            throw new BadRequestException(`Mã ưu đãi '${dto.code}' đã tồn tại`);
        }

        if (dto.value <= 0) {
            throw new BadRequestException('Giá trị giảm phải lớn hơn 0');
        }

        // chặn phần trăm (0 < v <= 100)
        if (dto.type === VoucherType.PERCENT && dto.value > 100) {
            throw new BadRequestException('Giá trị giảm phần trăm không được vượt quá 100%');
        }

        // chặn tạo voucher hết hạn từ trước
        if (dto.expiresAt && new Date(dto.expiresAt) <= new Date()) {
            throw new BadRequestException('Thời gian hết hạn phải lớn hơn thời gian hiện tại');
        }

        // validate thời gian bđ - kt
        if (dto.startsAt && dto.expiresAt && new Date(dto.startsAt) >= new Date(dto.expiresAt)) {
            throw new BadRequestException('Thời gian bắt đầu phải trước thời gian hết hạn');
        }

        return this.prisma.voucher.create({
            data: {
                code: dto.code,
                name: dto.name,
                description: dto.description,
                type: dto.type,
                value: new Prisma.Decimal(dto.value),
                minOrderAmount: new Prisma.Decimal(dto.minOrderAmount || 0),
                maxDiscountAmount: dto.maxDiscountAmount ? new Prisma.Decimal(dto.maxDiscountAmount) : null,
                quantity: dto.quantity,
                startsAt: dto.startsAt || null,
                expiresAt: dto.expiresAt || null,
                isActive: true
            }
        });
    }

    async findAllVouchersAdmin(query: { page?: number; limit?: number; search?: string }) {
        const { page = 1, limit = 10, search } = query;
        const skip = (page - 1) * limit;

        const where: Prisma.VoucherWhereInput = search
            ? {
                OR: [
                    { code: { contains: search } },
                    { name: { contains: search } }
                ]
            }
            : {};

        const [data, total] = await Promise.all([
            this.prisma.voucher.findMany({
                where,
                skip,
                take: Number(limit),
                orderBy: { createdAt: 'desc' }
            }),
            this.prisma.voucher.count({ where })
        ]);

        return {
            data,
            meta: {
                total,
                page: Number(page),
                limit: Number(limit),
                lastPage: Math.ceil(total / Number(limit))
            }
        };
    }

    async findVoucherByIdAdmin(id: string) {
        const voucher = await this.prisma.voucher.findUnique({
            where: { id }
        });
        if (!voucher) {
            throw new NotFoundException('Không tìm thấy mã ưu đãi này');
        }
        return voucher;
    }

    async updateVoucher(id: string, dto: UpdateVoucherDto) {
        const voucher = await this.findVoucherByIdAdmin(id);

        if (dto.code && dto.code !== voucher.code) {
            const existing = await this.prisma.voucher.findUnique({
                where: { code: dto.code }
            });
            if (existing) {
                throw new BadRequestException(`Mã ưu đãi '${dto.code}' đã tồn tại`);
            }
        }

        const type = dto.type || voucher.type;
        const value = dto.value !== undefined ? dto.value : Number(voucher.value);

        if (type === VoucherType.PERCENT && value > 100) {
            throw new BadRequestException('Giá trị giảm phần trăm không được vượt quá 100%');
        }

        const startsAt = dto.startsAt !== undefined ? dto.startsAt : voucher.startsAt;
        const expiresAt = dto.expiresAt !== undefined ? dto.expiresAt : voucher.expiresAt;

        if (startsAt && expiresAt) {
            if (new Date(startsAt) >= new Date(expiresAt)) {
                throw new BadRequestException('Thời gian bắt đầu phải trước thời gian hết hạn');
            }
        }

        return this.prisma.voucher.update({
            where: { id },
            data: {
                code: dto.code,
                name: dto.name,
                description: dto.description,
                type: dto.type,
                value: dto.value !== undefined ? new Prisma.Decimal(dto.value) : undefined,
                minOrderAmount: dto.minOrderAmount !== undefined ? new Prisma.Decimal(dto.minOrderAmount) : undefined,
                maxDiscountAmount: dto.maxDiscountAmount !== undefined ? (dto.maxDiscountAmount ? new Prisma.Decimal(dto.maxDiscountAmount) : null) : undefined,
                quantity: dto.quantity,
                startsAt: dto.startsAt !== undefined ? (dto.startsAt || null) : undefined,
                expiresAt: dto.expiresAt !== undefined ? (dto.expiresAt || null) : undefined
            }
        });
    }

    async updateVoucherStatus(id: string, statusDto: UpdateVoucherStatusDto) {
        await this.findVoucherByIdAdmin(id);

        return this.prisma.voucher.update({
            where: { id },
            data: { isActive: statusDto.isActive }
        });
    }

    async deleteVoucher(id: string) {
        await this.findVoucherByIdAdmin(id);

        return this.prisma.voucher.update({
            where: { id },
            data: { isActive: false }
        });
    }

    // client
    async getAvailableVouchers(userId: string) {
        const now = new Date();

        const vouchers = await this.prisma.voucher.findMany({
            where: {
                isActive: true,
                OR: [
                    { startsAt: null },
                    { startsAt: { lte: now } }
                ],
                AND: [
                    {
                        OR: [
                            { expiresAt: null },
                            { expiresAt: { gte: now } }
                        ]
                    }
                ],
                userVouchers: {
                    none: { userId }
                }
            },
            orderBy: { createdAt: 'desc' }
        });

        return vouchers.filter(v => v.claimedCount < v.quantity);
    }

    // lấy danh sách tất cả vc hợp lệ
    async getMyVouchers(userId: string) {
        const now = new Date();

        const userVouchers = await this.prisma.userVoucher.findMany({
            where: {
                userId,
                usedAt: null,
                voucher: {
                    isActive: true,
                    OR: [
                        { expiresAt: null },
                        { expiresAt: { gte: now } }
                    ]
                }
            },
            include: {
                voucher: true
            },
            orderBy: { claimedAt: 'desc' }
        });

        return userVouchers.map(uv => uv.voucher);
    }

    async claimVoucher(userId: string, voucherId: string) {
        return this.prisma.$transaction(async (tx) => {
            const vouchers = await tx.$queryRaw<any[]>`
                SELECT id, is_active as isActive, starts_at as startsAt, expires_at as expiresAt, quantity, claimed_count as claimedCount
                FROM vouchers 
                WHERE id = ${voucherId} 
                FOR UPDATE
                LIMIT 1;
            `;

            if (!vouchers || vouchers.length === 0) {
                throw new NotFoundException('Không tìm thấy mã ưu đãi');
            }

            const voucher = vouchers[0];

            if (!voucher.isActive) {
                throw new BadRequestException('Mã ưu đãi không còn hoạt động');
            }

            const now = new Date();
            if (voucher.startsAt && new Date(voucher.startsAt) > now) {
                throw new BadRequestException('Mã ưu đãi chưa được phép sử dụng');
            }

            if (voucher.expiresAt && new Date(voucher.expiresAt) < now) {
                throw new BadRequestException('Mã ưu đãi đã hết hạn sử dụng');
            }

            if (voucher.claimedCount >= voucher.quantity) {
                throw new BadRequestException('Mã ưu đãi đã hết lượt nhận');
            }

            const existingClaim = await tx.userVoucher.findUnique({
                where: {
                    userId_voucherId: { userId, voucherId }
                }
            });

            if (existingClaim) {
                throw new BadRequestException('Bạn đã nhận mã ưu đãi này rồi');
            }

            await tx.voucher.update({
                where: { id: voucherId },
                data: { claimedCount: { increment: 1 } }
            });

            return tx.userVoucher.create({
                data: {
                    userId,
                    voucherId,
                    claimedAt: now
                },
                include: {
                    voucher: true
                }
            });
        });
    }

    async getMyRewardPoints(userId: string) {
        const user = await this.prisma.user.findUnique({
            where: { id: userId },
            select: { rewardPoints: true, totalSpent: true }
        });
        if (!user) {
            throw new NotFoundException('Không tìm thấy tài khoản người dùng');
        }
        return {
            rewardPoints: user.rewardPoints,
            totalSpent: Number(user.totalSpent)
        };
    }

    async getMyPointTransactions(userId: string, query: { page?: number; limit?: number }) {
        const { page = 1, limit = 10 } = query;
        const skip = (page - 1) * limit;

        const [data, total] = await Promise.all([
            this.prisma.pointTransaction.findMany({
                where: { userId },
                skip,
                take: Number(limit),
                orderBy: { createdAt: 'desc' }
            }),
            this.prisma.pointTransaction.count({
                where: { userId }
            })
        ]);

        return {
            data,
            meta: {
                total,
                page: Number(page),
                limit: Number(limit),
                lastPage: Math.ceil(total / Number(limit))
            }
        };
    }

    async validateVoucherForCheckout(userId: string, voucherId: string, subtotal: number) {
        const userVoucher = await this.prisma.userVoucher.findUnique({
            where: {
                userId_voucherId: { userId, voucherId }
            },
            include: {
                voucher: true
            }
        });

        if (!userVoucher) {
            throw new BadRequestException('Bạn chưa nhận mã ưu đãi này');
        }

        if (userVoucher.usedAt) {
            throw new BadRequestException('Mã ưu đãi này đã được sử dụng');
        }

        const voucher = userVoucher.voucher;

        if (!voucher.isActive) {
            throw new BadRequestException('Mã ưu đãi không còn hoạt động');
        }

        const now = new Date();
        if (voucher.expiresAt && voucher.expiresAt < now) {
            throw new BadRequestException('Mã ưu đãi đã hết hạn sử dụng');
        }

        if (voucher.startsAt && voucher.startsAt > now) {
            throw new BadRequestException('Mã ưu đãi chưa được phép sử dụng');
        }

        if (subtotal < Number(voucher.minOrderAmount)) {
            throw new BadRequestException(
                `Giá trị đơn hàng (${subtotal.toLocaleString('vi-VN')}đ) chưa đạt mức tối thiểu (${Number(voucher.minOrderAmount).toLocaleString('vi-VN')}đ) để áp dụng mã này`
            );
        }

        return voucher;
    }

    calculateVoucherDiscount(voucher: any, subtotal: number): number {
        let discount = 0;

        if (voucher.type === VoucherType.PERCENT) {
            discount = subtotal * (Number(voucher.value) / 100);
            if (voucher.maxDiscountAmount) {
                discount = Math.min(discount, Number(voucher.maxDiscountAmount));
            }
        } else if (voucher.type === VoucherType.FIXED_AMOUNT) {
            discount = Number(voucher.value);
        }

        return Math.min(discount, subtotal);
    }

    async validatePointsForCheckout(userId: string, pointsToUse: number, subtotal: number) {
        if (pointsToUse <= 0) {
            throw new BadRequestException('Số điểm sử dụng phải lớn hơn 0');
        }

        const user = await this.prisma.user.findUnique({
            where: { id: userId },
            select: { rewardPoints: true }
        });

        if (!user) {
            throw new NotFoundException('Không tìm thấy tài khoản người dùng');
        }

        if (user.rewardPoints < pointsToUse) {
            throw new BadRequestException(
                `Bạn không đủ điểm thưởng. Điểm hiện có: ${user.rewardPoints}, điểm cần dùng: ${pointsToUse}`
            );
        }

        const pointsDiscount = this.calculatePointsDiscount(pointsToUse, subtotal);
        if (pointsDiscount <= 0) {
            throw new BadRequestException('Số điểm quy đổi phải đạt tối thiểu 100 điểm (10,000 VND)');
        }

        return pointsDiscount;
    }

    calculatePointsDiscount(
    pointsToUse: number, 
    subtotal: number, 
    maxDiscountPercent: number = 0.2 // tối đa 20% giá trị đơn
    ): number {
        const discount = Math.floor(pointsToUse / 100) * 10000;

        const maxAllowedDiscount = subtotal * maxDiscountPercent;

        return Math.min(discount, maxAllowedDiscount, subtotal);
    }

    async markVoucherUsed(userId: string, voucherId: string, orderId: string, tx: Prisma.TransactionClient) {
        const userVoucher = await tx.userVoucher.findUnique({
            where: {
                userId_voucherId: { userId, voucherId }
            }
        });

        if (!userVoucher) {
            throw new BadRequestException('Không tìm thấy thông tin nhận mã ưu đãi');
        }

        await tx.userVoucher.update({
            where: {
                userId_voucherId: { userId, voucherId }
            },
            data: {
                usedAt: new Date(),
                orderId: orderId
            }
        });

        await tx.voucher.update({
            where: { id: voucherId },
            data: {
                usedCount: { increment: 1 }
            }
        });
    }

    async redeemPoints(userId: string, orderId: string, points: number, tx: Prisma.TransactionClient) {
        const user = await tx.user.findUnique({
            where: { id: userId },
            select: { rewardPoints: true }
        });

        if (!user || user.rewardPoints < points) {
            throw new BadRequestException('Người dùng không đủ điểm để thanh toán');
        }

        const updatedUser = await tx.user.update({
            where: { id: userId },
            data: {
                rewardPoints: { decrement: points }
            }
        });

        await tx.pointTransaction.create({
            data: {
                userId,
                orderId,
                type: PointTransactionType.REDEEM,
                points: -points,
                balanceAfter: updatedUser.rewardPoints,
                description: `Sử dụng ${points} điểm cho đơn hàng #${orderId.slice(0, 8)}`
            }
        });
    }

    async earnPointsFromDeliveredOrder(orderId: string, tx: Prisma.TransactionClient) {
        // chặn nhận trùng lặp
        const existingEarn = await tx.pointTransaction.findFirst({
            where: {
                orderId,
                type: PointTransactionType.EARN
            }
        });

        if (existingEarn) {
            return;
        }

        const order = await tx.order.findUnique({
            where: { id: orderId }
        });

        if (!order) {
            throw new NotFoundException('Không tìm thấy đơn hàng để cộng điểm thưởng');
        }

        const earnedPoints = Math.floor(Number(order.totalAmount) / 1000);
        if (earnedPoints <= 0) return;

        const updatedUser = await tx.user.update({
            where: { id: order.userId },
            data: {
                rewardPoints: { increment: earnedPoints },
                totalSpent: { increment: order.totalAmount }
            }
        });

        await tx.pointTransaction.create({
            data: {
                userId: order.userId,
                orderId,
                type: PointTransactionType.EARN,
                points: earnedPoints,
                balanceAfter: updatedUser.rewardPoints,
                description: `Tích ${earnedPoints} điểm từ đơn hàng #${orderId.slice(0, 8)}`
            }
        });
    }
}
