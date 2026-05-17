import 'package:equatable/equatable.dart';

class ChatProfileEntity extends Equatable {
  final String id;
  final String email;
  final String role;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final DateTime? createdAt;

  const ChatProfileEntity({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.phone,
    this.avatarUrl,
    this.createdAt,
  });

  String get displayName =>
      fullName?.trim().isNotEmpty == true ? fullName! : email;

  @override
  List<Object?> get props => [
    id,
    email,
    role,
    fullName,
    phone,
    avatarUrl,
    createdAt,
  ];
}

class ChatRoomEntity extends Equatable {
  final String id;
  final String status;
  final String? staffId;
  final DateTime? lastMessageAt;
  final String? lastMessageContent;
  final int customerUnreadCount;
  final int staffUnreadCount;
  final ChatProfileEntity? customer;
  final ChatProfileEntity? staff;

  const ChatRoomEntity({
    required this.id,
    required this.status,
    this.staffId,
    this.lastMessageAt,
    this.lastMessageContent,
    this.customerUnreadCount = 0,
    this.staffUnreadCount = 0,
    this.customer,
    this.staff,
  });

  bool get isClosed => status == 'CLOSED';

  ChatRoomEntity copyWith({
    String? id,
    String? status,
    String? staffId,
    DateTime? lastMessageAt,
    String? lastMessageContent,
    int? customerUnreadCount,
    int? staffUnreadCount,
    ChatProfileEntity? customer,
    ChatProfileEntity? staff,
  }) {
    return ChatRoomEntity(
      id: id ?? this.id,
      status: status ?? this.status,
      staffId: staffId ?? this.staffId,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      customerUnreadCount: customerUnreadCount ?? this.customerUnreadCount,
      staffUnreadCount: staffUnreadCount ?? this.staffUnreadCount,
      customer: customer ?? this.customer,
      staff: staff ?? this.staff,
    );
  }

  @override
  List<Object?> get props => [
    id,
    status,
    staffId,
    lastMessageAt,
    lastMessageContent,
    customerUnreadCount,
    staffUnreadCount,
    customer,
    staff,
  ];
}
