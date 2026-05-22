import { BadRequestException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { Prisma, VoucherType } from '@prisma/client';
import { PrismaService } from 'src/prisma/prisma.service';
import { PromotionService } from './promotion.service';

describe('PromotionService', () => {
  let service: PromotionService;

  const mockPrismaService = {
    voucher: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      count: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    },
    userVoucher: {
      findUnique: jest.fn(),
      findMany: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
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
    jest.clearAllMocks();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('createVoucher', () => {
    it('should throw BadRequestException if voucher code already exists', async () => {
      mockPrismaService.voucher.findUnique.mockResolvedValue({
        id: '1',
        code: 'GEARUP',
      });

      await expect(
        service.createVoucher({
          code: 'GEARUP',
          name: 'Gear Up Voucher',
          type: VoucherType.PERCENT,
          value: 10,
          minOrderAmount: 100000,
          maxDiscountAmount: 50000,
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
          minOrderAmount: 100000,
          maxDiscountAmount: 50000,
          quantity: 100,
        }),
      ).rejects.toThrow(BadRequestException);
    });

    it('should create a voucher successfully', async () => {
      mockPrismaService.voucher.findUnique.mockResolvedValue(null);
      mockPrismaService.voucher.create.mockResolvedValue({
        id: '1',
        code: 'GEARUP',
      });

      const result = await service.createVoucher({
        code: 'GEARUP',
        name: 'Gear Up Voucher',
        type: VoucherType.PERCENT,
        value: 10,
        minOrderAmount: 100000,
        maxDiscountAmount: 50000,
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

      expect(service.calculateVoucherDiscount(voucher, 400000)).toBe(40000);
      expect(service.calculateVoucherDiscount(voucher, 1000000)).toBe(50000);
    });

    it('should calculate fixed amount discount correctly without exceeding subtotal', () => {
      const voucher = {
        type: VoucherType.FIXED_AMOUNT,
        value: new Prisma.Decimal(100000),
      };

      expect(service.calculateVoucherDiscount(voucher, 400000)).toBe(100000);
      expect(service.calculateVoucherDiscount(voucher, 50000)).toBe(50000);
    });
  });
});
