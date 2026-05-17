import React, { useState } from 'react';
import { ConfirmModal } from '../../components/ui/ConfirmModal';
import { ConversationList } from './components/ConversationList';
import { ConversationView } from './components/ConversationView';
import { CustomerContextSidebar } from './components/CustomerContextSidebar';
import { useChatInbox } from './useChatInbox';

export const ChatCenterPage: React.FC = () => {
  const chat = useChatInbox();
  const [isCloseModalOpen, setIsCloseModalOpen] = useState(false);

  return (
    <div className="-m-6 h-[calc(100vh-5rem)] overflow-hidden bg-slate-950 text-white lg:-m-10 lg:h-[calc(100vh-5rem)]">
      <div className="grid h-full grid-cols-1 overflow-hidden lg:grid-cols-[360px_minmax(0,1fr)] xl:grid-cols-[360px_minmax(0,1fr)_320px]">
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
