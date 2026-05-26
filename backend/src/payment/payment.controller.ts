import { Controller, Get, Param, Post, Query, Request, Response, UseGuards, Logger, BadRequestException } from '@nestjs/common';
import { PaymentService } from './payment.service';
import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';
import { Role } from '@prisma/client';
import { RolesGuard } from 'src/common/guards/roles.guard';
import { Roles } from 'src/common/decorators/roles.decorator';
import { ConfigService } from '@nestjs/config';

@Controller('payment')
export class PaymentController {
    private readonly logger = new Logger(PaymentController.name);

    constructor(
        private paymentService: PaymentService,
        private configService: ConfigService
    ) { }

    @Post('create-url/:orderId')
    @UseGuards(JwtAuthGuard)
    async createPaymentUrl(
        @Param('orderId') orderId: string,
        @Query('platform') platform: string = 'web',
        @Request() req) {
        // lay ip cua khach hang
        // neu chay qua proxy (Nginx/Cloudflare) thi dung 'x-forwarded-for'
        // neu khong thi dung remoteAddress
        const ipAddr =
            req.headers['x-forwarded-for']?.toString() ||
            req.socket.remoteAddress ||
            '127.0.0.1';

        return this.paymentService.createPaymentUrl(orderId, ipAddr, platform);
    }

    @Get('vnpay_return')
    async vnpayReturn(@Query() query: any, @Response() res) {
        const frontendUrl = this.configService.get<string>('FRONTEND_URL');
        const mobileScheme = this.configService.get<string>('MOBILE_SCHEME');
        const isMobile = query['platform'] === 'mobile';
        const baseRedirect = isMobile ? mobileScheme : frontendUrl;

        try {
            // this.logger.log(`VNPay return callback received with params: ${JSON.stringify(query)}`);

            if (!query['vnp_TxnRef']) {
                throw new BadRequestException('Missing vnp_TxnRef parameter');
            }

            const result = await this.paymentService.processVnpayReturn(query);

            if (result.success) {
                const r: any = result;
                return res.redirect(`${baseRedirect}?status=success&orderId=${r.orderId}`);
            } else {
                const r: any = result;
                return res.redirect(`${baseRedirect}?status=failed&message=${encodeURIComponent(r.message || 'Unknown error')}`);
            }
        } catch (error) {
            // this.logger.error(`Error in vnpayReturn: ${error.message}`, error.stack);
            return res.redirect(`${baseRedirect}?status=error&message=${encodeURIComponent(error.message)}`);
        }
    }

    @Get('vnpay_ipn')
    async vnpayIpn(@Query() query: any) {
        return this.paymentService.processVnpayIpn(query);
    }

    @Get('admin/transactions')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async getAllTransactions(@Query() query: any) {
        return this.paymentService.getAllTransactions(query);
    }

    @Post('refund/:orderId')
    @UseGuards(JwtAuthGuard, RolesGuard)
    @Roles(Role.ADMIN)
    async refundOrder(
        @Param('orderId') orderId: string,
        @Request() req
    ) {
        const ipAddr =
            req.headers['x-forwarded-for']?.toString() ||
            req.socket.remoteAddress ||
            '127.0.0.1';
        return this.paymentService.refundOrder(orderId, req.user.email, ipAddr);
    }
}
