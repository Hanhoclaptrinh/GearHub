export class VnPayHelper {
    static toVnpAmount(amount: number) {
        return amount * 100;
    }

    fromVnpAmount(amount: number) {
        return amount / 100;
    }
}