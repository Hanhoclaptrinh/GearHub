export interface PaymentGateway {
    createPayment(data: any): Promise<string>;
    verifyReturn(query: any): Promise<boolean>;
}