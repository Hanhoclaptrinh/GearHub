export class SyncCartItemDto {
    variantId: string;
    quantity: number;
}

export class SyncCartDto {
    items: SyncCartItemDto[];
}