import React, { memo } from 'react';
import { MailSearch, Search } from '../../../components/ui/IconlyIcons';
import {
  Chat as IconlyChat,
  User as IconlyUser,
  AddUser as IconlyAddUser,
  CloseSquare as IconlyCloseSquare,
  Notification as IconlyNotification,
} from 'react-iconly';
import { cn } from '../../../utils/cn';
import type { ChatRoomSummary, InboxFilter } from '../types';
import { formatShortTime, getDisplayName } from '../utils';
import { ChatAvatar } from './ChatAvatar';
import { RoomStatusBadge } from './RoomStatusBadge';
import { InboxSkeleton } from './InboxSkeleton';

const filters: Array<{ id: InboxFilter; label: string; icon: React.ElementType }> = [
  { id: 'all', label: 'Tất cả', icon: IconlyChat },
  { id: 'unclaimed', label: 'Đang đợi', icon: IconlyAddUser },
  { id: 'mine', label: 'Của tôi', icon: IconlyUser },
  { id: 'closed', label: 'Đã đóng', icon: IconlyCloseSquare },
  { id: 'unread', label: 'Chưa đọc', icon: IconlyNotification },
];

interface ConversationListProps {
  rooms: ChatRoomSummary[];
  activeRoomId: string | null;
  filter: InboxFilter;
  search: string;
  isLoading: boolean;
  onFilterChange: (filter: InboxFilter) => void;
  onSearchChange: (value: string) => void;
  onSelectRoom: (roomId: string) => void;
}

interface RoomItemProps {
  room: ChatRoomSummary;
  isActive: boolean;
  onSelect: (roomId: string) => void;
}

const RoomItem = memo<RoomItemProps>(({ room, isActive, onSelect }) => {
  const customer = room.customer;
  const preview = room.lastMessageContent || 'Chưa có tin nhắn...';
  const hasUnread = room.staffUnreadCount > 0;

  return (
    <button
      onClick={() => onSelect(room.id)}
      className={cn(
        'w-full rounded-[10px] px-4 py-3.5 text-left transition-all outline-none border',
        isActive
          ? 'bg-[#f2f7ff] border-[#dce7f1] shadow-[0_2px_8px_rgba(67,94,190,0.08)]'
          : 'bg-white border-transparent hover:bg-[#fbfcff] hover:border-[#f2f7ff]'
      )}
    >
      <div className="flex items-start gap-3">
        {/* Avatar with online dot */}
        <div className="relative shrink-0">
          <ChatAvatar profile={customer} />
          {room.status === 'STAFF_ACTIVE' && (
            <span className="absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full bg-[#5ddc97] border-2 border-white" />
          )}
        </div>

        <div className="min-w-0 flex-1">
          {/* Top row: name + time */}
          <div className="flex items-center justify-between gap-2 mb-0.5">
            <p className={cn(
              'truncate text-[13px] font-extrabold',
              isActive ? 'text-[#25396f]' : 'text-[#25396f]'
            )}>
              {getDisplayName(customer)}
            </p>
            <span className="shrink-0 text-[10px] font-semibold text-[#a8b4c7]">
              {formatShortTime(room.lastMessageAt)}
            </span>
          </div>

          {/* Email */}
          <p className="truncate text-[11px] font-semibold text-[#7c8db5] mb-1.5">
            {customer?.email || '—'}
          </p>

          {/* Preview */}
          <p className={cn(
            'line-clamp-1 text-[12px] leading-relaxed',
            hasUnread ? 'font-bold text-[#25396f]' : 'font-medium text-[#7c8db5]'
          )}>
            {preview}
          </p>

          {/* Bottom row: status + unread count */}
          <div className="mt-2 flex items-center justify-between gap-2">
            <RoomStatusBadge status={room.status} />
            {hasUnread && (
              <span className="grid h-5 min-w-5 place-items-center rounded-full bg-[#435ebe] px-1.5 text-[9px] font-black text-white">
                {room.staffUnreadCount}
              </span>
            )}
          </div>
        </div>
      </div>
    </button>
  );
});

RoomItem.displayName = 'RoomItem';

export const ConversationList: React.FC<ConversationListProps> = ({
  rooms,
  activeRoomId,
  filter,
  search,
  isLoading,
  onFilterChange,
  onSearchChange,
  onSelectRoom,
}) => {
  return (
    <aside className="flex min-h-0 flex-col overflow-hidden border-r border-[#dce7f1] bg-white">
      {/* Header */}
      <div className="shrink-0 border-b border-[#f2f7ff] bg-white px-4 pt-5 pb-4">
        <h6 className="mb-4 text-[11px] font-extrabold uppercase tracking-widest text-[#7c8db5]">
          Hội thoại
        </h6>

        {/* Search */}
        <div className="relative mb-3">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-[#a8b4c7]" />
          <input
            value={search}
            onChange={(e) => onSearchChange(e.target.value)}
            placeholder="Tìm theo tên hoặc email..."
            className="h-10 w-full rounded-[8px] border border-[#dce7f1] bg-[#f8fafc] pl-10 pr-3 text-sm font-semibold text-[#25396f] outline-none transition focus:border-[#435ebe] focus:bg-white focus:ring-2 focus:ring-[#435ebe]/10 placeholder:text-[#a8b4c7]"
          />
        </div>

        {/* Filter tabs */}
        <div className="flex gap-1">
          {filters.map((item) => {
            const Icon = item.icon;
            return (
              <button
                key={item.id}
                onClick={() => onFilterChange(item.id)}
                title={item.label}
                className={cn(
                  'flex flex-1 h-8 items-center justify-center rounded-[6px] transition-all text-[10px] font-extrabold uppercase tracking-wide',
                  filter === item.id
                    ? 'bg-[#435ebe] text-white shadow-sm'
                    : 'text-[#7c8db5] hover:bg-[#f2f7ff] hover:text-[#435ebe]'
                )}
              >
                <Icon set={filter === item.id ? 'bold' : 'light'} primaryColor="currentColor" size={15} />
              </button>
            );
          })}
        </div>
      </div>

      {/* Room list */}
      <div className="min-h-0 flex-1 overflow-y-auto overscroll-contain p-3">
        {isLoading ? (
          <InboxSkeleton />
        ) : rooms.length === 0 ? (
          <div className="flex h-full flex-col items-center justify-center px-6 py-16 text-center">
            <div className="w-14 h-14 rounded-[12px] bg-[#f2f7ff] flex items-center justify-center mb-4">
              <MailSearch className="h-7 w-7 text-[#435ebe]/50" />
            </div>
            <p className="text-[13px] font-extrabold text-[#25396f]">Không có hội thoại nào</p>
            <p className="mt-1 text-[11px] font-semibold text-[#7c8db5] leading-relaxed">
              Thử áp dụng bộ lọc khác hoặc tìm kiếm
            </p>
          </div>
        ) : (
          <div className="space-y-1.5">
            {rooms.map((room) => (
              <RoomItem key={room.id} room={room} isActive={room.id === activeRoomId} onSelect={onSelectRoom} />
            ))}
          </div>
        )}
      </div>
    </aside>
  );
};
