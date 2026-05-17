import 'package:equatable/equatable.dart';

class ChatMessageEntity extends Equatable {
  final String id;
  final String roomId;
  final String? senderId;
  final String content;
  final String type;
  final String status;
  final DateTime? readAt;
  final bool isAi;
  final DateTime createdAt;
  final String? clientMessageId;
  final bool isOptimistic;
  final bool isFailed;

  const ChatMessageEntity({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.status,
    required this.readAt,
    required this.isAi,
    required this.createdAt,
    this.clientMessageId,
    this.isOptimistic = false,
    this.isFailed = false,
  });

  bool get isSystem => type == 'SYSTEM';

  ChatMessageEntity copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? content,
    String? type,
    String? status,
    DateTime? readAt,
    bool? isAi,
    DateTime? createdAt,
    String? clientMessageId,
    bool? isOptimistic,
    bool? isFailed,
  }) {
    return ChatMessageEntity(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      readAt: readAt ?? this.readAt,
      isAi: isAi ?? this.isAi,
      createdAt: createdAt ?? this.createdAt,
      clientMessageId: clientMessageId ?? this.clientMessageId,
      isOptimistic: isOptimistic ?? this.isOptimistic,
      isFailed: isFailed ?? this.isFailed,
    );
  }

  @override
  List<Object?> get props => [
    id,
    roomId,
    senderId,
    content,
    type,
    status,
    readAt,
    isAi,
    createdAt,
    clientMessageId,
    isOptimistic,
    isFailed,
  ];
}
