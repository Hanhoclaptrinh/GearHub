import { Module } from '@nestjs/common';
import { PaymentService } from './payment.service';
import { PaymentController } from './payment.controller';
import { VnPayGateway } from './gateway/vnpay.gateway';

@Module({
  providers: [PaymentService, VnPayGateway],
  controllers: [PaymentController],
  exports: [PaymentService]
})
export class PaymentModule { }
