import 'package:mobile/src/features/chat/domain/entities/chat_message_entity.dart';

DateTime? _parseOptionalDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

DateTime _parseDate(dynamic value) {
  return DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
}

class ChatMessageModel extends ChatMessageEntity {
  const ChatMessageModel({
    required super.id,
    required super.roomId,
    required super.senderId,
    required super.content,
    required super.type,
    required super.status,
    required super.readAt,
    required super.isAi,
    required super.createdAt,
    super.clientMessageId,
    super.isOptimistic,
    super.isFailed,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      roomId: json['roomId']?.toString() ?? '',
      senderId: json['senderId']?.toString(),
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'TEXT',
      status: json['status']?.toString() ?? 'SENT',
      readAt: _parseOptionalDate(json['readAt']),
      isAi: json['isAi'] == true,
      createdAt: _parseDate(json['createdAt']),
      clientMessageId: json['clientMessageId']?.toString(),
    );
  }
}
