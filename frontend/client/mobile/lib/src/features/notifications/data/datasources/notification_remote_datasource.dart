import 'package:dio/dio.dart';
import '../models/notification_model.dart';

class NotificationRemoteDatasource {
  final Dio dio;

  NotificationRemoteDatasource({required this.dio});

  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 10,
    String? type,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (type != null && type.isNotEmpty && type != 'ALL') {
        queryParams['type'] = type;
      }

      final response = await dio.get(
        '/notifications',
        queryParameters: queryParams,
      );

      final List list = response.data['data'] ?? [];
      final List<NotificationModel> notifications = list
          .map(
            (json) => NotificationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      final meta = response.data['meta'] ?? {};
      final total = (meta['total'] as num?)?.toInt() ?? 0;
      final unreadCount = (meta['unreadCount'] as num?)?.toInt() ?? 0;
      final lastPage = (meta['lastPage'] as num?)?.toInt() ?? 1;

      return {
        'notifications': notifications,
        'total': total,
        'unreadCount': unreadCount,
        'lastPage': lastPage,
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await dio.patch('/notifications/$id/read');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await dio.patch('/notifications/read-all');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await dio.delete('/notifications/$id');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      await dio.delete('/notifications/clear-all');
    } catch (e) {
      rethrow;
    }
  }
}
