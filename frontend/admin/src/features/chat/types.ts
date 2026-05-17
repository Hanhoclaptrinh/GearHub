export type ChatRole = 'ADMIN' | 'STAFF' | 'USER';
export type RoomStatus = 'BOT_ONLY' | 'NEED_HUMAN' | 'STAFF_ACTIVE' | 'CLOSED';
export type MessageType = 'TEXT' | 'IMAGE' | 'SYSTEM';
export type MessageStatus = 'SENT' | 'DELIVERED' | 'READ';
export type InboxFilter = 'all' | 'unclaimed' | 'mine' | 'closed' | 'unread';

export interface ChatProfile {
  id: string;
  email: string;
  role: ChatRole;
  fullName: string | null;
  phone: string | null;
  avatarUrl: string | null;
  createdAt: string;
}

export interface ChatRoomSummary {
  id: string;
  status: RoomStatus;
  staffId: string | null;
  lastMessageAt: string | null;
  lastMessageContent: string | null;
  customerUnreadCount: number;
  staffUnreadCount: number;
  customer?: ChatProfile;
  staff?: ChatProfile | null;
}

export interface ChatMessage {
  id: string;
  roomId: string;
  senderId: string | null;
  content: string;
  type: MessageType;
  status: MessageStatus;
  readAt: string | null;
  isAi: boolean;
  createdAt: string;
  clientMessageId?: string;
  optimistic?: boolean;
  failed?: boolean;
}

export interface RoomsResponse {
  items: ChatRoomSummary[];
  total: number;
  page: number;
  limit: number;
}

export interface MessagesResponse {
  items: ChatMessage[];
  nextCursor: string | null;
}

export interface RoomUpdatedPayload {
  room: ChatRoomSummary;
}

export interface MessageNewPayload {
  clientMessageId?: string;
  message: ChatMessage;
  room: ChatRoomSummary;
}

export interface MessagesReadPayload {
  roomId: string;
  readerId: string;
  readerRole: ChatRole;
  readAt: string;
  room: ChatRoomSummary;
}

export interface RoomClaimedPayload {
  roomId: string;
  staffId: string;
  status: RoomStatus;
  room: ChatRoomSummary;
}

export interface RoomClosedPayload {
  roomId: string;
  closedById: string;
  status: RoomStatus;
  room: ChatRoomSummary;
}

export interface TypingPayload {
  roomId: string;
  userId: string;
}
