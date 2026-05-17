import { ChatRoom, Message, Profile, User } from '@prisma/client';

type UserWithProfile = Pick<User, 'id' | 'email' | 'role' | 'createdAt'> & {
  profile: Pick<Profile, 'fullName' | 'phone' | 'avatarUrl'> | null;
};

export type MessageResponseDto = {
  id: string;
  roomId: string;
  senderId: string | null;
  content: string;
  type: string;
  status: string;
  readAt: Date | null;
  isAi: boolean;
  createdAt: Date;
};

export type UserProfileResponseDto = {
  id: string;
  email: string;
  role: string;
  fullName: string | null;
  phone: string | null;
  avatarUrl: string | null;
  createdAt: Date;
};

export type ChatRoomSummaryResponseDto = {
  id: string;
  status: string;
  staffId: string | null;
  lastMessageAt: Date | null;
  lastMessageContent: string | null;
  customerUnreadCount: number;
  staffUnreadCount: number;
  customer?: UserProfileResponseDto;
  staff?: UserProfileResponseDto | null;
};

export type LatestCustomerRoomResponseDto = {
  room: ChatRoomSummaryResponseDto | null;
  isClosed: boolean;
  canStartNewRoom: boolean;
};

export type MessagesPageResponseDto = {
  items: MessageResponseDto[];
  nextCursor: string | null;
};

export type AdminRoomsPageResponseDto = {
  items: ChatRoomSummaryResponseDto[];
  total: number;
  page: number;
  limit: number;
};

export function toMessageResponse(
  message: Pick<
    Message,
    | 'id'
    | 'roomId'
    | 'senderId'
    | 'content'
    | 'type'
    | 'status'
    | 'readAt'
    | 'isAi'
    | 'createdAt'
  >,
): MessageResponseDto {
  return {
    id: message.id,
    roomId: message.roomId,
    senderId: message.senderId,
    content: message.content,
    type: message.type,
    status: message.status,
    readAt: message.readAt,
    isAi: message.isAi,
    createdAt: message.createdAt,
  };
}

export function toUserProfileResponse(
  user: UserWithProfile,
): UserProfileResponseDto {
  return {
    id: user.id,
    email: user.email,
    role: user.role,
    fullName: user.profile?.fullName ?? null,
    phone: user.profile?.phone ?? null,
    avatarUrl: user.profile?.avatarUrl ?? null,
    createdAt: user.createdAt,
  };
}

export function toChatRoomSummaryResponse(
  room: Pick<
    ChatRoom,
    | 'id'
    | 'status'
    | 'staffId'
    | 'lastMessageAt'
    | 'lastMessageContent'
    | 'customerUnreadCount'
    | 'staffUnreadCount'
  > & {
    user?: UserWithProfile;
    staff?: UserWithProfile | null;
  },
): ChatRoomSummaryResponseDto {
  return {
    id: room.id,
    status: room.status,
    staffId: room.staffId,
    lastMessageAt: room.lastMessageAt,
    lastMessageContent: room.lastMessageContent,
    customerUnreadCount: room.customerUnreadCount,
    staffUnreadCount: room.staffUnreadCount,
    customer: room.user ? toUserProfileResponse(room.user) : undefined,
    staff: room.staff ? toUserProfileResponse(room.staff) : null,
  };
}
