import { Injectable } from '@nestjs/common';
import {
  MessageStatus,
  MessageType,
  Prisma,
  Role,
  RoomStatus,
} from '@prisma/client';
import { PrismaService } from 'src/prisma/prisma.service';

const roomSelect = {
  id: true,
  userId: true,
  staffId: true,
  status: true,
  lastMessageAt: true,
  lastMessageContent: true,
  customerUnreadCount: true,
  staffUnreadCount: true,
} satisfies Prisma.ChatRoomSelect;

const messageSelect = {
  id: true,
  roomId: true,
  senderId: true,
  content: true,
  type: true,
  status: true,
  readAt: true,
  isAi: true,
  createdAt: true,
} satisfies Prisma.MessageSelect;

const userProfileSelect = {
  id: true,
  email: true,
  role: true,
  createdAt: true,
  profile: {
    select: {
      fullName: true,
      phone: true,
      avatarUrl: true,
    },
  },
} satisfies Prisma.UserSelect;

const roomDetailSelect = {
  ...roomSelect,
  createdAt: true,
  user: {
    select: userProfileSelect,
  },
  staff: {
    select: userProfileSelect,
  },
} satisfies Prisma.ChatRoomSelect;

export type ChatRoomRecord = Prisma.ChatRoomGetPayload<{
  select: typeof roomSelect;
}>;
export type ChatMessageRecord = Prisma.MessageGetPayload<{
  select: typeof messageSelect;
}>;
export type ChatRoomDetailRecord = Prisma.ChatRoomGetPayload<{
  select: typeof roomDetailSelect;
}>;
export type PrismaTransaction = Prisma.TransactionClient;

@Injectable()
export class ChatRepository {
  constructor(private readonly prisma: PrismaService) {}

  transaction<T>(callback: (tx: PrismaTransaction) => Promise<T>): Promise<T> {
    return this.prisma.$transaction(callback);
  }

  findRoomById(
    roomId: string,
    tx: PrismaTransaction | PrismaService = this.prisma,
  ) {
    return tx.chatRoom.findUnique({
      where: { id: roomId },
      select: roomSelect,
    });
  }

  findRoomDetailById(
    roomId: string,
    tx: PrismaTransaction | PrismaService = this.prisma,
  ) {
    return tx.chatRoom.findUnique({
      where: { id: roomId },
      select: roomDetailSelect,
    });
  }

  findActiveCustomerRoom(
    userId: string,
    tx: PrismaTransaction | PrismaService = this.prisma,
  ) {
    return tx.chatRoom.findFirst({
      where: {
        userId,
        status: { not: RoomStatus.CLOSED },
      },
      orderBy: [{ updatedAt: 'desc' }, { createdAt: 'desc' }],
      select: roomSelect,
    });
  }

  findLatestCustomerRoom(
    userId: string,
    tx: PrismaTransaction | PrismaService = this.prisma,
  ) {
    return tx.chatRoom.findFirst({
      where: { userId },
      orderBy: [{ updatedAt: 'desc' }, { createdAt: 'desc' }],
      select: roomSelect,
    });
  }

  createCustomerRoom(
    userId: string,
    status: RoomStatus = RoomStatus.NEED_HUMAN,
    tx: PrismaTransaction | PrismaService = this.prisma,
  ) {
    return tx.chatRoom.create({
      data: {
        userId,
        status,
        customerUnreadCount: 0,
        staffUnreadCount: 0,
      },
      select: roomSelect,
    });
  }

  async getMessagesPage(params: {
    roomId: string;
    cursor?: string;
    take: number;
  }) {
    const messages = await this.prisma.message.findMany({
      where: { roomId: params.roomId },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: params.take + 1,
      ...(params.cursor
        ? {
            cursor: { id: params.cursor },
            skip: 1,
          }
        : {}),
      select: messageSelect,
    });

    const hasMore = messages.length > params.take;
    const items = hasMore ? messages.slice(0, params.take) : messages;
    const nextCursor = hasMore ? (items[items.length - 1]?.id ?? null) : null;

    return {
      items: items.reverse(),
      nextCursor,
    };
  }

  messageExistsInRoom(roomId: string, messageId: string) {
    return this.prisma.message.findFirst({
      where: {
        id: messageId,
        roomId,
      },
      select: { id: true },
    });
  }

  async getAdminRooms(params: {
    status?: RoomStatus;
    staffId?: string;
    search?: string;
    unreadOnly?: boolean;
    page: number;
    limit: number;
  }) {
    const where: Prisma.ChatRoomWhereInput = {
      ...(params.status ? { status: params.status } : {}),
      ...(params.staffId ? { staffId: params.staffId } : {}),
      ...(params.unreadOnly ? { staffUnreadCount: { gt: 0 } } : {}),
      ...(params.search
        ? {
            OR: [
              { user: { email: { contains: params.search } } },
              { user: { profile: { fullName: { contains: params.search } } } },
            ],
          }
        : {}),
    };

    const [items, total] = await this.prisma.$transaction([
      this.prisma.chatRoom.findMany({
        where,
        orderBy: [{ lastMessageAt: 'desc' }, { createdAt: 'desc' }],
        skip: (params.page - 1) * params.limit,
        take: params.limit,
        select: roomDetailSelect,
      }),
      this.prisma.chatRoom.count({ where }),
    ]);

    return { items, total };
  }

  async claimRoom(params: { roomId: string; staffId: string }) {
    const result = await this.prisma.chatRoom.updateMany({
      where: {
        id: params.roomId,
        status: { not: RoomStatus.CLOSED },
        OR: [{ staffId: null }, { staffId: params.staffId }],
      },
      data: {
        staffId: params.staffId,
        status: RoomStatus.STAFF_ACTIVE,
      },
    });

    return {
      count: result.count,
      room: await this.findRoomDetailById(params.roomId),
    };
  }

  async createMessageAndUpdateRoom(params: {
    roomId: string;
    senderId: string;
    senderRole: Role;
    roomStatus: RoomStatus;
    content: string;
    now: Date;
    tx: PrismaTransaction;
  }) {
    const message = await params.tx.message.create({
      data: {
        roomId: params.roomId,
        senderId: params.senderId,
        content: params.content,
        type: MessageType.TEXT,
        status: MessageStatus.SENT,
        readAt: null,
        isAi: false,
        createdAt: params.now,
      },
      select: messageSelect,
    });

    const unreadUpdate =
      params.senderRole === Role.USER
        ? params.roomStatus === RoomStatus.BOT_ONLY
          ? {}
          : { staffUnreadCount: { increment: 1 } }
        : { customerUnreadCount: { increment: 1 } };

    const room = await params.tx.chatRoom.update({
      where: { id: params.roomId },
      data: {
        lastMessageAt: params.now,
        lastMessageContent: params.content,
        ...unreadUpdate,
      },
      select: roomDetailSelect,
    });

    return { message, room };
  }

  async createAiMessageAndUpdateRoom(params: {
    roomId: string;
    content: string;
    now: Date;
    tx: PrismaTransaction;
  }) {
    const message = await params.tx.message.create({
      data: {
        roomId: params.roomId,
        senderId: null,
        content: params.content,
        type: MessageType.TEXT,
        status: MessageStatus.SENT,
        readAt: null,
        isAi: true,
        createdAt: params.now,
      },
      select: messageSelect,
    });

    const room = await params.tx.chatRoom.update({
      where: { id: params.roomId },
      data: {
        lastMessageAt: params.now,
        lastMessageContent: params.content,
        customerUnreadCount: { increment: 1 },
      },
      select: roomDetailSelect,
    });

    return { message, room };
  }

  getLatestMessageInRoom(
    roomId: string,
    tx: PrismaTransaction | PrismaService = this.prisma,
  ) {
    return tx.message.findFirst({
      where: { roomId },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      select: messageSelect,
    });
  }

  async handoffRoomToHuman(params: {
    roomId: string;
    now: Date;
    tx: PrismaTransaction;
  }) {
    const message = await params.tx.message.create({
      data: {
        roomId: params.roomId,
        senderId: null,
        content: 'GearHub đã chuyển cuộc trò chuyện sang nhân viên hỗ trợ.',
        type: MessageType.SYSTEM,
        status: MessageStatus.SENT,
        readAt: null,
        isAi: false,
        createdAt: params.now,
      },
      select: messageSelect,
    });

    const room = await params.tx.chatRoom.update({
      where: { id: params.roomId },
      data: {
        status: RoomStatus.NEED_HUMAN,
        staffId: null,
        lastMessageAt: params.now,
        lastMessageContent: message.content,
        staffUnreadCount: { increment: 1 },
      },
      select: roomDetailSelect,
    });

    return { message, room };
  }

  async getRecentMessages(roomId: string, take: number) {
    const messages = await this.prisma.message.findMany({
      where: { roomId },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take,
      select: messageSelect,
    });

    return messages.reverse();
  }

  getAiContext(roomId: string) {
    return this.prisma.aiContext.findUnique({
      where: { roomId },
      select: {
        summary: true,
        tokensUsed: true,
      },
    });
  }

  async markRoomAsRead(params: {
    roomId: string;
    readerRole: Role;
    readAt: Date;
    tx: PrismaTransaction;
  }) {
    const messageSenderFilter =
      params.readerRole === Role.USER
        ? { sender: { is: { role: { in: [Role.ADMIN, Role.STAFF] } } } }
        : { sender: { is: { role: Role.USER } } };

    await params.tx.message.updateMany({
      where: {
        roomId: params.roomId,
        isAi: false,
        status: { not: MessageStatus.READ },
        ...messageSenderFilter,
      },
      data: {
        status: MessageStatus.READ,
        readAt: params.readAt,
      },
    });

    return params.tx.chatRoom.update({
      where: { id: params.roomId },
      data:
        params.readerRole === Role.USER
          ? { customerUnreadCount: 0 }
          : { staffUnreadCount: 0 },
      select: roomSelect,
    });
  }

  async closeRoom(params: {
    roomId: string;
    staffId: string;
    now: Date;
    tx: PrismaTransaction;
  }) {
    const message = await params.tx.message.create({
      data: {
        roomId: params.roomId,
        senderId: params.staffId,
        content: 'Cuộc hội thoại đã kết thúc.',
        type: MessageType.SYSTEM,
        status: MessageStatus.SENT,
        readAt: null,
        isAi: false,
        createdAt: params.now,
      },
      select: messageSelect,
    });

    const room = await params.tx.chatRoom.update({
      where: { id: params.roomId },
      data: {
        status: RoomStatus.CLOSED,
        lastMessageAt: params.now,
        lastMessageContent: message.content,
      },
      select: roomDetailSelect,
    });

    return { room, message };
  }
}
