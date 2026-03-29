import api from './api';
import type { Brand } from '../types';

export const brandService = {
  async getAllBrands() {
    const { data } = await api.get<Brand[]>('/brands');
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
  }
};
