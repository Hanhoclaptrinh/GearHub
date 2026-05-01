import api from './api';
import type { Product, Category, Brand } from '../types';

export const productService = {
  async getProducts(params?: any) {
    const { data } = await api.get('/products', { params });
    return data;
  },

  async getProductBySlug(slug: string) {
    const { data } = await api.get<Product>(`/products/${slug}`);
    return data;
  },

  async createProduct(formData: FormData) {
    const { data } = await api.post<Product>('/products', formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
    return data;
  },

  async updateProduct(id: string, formData: FormData) {
    const { data } = await api.patch<Product>(`/products/${id}`, formData, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
    return data;
  },

  async deleteProduct(id: string) {
    const { data } = await api.delete(`/products/${id}`);
    return data;
  },

  async hardDelete(id: string) {
    const { data } = await api.delete(`/products/${id}/hard-delete`);
    return data;
  },

  async restore(id: string) {
    const { data } = await api.patch(`/products/${id}/restore`);
    return data;
  },

  async getCategories() {
    const { data } = await api.get<Category[]>('/categories');
    return data;
  },

  async getBrands() {
    const { data } = await api.get<Brand[]>('/brands');
    return data;
  },

  async removeAsset(assetId: string) {
    const { data } = await api.delete(`/products/assets/${assetId}`);
    return data;
  },

  async setPrimaryAsset(productId: string, assetId: string) {
    const { data } = await api.patch(`/products/${productId}/assets/${assetId}/primary`);
    return data;
  },

  async getInventoryStats() {
    const { data } = await api.get('/products/inventory/stats');
    return data;
  },

  async toggleVariant(variantId: string) {
    const { data } = await api.patch(`/products/variant/${variantId}/toggle`);
    return data;
  },

  async generateVariants(axes: Record<string, string[]>, productSlug?: string) {
    const { data } = await api.post('/products/generate-variants', { axes, productSlug });
    return data;
  }
};
