export interface FlashSaleProduct {
  id: string;
  productVariantId: string;
  flashPrice: number;
  stockLimit: number;
  soldCount: number;
  startsAt: string;
  expiresAt: string;
  createdAt: string;
  updatedAt?: string;
  productVariant: {
    id: string;
    sku: string;
    price: number;
    stock: number;
    attributes: Record<string, any>;
    isActive: boolean;
    product: {
      name: string;
      thumbnailUrl?: string;
    };
  };
}

export interface CreateFlashSaleProductInput {
  productVariantId: string;
  flashPrice: number;
  stockLimit: number;
  startsAt: string;
  expiresAt: string;
}

export interface CreateFlashSaleBulkInput {
  productVariantIds: string[];
  discountType: 'PERCENT' | 'FIXED_AMOUNT' | 'PRICE';
  discountValue: number;
  stockLimit: number;
  startsAt: string;
  expiresAt: string;
}

export interface UpdateFlashSaleTimeBulkInput {
  ids: string[];
  startsAt: string;
  expiresAt: string;
}

