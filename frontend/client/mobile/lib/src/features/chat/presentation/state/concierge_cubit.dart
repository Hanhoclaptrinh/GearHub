import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile/src/core/storage/secure_storage_service.dart';
import 'package:mobile/src/features/chat/data/models/chat_message_model.dart';
import 'package:mobile/src/features/chat/data/models/chat_room_model.dart';
import 'package:mobile/src/features/chat/domain/entities/chat_message_entity.dart';
import 'package:mobile/src/features/chat/domain/repositories/chat_repository.dart';
import 'package:mobile/src/features/chat/presentation/services/chat_socket_service.dart';
import 'concierge_state.dart';

class ConciergeCubit extends Cubit<ConciergeState> {
  final ChatRepository repository;
  final ChatSocketService socketService;
  final SecureStorageService storageService;

  Timer? _typingTimer;
  final List<String> _pendingClientIds = [];

  ConciergeCubit({
    required this.repository,
    required this.socketService,
    required this.storageService,
  }) : super(const ConciergeState());

  Future<void> open() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final latestRoom = await repository.getLatestMyRoom();
      final room = latestRoom.room;
      if (room == null) {
        socketService.clearChatListeners();
        emit(
          state.copyWith(
            clearRoom: true,
            messages: const [],
            clearNextCursor: true,
            isLoading: false,
            canStartNewRoom: true,
            unreadCount: 0,
          ),
        );
        return;
      }

      final page = await repository.getMessages(roomId: room.id);
      emit(
        state.copyWith(
          room: room,
          messages: page.items,
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          isLoading: false,
          canStartNewRoom: latestRoom.canStartNewRoom,
          unreadCount: 0,
        ),
      );

      if (room.isClosed) {
        socketService.clearChatListeners();
        await markRead(emitSocket: false);
        return;
      }

      await _connectSocket(room.id);
      await markRead();
    } catch (error) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Không thể mở GearHub Concierge.',
        ),
      );
    }
  }

  Future<void> startNewConversation() async {
    if (state.isStartingNewRoom) return;
    emit(state.copyWith(isStartingNewRoom: true, clearError: true));
    try {
      socketService.clearChatListeners();
      _pendingClientIds.clear();

      final result = await repository.createNewRoom();
      final room = result.room;
      if (room == null) {
        emit(
          state.copyWith(
            isStartingNewRoom: false,
            errorMessage: 'KhÃ´ng thá»ƒ táº¡o cuá»™c trÃ² chuyá»‡n má»›i.',
          ),
        );
        return;
      }

      final page = await repository.getMessages(roomId: room.id);
      emit(
        state.copyWith(
          room: room,
          messages: page.items,
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          isStartingNewRoom: false,
          isConnected: false,
          canStartNewRoom: result.canStartNewRoom,
          unreadCount: 0,
        ),
      );

      if (!room.isClosed) {
        await _connectSocket(room.id);
        await markRead();
      }
    } catch (_) {
      emit(
        state.copyWith(
          isStartingNewRoom: false,
          errorMessage: 'KhÃ´ng thá»ƒ táº¡o cuá»™c trÃ² chuyá»‡n má»›i.',
        ),
      );
    }
  }

  Future<void> loadOlder() async {
    final room = state.room;
    final cursor = state.nextCursor;
    if (room == null || cursor == null || state.isLoadingOlder) return;

    emit(state.copyWith(isLoadingOlder: true));
    try {
      final page = await repository.getMessages(
        roomId: room.id,
        cursor: cursor,
      );
      emit(
        state.copyWith(
          messages: [...page.items, ...state.messages],
          nextCursor: page.nextCursor,
          isLoadingOlder: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoadingOlder: false));
    }
  }

  Future<void> send(String content) async {
    final room = state.room;
    final trimmed = content.trim();
    if (room == null || trimmed.isEmpty || room.isClosed) return;

    final clientMessageId =
        'mobile-${DateTime.now().millisecondsSinceEpoch}-${state.messages.length}';
    final message = ChatMessageEntity(
      id: clientMessageId,
      roomId: room.id,
      senderId: room.customer?.id,
      content: trimmed,
      type: 'TEXT',
      status: 'SENT',
      readAt: null,
      isAi: false,
      createdAt: DateTime.now(),
      clientMessageId: clientMessageId,
      isOptimistic: true,
    );

    _pendingClientIds.add(clientMessageId);
    emit(
      state.copyWith(messages: [...state.messages, message], isSending: true),
    );
    socketService.sendMessage(
      roomId: room.id,
      content: trimmed,
      clientMessageId: clientMessageId,
    );
  }

  void retryMessage(ChatMessageEntity failedMessage) {
    if (!failedMessage.isFailed) return;
    final failedId = failedMessage.clientMessageId ?? failedMessage.id;
    emit(
      state.copyWith(
        messages: state.messages
            .where(
              (message) =>
                  message.clientMessageId != failedId && message.id != failedId,
            )
            .toList(),
      ),
    );
    send(failedMessage.content);
  }

  Future<void> markRead({bool emitSocket = true}) async {
    final room = state.room;
    if (room == null) return;
    try {
      final updatedRoom = await repository.markRoomAsRead(room.id);
      if (emitSocket) socketService.markRead(room.id);
      emit(state.copyWith(room: updatedRoom, unreadCount: 0));
    } catch (_) {
      if (emitSocket) socketService.markRead(room.id);
    }
  }

  void setScreenActive(bool isActive) {
    emit(state.copyWith(screenActive: isActive));
    if (isActive) {
      final room = state.room;
      markRead(emitSocket: room?.isClosed != true);
      if (room != null && !room.isClosed && socketService.isConnected) {
        socketService.joinRoom(room.id);
      }
    }
  }

  void sendTyping(bool isTyping) {
    final room = state.room;
    if (room == null || room.isClosed) return;

    _typingTimer?.cancel();
    if (isTyping) {
      socketService.typingStart(room.id);
      _typingTimer = Timer(const Duration(milliseconds: 1100), () {
        socketService.typingStop(room.id);
      });
    } else {
      socketService.typingStop(room.id);
    }
  }

  Future<void> _connectSocket(String roomId) async {
    final token = await storageService.accessToken;
    if (token == null || token.isEmpty) return;

    socketService.connect(token);
    socketService.clearChatListeners();

    socketService.on('connect', (_) {
      emit(state.copyWith(isConnected: true));
      socketService.joinRoom(roomId);
    });
    socketService.on('reconnect', (_) {
      emit(state.copyWith(isConnected: true));
      socketService.joinRoom(roomId);
      _refreshAfterReconnect();
    });
    socketService.on('message:new', _handleMessageNew);
    socketService.on('message:chunk', _handleMessageChunk);
    socketService.on('room:updated', _handleRoomUpdated);
    socketService.on('typing:start', _handleTypingStart);
    socketService.on('typing:stop', _handleTypingStop);
    socketService.on('messages:read', _handleMessagesRead);
    socketService.on('room:closed', _handleRoomClosed);
    socketService.on('exception', _handleSocketException);

    if (socketService.isConnected) {
      socketService.joinRoom(roomId);
      emit(state.copyWith(isConnected: true));
    }
  }

  Future<void> _refreshAfterReconnect() async {
    final room = state.room;
    if (room == null) return;
    try {
      final page = await repository.getMessages(roomId: room.id);
      final latestRoom = await repository.getLatestMyRoom();
      final updatedRoom = latestRoom.room ?? room;
      emit(
        state.copyWith(
          room: updatedRoom,
          messages: page.items,
          nextCursor: page.nextCursor,
          clearNextCursor: page.nextCursor == null,
          canStartNewRoom: latestRoom.canStartNewRoom,
        ),
      );
      if (state.screenActive) {
        markRead(emitSocket: updatedRoom.isClosed != true);
      }
    } catch (_) {}
  }

  void _handleMessageNew(dynamic payload) {
    if (payload is! Map) return;
    final messageJson = payload['message'];
    final roomJson = payload['room'];
    if (messageJson is! Map || roomJson is! Map) return;

    final message = ChatMessageModel.fromJson(
      Map<String, dynamic>.from(messageJson),
    );
    final room = ChatRoomModel.fromJson(Map<String, dynamic>.from(roomJson));
    final clientMessageId = payload['clientMessageId']?.toString();

    final nextMessages = [...state.messages];
    
    int tempIndex = -1;
    if (message.isAi) {
      tempIndex = nextMessages.indexWhere(
        (item) => item.id.startsWith('ai-stream-') || item.clientMessageId?.startsWith('ai-stream-') == true,
      );
    }
    
    if (tempIndex < 0) {
      tempIndex = clientMessageId == null
          ? -1
          : nextMessages.indexWhere(
              (item) => item.clientMessageId == clientMessageId,
            );
    }

    if (tempIndex >= 0) {
      nextMessages[tempIndex] = message;
      if (clientMessageId != null) {
        _pendingClientIds.remove(clientMessageId);
      }
    } else if (!nextMessages.any((item) => item.id == message.id)) {
      nextMessages.add(message);
    }

    final isOwnMessage =
        clientMessageId != null ||
        (message.senderId != null && message.senderId != room.staffId);
    final shouldRead = state.screenActive && !isOwnMessage;

    emit(
      state.copyWith(
        room: room,
        messages: nextMessages,
        isSending: _pendingClientIds.isNotEmpty,
        unreadCount: shouldRead || isOwnMessage
            ? state.unreadCount
            : state.unreadCount + 1,
      ),
    );

    if (shouldRead) markRead();
  }

  void _handleMessageChunk(dynamic payload) {
    if (payload is! Map) return;
    final roomId = payload['roomId']?.toString();
    final messageId = payload['messageId']?.toString();
    final isEnd = payload['isEnd'] as bool? ?? false;
    final fullText = payload['fullText']?.toString() ?? '';

    final room = state.room;
    if (room == null || roomId != room.id || messageId == null) return;

    final nextMessages = [...state.messages];
    final existingIndex = nextMessages.indexWhere((msg) => msg.id == messageId);

    if (existingIndex >= 0) {
      final existingMsg = nextMessages[existingIndex];
      nextMessages[existingIndex] = ChatMessageEntity(
        id: existingMsg.id,
        roomId: existingMsg.roomId,
        senderId: existingMsg.senderId,
        content: fullText,
        type: existingMsg.type,
        status: isEnd ? 'SENT' : 'SENDING',
        readAt: existingMsg.readAt,
        isAi: true,
        createdAt: existingMsg.createdAt,
        clientMessageId: existingMsg.clientMessageId,
        isOptimistic: false,
        isFailed: false,
      );
    } else {
      final newMsg = ChatMessageEntity(
        id: messageId,
        roomId: room.id,
        senderId: null,
        content: fullText,
        type: 'TEXT',
        status: 'SENDING',
        readAt: null,
        isAi: true,
        createdAt: DateTime.now(),
        clientMessageId: messageId,
        isOptimistic: false,
        isFailed: false,
      );
      nextMessages.add(newMsg);
    }

    emit(state.copyWith(
      messages: nextMessages,
    ));
  }

  void _handleRoomUpdated(dynamic payload) {
    if (payload is! Map || payload['room'] is! Map) return;
    emit(
      state.copyWith(
        room: ChatRoomModel.fromJson(
          Map<String, dynamic>.from(payload['room'] as Map),
        ),
      ),
    );
  }

  void _handleRoomClosed(dynamic payload) => _handleRoomUpdated(payload);

  void _handleTypingStart(dynamic payload) {
    if (payload is Map && payload['roomId'] == state.room?.id) {
      emit(state.copyWith(
        isTyping: true,
        typingUserId: payload['userId']?.toString(),
      ));
    }
  }

  void _handleTypingStop(dynamic payload) {
    if (payload is Map && payload['roomId'] == state.room?.id) {
      emit(state.copyWith(
        isTyping: false,
        clearTypingUser: true,
      ));
    }
  }

  void _handleMessagesRead(dynamic payload) {
    if (payload is! Map || payload['roomId'] != state.room?.id) return;
    final readAt =
        DateTime.tryParse(payload['readAt']?.toString() ?? '') ??
        DateTime.now();
    final readerId = payload['readerId']?.toString();
    final next = state.messages
        .map(
          (message) => message.senderId != readerId
              ? message.copyWith(status: 'READ', readAt: readAt)
              : message,
        )
        .toList();
    _handleRoomUpdated(payload);
    emit(state.copyWith(messages: next));
  }

  void _handleSocketException(dynamic payload) {
    final failedId = _pendingClientIds.isNotEmpty
        ? _pendingClientIds.removeAt(0)
        : null;
    if (failedId == null) return;
    final next = state.messages
        .map(
          (message) => message.clientMessageId == failedId
              ? message.copyWith(isOptimistic: false, isFailed: true)
              : message,
        )
        .toList();
    emit(
      state.copyWith(
        messages: next,
        isSending: _pendingClientIds.isNotEmpty,
        errorMessage: payload is Map
            ? payload['message']?.toString()
            : 'Không thể gửi tin nhắn.',
      ),
    );
  }

  @override
  Future<void> close() {
    _typingTimer?.cancel();
    socketService.clearChatListeners();
    return super.close();
  }
}
