import api from './api';

export const transactionService = {
  async getAllTransactions(params?: any) {
    const { data } = await api.get('/payment/admin/transactions', { params });
    return data;
  },

  async getTransactionStats(params?: { startDate?: string; endDate?: string }) {
    const { data } = await api.get('/payment/admin/transactions/stats', { params });
    return data;
  }
};
