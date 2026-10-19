import '../../../../core/network/api_client.dart';
import '../../domain/entities/inbox_item.dart';
import 'static_inbox_data.dart';

class NotificationRemoteDataSource {
  NotificationRemoteDataSource._();
  static final NotificationRemoteDataSource instance = NotificationRemoteDataSource._();

  Future<List<NotificationItem>> getNotifications() async {
    try {
      final response = await ApiClient.instance.get('/notifications');
      if (response is List && response.isNotEmpty) {
        return response.map<NotificationItem>((item) {
          final id = item['id']?.toString() ?? '';
          final title = item['title'] ?? 'Notification';
          final subtitle = item['body'] ?? '';
          final type = (item['type'] ?? 'SYSTEM').toString().toUpperCase();
          final isRead = item['isRead'] == true;

          String iconType = 'activity';
          if (type == 'FOLLOW') {
            iconType = 'followers';
          } else if (type == 'SYSTEM') {
            iconType = 'system';
          }

          return NotificationItem(
            id: id,
            title: title,
            subtitle: subtitle,
            iconType: iconType,
            hasDot: !isRead,
          );
        }).toList();
      }
    } catch (_) {}
    return StaticInboxData.notifications;
  }

  Future<void> markAsRead(String notificationId) async {
    final id = int.tryParse(notificationId);
    if (id == null) return;
    try {
      await ApiClient.instance.put('/notifications/$id/read');
    } catch (_) {}
  }

  Future<int> getUnreadCount() async {
    try {
      final response = await ApiClient.instance.get('/notifications/unread-count');
      if (response is Map && response['unreadCount'] != null) {
        return (response['unreadCount'] as num).toInt();
      }
    } catch (_) {}
    return 0;
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiClient.instance.put('/notifications/read-all');
    } catch (_) {}
  }
}
