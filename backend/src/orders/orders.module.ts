import { Module } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { OrdersController } from './orders.controller';
import { ProductsModule } from 'src/products/products.module';
import { CartModule } from 'src/cart/cart.module';
import { ActivityLogModule } from 'src/activity-log/activity-log.module';
import { InventoriesModule } from 'src/inventories/inventories.module';

@Module({
  imports: [ProductsModule, CartModule, ActivityLogModule, InventoriesModule],
  providers: [OrdersService],
  controllers: [OrdersController]
})
export class OrdersModule { }
