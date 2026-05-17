import { MessageStatus, MessageType, Role, RoomStatus } from '@prisma/client';

export type ChatRoomSnapshot = {
  id: string;
  userId: string;
  staffId: string | null;
  status: RoomStatus;
  lastMessageAt: Date | null;
  lastMessageContent: string | null;
  customerUnreadCount: number;
  staffUnreadCount: number;
};

export type ChatMessageSnapshot = {
  id: string;
  roomId: string;
  senderId: string | null;
  content: string;
  type: MessageType;
  status: MessageStatus;
  readAt: Date | null;
  isAi: boolean;
  createdAt: Date;
};

export type JoinRoomPayload = {
  roomId?: string;
};

export type SendMessagePayload = {
  roomId?: string;
  content: string;
  clientMessageId?: string;
};

export type MarkRoomReadPayload = {
  roomId?: string;
};

export type TypingPayload = {
  roomId: string;
};

export type RoomJoinedPayload = {
  room: ChatRoomSnapshot;
  readAt: Date;
};

export type MessageCreatedPayload = {
  clientMessageId?: string;
  message: ChatMessageSnapshot;
  room: ChatRoomSnapshot;
};

export type RoomUpdatedPayload = {
  room: ChatRoomSnapshot;
};

export type TypingEventPayload = {
  roomId: string;
  userId: string;
};

export type MessagesReadPayload = {
  roomId: string;
  readerId: string;
  readerRole: Role;
  readAt: Date;
  room: ChatRoomSnapshot;
};

export type RoomClaimedPayload = {
  roomId: string;
  staffId: string;
  status: RoomStatus;
  room: ChatRoomSnapshot;
};

export type RoomClosedPayload = {
  roomId: string;
  closedById: string;
  status: RoomStatus;
  room: ChatRoomSnapshot;
};

export interface ClientToServerEvents {
  'room:join': (payload: JoinRoomPayload) => void;
  'message:send': (payload: SendMessagePayload) => void;
  'typing:start': (payload: TypingPayload) => void;
  'typing:stop': (payload: TypingPayload) => void;
  'messages:read': (payload: MarkRoomReadPayload) => void;
}

export interface ServerToClientEvents {
  'room:joined': (payload: RoomJoinedPayload) => void;
  'message:new': (payload: MessageCreatedPayload) => void;
  'room:updated': (payload: RoomUpdatedPayload) => void;
  'room:claimed': (payload: RoomClaimedPayload) => void;
  'room:closed': (payload: RoomClosedPayload) => void;
  'typing:start': (payload: TypingEventPayload) => void;
  'typing:stop': (payload: TypingEventPayload) => void;
  'messages:read': (payload: MessagesReadPayload) => void;
}

export interface InterServerEvents {}
