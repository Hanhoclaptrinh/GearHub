import React, { memo } from 'react';
import { Inbox, MailSearch, Search, UserCheck, UserPlus, Archive, BellDot } from 'lucide-react';
import { cn } from '../../../utils/cn';
import type { ChatRoomSummary, InboxFilter } from '../types';
import { formatShortTime, getDisplayName } from '../utils';
import { ChatAvatar } from './ChatAvatar';
import { RoomStatusBadge } from './RoomStatusBadge';
import { InboxSkeleton } from './InboxSkeleton';

const filters: Array<{ id: InboxFilter; label: string; icon: React.ElementType }> = [
  { id: 'all', label: 'Tất cả', icon: Inbox },
  { id: 'unclaimed', label: 'Đang đợi', icon: UserPlus },
  { id: 'mine', label: 'Của tôi', icon: UserCheck },
  { id: 'closed', label: 'Đã đóng', icon: Archive },
  { id: 'unread', label: 'Chưa đọc', icon: BellDot },
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
  const preview = room.lastMessageContent || 'No messages yet';

  return (
    <button
      onClick={() => onSelect(room.id)}
      className={cn(
        'w-full rounded-lg p-4 text-left transition-all ring-1',
        isActive
          ? 'bg-white text-slate-950 ring-white shadow-xl'
          : 'bg-white/[0.045] text-slate-200 ring-white/5 hover:bg-white/[0.08] hover:ring-white/10'
      )}
    >
      <div className="flex items-start gap-3">
        <ChatAvatar profile={customer} />
        <div className="min-w-0 flex-1">
          <div className="flex items-start justify-between gap-3">
            <div className="min-w-0">
              <p className={cn('truncate text-sm font-black', isActive ? 'text-slate-950' : 'text-white')}>
                {getDisplayName(customer)}
              </p>
              <p className={cn('truncate text-xs font-semibold', isActive ? 'text-slate-500' : 'text-slate-400')}>
                {customer?.email || 'Unknown email'}
              </p>
            </div>
            <span className={cn('shrink-0 text-[10px] font-black uppercase', isActive ? 'text-slate-500' : 'text-slate-500')}>
              {formatShortTime(room.lastMessageAt)}
            </span>
          </div>

          <p className={cn('mt-3 line-clamp-2 text-xs leading-relaxed', isActive ? 'text-slate-600' : 'text-slate-400')}>
            {preview}
          </p>

          <div className="mt-3 flex items-center justify-between gap-2">
            <div className="flex min-w-0 items-center gap-2">
              <RoomStatusBadge status={room.status} />
              {room.staff && (
                <span className={cn('truncate text-[10px] font-bold', isActive ? 'text-slate-500' : 'text-slate-500')}>
                  {room.staff.fullName || room.staff.email}
                </span>
              )}
            </div>
            {room.staffUnreadCount > 0 && (
              <span className="grid h-6 min-w-6 place-items-center rounded-full bg-orange-500 px-2 text-[10px] font-black text-white">
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
    <aside className="flex min-h-0 flex-col border-r border-white/10 bg-slate-950/80">
      <div className="sticky top-0 z-10 border-b border-white/10 bg-slate-950/95 p-4 backdrop-blur">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-lg font-black uppercase tracking-tight text-white">Quản lý tin nhắn</h1>
            <p className="text-xs font-semibold text-slate-500">Hộp thư chung </p>
          </div>
          <div className="rounded-full bg-emerald-400/10 px-3 py-1 text-[10px] font-black uppercase text-emerald-200 ring-1 ring-emerald-300/20">
            Live
          </div>
        </div>

        <div className="mt-4 grid grid-cols-5 gap-1 rounded-lg bg-white/[0.04] p-1 ring-1 ring-white/5">
          {filters.map((item) => (
            <button
              key={item.id}
              onClick={() => onFilterChange(item.id)}
              className={cn(
                'flex h-9 items-center justify-center rounded-md transition-all',
                filter === item.id ? 'bg-white text-slate-950' : 'text-slate-500 hover:bg-white/[0.06] hover:text-white'
              )}
              title={item.label}
            >
              <item.icon className="h-4 w-4" />
            </button>
          ))}
        </div>

        <div className="relative mt-4">
          <Search className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-500" />
          <input
            value={search}
            onChange={(event) => onSearchChange(event.target.value)}
            placeholder="Search name or email"
            className="h-11 w-full rounded-lg border border-white/10 bg-white/[0.04] pl-10 pr-3 text-sm font-semibold text-white outline-none transition focus:border-cyan-300/40 focus:bg-white/[0.07]"
          />
        </div>
      </div>

      <div className="min-h-0 flex-1 overflow-y-auto p-3">
        {isLoading ? (
          <InboxSkeleton />
        ) : rooms.length === 0 ? (
          <div className="flex h-full flex-col items-center justify-center px-8 text-center">
            <MailSearch className="h-10 w-10 text-slate-600" />
            <p className="mt-4 text-sm font-black text-white">Không có tin nhắn nào</p>
            <p className="mt-1 text-xs font-semibold leading-relaxed text-slate-500">Thử tìm kiếm với từ khóa khác hoặc áp dụng bộ lọc khác</p>
          </div>
        ) : (
          <div className="space-y-2">
            {rooms.map((room) => (
              <RoomItem key={room.id} room={room} isActive={room.id === activeRoomId} onSelect={onSelectRoom} />
            ))}
          </div>
        )}
      </div>
    </aside>
  );
};
