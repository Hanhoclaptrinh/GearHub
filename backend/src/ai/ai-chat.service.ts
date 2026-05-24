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
  // lock theo roomid và msgid tránh trùng lặp tin nhắn
  // không sinh ra 2 câu trả lời cùng lúc cho 1 tin nhắn - user spam
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

  // check trạng thái phòng chat
  isEnabled() {
    const value = this.configService.get<string>('AI_CHAT_ENABLED');
    return ['1', 'true', 'yes', 'on'].includes((value ?? '').toLowerCase());
  }

  /**
   * xử lý tin nhắn của người dùng trong phòng chat và sinh câu trả lời tự động bằng RAG AI
   * 
   * kiểm tra tính hợp lệ của tin nhắn (chỉ xử lý tin nhắn text mới nhất của khách hàng trong phòng BOT_ONLY)
   * xử lý trùng lặp tin nhắn, tránh user spam
   * kiểm tra yêu cầu gặp nhân viên hỗ trợ (nếu có) và chuyển giao
   * AI RAG (streaming chunk-by-chunk)
   */
  async respondToUserMessage(params: {
    room: ChatRoomRecord;
    userMessage: ChatMessageRecord;
    senderRole: Role;
    onStart?: () => void;
    onChunk?: (chunk: string) => void;
  }) {
    if (!this.isStrictlyEligible(params)) {
      return null;
    }

    const roomId = params.room.id;
    const messageId = params.userMessage.id;

    // tránh race condition cục bộ
    // bỏ qua nếu phòng chat hoặc tin nhắn này đang được xử lý song song
    if (
      this.roomLocks.has(roomId) ||
      this.processingMessageIds.has(messageId)
    ) {
      return null;
    }

    // locking
    this.roomLocks.add(roomId);
    this.processingMessageIds.add(messageId);

    try {
      // kiểm tra trạng thái phòng, đảm bảo chưa bị thay đổi
      const room = await this.chatRepository.findRoomById(roomId);
      if (!this.canUseRoomForAi(room, params.userMessage.senderId)) {
        return null;
      }

      // check yêu cầu chuyển giao
      // chuyển room mode sang WAITTING nếu có yêu cầu gặp staff
      if (
        this.safetyService.isHumanHandoffRequest(params.userMessage.content)
      ) {
        return this.handoffToHuman(roomId, messageId);
      }

      // callback AI typing
      if (params.onStart) {
        params.onStart();
      }

      const response = await this.generateResponse(roomId, params.userMessage, params.onChunk);

      const content = this.safetyService.sanitizeModelOutput(response.content);
      const now = new Date();

      // fallback
      if (response.usedFallback && params.onChunk) {
        params.onChunk(content);
      }

      // ghi db
      // chặn race condition
      const result = await this.chatRepository.transaction(async (tx) => {
        const currentRoom = await this.chatRepository.findRoomById(roomId, tx);
        if (!this.canUseRoomForAi(currentRoom, params.userMessage.senderId)) {
          return null; // phòng đã bị nhân viên tiếp quản hoặc thay đổi trạng thái
        }

        const latestMessage = await this.chatRepository.getLatestMessageInRoom(
          roomId,
          tx,
        );
        if (!this.isStillLatestTrigger(latestMessage, params.userMessage)) {
          return null;
        }

        // tạo tin nhắn của AI và cập nhật thông tin phòng chat
        return this.chatRepository.createAiMessageAndUpdateRoom({
          roomId: currentRoom.id,
          content,
          now,
          tx,
        });
      });

      if (!result) return null;

      // tracking
      await this.trackUsageBestEffort(roomId, response, content);

      return result;
    } finally {
      this.processingMessageIds.delete(messageId);
      this.roomLocks.delete(roomId);
    }
  }

  /**
   * chuyển giao phòng chat từ AI chatbot sang nhân viên hỗ trợ
   * 
   * chỉ cho phép chuyển giao khi phòng ở mode BOT_ONLY và chưa có nhân viên nào nhận hỗ trợ
   * đảm bảo không có tin nhắn nào mới hơn được gửi vào phòng sau tin nhắn kích hoạt chuyển giao
   * cập nhật trạng thái phòng sang WAITING và thông báo cho hệ thống
   */
  private async handoffToHuman(roomId: string, triggeringMessageId: string) {
    const now = new Date();
    return this.chatRepository.transaction(async (tx) => {
      // check trạng thái phòng mới nhất
      const currentRoom = await this.chatRepository.findRoomById(roomId, tx);
      if (
        !currentRoom ||
        currentRoom.status !== RoomStatus.BOT_ONLY ||
        currentRoom.staffId
      ) {
        return null;
      }

      // check yêu cầu hỗ trợ còn là tin nhắn mới nhất không
      const latestMessage = await this.chatRepository.getLatestMessageInRoom(
        roomId,
        tx,
      );
      if (latestMessage?.id !== triggeringMessageId) {
        return null;
      }

      // WAITTING mode
      return this.chatRepository.handoffRoomToHuman({
        roomId,
        now,
        tx,
      });
    });
  }

  /**
   * RAG (Retrieval-Augmented Generation)
   * 
   * lấy thông tin tóm tắt hội thoại cũ, 12 tin nhắn gần nhất và tìm kiếm ngữ nghĩa lấy top 5 sản phẩm phù hợp nhất với câu hỏi
   * prompt
   * call API
   * catch exeption
   */
  private async generateResponse(
    roomId: string,
    userMessage: ChatMessageRecord,
    onChunk?: (chunk: string) => void,
  ) {
    const startedAt = Date.now();
    const model = this.configService.get<string>('GEMINI_CHAT_MODEL')!;

    try {
      // thu thập đồng thời các nguồn context
      const [aiContext, recentMessages, products] = await Promise.all([
        this.chatRepository.getAiContext(roomId),
        this.chatRepository.getRecentMessages(roomId, 12), // lay 12 tin nhan gan nhat trong phong
        this.productRetrievalService.retrieveProducts(userMessage.content, 5), // thuc hien RAG tim 5 sp phu hop
      ]);

      // dựng prompt
      const promptText = this.promptBuilderService.buildPrompt({
        aiSummary: aiContext?.summary ?? null,
        recentMessages,
        products,
        currentUserMessage: userMessage.content,
      });

      // call gemini
      let content: string;
      if (onChunk) {
        content = await this.callGeminiStream(promptText, model, onChunk);
      } else {
        content = await this.callGemini(promptText, model);
      }

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
      const content = this.safetyService.buildFallbackMessage(); // fallback msg
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

  /**
   * call api ở norm mode để sinh text
   * 
   * config api key
   * config timeout
   * call ai -> gen response
   */
  private async callGemini(promptText: string, modelName: string) {
    const apiKey = this.configService.get<string>('GEMINI_API_KEY');
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY không được cấu hình');
    }

    const timeoutMs = Number(
      this.configService.get<string>('AI_GEMINI_TIMEOUT_MS'),
    );

    // gọi api với timeout
    return this.withTimeout(async () => {
      const genAi = new GoogleGenerativeAI(apiKey);
      const model = genAi.getGenerativeModel({ model: modelName });
      const result = await model.generateContent(promptText);
      return result.response.text();
    }, timeoutMs);
  }

  /**
   * chunk-by-chunk
   * 
   * config
   * streaming
   * loop
   * gen
   */
  private async callGeminiStream(
    promptText: string,
    modelName: string,
    onChunk: (chunk: string) => void,
  ): Promise<string> {
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

      // khởi tạo luồng sinh nội dung stream
      const resultStream = await model.generateContentStream(promptText);
      let accumulatedText = '';

      // loop
      for await (const chunk of resultStream.stream) {
        const text = chunk.text();
        accumulatedText += text;
        onChunk(text); // gửi chunk txt về client bằng socket/sse
      }
      return accumulatedText;
    }, timeoutMs);
  }

  private async withTimeout<T>(work: () => Promise<T>, timeoutMs: number) {
    let timeout: NodeJS.Timeout | undefined;
    try {
      return await Promise.race([
        work(),
        new Promise<never>((_, reject) => {
          timeout = setTimeout(
            () =>
              reject(
                new Error(`Gemini đã quá thời gian phản hồi ${timeoutMs}ms`),
              ),
            timeoutMs,
          );
        }),
      ]);
    } finally {
      if (timeout) clearTimeout(timeout);
    }
  }

  // điều kiện kích hoạt AI mode
  private isStrictlyEligible(params: {
    room: ChatRoomRecord;
    userMessage: ChatMessageRecord;
    senderRole: Role;
  }) {
    return (
      this.isEnabled() && // tính năng AI được active
      params.senderRole === Role.USER && // sender là khách hàng
      params.room.status === RoomStatus.BOT_ONLY && // phòng chat đang ở mode bot-only
      params.room.userId === params.userMessage.senderId && // sender phải là khách hàng đang mở phòng chat
      params.userMessage.type === MessageType.TEXT && // chỉ xử lý txt
      params.userMessage.content.trim().length > 0 && // tin nhắn không được rỗng
      !params.userMessage.isAi // không được loop
    );
  }

  // check trạng thái phòng cho ai
  private canUseRoomForAi(
    room: ChatRoomRecord | null,
    senderId: string | null,
  ): room is ChatRoomRecord {
    return Boolean(
      room && // phòng tồn tại
      room.status === RoomStatus.BOT_ONLY && // phòng ở mode bot-only
      !room.staffId && // chưa có ai claim
      room.userId === senderId, // sender là người active phòng
    );
  }

  // check trạng thái tin nhắn  active
  private isStillLatestTrigger(
    latestMessage: ChatMessageRecord | null,
    userMessage: ChatMessageRecord,
  ) {
    return Boolean(
      latestMessage &&
      latestMessage.id === userMessage.id &&
      latestMessage.roomId === userMessage.roomId &&
      latestMessage.senderId === userMessage.senderId &&
      latestMessage.type === MessageType.TEXT &&
      !latestMessage.isAi,
    );
  }

  // tracking token
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
