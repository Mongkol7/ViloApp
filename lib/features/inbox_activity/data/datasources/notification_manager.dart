import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/data/datasources/token_storage.dart';
import '../../domain/entities/inbox_item.dart';

class NotificationManager {
  NotificationManager._();

  static final NotificationManager instance = NotificationManager._();

  final ValueNotifier<List<NotificationItem>> notificationsNotifier =
      ValueNotifier<List<NotificationItem>>(<NotificationItem>[]);
  final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  List<NotificationItem> get notifications => notificationsNotifier.value;

  Future<void> loadForCurrentUser() async {
    if (!await TokenStorage.instance.hasValidToken()) {
      notificationsNotifier.value = <NotificationItem>[];
      unreadCountNotifier.value = 0;
      return;
    }
    final response = await ApiClient.instance.get(
      '/notifications?limit=100',
      requireAuth: true,
    );
    if (response is! Map) return;
    final raw = response['notifications'];
    if (raw is! List) return;
    final incoming = raw
        .whereType<Map>()
        .map(
          (item) => NotificationItem.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
    final byId = <String, NotificationItem>{
      for (final item in notifications) item.id: item,
    };
    for (final item in incoming) {
      byId[item.id] = item;
    }
    final merged = byId.values.toList()
      ..sort(
        (a, b) => (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
    notificationsNotifier.value = merged;
    unreadCountNotifier.value =
        (response['unreadCount'] as num?)?.toInt() ??
        merged.where((item) => !item.isRead).length;
  }

  Future<void> refresh() => loadForCurrentUser();

  Future<void> markRead(NotificationItem item) async {
    if (item.isRead) return;
    final previous = notificationsNotifier.value;
    notificationsNotifier.value = previous
        .map(
          (current) =>
              current.id == item.id ? current.copyWith(isRead: true) : current,
        )
        .toList();
    unreadCountNotifier.value = notificationsNotifier.value
        .where((current) => !current.isRead)
        .length;
    try {
      await ApiClient.instance.patch(
        '/notifications/${item.id}/read',
        requireAuth: true,
      );
    } catch (error) {
      notificationsNotifier.value = previous;
      unreadCountNotifier.value = previous
          .where((current) => !current.isRead)
          .length;
      rethrow;
    }
  }

  Future<void> markAllRead() async {
    final previous = notificationsNotifier.value;
    notificationsNotifier.value = previous
        .map((item) => item.copyWith(isRead: true))
        .toList();
    unreadCountNotifier.value = 0;
    try {
      await ApiClient.instance.post(
        '/notifications/read-all',
        requireAuth: true,
      );
    } catch (error) {
      notificationsNotifier.value = previous;
      unreadCountNotifier.value = previous.where((item) => !item.isRead).length;
      rethrow;
    }
  }
}
