import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PrismaModule } from './prisma/prisma.module';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { RedisModule } from './redis/redis.module';
import { CloudinaryModule } from './cloudinary/cloudinary.module';
import { CategoriesModule } from './categories/categories.module';
import { BrandsModule } from './brands/brands.module';
import { ProductsModule } from './products/products.module';
import { CartModule } from './cart/cart.module';
import { OrdersModule } from './orders/orders.module';
import { PaymentModule } from './payment/payment.module';
import { WishlistModule } from './wishlist/wishlist.module';
import { ReviewsModule } from './reviews/reviews.module';
import { ChatModule } from './chat/chat.module';
import { ActivityLogModule } from './activity-log/activity-log.module';
import { ActivityLogInterceptor } from './common/interceptors/activity-log.interceptor';
import { ScheduleModule } from '@nestjs/schedule';
import { InventoriesModule } from './inventories/inventories.module';
import { PromotionModule } from './promotion/promotion.module';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true
    }),

    ThrottlerModule.forRoot({
      throttlers: [
        {
          name: 'default',
          ttl: 60000,
          limit: 100
        },
        {
          name: 'chat',
          ttl: 60000,
          limit: 15
        }
      ]
    }),

    PrismaModule,
    AuthModule,
    UsersModule,
    RedisModule,
    CloudinaryModule,
    CategoriesModule,
    BrandsModule,
    ProductsModule,
    CartModule,
    OrdersModule,
    PaymentModule,
    WishlistModule,
    ReviewsModule,
    ChatModule,
    ActivityLogModule,
    ScheduleModule.forRoot(),
    InventoriesModule,
    PromotionModule
  ],
  controllers: [AppController],
  providers: [
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard
    },

    {
      provide: APP_INTERCEPTOR,
      useClass: ActivityLogInterceptor
    },

    AppService,
  ],
  exports: [AppService]
})
export class AppModule { }
