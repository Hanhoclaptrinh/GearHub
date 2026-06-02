import api from './api';
import type { Review } from '../types';

export interface GetReviewsResponse {
  data: Review[];
  meta: {
    total: number;
    page: number;
    lastPage: number;
  };
}

export interface ReviewStats {
  total: number;
  average: number;
  unreplied: number;
  replied: number;
  hidden: number;
  ratingDistribution: Record<string, number>;
}

export const reviewService = {
  async getReviews(params?: {
    page?: number;
    limit?: number;
    rating?: number;
    repliedStatus?: 'replied' | 'unreplied';
    isHidden?: boolean | string;
    search?: string;
  }) {
    const { data } = await api.get<GetReviewsResponse>('/reviews', { params });
    return data;
  },

  async replyReview(id: string, reply: string) {
    const { data } = await api.patch<Review>(`/reviews/${id}/reply`, { reply });
    return data;
  },

  async toggleVisibility(id: string) {
    const { data } = await api.patch<{ message: string; isHidden: boolean }>(`/reviews/${id}/toggle-visibility`);
    return data;
  },

  async generateAiReply(id: string) {
    const { data } = await api.post<{ replyDraft: string }>(`/reviews/${id}/ai-reply`);
    return data;
  },

  async getReviewStats(): Promise<ReviewStats> {
    const { data } = await api.get<ReviewStats>('/reviews/stats');
    return data;
  }
};
