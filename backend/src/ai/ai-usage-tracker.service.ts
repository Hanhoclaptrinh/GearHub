import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from 'src/prisma/prisma.service';

@Injectable()
export class AiUsageTracker {
  private readonly logger = new Logger(AiUsageTracker.name);

  estimateTokens(...parts: string[]) {
    const chars = parts.reduce((sum, part) => sum + part.length, 0);
    return Math.ceil(chars / 4); /// 1 token/4 ky tu
  }

  async addUsage(roomId: string, estimatedTokens: number) {
    /// luu muc do su dung vao db
    await this.prisma.aiContext.upsert({
      where: { roomId },
      create: {
        roomId,
        tokensUsed: estimatedTokens,
      },
      update: {
        tokensUsed: { increment: estimatedTokens },
      },
    });
  }

  logCompletion(params: {
    roomId: string;
    model: string;
    latencyMs: number;
    estimatedTokens: number;
    retrievedProducts: number;
    usedFallback: boolean;
  }) {
    this.logger.log(
      `AI chat room=${params.roomId} model=${params.model} latencyMs=${params.latencyMs} estimatedTokens=${params.estimatedTokens} products=${params.retrievedProducts} fallback=${params.usedFallback}`,
    );
  }

  logError(roomId: string, error: unknown) {
    const message = error instanceof Error ? error.message : String(error);
    this.logger.warn(`AI chat failed room=${roomId}: ${message}`);
  }

  constructor(private readonly prisma: PrismaService) { }
}
