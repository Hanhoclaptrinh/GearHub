import 'package:equatable/equatable.dart';
import 'package:mobile/src/features/chat/domain/entities/chat_message_entity.dart';
import 'package:mobile/src/features/chat/domain/entities/chat_room_entity.dart';

class ConciergeState extends Equatable {
  final ChatRoomEntity? room;
  final List<ChatMessageEntity> messages;
  final String? nextCursor;
  final bool isLoading;
  final bool isLoadingOlder;
  final bool isSending;
  final bool isTyping;
  final String? typingUserId;
  final bool isConnected;
  final bool screenActive;
  final bool canStartNewRoom;
  final bool isStartingNewRoom;
  final int unreadCount;
  final String? errorMessage;

  const ConciergeState({
    this.room,
    this.messages = const [],
    this.nextCursor,
    this.isLoading = false,
    this.isLoadingOlder = false,
    this.isSending = false,
    this.isTyping = false,
    this.typingUserId,
    this.isConnected = false,
    this.screenActive = true,
    this.canStartNewRoom = false,
    this.isStartingNewRoom = false,
    this.unreadCount = 0,
    this.errorMessage,
  });

  bool get isClosed => room?.isClosed ?? false;

  ConciergeState copyWith({
    ChatRoomEntity? room,
    bool clearRoom = false,
    List<ChatMessageEntity>? messages,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoading,
    bool? isLoadingOlder,
    bool? isSending,
    bool? isTyping,
    String? typingUserId,
    bool clearTypingUser = false,
    bool? isConnected,
    bool? screenActive,
    bool? canStartNewRoom,
    bool? isStartingNewRoom,
    int? unreadCount,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ConciergeState(
      room: clearRoom ? null : room ?? this.room,
      messages: messages ?? this.messages,
      nextCursor: clearNextCursor ? null : nextCursor ?? this.nextCursor,
      isLoading: isLoading ?? this.isLoading,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      isSending: isSending ?? this.isSending,
      isTyping: isTyping ?? this.isTyping,
      typingUserId: clearTypingUser ? null : typingUserId ?? this.typingUserId,
      isConnected: isConnected ?? this.isConnected,
      screenActive: screenActive ?? this.screenActive,
      canStartNewRoom: canStartNewRoom ?? this.canStartNewRoom,
      isStartingNewRoom: isStartingNewRoom ?? this.isStartingNewRoom,
      unreadCount: unreadCount ?? this.unreadCount,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    room,
    messages,
    nextCursor,
    isLoading,
    isLoadingOlder,
    isSending,
    isTyping,
    typingUserId,
    isConnected,
    screenActive,
    canStartNewRoom,
    isStartingNewRoom,
    unreadCount,
    errorMessage,
  ];
}
