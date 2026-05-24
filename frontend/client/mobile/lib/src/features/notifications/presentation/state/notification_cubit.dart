import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/notification_model.dart';
import '../../domain/repositories/notification_repository.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository _repository;

  NotificationCubit({required NotificationRepository repository})
    : _repository = repository,
      super(NotificationInitial());

  Future<void> loadNotifications({String type = 'ALL'}) async {
    emit(NotificationLoading());
    try {
      final result = await _repository.getNotifications(
        page: 1,
        limit: 15,
        type: type,
      );

      final notifications = result['notifications'] as List<dynamic>;
      final total = result['total'] as int;
      final unreadCount = result['unreadCount'] as int;
      final lastPage = result['lastPage'] as int;

      emit(
        NotificationLoaded(
          notifications: List<NotificationModel>.from(notifications),
          total: total,
          unreadCount: unreadCount,
          page: 1,
          hasReachedMax: 1 >= lastPage,
          type: type,
        ),
      );
    } catch (e) {
      emit(NotificationError(message: _extractErrorMessage(e)));
    }
  }

  Future<void> loadMoreNotifications() async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;
    if (currentState.hasReachedMax) return;

    try {
      final nextPage = currentState.page + 1;
      final result = await _repository.getNotifications(
        page: nextPage,
        limit: 15,
        type: currentState.type,
      );

      final notifications = result['notifications'] as List<dynamic>;
      final lastPage = result['lastPage'] as int;
      final total = result['total'] as int;
      final unreadCount = result['unreadCount'] as int;

      emit(
        currentState.copyWith(
          notifications: [
            ...currentState.notifications,
            ...notifications.cast<NotificationModel>(),
          ],
          page: nextPage,
          hasReachedMax: nextPage >= lastPage,
          total: total,
          unreadCount: unreadCount,
        ),
      );
    } catch (_) {}
  }

  Future<void> markAsRead(String id) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    final updatedNotifications = currentState.notifications.map((noti) {
      if (noti.id == id && !noti.isRead) {
        return noti.copyWith(isRead: true, readAt: DateTime.now());
      }
      return noti;
    }).toList();

    final newUnreadCount = (currentState.unreadCount - 1).clamp(
      0,
      currentState.total,
    );

    emit(
      currentState.copyWith(
        notifications: updatedNotifications,
        unreadCount: newUnreadCount,
      ),
    );

    try {
      await _repository.markAsRead(id);
    } catch (_) {
      loadNotifications(type: currentState.type ?? 'ALL');
    }
  }

  Future<void> markAllAsRead() async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    final updatedNotifications = currentState.notifications.map((noti) {
      return noti.copyWith(isRead: true, readAt: DateTime.now());
    }).toList();

    emit(
      currentState.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      ),
    );

    try {
      await _repository.markAllAsRead();
    } catch (_) {
      loadNotifications(type: currentState.type ?? 'ALL');
    }
  }

  Future<void> deleteNotification(String id) async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    final targetNoti = currentState.notifications.firstWhere(
      (noti) => noti.id == id,
    );
    final wasUnread = !targetNoti.isRead;

    final updatedNotifications = List<NotificationModel>.from(
      currentState.notifications,
    )..removeWhere((noti) => noti.id == id);

    final newUnreadCount = wasUnread
        ? (currentState.unreadCount - 1).clamp(0, currentState.total)
        : currentState.unreadCount;

    emit(
      currentState.copyWith(
        notifications: updatedNotifications,
        total: (currentState.total - 1).clamp(0, 9999),
        unreadCount: newUnreadCount,
      ),
    );

    try {
      await _repository.deleteNotification(id);
    } catch (_) {
      loadNotifications(type: currentState.type ?? 'ALL');
    }
  }

  Future<void> clearAllNotifications() async {
    final currentState = state;
    if (currentState is! NotificationLoaded) return;

    emit(
      currentState.copyWith(
        notifications: const [],
        total: 0,
        unreadCount: 0,
        hasReachedMax: true,
      ),
    );

    try {
      await _repository.clearAllNotifications();
    } catch (_) {
      loadNotifications(type: currentState.type ?? 'ALL');
    }
  }

  String _extractErrorMessage(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response!.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }
    return 'Không thể tải thông báo. Vui lòng thử lại.';
  }
}
