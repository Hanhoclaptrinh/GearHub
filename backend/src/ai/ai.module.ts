import { Module } from '@nestjs/common';
import { AiChatService } from './ai-chat.service';
import { AiSafetyService } from './ai-safety.service';
import { AiUsageTracker } from './ai-usage-tracker.service';
import { EmbeddingService } from './embedding.service';
import { ProductRetrievalService } from './product-retrieval.service';
import { PromptBuilderService } from './prompt-builder.service';
import { ChatRepository } from 'src/chat/repositories/chat.repository';

@Module({
  providers: [
    AiChatService,
    AiSafetyService,
    AiUsageTracker,
    EmbeddingService,
    ProductRetrievalService,
    PromptBuilderService,
    ChatRepository,
  ],
  exports: [
    AiChatService,
    AiSafetyService,
    EmbeddingService,
    ProductRetrievalService,
    PromptBuilderService,
  ],
})
export class AiModule {}
