import {
  Controller,
  Get,
  Param,
  Post,
  Query,
  Request,
  UseGuards,
} from '@nestjs/common';
import { Role } from '@prisma/client';
import { Roles } from 'src/common/decorators/roles.decorator';
import { JwtAuthGuard } from 'src/common/guards/jwt-auth.guard';
import { RolesGuard } from 'src/common/guards/roles.guard';
import { ChatService } from './chat.service';
import { GetAdminRoomsQueryDto } from './dto/get-admin-rooms-query.dto';
import { ChatGateway } from './gateway/chat.gateway';

@Controller('admin/chat')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN, Role.STAFF)
export class AdminChatController {
  constructor(
    private readonly chatService: ChatService,
    private readonly chatGateway: ChatGateway,
  ) {}

  @Get('rooms')
  getRooms(@Request() req, @Query() query: GetAdminRoomsQueryDto) {
    return this.chatService.getAdminRooms(this.toSocketUser(req), query);
  }

  @Get('rooms/:roomId')
  getRoomDetail(@Request() req, @Param('roomId') roomId: string) {
    return this.chatService.getAdminRoomDetail(this.toSocketUser(req), roomId);
  }

  @Post('rooms/:roomId/claim')
  async claimRoom(@Request() req, @Param('roomId') roomId: string) {
    const user = this.toSocketUser(req);
    const result = await this.chatService.claimRoom(user, roomId);

    this.chatGateway.publishRoomClaimed(result.socketRoom, user.id);
    this.chatGateway.publishRoomUpdated(result.socketRoom);

    return result.room;
  }

  @Post('rooms/:roomId/close')
  async closeRoom(@Request() req, @Param('roomId') roomId: string) {
    const user = this.toSocketUser(req);
    const result = await this.chatService.closeRoom(user, roomId);

    if (result.socketMessage) {
      this.chatGateway.publishMessageNew({
        message: result.socketMessage,
        room: result.socketRoom,
      });
    }

    this.chatGateway.publishRoomClosed(result.socketRoom, user.id);
    this.chatGateway.publishRoomUpdated(result.socketRoom);

    return {
      room: result.room,
      message: result.message,
    };
  }

  private toSocketUser(req) {
    return this.chatService.toSocketUser({
      id: req.user.userId,
      email: req.user.email,
      role: req.user.role as Role,
    });
  }
}
