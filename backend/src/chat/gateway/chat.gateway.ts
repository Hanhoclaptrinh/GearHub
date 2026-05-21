import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
  WsException,
} from '@nestjs/websockets';
import {
  BadRequestException,
  HttpException,
  Logger,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { Role } from '@prisma/client';
import { Server } from 'socket.io';
import { ChatService } from '../chat.service';
import { ChatSocketAuthGuard } from '../guards/chat-socket-auth.guard';
import type { AuthenticatedSocket } from '../types/socket-user.type';
import type {
  ClientToServerEvents,
  InterServerEvents,
  ServerToClientEvents,
} from '../types/chat-socket-events.type';
import { JoinRoomDto } from '../dto/join-room.dto';
import { SendMessageDto } from '../dto/send-message.dto';
import { MarkRoomReadDto } from '../dto/mark-room-read.dto';
import { TypingDto } from '../dto/typing.dto';

@UsePipes(
  new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }),
)
@WebSocketGateway({
  namespace: '/chat',
  cors: {
    origin: true,
    credentials: true,
  },
})
export class ChatGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  private server: Server<
    ClientToServerEvents,
    ServerToClientEvents,
    InterServerEvents
  >;

  private readonly logger = new Logger(ChatGateway.name);
  private readonly socketUsers = new Map<string, string>();

  constructor(
    private readonly chatService: ChatService,
    private readonly socketAuthGuard: ChatSocketAuthGuard,
  ) { }

  // middleware auth cho socket
  afterInit(
    server: Server<
      ClientToServerEvents,
      ServerToClientEvents,
      InterServerEvents
    >,
  ) {
    server.use(async (socket, next) => {
      try {
        const user = await this.socketAuthGuard.authenticate(socket);
        (socket as AuthenticatedSocket).data.user = user;
        next();
      } catch (error) {
        next(error instanceof Error ? error : new Error('Unauthorized'));
      }
    });
  }

  async handleConnection(client: AuthenticatedSocket) {
    const user = client.data.user; // lay user da duoc auth tu afterinit
    this.socketUsers.set(client.id, user.id); // luu socket id tuong ung userid

    // join room chat
    await client.join(this.userRoom(user.id));
    if (this.isStaff(user.role)) {
      await client.join('staff:online');
    }

    this.logger.log(`Chat socket connected: ${client.id} user=${user.id}`);
  }

  handleDisconnect(client: AuthenticatedSocket) {
    this.socketUsers.delete(client.id);
    this.logger.log(`Chat socket disconnected: ${client.id}`);
  }

  @SubscribeMessage('room:join')
  async handleJoinRoom(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: JoinRoomDto,
  ) {
    try {
      const result = await this.chatService.joinRoom(client.data.user, data); // kiem tra user co quyen join room khong
      await client.join(this.chatRoom(result.room.id)); // join room

      client.emit('room:joined', result);
      this.publishRoomUpdated(result.room);
      this.publishMessagesRead(
        result.room,
        client.data.user.role,
        client.data.user.id,
        result.readAt,
      );

      return result;
    } catch (error) {
      throw this.toWsException(error);
    }
  }

  @SubscribeMessage('message:send')
  async handleSendMessage(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: SendMessageDto,
  ) {
    try {
      const result = await this.chatService.sendMessage(client.data.user, data);
      await client.join(this.chatRoom(result.room.id));

      // broadcast tin nhan cho nguoi trong room
      this.server.to(this.chatRoom(result.room.id)).emit('message:new', {
        clientMessageId: result.clientMessageId,
        message: result.message,
        room: result.room,
      });

      this.publishRoomUpdated(result.room);

      this.chatService.scheduleAiResponseIfEligible(
        client.data.user,
        result,
        (aiResult) => {
          if (!aiResult) return;
          this.server.to(this.chatRoom(aiResult.room.id)).emit('message:new', {
            message: aiResult.message,
            room: aiResult.room,
          });
          this.publishRoomUpdated(aiResult.room);
        },
        () => {
          this.server.to(this.chatRoom(result.room.id)).emit('typing:start', {
            roomId: result.room.id,
            userId: 'ai',
          });
        },
        () => {
          this.server.to(this.chatRoom(result.room.id)).emit('typing:stop', {
            roomId: result.room.id,
            userId: 'ai',
          });
        },
      );

      return result;
    } catch (error) {
      throw this.toWsException(error);
    }
  }

  @SubscribeMessage('messages:read')
  async handleMessagesRead(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: MarkRoomReadDto,
  ) {
    try {
      const result = await this.chatService.markRoomAsRead(
        client.data.user,
        data,
      );
      this.publishRoomUpdated(result.room);
      this.publishMessagesRead(
        result.room,
        client.data.user.role,
        client.data.user.id,
        result.readAt,
      );

      return result;
    } catch (error) {
      throw this.toWsException(error);
    }
  }

  @SubscribeMessage('typing:start')
  async handleTypingStart(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: TypingDto,
  ) {
    try {
      await this.chatService.assertCanUseTyping(client.data.user, data);
      client.to(this.chatRoom(data.roomId)).emit('typing:start', {
        roomId: data.roomId,
        userId: client.data.user.id,
      });
    } catch (error) {
      throw this.toWsException(error);
    }
  }

  @SubscribeMessage('typing:stop')
  async handleTypingStop(
    @ConnectedSocket() client: AuthenticatedSocket,
    @MessageBody() data: TypingDto,
  ) {
    try {
      await this.chatService.assertCanUseTyping(client.data.user, data);
      client.to(this.chatRoom(data.roomId)).emit('typing:stop', {
        roomId: data.roomId,
        userId: client.data.user.id,
      });
    } catch (error) {
      throw this.toWsException(error);
    }
  }

  publishMessageNew(
    payload: Parameters<ServerToClientEvents['message:new']>[0],
  ) {
    this.server.to(this.chatRoom(payload.room.id)).emit('message:new', payload);
  }

  publishRoomUpdated(
    room: Parameters<ServerToClientEvents['room:updated']>[0]['room'],
  ) {
    this.server
      .to(this.chatRoom(room.id))
      .to(this.userRoom(room.userId))
      .to('staff:online')
      .emit('room:updated', { room });
  }

  publishMessagesRead(
    room: Parameters<ServerToClientEvents['messages:read']>[0]['room'],
    readerRole: Role,
    readerId: string,
    readAt: Date,
  ) {
    this.server.to(this.chatRoom(room.id)).emit('messages:read', {
      roomId: room.id,
      readerId,
      readerRole,
      readAt,
      room,
    });
  }

  publishRoomClaimed(
    room: Parameters<ServerToClientEvents['room:claimed']>[0]['room'],
    staffId: string,
  ) {
    this.server
      .to(this.chatRoom(room.id))
      .to(this.userRoom(room.userId))
      .to('staff:online')
      .emit('room:claimed', {
        roomId: room.id,
        staffId,
        status: room.status,
        room,
      });
  }

  publishRoomClosed(
    room: Parameters<ServerToClientEvents['room:closed']>[0]['room'],
    closedById: string,
  ) {
    this.server
      .to(this.chatRoom(room.id))
      .to(this.userRoom(room.userId))
      .to('staff:online')
      .emit('room:closed', {
        roomId: room.id,
        closedById,
        status: room.status,
        room,
      });
  }

  private chatRoom(roomId: string) {
    return `room:${roomId}`;
  }

  private userRoom(userId: string) {
    return `user:${userId}`;
  }

  private isStaff(role: Role) {
    return role === Role.ADMIN || role === Role.STAFF;
  }

  private toWsException(error: unknown) {
    if (error instanceof WsException) {
      return error;
    }

    if (error instanceof HttpException) {
      return new WsException({
        statusCode: error.getStatus(),
        message: error.message,
        error: error.getResponse(),
      });
    }

    if (error instanceof BadRequestException) {
      return new WsException(error.message);
    }

    return new WsException('Lỗi chat');
  }
}
