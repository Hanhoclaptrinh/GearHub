import '../../domain/repositories/notification_repository.dart';
import '../datasources/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDatasource remoteDatasource;

  NotificationRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 10,
    String? type,
  }) async {
    try {
      return await remoteDatasource.getNotifications(
        page: page,
        limit: limit,
        type: type,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> markAsRead(String id) async {
    try {
      await remoteDatasource.markAsRead(id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> markAllAsRead() async {
    try {
      await remoteDatasource.markAllAsRead();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> deleteNotification(String id) async {
    try {
      await remoteDatasource.deleteNotification(id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> clearAllNotifications() async {
    try {
      await remoteDatasource.clearAllNotifications();
    } catch (e) {
      rethrow;
    }
  }
}
