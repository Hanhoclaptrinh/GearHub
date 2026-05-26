import { Module } from '@nestjs/common';
import { PaymentService } from './payment.service';
import { PaymentController } from './payment.controller';
import { VnPayGateway } from './gateway/vnpay.gateway';
import { PromotionModule } from 'src/promotion/promotion.module';
import { NotificationModule } from 'src/notification/notification.module';
import { InventoriesModule } from 'src/inventories/inventories.module';

@Module({
  imports: [PromotionModule, NotificationModule, InventoriesModule],
  providers: [PaymentService, VnPayGateway],
  controllers: [PaymentController],
  exports: [PaymentService]
})
export class PaymentModule { }
