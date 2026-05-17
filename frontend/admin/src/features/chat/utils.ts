import type { ChatMessage, ChatProfile, ChatRoomSummary, RoomStatus } from './types';

export const getDisplayName = (profile?: ChatProfile | null) => {
  return profile?.fullName || profile?.email || 'Unknown';
};

export const getInitials = (profile?: ChatProfile | null) => {
  const source = getDisplayName(profile);
  return source
    .split(/\s+/)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase())
    .join('') || 'C';
};

export const formatShortTime = (value?: string | null) => {
  if (!value) return 'No activity';
  const date = new Date(value);
  const diff = Date.now() - date.getTime();
  const minute = 60 * 1000;
  const hour = 60 * minute;
  const day = 24 * hour;

  if (diff < minute) return 'Now';
  if (diff < hour) return `${Math.floor(diff / minute)}m`;
  if (diff < day) return `${Math.floor(diff / hour)}h`;
  return date.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit' });
};

export const formatMessageTime = (value?: string | null) => {
  if (!value) return '';
  return new Date(value).toLocaleString('vi-VN', {
    hour: '2-digit',
    minute: '2-digit',
    day: '2-digit',
    month: '2-digit',
  });
};

export const getRoomStatusLabel = (status: RoomStatus) => {
  const labels: Record<RoomStatus, string> = {
    BOT_ONLY: 'Legacy',
    NEED_HUMAN: 'Waiting',
    STAFF_ACTIVE: 'Active',
    CLOSED: 'Closed',
  };
  return labels[status];
};

export const sortRoomsForInbox = (rooms: ChatRoomSummary[]) => {
  return [...rooms].sort((a, b) => {
    const unreadDiff = Number(b.staffUnreadCount > 0) - Number(a.staffUnreadCount > 0);
    if (unreadDiff !== 0) return unreadDiff;

    const aTime = new Date(a.lastMessageAt || 0).getTime();
    const bTime = new Date(b.lastMessageAt || 0).getTime();
    return bTime - aTime;
  });
};

export const isCustomerMessage = (message: ChatMessage, room?: ChatRoomSummary | null) => {
  return !!room?.customer && message.senderId === room.customer.id;
};
