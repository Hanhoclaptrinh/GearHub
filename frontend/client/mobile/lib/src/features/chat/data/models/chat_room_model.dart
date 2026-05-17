import 'package:mobile/src/features/chat/domain/entities/chat_room_entity.dart';

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

class ChatProfileModel extends ChatProfileEntity {
  const ChatProfileModel({
    required super.id,
    required super.email,
    required super.role,
    super.fullName,
    super.phone,
    super.avatarUrl,
    super.createdAt,
  });

  factory ChatProfileModel.fromJson(Map<String, dynamic> json) {
    return ChatProfileModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'USER',
      fullName: json['fullName']?.toString(),
      phone: json['phone']?.toString(),
      avatarUrl: json['avatarUrl']?.toString(),
      createdAt: _parseDate(json['createdAt']),
    );
  }
}

class ChatRoomModel extends ChatRoomEntity {
  const ChatRoomModel({
    required super.id,
    required super.status,
    super.staffId,
    super.lastMessageAt,
    super.lastMessageContent,
    super.customerUnreadCount,
    super.staffUnreadCount,
    super.customer,
    super.staff,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'NEED_HUMAN',
      staffId: json['staffId']?.toString(),
      lastMessageAt: _parseDate(json['lastMessageAt']),
      lastMessageContent: json['lastMessageContent']?.toString(),
      customerUnreadCount: (json['customerUnreadCount'] as num?)?.toInt() ?? 0,
      staffUnreadCount: (json['staffUnreadCount'] as num?)?.toInt() ?? 0,
      customer: json['customer'] is Map<String, dynamic>
          ? ChatProfileModel.fromJson(json['customer'] as Map<String, dynamic>)
          : null,
      staff: json['staff'] is Map<String, dynamic>
          ? ChatProfileModel.fromJson(json['staff'] as Map<String, dynamic>)
          : null,
    );
  }
}
