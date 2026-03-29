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

  async updateStatus(id: string, status: OrderStatus) {
    const { data } = await api.patch<Order>(`/orders/${id}/status`, { status });
    return data;
  },
};
