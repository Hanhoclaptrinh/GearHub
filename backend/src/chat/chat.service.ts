import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { Role, RoomStatus, NotificationType } from '@prisma/client';
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
import { NotificationService } from 'src/notification/notification.service';

@Injectable()
export class ChatService {
  private readonly logger = new Logger(ChatService.name);

  constructor(
    private readonly chatRepository: ChatRepository,
    private readonly aiChatService: AiChatService,
    private readonly notificationService: NotificationService,
  ) { }

  /**
   * Cho phép người dùng hoặc nhân viên tham gia vào một phòng chat cụ thể.
   * 
   * xác thực và phân giải thông tin phòng chat
   * thực hiện cập nhật trạng thái đã đọc tin nhắn trong một db transaction để bảo toàn dữ liệu
   * trả về thông tin phòng chat đã cập nhật cùng mốc thời gian đọc
   */
  async joinRoom(user: SocketUser, data: JoinRoomDto) {
    // phân giải phòng chat dựa trên thông tin phiên socket, đồng thời kiểm tra quyền truy cập
    const room = await this.resolveRoom(user, data.roomId);
    const readAt = new Date();

    // cập nhật trạng thái đã đọc của phòng chat dựa theo role để xóa số lượng tin nhắn chưa đọc tương ứng
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

  /**
   * gửi tin nhắn mới vào phòng chat
   * 
   * kiểm tra tính hợp lệ của nội dung tin nhắn
   * xác thực quyền sở hữu và trạng thái hoạt động của phòng chat
   * lưu tin nhắn vào db và cập nhật tin nhắn cuối cùng của phòng chat thông qua transaction
   * gửi thông báo đẩy cho client
   */
  async sendMessage(user: SocketUser, data: SendMessageDto) {
    const content = data.content.trim();
    if (!content) {
      throw new BadRequestException('Nội dung tin nhắn không được để trống');
    }

    // kiểm tra sự tồn tại và quyền truy cập phòng chat của user
    const room = await this.resolveRoom(user, data.roomId);
    // chặn gửi tin nhắn nếu phòng chat đã đóng
    if (room.status === RoomStatus.CLOSED) {
      throw new BadRequestException('Không thể gửi tin nhắn vì phòng đã đóng');
    }

    const now = new Date();
    // thực hiện lưu tin nhắn và cập nhật thông tin phòng chat trong một transaction
    const result = await this.chatRepository.transaction(async (tx) => {
      const currentRoom = await this.chatRepository.findRoomById(room.id, tx);
      if (!currentRoom) {
        throw new NotFoundException('Không tìm thấy đoạn chat');
      }

      // kiểm tra lại trạng thái phòng chat trong transaction để tránh race condition
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

    // tự động gửi thông báo đẩy đến người nhận khi cần thiết
    this.sendChatNotificationIfNeeded(user, result.room, content);

    return {
      ...result,
      clientMessageId: data.clientMessageId,
    };
  }

  /**
   * đánh dấu đã đọc toàn bộ tin nhắn trong phòng chat
   * 
   * phân giải thông tin phòng chat và kiểm tra quyền truy cập của user
   * cập nhật trạng thái đã đọc tin nhắn trong phòng chat dựa theo role thông qua transaction
   * trả về phòng chat đã cập nhật cùng mốc thời gian đọc
   */
  async markRoomAsRead(user: SocketUser, data: MarkRoomReadDto) {
    // phân giải phòng chat dựa trên thông tin phiên socket, đồng thời kiểm tra quyền truy cập
    const room = await this.resolveRoom(user, data.roomId);
    const readAt = new Date();

    // cập nhật trạng thái đã đọc của phòng chat dựa theo role để xóa số lượng tin nhắn chưa đọc tương ứng
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

  /**
   * lấy thông tin phòng chat gần nhất của người dùng hiện tại
   * 
   * phân tích các luồng của khách hàng để quyết định có cho phép mở phòng mới hay không
   * trả về thông tin tóm tắt của phòng chat hiện tại cùng trạng thái đóng/mở của phòng
   */
  async getLatestMyRoom(
    userId: string,
  ): Promise<LatestCustomerRoomResponseDto> {
    // truy vấn tìm phòng chat được tạo gần nhất của người dùng
    // case 1: user chưa từng chat -> tạo mới
    // case 2: user đang chat -> vào lại chính phòng chat tiếp tục chat - không tạo phòng mới
    // case 3: room closed -> vào room closed trước đó -> hiện option chat mới
    const room = await this.chatRepository.findLatestCustomerRoom(userId);
    if (!room) {
      return {
        room: null,
        isClosed: false,
        canStartNewRoom: true,
      };
    }

    // kiểm tra xem phòng chat hiện tại đã đóng hoàn toàn hay chưa
    const isClosed = room.status === RoomStatus.CLOSED;
    return {
      room: toChatRoomSummaryResponse(room),
      isClosed,
      canStartNewRoom: isClosed,
    };
  }

  /**
   * tạo phòng chat mới cho khách hàng
   * 
   * kiểm tra xem người dùng đã có phòng chat nào đang hoạt động chưa để tái sử dụng
   * nếu chưa có, tiến hành khởi tạo phòng chat mới dựa theo cấu hình hỗ trợ AI
   * trả về thông tin tóm tắt của phòng chat mới tạo
   */
  async createNewCustomerRoom(
    userId: string,
  ): Promise<LatestCustomerRoomResponseDto> {
    const room = await this.chatRepository.transaction(async (tx) => {
      const activeRoom = await this.chatRepository.findActiveCustomerRoom(
        userId,
        tx,
      );
      // nếu người dùng đang có phòng chat hoạt động thì đi thẳng vào phòng đó, tránh tạo trùng lặp
      if (activeRoom) {
        return activeRoom;
      }

      // khởi tạo phòng chat mới: ưu tiên chế độ BOT_ONLY nếu hệ thống AI được kích hoạt, ngược lại chuyển thẳng cho nhân viên
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

  /**
   * tiếp nhận hỗ trợ phòng chat (admin/staff)
   * 
   * xác thực quyền hạn của người tiếp nhận
   * gán nhân viên hỗ trợ cho phòng chat nếu chưa có ai tiếp nhận
   * trả về kết quả tiếp nhận hoặc báo lỗi nếu phòng chat đã đóng hoặc đã có nhân viên khác nhận trước đó
   */
  async claimRoom(user: SocketUser, roomId: string) {
    // đảm bảo người thực hiện nhận phòng chat phải là nhân viên hoặc admin
    this.assertStaffOrAdmin(user);

    // thực hiện gán phòng chat cho nhân viên
    const result = await this.chatRepository.claimRoom({
      roomId,
      staffId: user.id,
    });

    if (!result.room) {
      throw new NotFoundException('Không tìm thấy đoạn chat');
    }

    // kiểm tra trường hợp không cập nhật được bản ghi (đã có người nhận hoặc phòng đã đóng)
    if (result.count === 0) {
      if (result.room.status === RoomStatus.CLOSED) {
        throw new BadRequestException('Không thể vào phòng đã đóng');
      }

      // nếu nhân viên đang tham gia là chính người gửi yêu cầu thì vẫn cho phép tiếp tục
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

  /**
   * đóng phòng chat đang hoạt động (admin/staff)
   * 
   * xác thực quyền hạn đóng phòng
   * cập nhật trạng thái phòng sang CLOSED và ghi nhận tin nhắn hệ thống đóng phòng thông qua transaction
   * trả về thông tin phòng chat đã đóng cùng tin nhắn hệ thống tương ứng
   */
  async closeRoom(user: SocketUser, roomId: string) {
    // đảm bảo người thực hiện đóng phòng chat phải là nhân viên hoặc admin
    this.assertStaffOrAdmin(user);

    const now = new Date();
    // thực hiện cập nhật trạng thái phòng chat trong transaction
    const result = await this.chatRepository.transaction(async (tx) => {
      const room = await this.chatRepository.findRoomById(roomId, tx);
      if (!room) {
        throw new NotFoundException('Không tìm thấy đoạn chat');
      }

      // nếu phòng chat đã đóng từ trước thì không làm gì thêm
      if (room.status === RoomStatus.CLOSED) {
        return {
          room,
          message: null,
        };
      }

      // kiểm tra quyền đóng phòng (chỉ admin hoặc nhân viên đang được gán cho phòng chat đó mới có quyền đóng)
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
    onChunk?: (chunk: string) => void,
  ) {
    return this.aiChatService.respondToUserMessage({
      room: result.room,
      userMessage: result.message,
      senderRole: user.role,
      onStart,
      onChunk,
    });
  }

  /**
   * lên lịch và kích hoạt sinh câu trả lời tự động bằng AI trong nền
   * 
   * gọi hàm tạo câu trả lời AI bất đồng bộ ngoài luồng chính để tránh gây block
   * xuất kết quả thông qua callback khi AI phản hồi thành công
   * xử lý lỗi và thực thi callback kết thúc trong mọi trường hợp
   */
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
    onChunk?: (chunk: string) => void,
  ) {
    // sinh phản hồi từ AI
    void this.respondWithAiIfEligible(user, result, onStart, onChunk)
      .then((aiResult) => {
        // phát phản hồi AI thông qua callback nếu kết quả sinh hợp lệ
        if (aiResult) {
          publish(aiResult);
        }
      })
      .catch((error) => {
        // ghi nhận cảnh báo nếu quá trình AI sinh phản hồi bị bỏ qua hoặc gặp lỗi
        this.logger.warn(
          `AI response skipped for room=${result.room.id} message=${result.message.id}: ${this.errorMessage(error)}`,
        );
      })
      .finally(() => {
        // đảm bảo callback kết thúc luôn được thực hiện khi tiến trình hoàn tất
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

  private sendChatNotificationIfNeeded(
    sender: SocketUser,
    room: ChatRoomRecord,
    content: string,
  ) {
    if (
      sender.id === room.userId ||
      (sender.role !== Role.ADMIN && sender.role !== Role.STAFF)
    ) {
      return;
    }

    void this.notificationService.sendToUser(room.userId, {
      notification: {
        title: 'Tin nhắn từ GearHub',
        body: content.length > 80 ? `${content.slice(0, 77)}...` : content,
      },
      data: {
        type: 'chat',
        roomId: room.id,
        route: '/chat',
      },
      type: NotificationType.CHAT,
    });
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
