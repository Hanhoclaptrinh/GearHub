import api from './api';
import type { Voucher, VoucherType } from '../types';

export interface VoucherListParams {
  page?: number;
  limit?: number;
  search?: string;
  status?: 'ACTIVE' | 'DISABLED' | 'EXPIRED' | 'UPCOMING';
  type?: VoucherType;
}

export interface VoucherListResponse {
  data: Voucher[];
  meta: {
    total: number;
    page: number;
    limit: number;
    lastPage: number;
  };
}

export interface VoucherAnalytics {
  stats: {
    total: number;
    active: number;
    disabled: number;
    expired: number;
    upcoming: number;
    expiringSoon: number;
    totalIssued: number;
    totalClaimed: number;
    totalUsed: number;
    totalDiscount: number;
  };
  chart: Array<{
    date: string;
    usedCount: number;
    discountAmount: number;
  }>;
}

export interface CreateVoucherPayload {
  code: string;
  name: string;
  description?: string;
  type: VoucherType;
  value: number;
  minOrderAmount?: number;
  maxDiscountAmount?: number;
  quantity: number;
  startsAt?: string;
  expiresAt?: string;
  isActive?: boolean;
}

export interface UpdateVoucherPayload {
  code?: string;
  name?: string;
  description?: string;
  type?: VoucherType;
  value?: number;
  minOrderAmount?: number;
  maxDiscountAmount?: number;
  quantity?: number;
  startsAt?: string;
  expiresAt?: string;
  isActive?: boolean;
}

export const voucherService = {
  getAllVouchers: async (params?: VoucherListParams) => {
    const { data } = await api.get<VoucherListResponse>('/admin/promotions/vouchers', { params });
    return data;
  },

  getVoucherAnalytics: async () => {
    const { data } = await api.get<VoucherAnalytics>('/admin/promotions/vouchers/analytics');
    return data;
  },

  getVoucherById: async (id: string) => {
    const { data } = await api.get<{ message: string; data: Voucher }>(`/admin/promotions/vouchers/${id}`);
    return data.data;
  },

  createVoucher: async (payload: CreateVoucherPayload) => {
    const { data } = await api.post<{ message: string; data: Voucher }>('/admin/promotions/vouchers', payload);
    return data;
  },

  updateVoucher: async (id: string, payload: UpdateVoucherPayload) => {
    const { data } = await api.patch<{ message: string; data: Voucher }>(`/admin/promotions/vouchers/${id}`, payload);
    return data;
  },

  toggleVoucherStatus: async (id: string, isActive: boolean) => {
    const { data } = await api.patch<{ message: string; data: Voucher }>(`/admin/promotions/vouchers/${id}/status`, { isActive });
    return data;
  },

  deleteVoucher: async (id: string) => {
    const { data } = await api.delete<{ message: string }>(`/admin/promotions/vouchers/${id}`);
    return data;
  },
};
