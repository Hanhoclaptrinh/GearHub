import { Module } from '@nestjs/common';
import { FlashSaleController } from './flash-sale.controller';
import { FlashSaleService } from './flash-sale.service';
import { PrismaModule } from 'src/prisma/prisma.module';
import { RedisModule } from 'src/redis/redis.module';
import { NotificationModule } from 'src/notification/notification.module';

@Module({
  imports: [PrismaModule, RedisModule, NotificationModule],
  controllers: [FlashSaleController],
  providers: [FlashSaleService],
  exports: [FlashSaleService]
})
export class FlashSaleModule {}
