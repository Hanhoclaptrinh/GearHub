import 'package:mobile/src/features/chat/data/datasources/chat_remote_datasource.dart';
import 'package:mobile/src/features/chat/domain/entities/chat_room_entity.dart';
import 'package:mobile/src/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDatasource remoteDatasource;

  ChatRepositoryImpl({required this.remoteDatasource});

  @override
  Future<LatestChatRoomResult> getLatestMyRoom() async {
    final result = await remoteDatasource.getLatestMyRoom();
    return LatestChatRoomResult(
      room: result.room,
      isClosed: result.isClosed,
      canStartNewRoom: result.canStartNewRoom,
    );
  }

  @override
  Future<LatestChatRoomResult> createNewRoom() async {
    final result = await remoteDatasource.createNewRoom();
    return LatestChatRoomResult(
      room: result.room,
      isClosed: result.isClosed,
      canStartNewRoom: result.canStartNewRoom,
    );
  }

  @override
  Future<ChatMessagesPage> getMessages({
    required String roomId,
    String? cursor,
    int take = 30,
  }) async {
    final page = await remoteDatasource.getMessages(
      roomId: roomId,
      cursor: cursor,
      take: take,
    );
    return ChatMessagesPage(items: page.items, nextCursor: page.nextCursor);
  }

  @override
  Future<ChatRoomEntity> markRoomAsRead(String roomId) {
    return remoteDatasource.markRoomAsRead(roomId);
  }
}
