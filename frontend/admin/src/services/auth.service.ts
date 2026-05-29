import api from './api';
import { Role } from '../types';
import type { AuthResponse, User } from '../types';

export const authService = {
  async login(identifier: string, password: string, deviceId: string = 'admin-cms') {
    const { data } = await api.post<AuthResponse>('/auth/login', {
      identifier,
      password,
      deviceId,
    });

    if (data.data.user.role !== Role.ADMIN && data.data.user.role !== Role.STAFF) {
      throw new Error('Access denied. Insufficient permissions.');
    }

    localStorage.setItem('admin_token', data.data.tokens.accessToken);
    localStorage.setItem('admin_refresh_token', data.data.tokens.refreshToken);
    localStorage.setItem('admin_user', JSON.stringify(data.data.user));

    return data.data;
  },

  async logout() {
    try {
      await api.post('/auth/logout');
    } catch (error) {
      console.error('Failed to log out from backend:', error);
    }
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_refresh_token');
    localStorage.removeItem('admin_user');
    window.location.href = '/login';
  },

  async refreshToken() {
    const refreshToken = localStorage.getItem('admin_refresh_token');
    const user = this.getCurrentUser();

    if (!refreshToken || !user) {
      this.logout();
      return null;
    }

    try {
      // su dung axios khong qua interceptor
      // tranh bi loop khi refresh token bi loi 401
      const { data } = await api.post('/auth/refresh', {
        refreshToken,
        userId: user.id,
        deviceId: 'admin-cms'
      });

      const { accessToken, refreshToken: newRefreshToken } = data;
      localStorage.setItem('admin_token', accessToken);
      localStorage.setItem('admin_refresh_token', newRefreshToken);

      return accessToken;
    } catch (error) {
      this.logout();
      return null;
    }
  },

  getCurrentUser(): User | null {
    const user = localStorage.getItem('admin_user');
    return user ? JSON.parse(user) : null;
  },

  async getMe() {
    const { data } = await api.get<User>('/auth/me');
    localStorage.setItem('admin_user', JSON.stringify(data));
    return data;
  },

  isAuthenticated(): boolean {
    return !!localStorage.getItem('admin_token');
  },
};
