import 'package:dio/dio.dart';
import 'package:mobile/src/features/chat/data/models/chat_message_model.dart';
import 'package:mobile/src/features/chat/data/models/chat_room_model.dart';

class ChatMessagesRemotePage {
  final List<ChatMessageModel> items;
  final String? nextCursor;

  const ChatMessagesRemotePage({required this.items, required this.nextCursor});
}

class LatestChatRoomRemoteResult {
  final ChatRoomModel? room;
  final bool isClosed;
  final bool canStartNewRoom;

  const LatestChatRoomRemoteResult({
    required this.room,
    required this.isClosed,
    required this.canStartNewRoom,
  });

  factory LatestChatRoomRemoteResult.fromJson(Map<String, dynamic> json) {
    return LatestChatRoomRemoteResult(
      room: json['room'] is Map<String, dynamic>
          ? ChatRoomModel.fromJson(json['room'] as Map<String, dynamic>)
          : null,
      isClosed: json['isClosed'] == true,
      canStartNewRoom: json['canStartNewRoom'] == true,
    );
  }
}

class ChatRemoteDatasource {
  final Dio dio;

  ChatRemoteDatasource({required this.dio});

  Future<LatestChatRoomRemoteResult> getLatestMyRoom() async {
    final response = await dio.get('/chat/my-room');
    return LatestChatRoomRemoteResult.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<LatestChatRoomRemoteResult> createNewRoom() async {
    final response = await dio.post('/chat/rooms');
    return LatestChatRoomRemoteResult.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ChatMessagesRemotePage> getMessages({
    required String roomId,
    String? cursor,
    int take = 30,
  }) async {
    final response = await dio.get(
      '/chat/rooms/$roomId/messages',
      queryParameters: {if (cursor != null) 'cursor': cursor, 'take': take},
    );

    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ChatMessageModel.fromJson)
        .toList();

    return ChatMessagesRemotePage(
      items: items,
      nextCursor: data['nextCursor']?.toString(),
    );
  }

  Future<ChatRoomModel> markRoomAsRead(String roomId) async {
    final response = await dio.post('/chat/rooms/$roomId/read');
    return ChatRoomModel.fromJson(response.data as Map<String, dynamic>);
  }
}
