import { Module } from '@nestjs/common';
import { ChatService } from './chat.service';
import { ChatController } from './chat.controller';
import { ChatGateway } from './gateway/chat.gateway';
import { ChatRepository } from './repositories/chat.repository';
import { ChatSocketAuthGuard } from './guards/chat-socket-auth.guard';
import { AdminChatController } from './admin-chat.controller';
import { AiModule } from 'src/ai/ai.module';

@Module({
  imports: [AiModule],
  providers: [ChatGateway, ChatService, ChatRepository, ChatSocketAuthGuard],
  controllers: [ChatController, AdminChatController],
})
export class ChatModule {}
