import api from './api';
import type { Category } from '../types';

export const categoryService = {
  async getAllCategories() {
    const { data } = await api.get<Category[]>('/categories');
    return data;
  },

  async getCategoryTree() {
    const { data } = await api.get<any[]>('/categories/tree');
    return data;
  },

  async createCategory(formData: FormData) {
    const { data } = await api.post<Category>('/categories', formData);
    return data;
  },

  async updateCategory(id: string, formData: FormData) {
    const { data } = await api.patch<Category>(`/categories/${id}`, formData);
    return data;
  },

  async deleteCategory(id: string) {
    const { data } = await api.delete(`/categories/${id}`);
    return data;
  }
};
