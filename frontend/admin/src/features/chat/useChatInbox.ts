import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { io, type Socket } from 'socket.io-client';
import { toast } from 'sonner';
import { authService } from '../../services/auth.service';
import { chatService } from '../../services/chat.service';
import type {
  ChatMessage,
  ChatRoomSummary,
  InboxFilter,
  MessageNewPayload,
  MessagesReadPayload,
  RoomClaimedPayload,
  RoomClosedPayload,
  RoomUpdatedPayload,
  TypingPayload
} from './types';
import { sortRoomsForInbox } from './utils';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000';

const filterToParams = (filter: InboxFilter, currentUserId?: string) => {
  switch (filter) {
    case 'unclaimed':
      return { status: 'NEED_HUMAN' as const };
    case 'mine':
      return currentUserId ? { mine: true } : {};
    case 'closed':
      return { status: 'CLOSED' as const };
    case 'unread':
      return { unreadOnly: true };
    default:
      return {};
  }
};

export function useChatInbox() {
  const currentUser = authService.getCurrentUser();
  const [rooms, setRooms] = useState<ChatRoomSummary[]>([]);
  const [activeRoomId, setActiveRoomId] = useState<string | null>(null);
  const [activeRoom, setActiveRoom] = useState<ChatRoomSummary | null>(null);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [nextCursor, setNextCursor] = useState<string | null>(null);
  const [filter, setFilter] = useState<InboxFilter>('all');
  const [search, setSearch] = useState('');
  const [roomsLoading, setRoomsLoading] = useState(true);
  const [messagesLoading, setMessagesLoading] = useState(false);
  const [olderLoading, setOlderLoading] = useState(false);
  const [actionLoading, setActionLoading] = useState(false);
  const [typingUsers, setTypingUsers] = useState<Record<string, string[]>>({});
  const socketRef = useRef<Socket | null>(null);
  const typingTimerRef = useRef<number | null>(null);
  const activeRoomIdRef = useRef<string | null>(null);
  const pendingClientMessageIdsRef = useRef<string[]>([]);

  useEffect(() => {
    activeRoomIdRef.current = activeRoomId;
  }, [activeRoomId]);

  const upsertRoom = useCallback((room: ChatRoomSummary) => {
    setRooms((current) => {
      const exists = current.some((item) => item.id === room.id);
      const next = exists ? current.map((item) => item.id === room.id ? { ...item, ...room } : item) : [room, ...current];
      return sortRoomsForInbox(next);
    });
    setActiveRoom((current) => current?.id === room.id ? { ...current, ...room } : current);
  }, []);

  const loadRooms = useCallback(async () => {
    setRoomsLoading(true);
    try {
      const response = await chatService.getRooms({
        ...filterToParams(filter, currentUser?.id),
        search: search.trim() || undefined,
        page: 1,
        limit: 50,
      });
      const sorted = sortRoomsForInbox(response.items);
      setRooms(sorted);
      if (!activeRoomId && sorted[0]) setActiveRoomId(sorted[0].id);
    } catch (error: any) {
      toast.error(error?.response?.data?.message || 'Không thể tải tin nhắn');
    } finally {
      setRoomsLoading(false);
    }
  }, [activeRoomId, currentUser?.id, filter, search]);

  const loadActiveRoom = useCallback(async (roomId: string) => {
    setMessagesLoading(true);
    try {
      const [room, messagePage] = await Promise.all([
        chatService.getRoom(roomId),
        chatService.getMessages(roomId, { take: 30 }),
        chatService.markRead(roomId),
      ]);
      setActiveRoom(room);
      upsertRoom({ ...room, staffUnreadCount: 0 });
      setMessages(messagePage.items);
      setNextCursor(messagePage.nextCursor);
      socketRef.current?.emit('room:join', { roomId });
    } catch (error: any) {
      toast.error(error?.response?.data?.message || 'Không thể mở đoạn chat');
    } finally {
      setMessagesLoading(false);
    }
  }, [upsertRoom]);

  const loadOlderMessages = useCallback(async () => {
    if (!activeRoomId || !nextCursor || olderLoading) return;
    setOlderLoading(true);
    try {
      const page = await chatService.getMessages(activeRoomId, { cursor: nextCursor, take: 30 });
      setMessages((current) => [...page.items, ...current]);
      setNextCursor(page.nextCursor);
    } catch (error: any) {
      toast.error(error?.response?.data?.message || 'Không thể tải tin nhắn cũ hơn');
    } finally {
      setOlderLoading(false);
    }
  }, [activeRoomId, nextCursor, olderLoading]);

  useEffect(() => {
    const timeout = window.setTimeout(() => {
      loadRooms();
    }, 250);
    return () => window.clearTimeout(timeout);
  }, [loadRooms]);

  useEffect(() => {
    if (activeRoomId) loadActiveRoom(activeRoomId);
  }, [activeRoomId, loadActiveRoom]);

  useEffect(() => {
    const token = localStorage.getItem('admin_token');
    if (!token) return;

    const socket = io(`${API_BASE_URL}/chat`, {
      auth: { token },
      transports: ['websocket', 'polling'],
    });
    socketRef.current = socket;

    const joinActiveRoom = () => {
      const roomId = activeRoomIdRef.current;
      if (roomId) socket.emit('room:join', { roomId });
    };

    socket.on('connect', joinActiveRoom);
    socket.on('message:new', (payload: MessageNewPayload) => {
      if (payload.clientMessageId) {
        pendingClientMessageIdsRef.current = pendingClientMessageIdsRef.current.filter((id) => id !== payload.clientMessageId);
      }
      upsertRoom(payload.room);
      setMessages((current) => {
        if (payload.clientMessageId) {
          const replaced = current.map((message) =>
            message.clientMessageId === payload.clientMessageId ? payload.message : message
          );
          if (replaced.some((message) => message.id === payload.message.id)) return replaced;
        }
        if (current.some((message) => message.id === payload.message.id)) return current;
        return payload.message.roomId === activeRoomIdRef.current ? [...current, payload.message] : current;
      });
      if (payload.message.roomId === activeRoomIdRef.current) {
        chatService.markRead(payload.message.roomId).catch(() => undefined);
      }
    });

    socket.on('room:updated', (payload: RoomUpdatedPayload) => upsertRoom(payload.room));
    socket.on('room:claimed', (payload: RoomClaimedPayload) => upsertRoom(payload.room));
    socket.on('room:closed', (payload: RoomClosedPayload) => upsertRoom(payload.room));
    socket.on('messages:read', (payload: MessagesReadPayload) => {
      upsertRoom(payload.room);
      if (payload.roomId === activeRoomIdRef.current) {
        setMessages((current) => current.map((message) => ({
          ...message,
          status: message.senderId !== payload.readerId ? 'READ' : message.status,
          readAt: message.senderId !== payload.readerId ? payload.readAt : message.readAt,
        })));
      }
    });
    socket.on('exception', (error: any) => {
      const failedId = pendingClientMessageIdsRef.current.shift();
      if (failedId) {
        setMessages((current) => current.map((message) =>
          message.clientMessageId === failedId ? { ...message, optimistic: false, failed: true } : message
        ));
      }
      toast.error(error?.message || 'Không thể gửi tin nhắn');
    });
    socket.on('typing:start', (payload: TypingPayload) => {
      setTypingUsers((current) => ({
        ...current,
        [payload.roomId]: Array.from(new Set([...(current[payload.roomId] || []), payload.userId])),
      }));
    });
    socket.on('typing:stop', (payload: TypingPayload) => {
      setTypingUsers((current) => ({
        ...current,
        [payload.roomId]: (current[payload.roomId] || []).filter((id) => id !== payload.userId),
      }));
    });

    return () => {
      if (typingTimerRef.current) {
        window.clearTimeout(typingTimerRef.current);
        typingTimerRef.current = null;
      }
      socket.disconnect();
      socketRef.current = null;
    };
  }, [upsertRoom]);

  const sendMessage = useCallback(async (content: string) => {
    if (!activeRoomId || !content.trim() || !currentUser) return;
    const clientMessageId = `local-${Date.now()}-${Math.random().toString(36).slice(2)}`;
    const optimisticMessage: ChatMessage = {
      id: clientMessageId,
      roomId: activeRoomId,
      senderId: currentUser.id,
      content: content.trim(),
      type: 'TEXT',
      status: 'SENT',
      readAt: null,
      isAi: false,
      createdAt: new Date().toISOString(),
      clientMessageId,
      optimistic: true,
    };

    setMessages((current) => [...current, optimisticMessage]);
    pendingClientMessageIdsRef.current.push(clientMessageId);
    socketRef.current?.emit('message:send', { roomId: activeRoomId, content: content.trim(), clientMessageId });
  }, [activeRoomId, currentUser]);

  const emitTyping = useCallback((isTyping: boolean) => {
    if (!activeRoomId) return;
    socketRef.current?.emit(isTyping ? 'typing:start' : 'typing:stop', { roomId: activeRoomId });
    if (typingTimerRef.current) window.clearTimeout(typingTimerRef.current);
    if (isTyping) {
      typingTimerRef.current = window.setTimeout(() => {
        socketRef.current?.emit('typing:stop', { roomId: activeRoomId });
      }, 1200);
    }
  }, [activeRoomId]);

  const claimRoom = useCallback(async () => {
    if (!activeRoomId) return;
    setActionLoading(true);
    try {
      const room = await chatService.claimRoom(activeRoomId);
      upsertRoom(room);
      setActiveRoom(room);
      toast.success('Đã tiếp nhận tin nhắn');
    } catch (error: any) {
      toast.error(error?.response?.data?.message || 'Không thể tiếp nhận tin nhắn');
    } finally {
      setActionLoading(false);
    }
  }, [activeRoomId, upsertRoom]);

  const closeRoom = useCallback(async () => {
    if (!activeRoomId) return;
    setActionLoading(true);
    try {
      const result = await chatService.closeRoom(activeRoomId);
      upsertRoom(result.room);
      setActiveRoom(result.room);
      toast.success('Đã đóng đoạn chat');
    } catch (error: any) {
      toast.error(error?.response?.data?.message || 'Không thể đóng đoạt chat');
    } finally {
      setActionLoading(false);
    }
  }, [activeRoomId, upsertRoom]);

  const activeTypingUsers = useMemo(() => {
    if (!activeRoomId) return [];
    return typingUsers[activeRoomId] || [];
  }, [activeRoomId, typingUsers]);

  return {
    currentUser,
    rooms,
    activeRoom,
    activeRoomId,
    messages,
    nextCursor,
    filter,
    search,
    roomsLoading,
    messagesLoading,
    olderLoading,
    actionLoading,
    activeTypingUsers,
    setFilter,
    setSearch,
    setActiveRoomId,
    loadOlderMessages,
    sendMessage,
    emitTyping,
    claimRoom,
    closeRoom,
    refreshRooms: loadRooms,
  };
}
