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
import { GetMessagesQueryDto } from './dto/get-messages-query.dto';
import { ChatGateway } from './gateway/chat.gateway';

@Controller('chat')
@UseGuards(JwtAuthGuard)
export class ChatController {
  constructor(
    private readonly chatService: ChatService,
    private readonly chatGateway: ChatGateway,
  ) {}

  @Get('my-room')
  @UseGuards(RolesGuard)
  @Roles(Role.USER)
  getMyRoom(@Request() req) {
    return this.chatService.getLatestMyRoom(req.user.userId);
  }

  @Post('rooms')
  @UseGuards(RolesGuard)
  @Roles(Role.USER)
  createRoom(@Request() req) {
    return this.chatService.createNewCustomerRoom(req.user.userId);
  }

  @Get('rooms/:roomId/messages')
  getRoomMessages(
    @Request() req,
    @Param('roomId') roomId: string,
    @Query() query: GetMessagesQueryDto,
  ) {
    return this.chatService.getRoomMessages(
      this.toSocketUser(req),
      roomId,
      query,
    );
  }

  @Post('rooms/:roomId/read')
  async markRoomAsRead(@Request() req, @Param('roomId') roomId: string) {
    const user = this.toSocketUser(req);
    const result = await this.chatService.markRoomAsReadFromRest(user, roomId);

    this.chatGateway.publishRoomUpdated(result.socketRoom);
    this.chatGateway.publishMessagesRead(
      result.socketRoom,
      user.role,
      user.id,
      result.readAt,
    );

    return result.room;
  }

  private toSocketUser(req) {
    return this.chatService.toSocketUser({
      id: req.user.userId,
      email: req.user.email,
      role: req.user.role as Role,
    });
  }
}
