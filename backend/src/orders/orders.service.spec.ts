import { Test, TestingModule } from '@nestjs/testing';
import { ActivityLogService } from 'src/activity-log/activity-log.service';
import { InventoriesService } from 'src/inventories/inventories.service';
import { NotificationService } from 'src/notification/notification.service';
import { PrismaService } from 'src/prisma/prisma.service';
import { PromotionService } from 'src/promotion/promotion.service';
import { OrdersService } from './orders.service';

describe('OrdersService', () => {
  let service: OrdersService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        OrdersService,
        { provide: PrismaService, useValue: {} },
        { provide: ActivityLogService, useValue: {} },
        { provide: InventoriesService, useValue: {} },
        { provide: PromotionService, useValue: {} },
        { provide: NotificationService, useValue: { sendToUser: jest.fn() } },
      ],
    }).compile();

    service = module.get<OrdersService>(OrdersService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });
});
