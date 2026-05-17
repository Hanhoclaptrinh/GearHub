import React, { useEffect, useMemo, useRef } from "react";
import {
  Archive,
  CheckCheck,
  Loader2,
  Lock,
  MessageSquareText,
  UserPlus,
} from "lucide-react";
import { Button } from "../../../components/ui/Button";
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
  const isCustomer = isCustomerMessage(message, room);

  if (isSystem) {
    return (
      <div className="flex justify-center py-2">
        <div className="rounded-full bg-white/[0.06] px-4 py-2 text-xs font-bold text-slate-400 ring-1 ring-white/10">
          {message.content}
        </div>
      </div>
    );
  }

  return (
    <div className={cn("flex gap-3", isMine ? "justify-end" : "justify-start")}>
      {!isMine && (
        <ChatAvatar profile={room.customer} size="sm" className="mt-1" />
      )}
      <div className={cn("max-w-[78%]", isMine && "items-end text-right")}>
        <div
          className={cn(
            "rounded-lg px-4 py-3 text-sm font-semibold leading-relaxed shadow-sm ring-1",
            isMine
              ? "bg-cyan-300 text-slate-950 ring-cyan-100/40"
              : "bg-white/[0.08] text-slate-100 ring-white/10",
            message.optimistic && "opacity-70",
            message.failed && "bg-red-500/20 text-red-100 ring-red-400/30",
          )}
        >
          {message.content}
        </div>
        <div
          className={cn(
            "mt-1 flex items-center gap-2 text-[10px] font-bold uppercase text-slate-500",
            isMine && "justify-end",
          )}
        >
          <span>{isCustomer ? "Customer" : "Staff"}</span>
          <span>{formatMessageTime(message.createdAt)}</span>
          {isMine && (
            <span
              className={cn(
                "inline-flex items-center gap-1",
                message.status === "READ" && "text-emerald-300",
              )}
            >
              <CheckCheck className="h-3 w-3" />
              {message.optimistic ? "Sending" : message.status}
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
    if (!room)
      return { disabled: true, reason: "Chọn một cuộc hội thoại để trả lời" };
    if (room.status === "CLOSED")
      return { disabled: true, reason: "Cuộc hội thoại đã kết thúc" };
    if (!room.staffId)
      return {
        disabled: true,
        reason: "Tiếp nhận cuộc trò chuyện trước khi bắt đầu nhắn",
      };
    if (room.staffId !== currentUser?.id)
      return {
        disabled: true,
        reason: "Cuộc hội thoại này đã được chuyển tiếp cho nhân viên khác.",
      };
    return { disabled: false, reason: "" };
  }, [currentUser?.id, room]);

  const canCloseRoom =
    !!room &&
    room.status !== "CLOSED" &&
    (currentUser?.role === "ADMIN" || room.staffId === currentUser?.id);

  if (!room) {
    return (
      <section className="flex min-h-0 flex-1 flex-col items-center justify-center bg-slate-950 text-center">
        <div className="grid h-16 w-16 place-items-center rounded-lg bg-white/[0.06] ring-1 ring-white/10">
          <MessageSquareText className="h-8 w-8 text-slate-500" />
        </div>
        <h2 className="mt-5 text-lg font-black uppercase text-white">
          Không có đoạn chat nào được chọn
        </h2>
        <p className="mt-2 max-w-sm text-sm font-semibold leading-relaxed text-slate-500">
          Chọn một đoạn chat để đánh giá ngữ cảnh và trả lời khách hàng
        </p>
      </section>
    );
  }

  return (
    <section className="flex min-h-0 flex-1 flex-col bg-slate-950">
      <header className="sticky top-0 z-10 flex items-center justify-between gap-4 border-b border-white/10 bg-slate-950/95 px-5 py-4 backdrop-blur">
        <div className="flex min-w-0 items-center gap-3">
          <ChatAvatar profile={room.customer} />
          <div className="min-w-0">
            <h2 className="truncate text-base font-black uppercase text-white">
              {getDisplayName(room.customer)}
            </h2>
            <p className="truncate text-xs font-semibold text-slate-500">
              {room.customer?.email}
            </p>
          </div>
        </div>
        <div className="flex shrink-0 items-center gap-2">
          <RoomStatusBadge status={room.status} />
          {!room.staffId && room.status !== "CLOSED" && (
            <Button
              size="sm"
              className="gap-2 bg-cyan-300 text-slate-950 hover:bg-cyan-200"
              onClick={onClaim}
              isLoading={actionLoading}
            >
              <UserPlus className="h-4 w-4" />
              Claim
            </Button>
          )}
          {canCloseRoom && (
            <Button
              size="sm"
              variant="ghost"
              className="gap-2 text-slate-300 hover:bg-white/10 hover:text-white"
              onClick={onRequestClose}
            >
              <Archive className="h-4 w-4" />
              Close
            </Button>
          )}
        </div>
      </header>

      <div ref={scrollRef} className="min-h-0 flex-1 overflow-y-auto px-5 py-5">
        {hasOlder && (
          <div className="mb-4 flex justify-center">
            <button
              onClick={onLoadOlder}
              disabled={olderLoading}
              className="rounded-full bg-white/[0.06] px-4 py-2 text-xs font-black uppercase text-slate-300 ring-1 ring-white/10 hover:bg-white/[0.1] disabled:opacity-50"
            >
              {olderLoading ? "Loading..." : "Load older"}
            </button>
          </div>
        )}

        {isLoading ? (
          <div className="flex h-full items-center justify-center text-slate-500">
            <Loader2 className="h-6 w-6 animate-spin" />
          </div>
        ) : messages.length === 0 ? (
          <div className="flex h-full flex-col items-center justify-center text-center">
            <Lock className="h-9 w-9 text-slate-600" />
            <p className="mt-4 text-sm font-black text-white">
              Chưa có tin nhắn
            </p>
            <p className="mt-1 text-xs font-semibold text-slate-500">
              Lịch sử trò chuyện sẽ hiển thị ở đây
            </p>
          </div>
        ) : (
          <div className="space-y-5">
            {messages.map((message) => (
              <MessageBubble
                key={message.id}
                message={message}
                room={room}
                currentUserId={currentUser?.id}
              />
            ))}
          </div>
        )}

        {typingUserIds.length > 0 && (
          <div className="mt-4 flex items-center gap-2 text-xs font-bold text-cyan-200">
            <span className="flex gap-1">
              <span className="h-1.5 w-1.5 animate-bounce rounded-full bg-cyan-200" />
              <span className="h-1.5 w-1.5 animate-bounce rounded-full bg-cyan-200 [animation-delay:120ms]" />
              <span className="h-1.5 w-1.5 animate-bounce rounded-full bg-cyan-200 [animation-delay:240ms]" />
            </span>
            Khách hàng đang nhập
          </div>
        )}
      </div>

      <MessageComposer
        disabled={composerState.disabled}
        disabledReason={composerState.reason}
        onSend={onSend}
        onTyping={onTyping}
      />
    </section>
  );
};
