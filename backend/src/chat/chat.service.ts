import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { Role, RoomStatus } from '@prisma/client';
import { SendMessageDto } from './dto/send-message.dto';
import { JoinRoomDto } from './dto/join-room.dto';
import { MarkRoomReadDto } from './dto/mark-room-read.dto';
import { SocketUser } from './types/socket-user.type';
import { ChatRepository, ChatRoomRecord } from './repositories/chat.repository';
import { TypingDto } from './dto/typing.dto';
import { GetMessagesQueryDto } from './dto/get-messages-query.dto';
import { GetAdminRoomsQueryDto } from './dto/get-admin-rooms-query.dto';
import {
  toChatRoomSummaryResponse,
  toMessageResponse,
  MessagesPageResponseDto,
  AdminRoomsPageResponseDto,
  ChatRoomSummaryResponseDto,
  LatestCustomerRoomResponseDto,
} from './dto/chat-response.dto';
import { AiChatService } from 'src/ai/ai-chat.service';

@Injectable()
export class ChatService {
  private readonly logger = new Logger(ChatService.name);

  constructor(
    private readonly chatRepository: ChatRepository,
    private readonly aiChatService: AiChatService,
  ) { }

  async joinRoom(user: SocketUser, data: JoinRoomDto) {
    const room = await this.resolveRoom(user, data.roomId);
    const readAt = new Date();

    const updatedRoom = await this.chatRepository.transaction(async (tx) => {
      return this.chatRepository.markRoomAsRead({
        roomId: room.id,
        readerRole: user.role,
        readAt,
        tx,
      });
    });

    return {
      room: updatedRoom,
      readAt,
    };
  }

  async sendMessage(user: SocketUser, data: SendMessageDto) {
    const content = data.content.trim();
    if (!content) {
      throw new BadRequestException('Nội dung tin nhắn không được để trống');
    }

    const room = await this.resolveRoom(user, data.roomId);
    if (room.status === RoomStatus.CLOSED) {
      throw new BadRequestException('Không thể gửi tin nhắn vì phòng đã đóng');
    }

    const now = new Date();
    const result = await this.chatRepository.transaction(async (tx) => {
      const currentRoom = await this.chatRepository.findRoomById(room.id, tx);
      if (!currentRoom) {
        throw new NotFoundException('Không tìm thấy đoạn chat');
      }

      if (currentRoom.status === RoomStatus.CLOSED) {
        throw new BadRequestException(
          'Không thể gửi tin nhắn vì phòng đã đóng',
        );
      }

      return this.chatRepository.createMessageAndUpdateRoom({
        roomId: currentRoom.id,
        senderId: user.id,
        senderRole: user.role,
        roomStatus: currentRoom.status,
        content,
        now,
        tx,
      });
    });

    return {
      ...result,
      clientMessageId: data.clientMessageId,
    };
  }

  async markRoomAsRead(user: SocketUser, data: MarkRoomReadDto) {
    const room = await this.resolveRoom(user, data.roomId);
    const readAt = new Date();

    const updatedRoom = await this.chatRepository.transaction(async (tx) => {
      return this.chatRepository.markRoomAsRead({
        roomId: room.id,
        readerRole: user.role,
        readAt,
        tx,
      });
    });

    return {
      room: updatedRoom,
      readAt,
    };
  }

  async getLatestMyRoom(
    userId: string,
  ): Promise<LatestCustomerRoomResponseDto> {
    // lay phong chat cuoi cung cua user
    // case 1: user chua tung chat -> tao moi
    // case 2: user dang chat -> vao lai chinh phong chat tiep tuc chat - khong tao phong moi
    // case 3: room closed -> vao room closed truoc do -> hien option new chat
    const room = await this.chatRepository.findLatestCustomerRoom(userId);
    if (!room) {
      return {
        room: null,
        isClosed: false,
        canStartNewRoom: true,
      };
    }

    const isClosed = room.status === RoomStatus.CLOSED;
    return {
      room: toChatRoomSummaryResponse(room),
      isClosed,
      canStartNewRoom: isClosed,
    };
  }

  async createNewCustomerRoom(
    userId: string,
  ): Promise<LatestCustomerRoomResponseDto> {
    const room = await this.chatRepository.transaction(async (tx) => {
      const activeRoom = await this.chatRepository.findActiveCustomerRoom(
        userId,
        tx,
      );
      if (activeRoom) {
        // neu user dang co chat chua closed -> vao chinh phong do - khong tao room moi
        return activeRoom;
      }

      // AI-enabled rooms start in BOT_ONLY; otherwise preserve human support flow.
      return this.chatRepository.createCustomerRoom(
        userId,
        this.aiChatService.isEnabled()
          ? RoomStatus.BOT_ONLY
          : RoomStatus.NEED_HUMAN,
        tx,
      );
    });

    return {
      room: toChatRoomSummaryResponse(room),
      isClosed: room.status === RoomStatus.CLOSED,
      canStartNewRoom: room.status === RoomStatus.CLOSED,
    };
  }

  async getRoomMessages(
    user: SocketUser,
    roomId: string,
    query: GetMessagesQueryDto,
  ): Promise<MessagesPageResponseDto> {
    await this.resolveRoom(user, roomId);

    if (query.cursor) {
      const cursor = await this.chatRepository.messageExistsInRoom(
        roomId,
        query.cursor,
      );
      if (!cursor) {
        throw new BadRequestException('Tin nhắn không hợp lệ');
      }
    }

    const page = await this.chatRepository.getMessagesPage({
      roomId,
      cursor: query.cursor,
      take: query.take ?? 30,
    });

    return {
      items: page.items.map(toMessageResponse),
      nextCursor: page.nextCursor,
    };
  }

  async markRoomAsReadFromRest(user: SocketUser, roomId: string) {
    const result = await this.markRoomAsRead(user, { roomId });

    return {
      room: toChatRoomSummaryResponse(result.room),
      socketRoom: result.room,
      readAt: result.readAt,
    };
  }

  async getAdminRooms(
    user: SocketUser,
    query: GetAdminRoomsQueryDto,
  ): Promise<AdminRoomsPageResponseDto> {
    this.assertStaffOrAdmin(user);

    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const result = await this.chatRepository.getAdminRooms({
      status: query.status,
      staffId: query.mine ? user.id : undefined,
      search: query.search?.trim() || undefined,
      unreadOnly: query.unreadOnly,
      page,
      limit,
    });

    return {
      items: result.items.map(toChatRoomSummaryResponse),
      total: result.total,
      page,
      limit,
    };
  }

  async getAdminRoomDetail(
    user: SocketUser,
    roomId: string,
  ): Promise<ChatRoomSummaryResponseDto> {
    this.assertStaffOrAdmin(user);

    const room = await this.chatRepository.findRoomDetailById(roomId);
    if (!room) {
      throw new NotFoundException('Không tìm thấy đoạn chat');
    }

    return toChatRoomSummaryResponse(room);
  }

  async claimRoom(user: SocketUser, roomId: string) {
    this.assertStaffOrAdmin(user); // dam bao nguoi thuc hien claim la staff hoac admin

    // chi thuc hien logic khi chua co ai nhan hoac nguoi dang nhan chinh la cu
    const result = await this.chatRepository.claimRoom({
      roomId,
      staffId: user.id,
    });

    if (!result.room) {
      throw new NotFoundException('Không tìm thấy đoạn chat');
    }

    if (result.count === 0) {
      if (result.room.status === RoomStatus.CLOSED) {
        throw new BadRequestException('Không thể vào phòng đã đóng');
      }

      if (result.room.staffId === user.id) {
        return {
          room: toChatRoomSummaryResponse(result.room),
          socketRoom: result.room,
        };
      }

      throw new ConflictException('Đoạn chat đang có nhân viên khác tham gia');
    }

    return {
      room: toChatRoomSummaryResponse(result.room),
      socketRoom: result.room,
    };
  }

  async closeRoom(user: SocketUser, roomId: string) {
    this.assertStaffOrAdmin(user);

    const now = new Date();
    const result = await this.chatRepository.transaction(async (tx) => {
      const room = await this.chatRepository.findRoomById(roomId, tx);
      if (!room) {
        throw new NotFoundException('Không tìm thấy đoạn chat');
      }

      if (room.status === RoomStatus.CLOSED) {
        return {
          room,
          message: null,
        };
      }

      this.assertCanCloseRoom(user, room);

      return this.chatRepository.closeRoom({
        roomId,
        staffId: user.id,
        now,
        tx,
      });
    });

    return {
      room: toChatRoomSummaryResponse(result.room),
      socketRoom: result.room,
      socketMessage: result.message,
      message: result.message ? toMessageResponse(result.message) : null,
    };
  }

  async assertCanUseTyping(user: SocketUser, data: TypingDto) {
    await this.resolveRoom(user, data.roomId);
  }

  async respondWithAiIfEligible(
    user: SocketUser,
    result: Awaited<ReturnType<ChatRepository['createMessageAndUpdateRoom']>>,
    onStart?: () => void,
  ) {
    return this.aiChatService.respondToUserMessage({
      room: result.room,
      userMessage: result.message,
      senderRole: user.role,
      onStart,
    });
  }

  scheduleAiResponseIfEligible(
    user: SocketUser,
    result: Awaited<
      ReturnType<ChatRepository['createMessageAndUpdateRoom']>
    > & {
      clientMessageId?: string;
    },
    publish: (
      aiResult: Awaited<ReturnType<AiChatService['respondToUserMessage']>>,
    ) => void,
    onStart?: () => void,
    onEnd?: () => void,
  ) {
    void this.respondWithAiIfEligible(user, result, onStart)
      .then((aiResult) => {
        if (aiResult) {
          publish(aiResult);
        }
      })
      .catch((error) => {
        this.logger.warn(
          `AI response skipped for room=${result.room.id} message=${result.message.id}: ${this.errorMessage(error)}`,
        );
      })
      .finally(() => {
        if (onEnd) {
          onEnd();
        }
      });
  }

  private async resolveRoom(
    user: SocketUser,
    roomId?: string,
  ): Promise<ChatRoomRecord> {
    if (roomId) {
      const room = await this.chatRepository.findRoomById(roomId);
      if (!room) {
        throw new NotFoundException('Không tìm thấy đoạn chat');
      }

      this.assertCanAccessRoom(user, room);
      return room;
    }

    if (user.role !== Role.USER) {
      throw new BadRequestException(
        'Nhân viên và Quản trị viên phải cung cấp roomId',
      );
    }

    const room = await this.chatRepository.findActiveCustomerRoom(user.id);
    if (room) {
      return room;
    }

    throw new BadRequestException(
      'Không có cuộc trò chuyện đang hoạt động. Vui lòng bắt đầu cuộc trò chuyện mới.',
    );
  }

  private assertCanAccessRoom(user: SocketUser, room: ChatRoomRecord) {
    if (user.role === Role.USER && room.userId !== user.id) {
      throw new ForbiddenException('Bạn không thể truy cập đoạn chat này');
    }
  }

  private assertStaffOrAdmin(user: SocketUser) {
    if (user.role !== Role.ADMIN && user.role !== Role.STAFF) {
      throw new ForbiddenException(
        'Chỉ nhân viên hoặc quản trị viên mới truy cập vào đoạn chat',
      );
    }
  }

  private assertCanCloseRoom(user: SocketUser, room: ChatRoomRecord) {
    if (user.role === Role.ADMIN) {
      return;
    }

    if (room.staffId !== user.id) {
      throw new ForbiddenException(
        'Chỉ nhân viên đang phụ trách đoạn chat mới có thể đóng',
      );
    }
  }

  toSocketUser(user: { id: string; email?: string; role: Role }): SocketUser {
    return {
      id: user.id,
      email: user.email ?? '',
      role: user.role,
    };
  }

  private errorMessage(error: unknown) {
    return error instanceof Error ? error.message : String(error);
  }
}
