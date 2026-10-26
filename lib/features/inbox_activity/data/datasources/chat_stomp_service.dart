import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../../auth/data/datasources/token_storage.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/inbox_item.dart';

typedef OnMessageReceived = void Function(ChatMessage message);
typedef OnNotificationReceived = void Function(NotificationItem notification);

class ChatStompService {
  ChatStompService._();
  static final ChatStompService instance = ChatStompService._();

  StompClient? _client;
  bool _isConnected = false;
  final List<OnMessageReceived> _messageListeners = [];
  final List<OnNotificationReceived> _notificationListeners = [];

  String _resolveMediaUrl(dynamic raw) {
    final value = raw?.toString().trim() ?? '';
    if (value.isEmpty ||
        value.startsWith('http://') ||
        value.startsWith('https://')) {
      return value;
    }
    return '${ApiClient.baseUrl.replaceFirst('/api/v1', '')}${value.startsWith('/') ? value : '/$value'}';
  }

  bool get isConnected => _isConnected;

  static String get wsEndpoint {
    if (kIsWeb) return 'ws://localhost:3000/ws-vilo';
    if (Platform.isAndroid) return 'ws://10.0.2.2:3000/ws-vilo';
    return 'ws://localhost:3000/ws-vilo';
  }

  void addMessageListener(OnMessageReceived listener) {
    if (!_messageListeners.contains(listener)) {
      _messageListeners.add(listener);
    }
  }

  void removeMessageListener(OnMessageReceived listener) {
    _messageListeners.remove(listener);
  }

  void addNotificationListener(OnNotificationReceived listener) {
    if (!_notificationListeners.contains(listener)) {
      _notificationListeners.add(listener);
    }
  }

  void removeNotificationListener(OnNotificationReceived listener) {
    _notificationListeners.remove(listener);
  }

  Future<void> connect() async {
    if (_isConnected || Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }

    final token = await TokenStorage.instance.getAccessToken();
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      headers['token'] = token;
    }

    _client = StompClient(
      config: StompConfig(
        url: wsEndpoint,
        onConnect: _onConnect,
        onDisconnect: (frame) {
          _isConnected = false;
          debugPrint('[STOMP] Disconnected');
        },
        onWebSocketError: (error) {
          _isConnected = false;
          debugPrint('[STOMP] WebSocket error: $error');
        },
        onStompError: (frame) {
          debugPrint('[STOMP] Error frame: ${frame.body}');
        },
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _client?.activate();
  }

  void _onConnect(StompFrame frame) {
    _isConnected = true;
    debugPrint('[STOMP] Successfully connected to Spring Boot WebSocket!');

    // 1. Subscribe to personal direct messages queue
    _client?.subscribe(
      destination: '/user/queue/messages',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!);
            final deleted =
                data['deleted'] == true || data['deletedForEveryone'] == true;
            final isMe = data['isMe'] == true;
            final text = deleted
                ? (isMe ? 'You deleted a message' : 'This message was deleted')
                : (data['content'] ?? '');
            final isRead = data['isRead'] == true;
            final sentAt = DateTime.tryParse(
              data['createdAt']?.toString() ?? '',
            )?.toLocal();

            final chatMsg = ChatMessage(
              id:
                  data['id']?.toString() ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              text: text,
              isMe: isMe,
              timestamp: 'Just now',
              status: isRead ? 'Seen' : (isMe ? 'Sent' : 'Received'),
              mediaUrl: deleted ? null : _resolveMediaUrl(data['mediaUrl']),
              isDeletedForEveryone: deleted,
              sentAt: sentAt,
            );

            for (final listener in List.of(_messageListeners)) {
              listener(chatMsg);
            }
          } catch (e) {
            debugPrint('[STOMP] Error parsing incoming message: $e');
          }
        }
      },
    );

    // Notify the inbox immediately when somebody sends a new chat message.
    _client?.subscribe(
      destination: '/user/queue/notifications',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final data = jsonDecode(frame.body!);
          final notification = NotificationItem(
            id:
                data['id']?.toString() ??
                DateTime.now().millisecondsSinceEpoch.toString(),
            title: data['title']?.toString() ?? 'New notification',
            subtitle: data['body']?.toString() ?? '',
            iconType: data['type']?.toString().toLowerCase() == 'message'
                ? 'message'
                : 'activity',
            type: data['type']?.toString() ?? 'SYSTEM',
            entityId: data['entityId']?.toString(),
            entityType: data['entityType']?.toString(),
            actorId: data['actorId'] is num
                ? (data['actorId'] as num).toInt()
                : null,
            actorUsername: data['actorUsername']?.toString(),
            actorDisplayName: data['actorDisplayName']?.toString(),
            actorAvatarUrl: data['actorAvatarUrl']?.toString(),
            hasDot: true,
            timeAgo: 'Just now',
          );
          for (final listener in List.of(_notificationListeners)) {
            listener(notification);
          }
        } catch (e) {
          debugPrint('[STOMP] Error parsing notification: $e');
        }
      },
    );
  }

  void subscribeToConversation(
    String conversationId,
    OnMessageReceived onThreadMessage,
  ) {
    if (!_isConnected || _client == null) return;

    _client?.subscribe(
      destination: '/topic/conversations/$conversationId',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!);
            final deleted =
                data['deleted'] == true || data['deletedForEveryone'] == true;
            final isMe = data['isMe'] == true;
            final text = deleted
                ? (isMe ? 'You deleted a message' : 'This message was deleted')
                : (data['content'] ?? '');
            final isRead = data['isRead'] == true;
            final sentAt = DateTime.tryParse(
              data['createdAt']?.toString() ?? '',
            )?.toLocal();

            final chatMsg = ChatMessage(
              id:
                  data['id']?.toString() ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              text: text,
              isMe: isMe,
              timestamp: 'Just now',
              status: isRead ? 'Seen' : (isMe ? 'Sent' : 'Received'),
              mediaUrl: deleted ? null : _resolveMediaUrl(data['mediaUrl']),
              isDeletedForEveryone: deleted,
              sentAt: sentAt,
            );
            onThreadMessage(chatMsg);
          } catch (e) {
            debugPrint('[STOMP] Error parsing thread message: $e');
          }
        }
      },
    );
  }

  void sendMessage({
    required int recipientId,
    required String content,
    String? mediaUrl,
  }) {
    if (!_isConnected || _client == null) return;

    _client?.send(
      destination: '/app/chat.sendMessage',
      body: jsonEncode({
        'recipientId': recipientId,
        'content': content,
        if (mediaUrl != null) ...{
          'mediaUrl': mediaUrl,
        },
      }),
    );
  }

  void markSeen({required int otherUserId}) {
    if (!_isConnected || _client == null) return;

    _client?.send(
      destination: '/app/chat.markSeen',
      body: jsonEncode({'otherUserId': otherUserId}),
    );
  }

  void disconnect() {
    _client?.deactivate();
    _isConnected = false;
  }
}
