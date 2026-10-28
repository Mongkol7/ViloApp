import '../../../auth/data/datasources/token_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../../domain/entities/inbox_item.dart';
import 'static_inbox_data.dart';

class NotificationRemoteDataSource {
  NotificationRemoteDataSource._();
  static final NotificationRemoteDataSource instance = NotificationRemoteDataSource._();

  Future<List<NotificationItem>> getNotifications() async {
    try {
      final response = await ApiClient.instance.get('/notifications');
      if (response is List) {
        final rawList = response.map<NotificationItem?>((item) {
          final id = item['id']?.toString() ?? '';
          final title = item['title'] ?? 'Notification';
          final subtitle = item['body'] ?? '';
          String rawType = (item['type'] ?? 'SYSTEM').toString().toUpperCase();
          final isRead = item['isRead'] == true;
          final entityId = item['entityId']?.toString();
          final entityType = item['entityType']?.toString();
          final actorId = item['actorId'] != null ? (item['actorId'] as num).toInt() : null;
          final actorUsername = item['actorUsername']?.toString();
          final actorDisplayName = item['actorDisplayName']?.toString();
          final actorAvatarUrl = item['actorAvatarUrl']?.toString();

          // Title / body-based detection fallback for absolute accuracy
          final lowerTitle = title.toLowerCase();
          final lowerSub = subtitle.toLowerCase();

          // Do NOT alert or notify for story views
          if (rawType == 'STORY_VIEW' ||
              lowerTitle.contains('story view') ||
              lowerSub.contains('viewed your story') ||
              lowerSub.contains('viewed your 24h thought')) {
            return null;
          }

          if (rawType == 'SYSTEM' || rawType == 'LIKE' || rawType == 'ACTIVITY' || rawType.isEmpty) {
            if (lowerTitle.contains('message') || lowerTitle.contains('hi sak') || lowerSub.contains('hi sak') || lowerSub.contains('me liza')) {
              rawType = 'MESSAGE';
            } else if (lowerTitle.contains('follower') || lowerSub.contains('started following')) {
              rawType = 'FOLLOW';
            } else if (lowerTitle.contains('comment') || lowerSub.contains('commented:')) {
              rawType = 'COMMENT';
            } else if (lowerTitle.contains('like') || lowerSub.contains('liked your')) {
              rawType = 'LIKE';
            }
          }

          String iconType = 'activity';
          if (rawType == 'FOLLOW') {
            iconType = 'followers';
          } else if (rawType == 'MESSAGE') {
            iconType = 'message';
          } else if (rawType == 'LIKE') {
            iconType = 'like';
          } else if (rawType == 'SYSTEM') {
            iconType = 'system';
          }

          // Smart username fallback
          String? cleanUsername = actorUsername;
          if (cleanUsername == null || cleanUsername.isEmpty) {
            if (lowerTitle.contains('from ')) {
              final idx = lowerTitle.indexOf('from ');
              cleanUsername = title.substring(idx + 5).trim();
            } else if (lowerSub.contains(' commented:')) {
              cleanUsername = subtitle.split(' commented:').first.trim();
            } else if (lowerSub.contains(' liked your')) {
              cleanUsername = subtitle.split(' liked your').first.trim();
            } else if (lowerSub.contains(' started following')) {
              cleanUsername = subtitle.split(' started').first.trim();
            } else if (lowerSub.contains('me liza')) {
              cleanUsername = 'liza';
            }
          }

          int? effectiveActorId = actorId;
          if (effectiveActorId == null && cleanUsername != null) {
            final uLower = cleanUsername.toLowerCase();
            if (uLower == 'liza') effectiveActorId = 2;
            if (uLower == 'sak') effectiveActorId = 1;
          }

          String? effectiveAvatar = actorAvatarUrl;
          if (effectiveAvatar == null ||
              effectiveAvatar.isEmpty ||
              effectiveAvatar.contains('534528741775') ||
              effectiveAvatar.contains('535713875002')) {
            if (cleanUsername != null && cleanUsername.isNotEmpty) {
              effectiveAvatar = ProfileSyncService.getDefaultAvatarForUser(cleanUsername);
            }
          }

          return NotificationItem(
            id: id,
            title: title,
            subtitle: subtitle,
            iconType: iconType,
            type: rawType,
            hasDot: !isRead,
            entityId: entityId,
            entityType: entityType,
            actorId: effectiveActorId,
            actorUsername: cleanUsername,
            actorDisplayName: actorDisplayName ?? cleanUsername,
            actorAvatarUrl: effectiveAvatar,
            timeAgo: 'Recently',
          );
        }).whereType<NotificationItem>().toList();

        // Deduplicate: Keep only the latest notification per actor & type
        final List<NotificationItem> deduplicated = [];
        final Set<String> seen = {};
        for (final item in rawList) {
          final actorKey = (item.actorUsername != null && item.actorUsername!.isNotEmpty)
              ? item.actorUsername!.toLowerCase().trim()
              : (item.actorId != null ? item.actorId.toString() : item.title.toLowerCase().trim());
          final key = '${item.type}_$actorKey';
          if (!seen.contains(key)) {
            seen.add(key);
            deduplicated.add(item);
          }
        }
        return deduplicated;
      }
    } catch (_) {}

    final isDemoUser = (TokenStorage.instance.isDemoUserSync ||
            TokenStorage.instance.currentUserIdSync == null) &&
        (TokenStorage.instance.currentUsernameSync == null ||
            TokenStorage.instance.currentUsernameSync == 'mongkol');
    if (isDemoUser) {
      return StaticInboxData.notifications;
    }
    return const [];
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
    return StaticInboxData.notifications.where((n) => n.hasDot || (n.badgeCount != null && n.badgeCount! > 0)).length;
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiClient.instance.put('/notifications/read-all');
    } catch (_) {}
  }
}
