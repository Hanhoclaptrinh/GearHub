import 'package:mobile/src/features/chat/domain/entities/chat_message_entity.dart';
import 'package:mobile/src/features/chat/domain/entities/chat_room_entity.dart';

class ChatMessagesPage {
  final List<ChatMessageEntity> items;
  final String? nextCursor;

  const ChatMessagesPage({required this.items, required this.nextCursor});
}

class LatestChatRoomResult {
  final ChatRoomEntity? room;
  final bool isClosed;
  final bool canStartNewRoom;

  const LatestChatRoomResult({
    required this.room,
    required this.isClosed,
    required this.canStartNewRoom,
  });
}

abstract class ChatRepository {
  Future<LatestChatRoomResult> getLatestMyRoom();

  Future<LatestChatRoomResult> createNewRoom();

  Future<ChatMessagesPage> getMessages({
    required String roomId,
    String? cursor,
    int take = 30,
  });

  Future<ChatRoomEntity> markRoomAsRead(String roomId);
}
