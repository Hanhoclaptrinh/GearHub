import React, { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import {
  AddUser as IconlyAddUser,
  Chat as IconlyChat,
  Notification as IconlyNotification,
  User as IconlyUser,
} from 'react-iconly';
import { ConfirmModal } from '../../components/ui/ConfirmModal';
import { ConversationList } from './components/ConversationList';
import { ConversationView } from './components/ConversationView';
import { CustomerContextSidebar } from './components/CustomerContextSidebar';
import { useChatInbox } from './useChatInbox';
import { chatService } from '../../services/chat.service';
import { cn } from '../../utils/cn';

export const ChatCenterPage: React.FC = () => {
  const chat = useChatInbox();
  const [isCloseModalOpen, setIsCloseModalOpen] = useState(false);

  const { data: allRoomsData } = useQuery({
    queryKey: ['chat', 'room-stats', 'all'],
    queryFn: () => chatService.getRooms({ page: 1, limit: 1 }),
  });

  const { data: unclaimedRoomsData } = useQuery({
    queryKey: ['chat', 'room-stats', 'unclaimed'],
    queryFn: () => chatService.getRooms({ status: 'NEED_HUMAN', page: 1, limit: 1 }),
  });

  const { data: mineRoomsData } = useQuery({
    queryKey: ['chat', 'room-stats', 'mine', chat.currentUser?.id],
    queryFn: () => chatService.getRooms({ mine: true, page: 1, limit: 1 }),
    enabled: Boolean(chat.currentUser?.id),
  });

  const { data: unreadRoomsData } = useQuery({
    queryKey: ['chat', 'room-stats', 'unread'],
    queryFn: () => chatService.getRooms({ unreadOnly: true, page: 1, limit: 1 }),
  });

  const statCards = [
    {
      label: 'Tổng hội thoại',
      value: allRoomsData?.total ?? chat.rooms.length,
      icon: IconlyChat,
      bgClass: 'bg-[#9694ff]',
      onClick: () => chat.setFilter('all'),
      active: chat.filter === 'all',
    },
    {
      label: 'Đang chờ xử lý',
      value: unclaimedRoomsData?.total ?? 0,
      icon: IconlyAddUser,
      bgClass: 'bg-[#57caeb]',
      onClick: () => chat.setFilter('unclaimed'),
      active: chat.filter === 'unclaimed',
    },
    {
      label: 'Của tôi',
      value: mineRoomsData?.total ?? 0,
      icon: IconlyUser,
      bgClass: 'bg-[#5ddc97]',
      onClick: () => chat.setFilter('mine'),
      active: chat.filter === 'mine',
    },
    {
      label: 'Chưa đọc',
      value: unreadRoomsData?.total ?? 0,
      icon: IconlyNotification,
      bgClass: 'bg-[#ff7976]',
      onClick: () => chat.setFilter('unread'),
      active: chat.filter === 'unread',
    },
  ];

  return (
    <div className="flex h-[calc(100vh-8.5rem)] min-h-0 flex-col overflow-hidden">
      <div className="mb-4 grid shrink-0 grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        {statCards.map((card) => {
          const Icon = card.icon;

          return (
            <button
              key={card.label}
              type="button"
              onClick={card.onClick}
              className={cn(
                'border-none shadow-[0_5px_15px_rgba(25,42,70,0.06)] rounded-[12px] bg-white transition-all duration-300 group py-4 px-5 flex items-center gap-4 text-left',
              )}
            >
              <div className={cn('w-11 h-11 rounded-[10px] flex items-center justify-center transition-transform duration-300 group-hover:scale-105 shadow-xs shrink-0 text-white', card.bgClass)}>
                <Icon set="bold" primaryColor="white" size={22} />
              </div>
              <div className="flex-1 min-w-0">
                <h6 className="text-[15px] font-semibold text-[#7c8db5] leading-tight mb-1 truncate">{card.label}</h6>
                <h6 className="text-[24px] font-extrabold text-[#25396f] leading-none mb-0 font-heading truncate">{card.value}</h6>
              </div>
            </button>
          );
        })}
      </div>

      {/* Chat panel */}
      <div className="min-h-0 flex-1 overflow-hidden rounded-[12px] border border-[#dce7f1] bg-white shadow-[0_5px_15px_rgba(25,42,70,0.06)]">
        <div className="grid h-full min-h-0 overflow-hidden grid-cols-1 lg:grid-cols-[360px_minmax(0,1fr)] xl:grid-cols-[360px_minmax(0,1fr)_320px] 2xl:grid-cols-[380px_minmax(0,1fr)_340px]">
          <ConversationList
            rooms={chat.rooms}
            activeRoomId={chat.activeRoomId}
            filter={chat.filter}
            search={chat.search}
            isLoading={chat.roomsLoading}
            onFilterChange={chat.setFilter}
            onSearchChange={chat.setSearch}
            onSelectRoom={chat.setActiveRoomId}
          />

          <ConversationView
            room={chat.activeRoom}
            messages={chat.messages}
            currentUser={chat.currentUser}
            isLoading={chat.messagesLoading}
            olderLoading={chat.olderLoading}
            hasOlder={!!chat.nextCursor}
            actionLoading={chat.actionLoading}
            typingUserIds={chat.activeTypingUsers}
            onLoadOlder={chat.loadOlderMessages}
            onSend={chat.sendMessage}
            onTyping={chat.emitTyping}
            onClaim={chat.claimRoom}
            onRequestClose={() => setIsCloseModalOpen(true)}
          />

          <CustomerContextSidebar room={chat.activeRoom} />
        </div>
      </div>

      <ConfirmModal
        isOpen={isCloseModalOpen}
        onClose={() => setIsCloseModalOpen(false)}
        onConfirm={async () => {
          await chat.closeRoom();
          setIsCloseModalOpen(false);
        }}
        title="Đóng cuộc hội thoại"
        message="Việc này sẽ đóng cuộc hội thoại hiện tại và không thể nhắn tin cho đến khi có cuộc hội thoại mới được mở"
        confirmText="Đóng"
        cancelText="Hủy"
        variant="warning"
        isLoading={chat.actionLoading}
      />
    </div>
  );
};
