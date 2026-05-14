import api from './api';

export const userService = {
  async getAllUsers(params?: any) {
    const { data } = await api.get('/users/all-users', { params });
    return data;
  },

  async updateUserStatus(userId: string, status: string) {
    const { data } = await api.patch(`/users/${userId}/status`, { status });
    return data;
  },

  async updateUserRole(userId: string, role: string) {
    const { data } = await api.patch(`/users/${userId}/role`, { role });
    return data;
  },
  async createUser(userData: any) {
    const { data } = await api.post('/users/admin/create', userData);
    return data;
  },
  async getUserStats() {
    const { data } = await api.get('/users/admin/stats');
    return data;
  },
  async getUserDetail(userId: string) {
    const { data } = await api.get(`/users/${userId}/detail`);
    return data;
  }
};
