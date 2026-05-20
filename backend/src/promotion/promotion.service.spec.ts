import { Test, TestingModule } from '@nestjs/testing';
import { PromotionService } from './promotion.service';
import { PrismaService } from 'src/prisma/prisma.service';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { VoucherType, PointTransactionType, Prisma } from '@prisma/client';

describe('PromotionService', () => {
    let service: PromotionService;
    let prisma: PrismaService;

    const mockPrismaService = {
        voucher: {
            findUnique: jest.fn(),
            findMany: jest.fn(),
            count: jest.fn(),
            create: jest.fn(),
            update: jest.fn(),
            updateMany: jest.fn(),
        },
        userVoucher: {
            findUnique: jest.fn(),
            findFirst: jest.fn(),
            findMany: jest.fn(),
            create: jest.fn(),
            update: jest.fn(),
        },
        pointTransaction: {
            findFirst: jest.fn(),
            findMany: jest.fn(),
            count: jest.fn(),
            create: jest.fn(),
        },
        user: {
            findUnique: jest.fn(),
            update: jest.fn(),
        },
        order: {
            findUnique: jest.fn(),
        },
        $transaction: jest.fn(),
    };

    beforeEach(async () => {
        const module: TestingModule = await Test.createTestingModule({
            providers: [
                PromotionService,
                {
                    provide: PrismaService,
                    useValue: mockPrismaService,
                },
            ],
        }).compile();

        service = module.get<PromotionService>(PromotionService);
        prisma = module.get<PrismaService>(PrismaService);

        jest.clearAllMocks();
    });

    it('should be defined', () => {
        expect(service).toBeDefined();
    });

    describe('createVoucher', () => {
        it('should throw BadRequestException if voucher code already exists', async () => {
            mockPrismaService.voucher.findUnique.mockResolvedValue({ id: '1', code: 'GEARUP' });

            await expect(
                service.createVoucher({
                    code: 'GEARUP',
                    name: 'Gear Up Voucher',
                    type: VoucherType.PERCENT,
                    value: 10,
                    quantity: 100,
                }),
            ).rejects.toThrow(BadRequestException);
        });

        it('should throw BadRequestException if type is PERCENT and value > 100', async () => {
            mockPrismaService.voucher.findUnique.mockResolvedValue(null);

            await expect(
                service.createVoucher({
                    code: 'HUGEPERCENT',
                    name: 'Invalid Percent',
                    type: VoucherType.PERCENT,
                    value: 150,
                    quantity: 100,
                }),
            ).rejects.toThrow(BadRequestException);
        });

        it('should create a voucher successfully', async () => {
            mockPrismaService.voucher.findUnique.mockResolvedValue(null);
            mockPrismaService.voucher.create.mockResolvedValue({ id: '1', code: 'GEARUP' });

            const result = await service.createVoucher({
                code: 'GEARUP',
                name: 'Gear Up Voucher',
                type: VoucherType.PERCENT,
                value: 10,
                quantity: 100,
            });

            expect(result).toBeDefined();
            expect(mockPrismaService.voucher.create).toHaveBeenCalled();
        });
    });

    describe('calculateVoucherDiscount', () => {
        it('should calculate percent discount correctly without exceeding maxDiscountAmount', () => {
            const voucher = {
                type: VoucherType.PERCENT,
                value: new Prisma.Decimal(10),
                maxDiscountAmount: new Prisma.Decimal(50000),
            };

            // subtotal = 400k -> 10% is 40k
            const discount1 = service.calculateVoucherDiscount(voucher, 400000);
            expect(discount1).toBe(40000);

            // subtotal = 1000k -> 10% is 100k, capped at 50k
            const discount2 = service.calculateVoucherDiscount(voucher, 1000000);
            expect(discount2).toBe(50000);
        });

        it('should calculate fixed amount discount correctly without exceeding subtotal', () => {
            const voucher = {
                type: VoucherType.FIXED_AMOUNT,
                value: new Prisma.Decimal(100000),
            };

            // subtotal = 400k -> discount is 100k
            const discount1 = service.calculateVoucherDiscount(voucher, 400000);
            expect(discount1).toBe(100000);

            // subtotal = 50k -> discount is 50k (capped at subtotal)
            const discount2 = service.calculateVoucherDiscount(voucher, 50000);
            expect(discount2).toBe(50000);
        });
    });

    describe('calculatePointsDiscount', () => {
        it('should calculate points discount based on 100 points = 10k VND', () => {
            // subtotal = 500k, points = 250 -> 200 points converted = 20k
            const discount1 = service.calculatePointsDiscount(250, 500000);
            expect(discount1).toBe(20000);

            // subtotal = 15k, points = 300 -> 300 points converted = 30k, capped at 15k
            const discount2 = service.calculatePointsDiscount(300, 15000);
            expect(discount2).toBe(15000);
        });
    });

    describe('earnPointsFromDeliveredOrder', () => {
        it('should not add points if transaction type EARN already exists (Double Earn Protection)', async () => {
            const orderId = 'order-123';
            const txMock = {
                pointTransaction: {
                    findFirst: jest.fn().mockResolvedValue({ id: 'tx-1' }),
                },
                order: {
                    findUnique: jest.fn(),
                },
                user: {
                    update: jest.fn(),
                },
            };

            await service.earnPointsFromDeliveredOrder(orderId, txMock as any);

            expect(txMock.pointTransaction.findFirst).toHaveBeenCalled();
            expect(txMock.order.findUnique).not.toHaveBeenCalled();
        });

        it('should add points based on 1000 VND = 1 point upon order delivery', async () => {
            const orderId = 'order-123';
            const txMock = {
                pointTransaction: {
                    findFirst: jest.fn().mockResolvedValue(null),
                    create: jest.fn().mockResolvedValue({ id: 'tx-2' }),
                },
                order: {
                    findUnique: jest.fn().mockResolvedValue({
                        id: orderId,
                        userId: 'user-123',
                        totalAmount: new Prisma.Decimal(250000), // 250 points
                    }),
                },
                user: {
                    update: jest.fn().mockResolvedValue({ id: 'user-123', rewardPoints: 250 }),
                },
            };

            await service.earnPointsFromDeliveredOrder(orderId, txMock as any);

            expect(txMock.pointTransaction.findFirst).toHaveBeenCalled();
            expect(txMock.order.findUnique).toHaveBeenCalledWith({ where: { id: orderId } });
            expect(txMock.user.update).toHaveBeenCalledWith({
                where: { id: 'user-123' },
                data: {
                    rewardPoints: { increment: 250 },
                    totalSpent: { increment: new Prisma.Decimal(250000) },
                },
            });
            expect(txMock.pointTransaction.create).toHaveBeenCalledWith({
                data: {
                    userId: 'user-123',
                    orderId,
                    type: PointTransactionType.EARN,
                    points: 250,
                    balanceAfter: 250,
                    description: expect.any(String),
                },
            });
        });
    });

    describe('redeemPoints', () => {
        it('should deduct points and create REDEEM transaction log', async () => {
            const userId = 'user-123';
            const orderId = 'order-123';
            const pointsToUse = 500;

            const txMock = {
                user: {
                    findUnique: jest.fn().mockResolvedValue({ rewardPoints: 600 }),
                    update: jest.fn().mockResolvedValue({ id: userId, rewardPoints: 100 }),
                },
                pointTransaction: {
                    create: jest.fn().mockResolvedValue({ id: 'tx-log' }),
                },
            };

            await service.redeemPoints(userId, orderId, pointsToUse, txMock as any);

            expect(txMock.user.findUnique).toHaveBeenCalledWith({
                where: { id: userId },
                select: { rewardPoints: true },
            });
            expect(txMock.user.update).toHaveBeenCalledWith({
                where: { id: userId },
                data: { rewardPoints: { decrement: pointsToUse } },
            });
            expect(txMock.pointTransaction.create).toHaveBeenCalledWith({
                data: {
                    userId,
                    orderId,
                    type: PointTransactionType.REDEEM,
                    points: -pointsToUse,
                    balanceAfter: 100,
                    description: expect.any(String),
                },
            });
        });

        it('should throw BadRequestException if user does not have enough points', async () => {
            const userId = 'user-123';
            const orderId = 'order-123';
            const pointsToUse = 500;

            const txMock = {
                user: {
                    findUnique: jest.fn().mockResolvedValue({ rewardPoints: 100 }),
                },
            };

            await expect(
                service.redeemPoints(userId, orderId, pointsToUse, txMock as any),
            ).rejects.toThrow(BadRequestException);
        });
    });
});
