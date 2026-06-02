import api from './api';
import type { Brand } from '../types';

export const brandService = {
  async getAllBrands(page?: number, limit?: number, search?: string) {
    const params: any = {};
    if (page !== undefined) params.page = page;
    if (limit !== undefined) params.limit = limit;
    if (search !== undefined) params.search = search;

    const { data } = await api.get('/brands', { params });
    return data;
  },

  async createBrand(formData: FormData) {
    const { data } = await api.post<Brand>('/brands', formData);
    return data;
  },

  async updateBrand(id: string, formData: FormData) {
    const { data } = await api.patch<Brand>(`/brands/${id}`, formData);
    return data;
  },

  async deleteBrand(id: string) {
    const { data } = await api.delete(`/brands/${id}`);
    return data;
  },

  async toggleBrand(id: string) {
    const { data } = await api.patch(`/brands/${id}/toggle`);
    return data;
  },

  async toggleFeaturedBrand(id: string) {
    const { data } = await api.patch(`/brands/${id}/featured`);
    return data;
  }
};
