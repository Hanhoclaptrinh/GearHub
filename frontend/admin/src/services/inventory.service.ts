import api from './api';

export interface InventoryVariant {
    variantId: string;
    sku: string;
    variantName: string;
    attributes: Record<string, any>;
    currentStock: number;
    price: number;
    imageUrl: string | null;
    isActive: boolean;
    stockStatus: 'IN_STOCK' | 'LOW_STOCK' | 'OUT_OF_STOCK';
}

export interface InventoryItem {
    productId: string;
    productName: string;
    thumbnailUrl: string | null;
    category: { id: string; name: string } | null;
    brand: { id: string; name: string } | null;
    totalStock: number;
    variants: InventoryVariant[];
}

export interface InventoryTransaction {
    id: string;
    variantId: string;
    type: string;
    quantity: number;
    beforeStock: number;
    afterStock: number;
    reason: string | null;
    referenceId: string | null;
    createdBy: {
        id: string;
        email: string;
        profile: { fullName: string | null } | null;
    } | null;
    createdAt: string;
}

export interface AdjustStockPayload {
    type: 'IMPORT' | 'DAMAGED' | 'ADJUSTMENT' | 'RETURN';
    quantity: number;
    reason?: string;
    mode?: 'INCREASE' | 'DECREASE';
}

export const inventoryService = {
    async getInventoryList(params?: {
        search?: string;
        categoryId?: string;
        brandId?: string;
        stockFilter?: string;
        page?: number;
        limit?: number;
    }) {
        const { data } = await api.get('/inventory', { params });
        return data;
    },

    async adjustStock(variantId: string, payload: AdjustStockPayload) {
        const { data } = await api.post(`/inventory/${variantId}/adjust`, payload);
        return data;
    },

    async getTransactionHistory(variantId: string, params?: { page?: number; limit?: number }) {
        const { data } = await api.get(`/inventory/${variantId}/transactions`, { params });
        return data;
    },
};
