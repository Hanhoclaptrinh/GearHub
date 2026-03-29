import api from './api';

export const dashboardService = {
  async getStats() {
    const { data } = await api.get<{ stats: any, topProducts: any }>('/orders/admin/dashboard');
    return data;
  },
};
