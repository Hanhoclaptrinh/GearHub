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

    if (data.data.user.role !== Role.ADMIN) {
      throw new Error('Access denied. Admin only.');
    }

    localStorage.setItem('admin_token', data.data.tokens.accessToken);
    localStorage.setItem('admin_user', JSON.stringify(data.data.user));

    return data.data;
  },

  logout() {
    localStorage.removeItem('admin_token');
    localStorage.removeItem('admin_user');
    window.location.href = '/login';
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
