import React, { useEffect, useMemo, useRef } from "react";
import {
  Archive,
  CheckCheck,
  Loader2,
  Lock,
  MessageSquareText,
  UserPlus,
} from '../../../components/ui/IconlyIcons';
import { cn } from "../../../utils/cn";
import type { User } from "../../../types";
import type { ChatMessage, ChatRoomSummary } from "../types";
import { formatMessageTime, getDisplayName, isCustomerMessage } from "../utils";
import { ChatAvatar } from "./ChatAvatar";
import { MessageComposer } from "./MessageComposer";
import { RoomStatusBadge } from "./RoomStatusBadge";

interface ConversationViewProps {
  room: ChatRoomSummary | null;
  messages: ChatMessage[];
  currentUser: User | null;
  isLoading: boolean;
  olderLoading: boolean;
  hasOlder: boolean;
  actionLoading: boolean;
  typingUserIds: string[];
  onLoadOlder: () => void;
  onSend: (content: string) => void;
  onTyping: (isTyping: boolean) => void;
  onClaim: () => void;
  onRequestClose: () => void;
}

const MessageBubble: React.FC<{
  message: ChatMessage;
  room: ChatRoomSummary;
  currentUserId?: string;
}> = ({ message, room, currentUserId }) => {
  const isSystem = message.type === "SYSTEM";
  const isMine = message.senderId === currentUserId;
  const isAi = message.isAi;
  const isCustomer = isCustomerMessage(message, room);

  if (isSystem) {
    return (
      <div className="flex justify-center py-3">
        <div className="rounded-full bg-[#f2f7ff] border border-[#dce7f1] px-4 py-1.5 text-[11px] font-semibold text-[#7c8db5]">
          {message.content}
        </div>
      </div>
    );
  }

  return (
    <div className={cn("flex items-end gap-2.5", isMine ? "flex-row-reverse" : "flex-row")}>
      {/* Avatar for non-mine messages */}
      {!isMine && !isAi && (
        <ChatAvatar profile={room.customer} size="sm" className="shrink-0 mb-1" />
      )}
      {!isMine && isAi && (
        <div className="shrink-0 mb-1 grid h-8 w-8 place-items-center rounded-full bg-[#edf9f1] text-[#2f8f5b] border border-[#dce7f1]">
          <MessageSquareText className="h-4 w-4" />
        </div>
      )}
      {isMine && <div className="w-8 shrink-0" />}

      <div className={cn("flex flex-col max-w-[72%]", isMine ? "items-end" : "items-start")}>
        {/* Sender label */}
        <p className="mb-1.5 text-[10px] font-extrabold uppercase tracking-widest text-[#a8b4c7] px-1">
          {isAi ? "GearHub AI" : isCustomer ? "Khách hàng" : "Nhân viên"}
        </p>

        {/* Bubble */}
        <div
          className={cn(
            "rounded-[14px] px-4 py-2.5 text-[13px] leading-relaxed",
            // Mine (staff): Mazer .chat pattern — light bg, dark text
            isMine && !message.failed
              ? "bg-white text-[#25396f] shadow-[0_2px_8px_rgba(25,42,70,0.10)] border border-[#dce7f1] rounded-br-none"
              : "",
            // Customer: Mazer .chat-left pattern — brand blue
            !isMine && !isAi && !message.failed
              ? "bg-[#435ebe] text-white rounded-bl-none shadow-[0_2px_8px_rgba(67,94,190,0.25)]"
              : "",
            // AI bot: soft green
            !isMine && isAi && !message.failed
              ? "bg-[#edf9f1] text-[#2f8f5b] border border-[#dce7f1] rounded-bl-none"
              : "",
            message.optimistic && "opacity-60",
            message.failed ? "bg-red-50 text-red-700 border border-red-200 rounded-none" : "",
          )}
        >
          {message.content}
        </div>

        {/* Timestamp + status */}
        <div className={cn("mt-1.5 flex items-center gap-1.5 px-1 text-[10px] text-[#a8b4c7]", isMine && "flex-row-reverse")}>
          <span className="font-semibold">{formatMessageTime(message.createdAt)}</span>
          {isMine && (
            <span className={cn("inline-flex items-center gap-0.5 font-bold", message.status === "READ" ? "text-[#5ddc97]" : "text-[#a8b4c7]")}>
              <CheckCheck className="h-3 w-3" />
              <span>{message.optimistic ? "Đang gửi" : message.status === "READ" ? "Đã đọc" : "Đã gửi"}</span>
            </span>
          )}
        </div>
      </div>
    </div>
  );
};

export const ConversationView: React.FC<ConversationViewProps> = ({
  room,
  messages,
  currentUser,
  isLoading,
  olderLoading,
  hasOlder,
  actionLoading,
  typingUserIds,
  onLoadOlder,
  onSend,
  onTyping,
  onClaim,
  onRequestClose,
}) => {
  const scrollRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    scrollRef.current?.scrollTo({
      top: scrollRef.current.scrollHeight,
      behavior: "smooth",
    });
  }, [messages.length, room?.id]);

  const composerState = useMemo(() => {
    if (!room) return { disabled: true, reason: "Chọn một cuộc hội thoại để trả lời" };
    if (room.status === "CLOSED") return { disabled: true, reason: "Cuộc hội thoại đã kết thúc" };
    if (!room.staffId) return { disabled: true, reason: "Tiếp nhận cuộc trò chuyện trước khi bắt đầu nhắn" };
    if (room.staffId !== currentUser?.id) return { disabled: true, reason: "Cuộc hội thoại này đã được chuyển tiếp cho nhân viên khác." };
    return { disabled: false, reason: "" };
  }, [currentUser?.id, room]);

  const canCloseRoom =
    !!room &&
    room.status !== "CLOSED" &&
    (currentUser?.role === "ADMIN" || room.staffId === currentUser?.id);

  // Empty state — no room selected
  if (!room) {
    return (
      <section className="flex min-h-0 flex-1 flex-col items-center justify-center bg-[#fbfcff] text-center p-8">
        <div className="w-20 h-20 rounded-[18px] bg-white border border-[#dce7f1] shadow-[0_5px_15px_rgba(25,42,70,0.06)] grid place-items-center mb-5">
          <MessageSquareText className="h-9 w-9 text-[#435ebe]" />
        </div>
        <h2 className="text-[15px] font-extrabold uppercase tracking-wide text-[#25396f]">
          Chưa chọn hội thoại
        </h2>
        <p className="mt-2 max-w-xs text-[13px] font-semibold leading-relaxed text-[#7c8db5]">
          Chọn một hội thoại bên trái để xem lịch sử và trả lời khách hàng
        </p>
      </section>
    );
  }

  return (
    <section className="flex min-h-0 flex-1 flex-col overflow-hidden">
      {/* ── Chat Header ── */}
      <header className="shrink-0 flex items-center justify-between gap-4 border-b border-[#dce7f1] bg-white px-5 py-3.5">
        <div className="flex min-w-0 items-center gap-3">
          <div className="relative shrink-0">
            <ChatAvatar profile={room.customer} />
            {room.status === 'STAFF_ACTIVE' && (
              <span className="absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full bg-[#5ddc97] border-2 border-white" />
            )}
          </div>
          <div className="min-w-0">
            <h2 className="truncate text-[14px] font-extrabold text-[#25396f]">
              {getDisplayName(room.customer)}
            </h2>
            <p className="truncate text-[11px] font-semibold text-[#7c8db5]">
              {room.customer?.email}
            </p>
          </div>
        </div>

        <div className="flex shrink-0 items-center gap-2">
          <RoomStatusBadge status={room.status} />

          {!room.staffId && room.status !== "CLOSED" && (
            <button
              onClick={onClaim}
              disabled={actionLoading}
              className="h-9 rounded-[6px] bg-[#435ebe] px-4 text-[12px] font-extrabold text-white inline-flex items-center gap-1.5 hover:bg-[#3950a2] disabled:opacity-60 transition-colors shadow-[0_2px_8px_rgba(67,94,190,0.25)]"
            >
              {actionLoading ? (
                <Loader2 className="h-3.5 w-3.5 animate-spin" />
              ) : (
                <UserPlus className="h-3.5 w-3.5" />
              )}
              Nhận chat
            </button>
          )}

          {canCloseRoom && (
            <button
              onClick={onRequestClose}
              className="h-9 rounded-[6px] border border-[#dce7f1] bg-white px-4 text-[12px] font-extrabold text-[#607080] inline-flex items-center gap-1.5 hover:bg-[#f2f7ff] hover:text-[#25396f] hover:border-[#b0c0d8] transition-colors"
            >
              <Archive className="h-3.5 w-3.5" />
              Đóng chat
            </button>
          )}
        </div>
      </header>

      {/* ── Messages area ── */}
      <div
        ref={scrollRef}
        className="min-h-0 flex-1 overflow-y-auto overscroll-contain bg-[#f8fafc] px-5 py-5 space-y-5"
      >
        {/* Load older */}
        {hasOlder && (
          <div className="flex justify-center">
            <button
              onClick={onLoadOlder}
              disabled={olderLoading}
              className="rounded-full border border-[#dce7f1] bg-white px-5 py-2 text-[11px] font-extrabold uppercase tracking-wide text-[#607080] shadow-sm hover:bg-[#f2f7ff] hover:text-[#25396f] disabled:opacity-50 transition"
            >
              {olderLoading ? "Đang tải..." : "Tải tin nhắn cũ hơn"}
            </button>
          </div>
        )}

        {/* Loading spinner */}
        {isLoading ? (
          <div className="flex h-full items-center justify-center">
            <Loader2 className="h-7 w-7 animate-spin text-[#435ebe]" />
          </div>
        ) : messages.length === 0 ? (
          <div className="flex h-full flex-col items-center justify-center text-center py-20">
            <div className="w-16 h-16 rounded-[14px] bg-white border border-[#dce7f1] shadow-sm grid place-items-center mb-4">
              <Lock className="h-7 w-7 text-[#a8b4c7]" />
            </div>
            <p className="text-[13px] font-extrabold text-[#25396f]">Chưa có tin nhắn</p>
            <p className="mt-1 text-[12px] font-semibold text-[#7c8db5]">
              Lịch sử trò chuyện sẽ hiển thị ở đây
            </p>
          </div>
        ) : (
          messages.map((message) => (
            <MessageBubble
              key={message.id}
              message={message}
              room={room}
              currentUserId={currentUser?.id}
            />
          ))
        )}

        {/* Typing indicator */}
        {typingUserIds.length > 0 && (
          <div className="flex items-center gap-2 text-[11px] font-extrabold text-[#435ebe]">
            <span className="flex gap-1 items-center">
              <span className="h-2 w-2 animate-bounce rounded-full bg-[#435ebe]" style={{ animationDelay: '0ms' }} />
              <span className="h-2 w-2 animate-bounce rounded-full bg-[#435ebe]" style={{ animationDelay: '120ms' }} />
              <span className="h-2 w-2 animate-bounce rounded-full bg-[#435ebe]" style={{ animationDelay: '240ms' }} />
            </span>
            Khách hàng đang nhập...
          </div>
        )}
      </div>

      {/* ── Composer ── */}
      <MessageComposer
        disabled={composerState.disabled}
        disabledReason={composerState.reason}
        onSend={onSend}
        onTyping={onTyping}
      />
    </section>
  );
};
