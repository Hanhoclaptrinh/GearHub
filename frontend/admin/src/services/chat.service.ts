import api from './api';
import type { ChatRoomSummary, MessagesResponse, RoomsResponse, RoomStatus } from '../features/chat/types';

export interface AdminRoomsParams {
  status?: RoomStatus;
  mine?: boolean;
  search?: string;
  unreadOnly?: boolean;
  page?: number;
  limit?: number;
}

export const chatService = {
  async getRooms(params: AdminRoomsParams) {
    const { data } = await api.get<RoomsResponse>('/admin/chat/rooms', { params });
    return data;
  },

  async getRoom(roomId: string) {
    const { data } = await api.get<ChatRoomSummary>(`/admin/chat/rooms/${roomId}`);
    return data;
  },

  async getMessages(roomId: string, params?: { cursor?: string; take?: number }) {
    const { data } = await api.get<MessagesResponse>(`/chat/rooms/${roomId}/messages`, { params });
    return data;
  },

  async markRead(roomId: string) {
    const { data } = await api.post<ChatRoomSummary>(`/chat/rooms/${roomId}/read`);
    return data;
  },

  async claimRoom(roomId: string) {
    const { data } = await api.post<ChatRoomSummary>(`/admin/chat/rooms/${roomId}/claim`);
    return data;
  },

  async closeRoom(roomId: string) {
    const { data } = await api.post<{ room: ChatRoomSummary }>(`/admin/chat/rooms/${roomId}/close`);
    return data;
  },
};
