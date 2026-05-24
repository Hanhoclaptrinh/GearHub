abstract class NotificationRepository {
  Future<Map<String, dynamic>> getNotifications({
    int page = 1,
    int limit = 10,
    String? type,
  });
  Future<void> markAsRead(String id);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String id);
  Future<void> clearAllNotifications();
}
