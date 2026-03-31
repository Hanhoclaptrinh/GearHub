import { Injectable } from '@nestjs/common';
import { PaymentGateway } from '../types/payment-gateway.interface';
import * as crypto from 'crypto';
import moment from 'moment';
import qs from 'qs';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class VnPayGateway implements PaymentGateway {
    constructor(private configService: ConfigService) { }

    async createPayment(data: { orderId: string; amount: number; ipAddr: string }): Promise<string> {
        const vnpTmnCode = this.configService.get<string>('VNP_TMN_CODE')!;
        const vnpHashSecret = this.configService.get<string>('VNP_HASH_SECRET')!;
        const vnpUrl = this.configService.get<string>('VNP_URL')!;
        const vnpReturnUrl = this.configService.get<string>('VNP_RETURN_URL')!;

        const createDate = moment().format('YYYYMMDDHHmmss');

        const vnp_Params: any = {
            vnp_Amount: Math.floor(data.amount * 100),
            vnp_Command: 'pay',
            vnp_CreateDate: createDate,
            vnp_CurrCode: 'VND',
            vnp_IpAddr: data.ipAddr,
            vnp_Locale: 'vn',
            vnp_OrderInfo: `Thanh toan don hang ${data.orderId}`,
            vnp_OrderType: 'other',
            vnp_ReturnUrl: vnpReturnUrl,
            vnp_TmnCode: vnpTmnCode,
            vnp_TxnRef: data.orderId,
            vnp_Version: '2.1.0',
        };

        const sortedParams = this.sortObject(vnp_Params);

        const signData = new URLSearchParams(sortedParams).toString();

        const hmac = crypto.createHmac('sha512', vnpHashSecret);
        const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');

        return `${vnpUrl}?${signData}&vnp_SecureHash=${signed}`;
    }

    private sortObject(obj: any) {
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

        const signData = Object.keys(sortedParams)
            .map((key) => {
                const value = encodeURIComponent(sortedParams[key].toString()).replace(/%20/g, "+");
                return `${key}=${value}`;
            })
            .join('&');

        const hmac = crypto.createHmac('sha512', vnpHashSecret);
        const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');

        // log chuoi hash 2 chieu
        // console.log('Chuỗi băm chiều về:', signData);
        // console.log('Mã băm tự tính:', signed);
        // console.log('Mã băm VNPAY gửi:', vnpSecureHash);

        return signed === vnpSecureHash;
    }
}