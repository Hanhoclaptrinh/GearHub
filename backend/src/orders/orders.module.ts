import { Module } from '@nestjs/common';
import { OrdersService } from './orders.service';
import { OrdersController } from './orders.controller';
import { ProductsModule } from 'src/products/products.module';
import { CartModule } from 'src/cart/cart.module';

@Module({
  imports: [ProductsModule, CartModule],
  providers: [OrdersService],
  controllers: [OrdersController]
})
export class OrdersModule { }
