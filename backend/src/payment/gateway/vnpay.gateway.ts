import { Injectable } from '@nestjs/common';
import { PaymentGateway } from '../types/payment-gateway.interface';
import * as crypto from 'crypto';
import moment from 'moment';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class VnPayGateway implements PaymentGateway {
    constructor(private configService: ConfigService) { }

    /**
     * tạo đường dẫn thanh toán chuyển hướng sang cổng vnpay
     * tự động cấu hình các tham số bắt buộc, sắp xếp và sinh chữ ký bảo mật hmac-sha512
     */
    async createPayment(data: { orderId: string; amount: number; ipAddr: string, orderInfo: string, platform?: string }): Promise<string> {
        const vnpTmnCode = this.configService.get<string>('VNP_TMN_CODE')!;
        const vnpHashSecret = this.configService.get<string>('VNP_HASH_SECRET')!;
        const vnpUrl = this.configService.get<string>('VNP_URL')!;
        let vnpReturnUrl = this.configService.get<string>('VNP_RETURN_URL')!;
        const createDate = moment().format('YYYYMMDDHHmmss');

        // thêm platform vào return url để redirect chính xác sau khi thanh toán xong
        if (data.platform) {
            const url = new URL(vnpReturnUrl);
            url.searchParams.set('platform', data.platform);
            vnpReturnUrl = url.toString();
        }

        // các tham số theo tài liệu tích hợp vnpay
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

        // sắp xếp tham số theo bảng chữ cái alphabet tăng dần
        const sortedParams = this.sortObject(vnp_Params);

        // build chuỗi query string
        const signData = Object.keys(sortedParams)
            .map((key) => `${key}=${encodeURIComponent(sortedParams[key]).replace(/%20/g, "+")}`)
            .join('&');

        // mã hóa hmac-sha512 bằng chuỗi hash secret
        const hmac = crypto.createHmac('sha512', vnpHashSecret);
        const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');

        // tạo url thanh toán hoàn chỉnh kèm chữ ký bảo mật
        const finalUrl = `${vnpUrl}?${signData}&vnp_SecureHash=${signed}`;
        return finalUrl;
    }

    /**
     * thực hiện yêu cầu hoàn tiền toàn phần sang cổng vnpay
     * sử dụng hình thức s2s - server-to-server: post thẳng lên server
     */
    async fullRefund(data: {
        orderId: string;
        amount: number;
        ipAddr: string;
        transactionNo: string;
        transactionDate: string;
        createBy: string;
    }): Promise<any> {
        const vnpTmnCode = this.configService.get<string>('VNP_TMN_CODE')!;
        const vnpHashSecret = this.configService.get<string>('VNP_HASH_SECRET')!;
        const vnpUrl = this.configService.get<string>('VNP_URL')!;

        // tự động chọn api hoàn tiền
        const refundUrl = vnpUrl.includes('sandbox')
            ? 'https://sandbox.vnpayment.vn/merchant_webapi/api/transaction'
            : 'https://merchant.vnpay.vn/merchant_webapi/api/transaction';

        const vnp_RequestId = moment().valueOf().toString();
        const vnp_Version = '2.1.0';
        const vnp_Command = 'refund';
        const vnp_TransactionType = '02'; // code hoàn tiền toàn phần
        const vnp_CreateDate = moment().format('YYYYMMDDHHmmss');
        const vnp_OrderInfo = `Hoan tien don hang ${data.orderId}`;

        // ghép chuỗi hash theo thứ tự
        const signData = [
            vnp_RequestId,
            vnp_Version,
            vnp_Command,
            vnpTmnCode,
            vnp_TransactionType,
            data.orderId,
            Math.floor(Number(data.amount) * 100).toString(),
            data.transactionNo,
            data.transactionDate,
            data.createBy,
            vnp_CreateDate,
            data.ipAddr,
            vnp_OrderInfo
        ].join('|');

        // ký mã bảo mật secure hash bằng hmac-sha512
        const hmac = crypto.createHmac('sha512', vnpHashSecret);
        const vnp_SecureHash = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');

        const requestBody = {
            vnp_RequestId,
            vnp_Version,
            vnp_Command,
            vnp_TmnCode: vnpTmnCode,
            vnp_TransactionType,
            vnp_TxnRef: data.orderId,
            vnp_Amount: Math.floor(Number(data.amount) * 100),
            vnp_TransactionNo: data.transactionNo,
            vnp_TransactionDate: data.transactionDate,
            vnp_CreateBy: data.createBy,
            vnp_CreateDate,
            vnp_IpAddr: data.ipAddr,
            vnp_OrderInfo,
            vnp_SecureHash
        };

        // vnpay api merchant
        const response = await fetch(refundUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(requestBody)
        });

        if (!response.ok) {
            throw new Error(`VNPay Refund API failed: ${response.statusText}`);
        }

        return await response.json();
    }

    // hoàn tiền một phần
    async partialRefund(data: {}) { }

    // sắp xếp theo thứ tự chữ cái
    private sortObject(obj: object) {
        const sorted: any = {};
        const keys = Object.keys(obj).sort();
        keys.forEach((key) => {
            sorted[key] = obj[key].toString();
        });
        return sorted;
    }

    /**
     * xác thực chữ ký bảo mật vnpay gửi về sau thanh toán
     * loại bỏ các tham số không hợp lệ trước khi hash kiểm tra
     */
    async verifyReturn(query: any): Promise<boolean> {
        const vnpHashSecret = this.configService.get<string>('VNP_HASH_SECRET')!;
        const vnpSecureHash = query['vnp_SecureHash'];

        const data = { ...query };

        // loại bỏ các tham số chữ ký ra khỏi dữ liệu hash
        delete data['vnp_SecureHash'];
        delete data['vnp_SecureHashType'];

        // chỉ giữ lại các tham số bắt đầu bằng vnp_
        Object.keys(data).forEach(key => {
            if (!key.startsWith('vnp_')) {
                delete data[key];
            }
        });

        // sắp xếp tham số tăng dần theo alphabet
        const sortedParams = this.sortObject(data);

        // build chuỗi query string
        const signData = Object.keys(sortedParams)
            .map((key) => {
                const value = encodeURIComponent(sortedParams[key].toString()).replace(/%20/g, "+");
                return `${key}=${value}`;
            })
            .join('&');

        // mã hóa hmac-sha512
        const hmac = crypto.createHmac('sha512', vnpHashSecret);
        const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');

        // so sánh chữ ký tự sinh và chữ ký vnpay gửi về
        return signed === vnpSecureHash;
    }
}