import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../../../auth/data/datasources/token_storage.dart';
import '../../domain/entities/inbox_item.dart';

typedef OnMessageReceived = void Function(ChatMessage message);

class ChatStompService {
  ChatStompService._();
  static final ChatStompService instance = ChatStompService._();

  StompClient? _client;
  bool _isConnected = false;
  final List<OnMessageReceived> _messageListeners = [];

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

  Future<void> connect() async {
    if (_isConnected) return;

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
            final chatMsg = ChatMessage(
              id: data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              text: data['content'] ?? '',
              isMe: data['isMe'] == true,
              timestamp: 'Just now',
              status: 'Received',
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
  }

  void subscribeToConversation(String conversationId, OnMessageReceived onThreadMessage) {
    if (!_isConnected || _client == null) return;

    _client?.subscribe(
      destination: '/topic/conversations/$conversationId',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final data = jsonDecode(frame.body!);
            final chatMsg = ChatMessage(
              id: data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
              text: data['content'] ?? '',
              isMe: data['isMe'] == true,
              timestamp: 'Just now',
              status: 'Received',
            );
            onThreadMessage(chatMsg);
          } catch (e) {
            debugPrint('[STOMP] Error parsing thread message: $e');
          }
        }
      },
    );
  }

  void sendMessage({required int recipientId, required String content, String? mediaUrl}) {
    if (!_isConnected || _client == null) return;

    _client?.send(
      destination: '/app/chat.sendMessage',
      body: jsonEncode({
        'recipientId': recipientId,
        'content': content,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
      }),
    );
  }

  void disconnect() {
    _client?.deactivate();
    _isConnected = false;
  }
}
