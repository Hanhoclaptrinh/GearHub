import api from './api';

export const activityLogService = {
  async getAllLogs(params?: any) {
    const { data } = await api.get('/activity-logs', { params });
    return data;
  }
};
