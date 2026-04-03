import { Controller, Get, Param, Post, Query, Request, Response, UseGuards, Logger, BadRequestException } from '@nestjs/common';
import { PaymentService } from './payment.service';
import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';
import { Role } from '@prisma/client';
import { RolesGuard } from 'src/common/guards/roles.guard';
import { Roles } from 'src/common/decorators/roles.decorator';

@Controller('payment')
export class PaymentController {
    private readonly logger = new Logger(PaymentController.name);

    constructor(private paymentService: PaymentService) { }

    @Post('create-url/:orderId')
    @UseGuards(JwtAuthGuard)
    async createPaymentUrl(@Param('orderId') orderId: string, @Request() req) {
        // lay ip cua khach hang
        // neu chay qua proxy (Nginx/Cloudflare) thi dung 'x-forwarded-for'
        // neu khong thi dung remoteAddress
        const ipAddr =
            req.headers['x-forwarded-for']?.toString() ||
            req.socket.remoteAddress ||
            '127.0.0.1';

        return this.paymentService.createPaymentUrl(orderId, ipAddr);
    }

    @Get('vnpay_return')
    async vnpayReturn(@Query() query: any, @Response() res) {
        try {
            // this.logger.log(`VNPay return callback received with params: ${JSON.stringify(query)}`);

            if (!query['vnp_TxnRef']) {
                throw new BadRequestException('Missing vnp_TxnRef parameter');
            }

            const result = await this.paymentService.processVnpayReturn(query);

            if (result.success) {
                // this.logger.log(`Payment successful for order: ${result.orderId}`);
                return res.redirect(`http://localhost:5173/payment-success?orderId=${result.orderId}`);
            } else {
                const message = result.message || 'Unknown error';
                // this.logger.warn(`Payment failed: ${message}`);
                return res.redirect(`http://localhost:5173/payment-failed?message=${encodeURIComponent(message)}`);
            }
        } catch (error) {
            // this.logger.error(`Error in vnpayReturn: ${error.message}`, error.stack);
            return res.redirect(`http://localhost:5173/payment-failed?error=${encodeURIComponent(error.message)}`);
        }
    }

    @Get('admin/transactions')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async getAllTransactions(@Query() query: any) {
        return this.paymentService.getAllTransactions(query);
    }
}
