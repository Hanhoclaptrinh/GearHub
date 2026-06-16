import api from './api';
import type {
  FlashSaleProduct,
  CreateFlashSaleProductInput,
  CreateFlashSaleBulkInput,
  UpdateFlashSaleTimeBulkInput,
} from '../types/flash-sale.types';

export const flashSaleService = {
  async getFlashSales(params?: { page?: number; limit?: number; search?: string }) {
    const { data } = await api.get<{
      data: FlashSaleProduct[];
      meta: {
        total: number;
        page: number;
        limit: number;
        lastPage: number;
      };
    }>('/admin/flash-sale', { params });
    return data;
  },

  async createFlashSale(input: CreateFlashSaleProductInput) {
    const { data } = await api.post<FlashSaleProduct>('/admin/flash-sale', input);
    return data;
  },

  async createFlashSaleBulk(input: CreateFlashSaleBulkInput) {
    const { data } = await api.post<{ message: string; count: number }>('/admin/flash-sale/bulk', input);
    return data;
  },

  async updateTimeBulk(input: UpdateFlashSaleTimeBulkInput) {
    const { data } = await api.patch<{ message: string; count: number }>(
      '/admin/flash-sale/bulk-time',
      input
    );
    return data;
  },

  async deleteFlashSale(id: string) {
    const { data } = await api.delete(`/admin/flash-sale/${id}`);
    return data;
  },
};
