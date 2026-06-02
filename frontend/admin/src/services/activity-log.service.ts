import api from './api';

export const activityLogService = {
  async getAllLogs(params?: any) {
    const { data } = await api.get('/activity-logs', { params });
    return data;
  },

  async getStats(params?: any) {
    const { data } = await api.get('/activity-logs/stats', { params });
    return data;
  }
};
