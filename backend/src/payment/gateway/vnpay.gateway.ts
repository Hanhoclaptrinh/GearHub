import { Injectable } from '@nestjs/common';
import { PaymentGateway } from '../types/payment-gateway.interface';
import * as crypto from 'crypto';
import moment from 'moment';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class VnPayGateway implements PaymentGateway {
    constructor(private configService: ConfigService) { }

    async createPayment(data: { orderId: string; amount: number; ipAddr: string, orderInfo: string, platform?: string }): Promise<string> {
        const vnpTmnCode = this.configService.get<string>('VNP_TMN_CODE')!;
        const vnpHashSecret = this.configService.get<string>('VNP_HASH_SECRET')!;
        const vnpUrl = this.configService.get<string>('VNP_URL')!;
        let vnpReturnUrl = this.configService.get<string>('VNP_RETURN_URL')!;

        const createDate = moment().format('YYYYMMDDHHmmss');

        // add platform to return url
        if (data.platform) {
            const url = new URL(vnpReturnUrl);
            url.searchParams.set('platform', data.platform);
            vnpReturnUrl = url.toString();
        }

        const vnp_Params: any = {
            vnp_Version: '2.1.0',
            vnp_Command: 'pay',
            vnp_TmnCode: vnpTmnCode,
            vnp_Amount: Math.floor(data.amount * 100),
            vnp_CurrCode: 'VND',
            vnp_TxnRef: data.orderId,
            vnp_OrderInfo: data.orderInfo,
            vnp_OrderType: 'other',
            vnp_Locale: 'vn',
            vnp_ReturnUrl: vnpReturnUrl,
            vnp_IpAddr: data.ipAddr,
            vnp_CreateDate: createDate,
        };

        const sortedParams = this.sortObject(vnp_Params);

        // build query string
        const signData = Object.keys(sortedParams)
            .map((key) => `${key}=${encodeURIComponent(sortedParams[key]).replace(/%20/g, "+")}`)
            .join('&');

        // hash data
        const hmac = crypto.createHmac('sha512', vnpHashSecret);
        const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');

        // url generate
        const finalUrl = `${vnpUrl}?${signData}&vnp_SecureHash=${signed}`;
        return finalUrl;
    }

    private sortObject(obj: object) {
        const sorted: any = {};
        const keys = Object.keys(obj).sort();
        keys.forEach((key) => {
            sorted[key] = obj[key].toString();
        });
        return sorted;
    }

    async verifyReturn(query: any): Promise<boolean> {
        const vnpHashSecret = this.configService.get<string>('VNP_HASH_SECRET')!;
        const vnpSecureHash = query['vnp_SecureHash'];

        const data = { ...query };
        delete data['vnp_SecureHash'];
        delete data['vnp_SecureHashType'];

        const sortedParams = this.sortObject(data);

        // encoding
        const signData = Object.keys(sortedParams)
            .map((key) => {
                const value = encodeURIComponent(sortedParams[key].toString()).replace(/%20/g, "+");
                return `${key}=${value}`;
            })
            .join('&');

        const hmac = crypto.createHmac('sha512', vnpHashSecret);
        const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');

        return signed === vnpSecureHash;
    }
}