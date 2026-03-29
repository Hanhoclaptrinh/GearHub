import api from './api';

export const userService = {
  async getAllUsers(params?: any) {
    const { data } = await api.get('/users/all-users', { params });
    return data;
  }
};
