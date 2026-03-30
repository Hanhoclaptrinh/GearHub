import api from './api';
import type { Order, OrderStatus } from '../types';

export const orderService = {
  async getOrders(params?: any) {
    const { data } = await api.get('/orders/admin', { params });
    return data;
  },

  async getOrderById(id: string) {
    const { data } = await api.get<Order>(`/orders/${id}`);
    return data;
  },

  async updateStatus(id: string, payload: { status: OrderStatus; description?: string }) {
    const { data } = await api.patch<Order>(`/orders/${id}`, payload);
    return data;
  },

  async getAdminStats() {
    const { data } = await api.get('/orders/admin/dashboard');
    return data;
  },

  async getTopSellingProducts() {
    const { data } = await api.get('/orders/top-products');
    return data;
  },
};
