import { Module } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { OrdersController } from './orders.controller';
import { ProductsModule } from 'src/products/products.module';
import { CartModule } from 'src/cart/cart.module';
import { ActivityLogModule } from 'src/activity-log/activity-log.module';
import { InventoriesModule } from 'src/inventories/inventories.module';
import { PromotionModule } from 'src/promotion/promotion.module';
import { NotificationModule } from 'src/notification/notification.module';
import { FlashSaleModule } from 'src/flash-sale/flash-sale.module';

@Module({
  imports: [
    ProductsModule,
    CartModule,
    ActivityLogModule,
    InventoriesModule,
    PromotionModule,
    NotificationModule,
    FlashSaleModule,
  ],
  providers: [OrdersService],
  controllers: [OrdersController],
})
export class OrdersModule {}
