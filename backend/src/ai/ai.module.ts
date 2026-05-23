import { Module } from '@nestjs/common';
import { AiChatService } from './ai-chat.service';
import { AiSafetyService } from './ai-safety.service';
import { AiUsageTracker } from './ai-usage-tracker.service';
import { EmbeddingService } from './embedding.service';
import { ImageSearchController } from './image-search.controller';
import { ImageSearchService } from './image-search.service';
import { ProductRetrievalService } from './product-retrieval.service';
import { ProductImageEmbeddingService } from './product-image-embedding.service';
import { PromptBuilderService } from './prompt-builder.service';
import { ChatRepository } from 'src/chat/repositories/chat.repository';

@Module({
  controllers: [ImageSearchController],
  providers: [
    AiChatService,
    AiSafetyService,
    AiUsageTracker,
    EmbeddingService,
    ImageSearchService,
    ProductImageEmbeddingService,
    ProductRetrievalService,
    PromptBuilderService,
    ChatRepository,
  ],
  exports: [
    AiChatService,
    AiSafetyService,
    EmbeddingService,
    ImageSearchService,
    ProductImageEmbeddingService,
    ProductRetrievalService,
    PromptBuilderService,
  ],
})
export class AiModule {}
