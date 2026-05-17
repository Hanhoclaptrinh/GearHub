import { MessageStatus, MessageType, Role, RoomStatus } from '@prisma/client';
import { AiChatService } from './ai-chat.service';
import { AiSafetyService } from './ai-safety.service';

const room = {
  id: 'room-1',
  userId: 'user-1',
  staffId: null,
  status: RoomStatus.BOT_ONLY,
  lastMessageAt: null,
  lastMessageContent: null,
  customerUnreadCount: 0,
  staffUnreadCount: 0,
};

const userMessage = {
  id: 'message-1',
  roomId: 'room-1',
  senderId: 'user-1',
  content: 'Tư vấn laptop đi làm',
  type: MessageType.TEXT,
  status: MessageStatus.SENT,
  readAt: null,
  isAi: false,
  createdAt: new Date('2026-05-17T00:00:00.000Z'),
};

const aiMessage = {
  id: 'ai-message-1',
  roomId: 'room-1',
  senderId: null,
  content: 'Gợi ý laptop mỏng nhẹ',
  type: MessageType.TEXT,
  status: MessageStatus.SENT,
  readAt: null,
  isAi: true,
  createdAt: new Date('2026-05-17T00:00:01.000Z'),
};

describe('AiChatService', () => {
  function createService(overrides: Record<string, any> = {}) {
    const chatRepository = {
      findRoomById: jest.fn().mockResolvedValue(room),
      transaction: jest.fn(async (callback) => callback({})),
      getLatestMessageInRoom: jest.fn().mockResolvedValue(userMessage),
      createAiMessageAndUpdateRoom: jest.fn().mockResolvedValue({
        room: { ...room, lastMessageContent: aiMessage.content },
        message: aiMessage,
      }),
      handoffRoomToHuman: jest.fn().mockResolvedValue({
        room: { ...room, status: RoomStatus.NEED_HUMAN },
        message: {
          ...userMessage,
          id: 'system-1',
          senderId: null,
          type: MessageType.SYSTEM,
          content: 'GearHub đã chuyển cuộc trò chuyện sang nhân viên hỗ trợ.',
        },
      }),
      getAiContext: jest.fn().mockResolvedValue({ summary: 'Khach can laptop.' }),
      getRecentMessages: jest.fn().mockResolvedValue([userMessage]),
      ...overrides.chatRepository,
    };

    const productRetrievalService = {
      retrieveProducts: jest.fn().mockResolvedValue([]),
      ...overrides.productRetrievalService,
    };
    const promptBuilderService = {
      buildPrompt: jest.fn().mockReturnValue('bounded prompt'),
      ...overrides.promptBuilderService,
    };
    const usageTracker = {
      estimateTokens: jest.fn().mockReturnValue(10),
      addUsage: jest.fn().mockResolvedValue(undefined),
      logCompletion: jest.fn(),
      logError: jest.fn(),
      ...overrides.usageTracker,
    };

    const service = new AiChatService(
      chatRepository as any,
      new AiSafetyService(),
      productRetrievalService as any,
      promptBuilderService as any,
      usageTracker as any,
      {
        get: jest.fn((key: string) => {
          if (key === 'AI_CHAT_ENABLED') return 'true';
          if (key === 'GEMINI_CHAT_MODEL') return 'gemini-test';
          return undefined;
        }),
        ...overrides.configService,
      } as any,
    );

    jest.spyOn(service as any, 'callGemini').mockResolvedValue(aiMessage.content);

    return {
      service,
      chatRepository,
      productRetrievalService,
      promptBuilderService,
      usageTracker,
      callGemini: (service as any).callGemini as jest.Mock,
    };
  }

  it('triggers the AI path for BOT_ONLY USER text messages', async () => {
    const { service, chatRepository, callGemini } = createService();

    const result = await service.respondToUserMessage({
      room,
      userMessage,
      senderRole: Role.USER,
    });

    expect(callGemini).toHaveBeenCalledWith('bounded prompt', 'gemini-test');
    expect(chatRepository.createAiMessageAndUpdateRoom).toHaveBeenCalledWith({
      roomId: room.id,
      content: aiMessage.content,
      now: expect.any(Date),
      tx: {},
    });
    expect(result?.message).toMatchObject({
      senderId: null,
      isAi: true,
      type: MessageType.TEXT,
      status: MessageStatus.SENT,
    });
  });

  it.each([
    RoomStatus.NEED_HUMAN,
    RoomStatus.STAFF_ACTIVE,
    RoomStatus.CLOSED,
  ])('does not trigger AI when room status is %s', async (status) => {
    const { service, chatRepository, callGemini } = createService();

    const result = await service.respondToUserMessage({
      room: { ...room, status },
      userMessage,
      senderRole: Role.USER,
    });

    expect(result).toBeNull();
    expect(callGemini).not.toHaveBeenCalled();
    expect(chatRepository.createAiMessageAndUpdateRoom).not.toHaveBeenCalled();
  });

  it.each([Role.STAFF, Role.ADMIN])(
    'does not trigger AI for %s messages',
    async (senderRole) => {
      const { service, chatRepository, callGemini } = createService();

      const result = await service.respondToUserMessage({
        room,
        userMessage: { ...userMessage, senderId: 'staff-1' },
        senderRole,
      });

      expect(result).toBeNull();
      expect(callGemini).not.toHaveBeenCalled();
      expect(chatRepository.createAiMessageAndUpdateRoom).not.toHaveBeenCalled();
    },
  );

  it('does not trigger AI for non-text messages', async () => {
    const { service, callGemini } = createService();

    const result = await service.respondToUserMessage({
      room,
      userMessage: { ...userMessage, type: MessageType.SYSTEM },
      senderRole: Role.USER,
    });

    expect(result).toBeNull();
    expect(callGemini).not.toHaveBeenCalled();
  });

  it('hands off BOT_ONLY rooms and skips Gemini for handoff phrases', async () => {
    const { service, chatRepository, callGemini } = createService();

    const result = await service.respondToUserMessage({
      room,
      userMessage: { ...userMessage, content: 'Minh muon gap nhan vien ho tro' },
      senderRole: Role.USER,
    });

    expect(callGemini).not.toHaveBeenCalled();
    expect(chatRepository.handoffRoomToHuman).toHaveBeenCalledWith({
      roomId: room.id,
      now: expect.any(Date),
      tx: {},
    });
    expect(result?.room.status).toBe(RoomStatus.NEED_HUMAN);
  });

  it('aborts when room status changes before saving the AI reply', async () => {
    const { service, chatRepository, callGemini } = createService({
      chatRepository: {
        findRoomById: jest
          .fn()
          .mockResolvedValueOnce(room)
          .mockResolvedValueOnce({ ...room, status: RoomStatus.NEED_HUMAN }),
      },
    });

    const result = await service.respondToUserMessage({
      room,
      userMessage,
      senderRole: Role.USER,
    });

    expect(callGemini).toHaveBeenCalled();
    expect(result).toBeNull();
    expect(chatRepository.createAiMessageAndUpdateRoom).not.toHaveBeenCalled();
  });

  it('aborts when staff is assigned before saving the AI reply', async () => {
    const { service, chatRepository, callGemini } = createService({
      chatRepository: {
        findRoomById: jest
          .fn()
          .mockResolvedValueOnce(room)
          .mockResolvedValueOnce({ ...room, staffId: 'staff-1' }),
      },
    });

    const result = await service.respondToUserMessage({
      room,
      userMessage,
      senderRole: Role.USER,
    });

    expect(callGemini).toHaveBeenCalled();
    expect(result).toBeNull();
    expect(chatRepository.createAiMessageAndUpdateRoom).not.toHaveBeenCalled();
  });

  it('aborts when latest room message is no longer the triggering user message', async () => {
    const { service, chatRepository, callGemini } = createService({
      chatRepository: {
        getLatestMessageInRoom: jest.fn().mockResolvedValue({
          ...userMessage,
          id: 'message-2',
          content: 'Tin nhan moi hon',
        }),
      },
    });

    const result = await service.respondToUserMessage({
      room,
      userMessage,
      senderRole: Role.USER,
    });

    expect(callGemini).toHaveBeenCalled();
    expect(result).toBeNull();
    expect(chatRepository.createAiMessageAndUpdateRoom).not.toHaveBeenCalled();
  });

  it('uses a per-room lock to prevent duplicate concurrent replies', async () => {
    let resolveGemini: (value: string) => void = () => undefined;
    const { service, chatRepository } = createService();
    jest.spyOn(service as any, 'callGemini').mockReturnValue(
      new Promise((resolve) => {
        resolveGemini = resolve;
      }),
    );

    const first = service.respondToUserMessage({
      room,
      userMessage,
      senderRole: Role.USER,
    });
    const second = await service.respondToUserMessage({
      room,
      userMessage,
      senderRole: Role.USER,
    });

    expect(second).toBeNull();
    resolveGemini('GearHub goi y laptop mong nhe.');
    await first;

    expect(chatRepository.createAiMessageAndUpdateRoom).toHaveBeenCalledTimes(1);
  });
});
