import 'package:equatable/equatable.dart';
import '../../data/models/notification_model.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final int total;
  final int unreadCount;
  final int page;
  final bool hasReachedMax;
  final String? type;

  const NotificationLoaded({
    required this.notifications,
    required this.total,
    required this.unreadCount,
    required this.page,
    required this.hasReachedMax,
    this.type = 'ALL',
  });

  NotificationLoaded copyWith({
    List<NotificationModel>? notifications,
    int? total,
    int? unreadCount,
    int? page,
    bool? hasReachedMax,
    String? type,
  }) {
    return NotificationLoaded(
      notifications: notifications ?? this.notifications,
      total: total ?? this.total,
      unreadCount: unreadCount ?? this.unreadCount,
      page: page ?? this.page,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [
    notifications,
    total,
    unreadCount,
    page,
    hasReachedMax,
    type,
  ];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError({required this.message});

  @override
  List<Object> get props => [message];
}
