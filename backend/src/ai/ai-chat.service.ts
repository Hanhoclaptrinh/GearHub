import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenerativeAI } from '@google/generative-ai';
import { MessageType, Role, RoomStatus } from '@prisma/client';
import {
  ChatMessageRecord,
  ChatRepository,
  ChatRoomRecord,
} from 'src/chat/repositories/chat.repository';
import { AiSafetyService } from './ai-safety.service';
import { AiUsageTracker } from './ai-usage-tracker.service';
import { ProductRetrievalService } from './product-retrieval.service';
import { PromptBuilderService } from './prompt-builder.service';
import { AiChatResponse } from './types/ai.types';

@Injectable()
export class AiChatService {
  private readonly logger = new Logger(AiChatService.name);
  /// lock theo roomid va msgid tranh trung lap tin nhan
  /// khong sinh ra 2 cau tra loi cung luc cho 1 tin nhan - user spam
  private readonly roomLocks = new Set<string>();
  private readonly processingMessageIds = new Set<string>();

  constructor(
    private readonly chatRepository: ChatRepository,
    private readonly safetyService: AiSafetyService,
    private readonly productRetrievalService: ProductRetrievalService,
    private readonly promptBuilderService: PromptBuilderService,
    private readonly usageTracker: AiUsageTracker,
    private readonly configService: ConfigService,
  ) { }

  /// kiem tra trang thai cua phong chat
  /// chat voi staff hay voi ai
  isEnabled() {
    const value = this.configService.get<string>('AI_CHAT_ENABLED');
    return ['1', 'true', 'yes', 'on'].includes((value ?? '').toLowerCase());
  }

  async respondToUserMessage(params: {
    room: ChatRoomRecord;
    userMessage: ChatMessageRecord;
    senderRole: Role;
  }) {
    /// loc tin nhan khong du dieu kien
    /// tinh nang AI chat bi tat
    /// sender khong phai khach hang
    /// phong chat khong co trang thai bot-only
    /// tin nhan rong hoac tin nhan he thong
    if (!this.isStrictlyEligible(params)) {
      return null;
    }

    /// lock
    const roomId = params.room.id;
    const messageId = params.userMessage.id;
    if (this.roomLocks.has(roomId) || this.processingMessageIds.has(messageId)) {
      return null;
    }

    this.roomLocks.add(roomId);
    this.processingMessageIds.add(messageId);

    try {
      /// dam bao phong chat dang o mode bot-only va khong co ai claim
      const room = await this.chatRepository.findRoomById(roomId);
      if (!this.canUseRoomForAi(room, params.userMessage.senderId)) {
        return null;
      }

      /// user gap nhan vien ho tro
      if (this.safetyService.isHumanHandoffRequest(params.userMessage.content)) {
        return this.handoffToHuman(roomId, messageId);
      }

      /// RAG
      const response = await this.generateResponse(roomId, params.userMessage);
      const content = this.safetyService.sanitizeModelOutput(response.content); /// lam sach cau tra loi
      const now = new Date();

      /// chan race condition
      const result = await this.chatRepository.transaction(async (tx) => {
        const currentRoom = await this.chatRepository.findRoomById(roomId, tx);
        if (!this.canUseRoomForAi(currentRoom, params.userMessage.senderId)) {
          return null; /// trang thai phong bi thay doi
        }

        /// tin nhan cua AI khong con la tin nhan moi nhat trong phong
        /// huy bo ket qua vua tao
        const latestMessage = await this.chatRepository.getLatestMessageInRoom(
          roomId,
          tx,
        );
        if (!this.isStillLatestTrigger(latestMessage, params.userMessage)) {
          return null;
        }

        return this.chatRepository.createAiMessageAndUpdateRoom({
          roomId: currentRoom.id,
          content,
          now,
          tx,
        });
      });

      /// save token
      /// giai phong lock
      if (!result) return null;

      await this.trackUsageBestEffort(roomId, response, content);

      return result;
    } finally {
      this.processingMessageIds.delete(messageId);
      this.roomLocks.delete(roomId);
    }
  }

  /// chuyen cuoc hoi thoai sang nhan vien
  private async handoffToHuman(roomId: string, triggeringMessageId: string) {
    const now = new Date();
    return this.chatRepository.transaction(async (tx) => {
      /// chuyen giao phong chat dang o mode chatbot va chua co ai claim
      const currentRoom = await this.chatRepository.findRoomById(roomId, tx);
      if (
        !currentRoom ||
        currentRoom.status !== RoomStatus.BOT_ONLY ||
        currentRoom.staffId
      ) {
        return null;
      }

      /// race condition
      const latestMessage = await this.chatRepository.getLatestMessageInRoom(
        roomId,
        tx,
      );
      if (latestMessage?.id !== triggeringMessageId) {
        return null;
      }

      return this.chatRepository.handoffRoomToHuman({
        roomId,
        now,
        tx,
      });
    });
  }

  /// RAG
  /// su dung chat model tao phan hoi cho nguoi dung
  private async generateResponse(
    roomId: string,
    userMessage: ChatMessageRecord,
  ) {
    const startedAt = Date.now();
    const model = this.configService.get<string>('GEMINI_CHAT_MODEL')!;

    try {
      /// thu thap context
      const [aiContext, recentMessages, products] = await Promise.all([
        this.chatRepository.getAiContext(roomId),
        this.chatRepository.getRecentMessages(roomId, 12), /// lay 12 tin nhan gan nhat trong phong
        this.productRetrievalService.retrieveProducts(userMessage.content, 5), /// thuc hien RAG tim 5 sp phu hop
      ]);

      /// cau hinh prompt cho AI khong tra loi lan man
      const promptText = this.promptBuilderService.buildPrompt({
        aiSummary: aiContext?.summary ?? null,
        recentMessages,
        products,
        currentUserMessage: userMessage.content,
      });

      /// call gemini
      const content = await this.callGemini(promptText, model);

      return {
        content,
        promptText,
        retrievedProducts: products,
        latencyMs: Date.now() - startedAt,
        model,
        usedFallback: false,
      };
    } catch (error) {
      this.usageTracker.logError(roomId, error);
      const content = this.safetyService.buildFallbackMessage(); /// fallback msg
      return {
        content,
        promptText: '',
        retrievedProducts: [],
        latencyMs: Date.now() - startedAt,
        model,
        usedFallback: true,
      };
    }
  }

  private async callGemini(promptText: string, modelName: string) {
    const apiKey = this.configService.get<string>('GEMINI_API_KEY');
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY không được cấu hình');
    }

    const timeoutMs = Number(
      this.configService.get<string>('AI_GEMINI_TIMEOUT_MS'),
    );

    return this.withTimeout(async () => {
      const genAi = new GoogleGenerativeAI(apiKey);
      const model = genAi.getGenerativeModel({ model: modelName });
      const result = await model.generateContent(promptText);
      return result.response.text();
    }, timeoutMs);
  }

  private async withTimeout<T>(work: () => Promise<T>, timeoutMs: number) {
    let timeout: NodeJS.Timeout | undefined;
    try {
      return await Promise.race([
        work(),
        new Promise<never>((_, reject) => {
          timeout = setTimeout(
            () => reject(new Error(`Gemini đã quá thời gian phản hồi ${timeoutMs}ms`)),
            timeoutMs,
          );
        }),
      ]);
    } finally {
      if (timeout) clearTimeout(timeout);
    }
  }

  /// dieu kien kich hoat AI mode
  private isStrictlyEligible(params: {
    room: ChatRoomRecord;
    userMessage: ChatMessageRecord;
    senderRole: Role;
  }) {
    return (
      this.isEnabled() && /// tinh nang AI duoc kich hoat
      params.senderRole === Role.USER && /// sender la khach hang
      params.room.status === RoomStatus.BOT_ONLY && /// phong chat dang o mode bot-only
      params.room.userId === params.userMessage.senderId && /// nguoi gui tin nhan phai la khach hang dang mo phong chat
      params.userMessage.type === MessageType.TEXT && /// chi xu ly van ban
      params.userMessage.content.trim().length > 0 && /// tin nhan khong duoc rong
      !params.userMessage.isAi /// khong duoc loop
    );
  }

  /// check trang thai phong cho ai
  private canUseRoomForAi(
    room: ChatRoomRecord | null,
    senderId: string | null,
  ): room is ChatRoomRecord {
    return Boolean(
      room && /// phong ton tai
      room.status === RoomStatus.BOT_ONLY && /// phong o mode bot-only
      !room.staffId && /// phong chua co ai claim
      room.userId === senderId, /// sender la nguoi kich hoat phong
    );
  }

  /// check trang thai tin nhan kich hoat
  private isStillLatestTrigger(
    latestMessage: ChatMessageRecord | null,
    userMessage: ChatMessageRecord,
  ) {
    return Boolean(
      latestMessage &&
      latestMessage.id === userMessage.id && /// id tin nhan moi nhat trong db phai === id tin nhan kich hoat ai
      latestMessage.roomId === userMessage.roomId &&
      latestMessage.senderId === userMessage.senderId &&
      latestMessage.type === MessageType.TEXT &&
      !latestMessage.isAi,
    );
  }

  /// tracking token tieu thu
  private async trackUsageBestEffort(
    roomId: string,
    response: AiChatResponse,
    content: string,
  ) {
    try {
      const estimatedTokens = this.usageTracker.estimateTokens(
        response.promptText,
        content,
      );
      await this.usageTracker.addUsage(roomId, estimatedTokens);
      this.usageTracker.logCompletion({
        roomId,
        model: response.model,
        latencyMs: response.latencyMs,
        estimatedTokens,
        retrievedProducts: response.retrievedProducts.length,
        usedFallback: response.usedFallback,
      });
    } catch (error) {
      this.logger.warn(
        `AI usage tracking skipped room=${roomId}: ${this.errorMessage(error)}`,
      );
    }
  }

  private errorMessage(error: unknown) {
    return error instanceof Error ? error.message : String(error);
  }
}
