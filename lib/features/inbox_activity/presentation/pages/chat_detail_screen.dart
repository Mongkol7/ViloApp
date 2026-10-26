import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/data/datasources/token_storage.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../data/datasources/chat_manager.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/datasources/chat_stomp_service.dart';
import '../../domain/entities/inbox_item.dart';

class ChatDetailScreen extends StatefulWidget {
  final DirectMessageThread thread;

  const ChatDetailScreen({super.key, required this.thread});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  late List<ChatMessage> _messages;
  final ScrollController _scrollController = ScrollController();
  final List<String> _pendingImagePaths = [];
  bool _isUploadingImages = false;
  bool get _canSend =>
      _messageController.text.trim().isNotEmpty || _pendingImagePaths.isNotEmpty;
  final Set<String> _expandedTimestampIds = {};
  late bool _isFollowing;
  late bool _followsYou;

  bool get _isFriend => _isFollowing && _followsYou;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.thread.isFollowing;
    _followsYou = widget.thread.followsYou;
    final savedMessages = ChatManager.instance.getMessages(widget.thread.id);
    _messages = savedMessages.isNotEmpty
        ? savedMessages
        : List.from(widget.thread.messages);
    _messageController.addListener(() {
      setState(() {});
    });
    ChatStompService.instance.connect();
    ChatStompService.instance.addMessageListener(_handleIncomingMessage);
    final convId = widget.thread.id;
    if (convId.isNotEmpty) {
      ChatStompService.instance.subscribeToConversation(
        convId,
        _handleIncomingMessage,
      );
    }
    _loadMessages();

    // Always open a conversation at its newest message instead of leaving
    // the list at its default position near the beginning of the chat.
    _scrollToBottom();
  }

  @override
  void dispose() {
    ChatStompService.instance.removeMessageListener(_handleIncomingMessage);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final userId = _resolvedUserId;
    if (userId != null) {
      try {
        final profile = await ProfileRemoteDataSource.instance.getUserById(
          userId,
        );
        if (mounted) {
          setState(() {
            _isFollowing = profile.isFollowing;
            _followsYou = profile.followsYou;
          });
          ChatManager.instance.updateFollowState(userId, profile.isFollowing);
        }
      } catch (_) {}

      // Mark messages as seen when opening the conversation
      ChatRemoteDataSource.instance.markAsRead(userId);
      ChatStompService.instance.markSeen(otherUserId: userId);

      final myUid = TokenStorage.instance.currentUserIdSync ??
          (TokenStorage.instance.currentUsernameSync == 's1' ? 99 : 1);
      ChatManager.instance.markConversationSeenByRecipient(
        recipientId: myUid,
        senderId: userId,
      );

      final remoteMessages = await ChatRemoteDataSource.instance.getMessages(
        userId,
      );
      if (mounted && remoteMessages.isNotEmpty) {
        final existingTexts = remoteMessages.map((m) => m.text).toSet();
        final unsynced = _messages
            .where((m) => m.isMe && !existingTexts.contains(m.text))
            .toList();
        setState(() {
          _messages = [...remoteMessages, ...unsynced];
        });
        _scrollToBottom();
      }
    }
  }

  void _handleIncomingMessage(ChatMessage msg) {
    if (!mounted) return;

    if (msg.status == 'Seen') {
      setState(() {
        final exactIndex = _messages.indexWhere(
          (existing) => existing.id == msg.id,
        );
        if (exactIndex != -1) {
          _messages[exactIndex] = msg;
        } else {
          final optimisticIndex = _messages.indexWhere(
            (existing) =>
                existing.isMe &&
                (existing.text == msg.text || existing.id == msg.id),
          );
          if (optimisticIndex != -1) {
            _messages[optimisticIndex] = _messages[optimisticIndex].copyWith(
              id: msg.id,
              status: 'Seen',
            );
          }
        }
        for (int i = 0; i < _messages.length; i++) {
          if (_messages[i].isMe && _messages[i].status != 'Seen') {
            _messages[i] = _messages[i].copyWith(status: 'Seen');
          }
        }
      });
      ChatManager.instance.updateMessagesStatus(widget.thread.id, 'Seen');
      return;
    }

    setState(() {
      // The backend echoes a sent message through STOMP after the UI has
      // already inserted its optimistic copy. Replace that copy instead of
      // rendering the same message twice.
      final exactIndex = _messages.indexWhere(
        (existing) => existing.id == msg.id,
      );
      if (exactIndex != -1) {
        _messages[exactIndex] = msg;
        return;
      }

      if (msg.isMe) {
        final optimisticIndex = _messages.indexWhere(
          (existing) =>
              existing.isMe &&
              existing.text == msg.text &&
              existing.status == 'Sent',
        );
        if (optimisticIndex != -1) {
          _messages[optimisticIndex] = msg;
          return;
        }
      }

      _messages.add(msg);
    });
    _scrollToBottom();

    // If an incoming message from the other person arrived while chat is open, mark it as seen
    if (!msg.isMe) {
      final userId = _resolvedUserId;
      if (userId != null) {
        ChatRemoteDataSource.instance.markAsRead(userId);
        ChatStompService.instance.markSeen(otherUserId: userId);
        final myUid = TokenStorage.instance.currentUserIdSync ??
            (TokenStorage.instance.currentUsernameSync == 's1' ? 99 : 1);
        ChatManager.instance.markConversationSeenByRecipient(
          recipientId: myUid,
          senderId: userId,
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$minute ${now.hour >= 12 ? 'PM' : 'AM'}';

    final optimisticMsg = ChatMessage(
      id: now.millisecondsSinceEpoch.toString(),
      text: text,
      isMe: true,
      timestamp: timeStr,
      status: 'Sent',
      sentAt: now,
    );

    setState(() {
      _messages.add(optimisticMsg);
      _messageController.clear();
    });
    _scrollToBottom();

    // Persist to database via ChatManager without auto-reply
    ChatManager.instance.sendMessage(threadId: widget.thread.id, text: text);
  }

  Future<void> _pickImages() async {
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 90);
      if (!mounted || picked.isEmpty) return;
      setState(() {
        for (final file in picked) {
          if (file.path.isNotEmpty && !_pendingImagePaths.contains(file.path)) {
            _pendingImagePaths.add(file.path);
          }
        }
      });
    } catch (e) {
      debugPrint('[Chat] Error picking images: $e');
    }
  }

  Future<void> _pickCameraImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (!mounted || picked == null || picked.path.isEmpty) return;
      setState(() {
        if (!_pendingImagePaths.contains(picked.path)) {
          _pendingImagePaths.add(picked.path);
        }
      });
    } catch (e) {
      debugPrint('[Chat] Error taking photo: $e');
    }
  }

  void _removePendingImage(int index) {
    if (index >= 0 && index < _pendingImagePaths.length) {
      setState(() {
        _pendingImagePaths.removeAt(index);
      });
    }
  }

  void _showImagePreviewDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.of(ctx).pop(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0x99000000),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendSelectedImages() async {
    if (_pendingImagePaths.isEmpty || !mounted) return;
    final paths = List<String>.from(_pendingImagePaths);
    setState(() {
      _pendingImagePaths.clear();
      _isUploadingImages = true;
    });

    final targetUserId = _resolvedUserId ?? TokenStorage.instance.currentUserIdSync ?? 1;

    try {
      for (final path in paths) {
        String? mediaUrl;
        try {
          mediaUrl = await ChatRemoteDataSource.instance.uploadChatImage(
            targetUserId,
            path,
          );
        } catch (e) {
          debugPrint('[Chat] uploadChatImage error, using local path: $e');
          mediaUrl = path;
        }

        const text = 'Photo';
        final now = DateTime.now();
        final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
        final minute = now.minute.toString().padLeft(2, '0');
        final timeStr = '$hour:$minute ${now.hour >= 12 ? 'PM' : 'AM'}';

        final newMsg = ChatMessage(
          id: now.millisecondsSinceEpoch.toString(),
          text: text,
          isMe: true,
          timestamp: timeStr,
          status: 'Sent',
          mediaUrl: mediaUrl,
          sentAt: now,
        );

        setState(() {
          _messages.add(newMsg);
        });
        ChatManager.instance.sendMessage(
          threadId: widget.thread.id,
          text: text,
          mediaUrl: mediaUrl,
        );
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not send image: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImages = false);
      }
    }
  }

  Future<void> _handleSend() async {
    if (_isUploadingImages) return;
    if (_pendingImagePaths.isNotEmpty) {
      await _sendSelectedImages();
    }
    if (_messageController.text.trim().isNotEmpty) {
      _sendMessage();
    }
  }

  int? get _resolvedUserId =>
      widget.thread.userId ??
      int.tryParse(widget.thread.id) ??
      ChatManager.instance.resolveUserId(widget.thread.id, widget.thread.username);

  String? _displayMessageStatus(ChatMessage message) {
    if (!message.isMe) return null;
    if (message.isDeletedForEveryone) return null;
    if (message.status == 'Seen') return 'Seen';
    final index = _messages.indexWhere((m) => m.id == message.id);
    if (index != -1) {
      final hasLaterSeen = _messages.skip(index + 1).any((m) => m.isMe && m.status == 'Seen');
      if (hasLaterSeen) return 'Seen';
    }
    return message.status ?? 'Sent';
  }

  bool _shouldShowTimestamp(ChatMessage message) {
    return _expandedTimestampIds.contains(message.id);
  }

  String _messageTime(ChatMessage message) {
    final time = message.sentAt;
    if (time != null) {
      final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
      return '$hour:${time.minute.toString().padLeft(2, '0')} ${time.hour >= 12 ? 'PM' : 'AM'}';
    }
    if (message.timestamp.isNotEmpty && message.timestamp != 'Just now') {
      return message.timestamp;
    }
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    return '$hour:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'PM' : 'AM'}';
  }

  void _toggleTimestamp(ChatMessage message) {
    setState(() {
      if (_expandedTimestampIds.contains(message.id)) {
        _expandedTimestampIds.remove(message.id);
      } else {
        _expandedTimestampIds.add(message.id);
      }
    });
  }

  void _openProfile() {
    final uid = _resolvedUserId;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => PublicProfileScreen(
              userId: uid,
              username: widget.thread.username.toLowerCase().replaceAll(
                ' ',
                '_',
              ),
              displayName: widget.thread.username,
              avatarUrl: widget.thread.avatarUrl,
              isFollowing: _isFollowing,
              followsYou: _followsYou,
            ),
          ),
        )
        .then((_) {
          // Re-sync follow state if changed in profile
          if (uid != null && mounted) {
            final currentThread = ChatManager.instance.getThread(
              widget.thread.id,
            );
            if (currentThread.isFollowing != _isFollowing) {
              setState(() {
                _isFollowing = currentThread.isFollowing;
              });
            }
          }
        });
  }

  void _toggleFollow() async {
    HapticFeedback.lightImpact();
    final newStatus = !_isFollowing;
    setState(() {
      _isFollowing = newStatus;
    });

    final uid = _resolvedUserId;
    if (uid != null) {
      ChatManager.instance.updateFollowState(uid, newStatus);
      ProfileSyncService.instance.notifyFollowChanged(
        targetUserId: uid,
        isFollowing: newStatus,
      );
      try {
        if (newStatus) {
          await ProfileRemoteDataSource.instance.toggleFollow(uid);
        } else {
          await ProfileRemoteDataSource.instance.unfollow(uid);
        }
      } catch (_) {}
    }
  }

  void _showChatOptionsMenu() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16161A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                title: const Text(
                  'View Profile',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _openProfile();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFFE2C55),
                  size: 22,
                ),
                title: Text(
                  'Delete Chat with ${widget.thread.username}',
                  style: const TextStyle(
                    color: Color(0xFFFE2C55),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmDeleteChat();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.visibility_off_outlined,
                  color: Colors.white70,
                  size: 22,
                ),
                title: const Text(
                  'Delete chat for me',
                  style: TextStyle(color: Colors.white, fontSize: 15),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  ChatManager.instance.removeThreadLocally(widget.thread.id);
                  Navigator.of(context).pop(true);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Delete Chat with ${widget.thread.username}?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this chat? All messages in this conversation will be permanently removed.',
          style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8E8E93)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFE2C55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ChatManager.instance.deleteThread(widget.thread.id);
              Navigator.of(context).pop(true);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(ChatMessage message) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF16161A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF222228),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message.isDeletedForEveryone
                        ? (message.isMe
                              ? 'You deleted a message'
                              : 'This message was deleted')
                        : message.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontStyle: message.isDeletedForEveryone
                          ? FontStyle.italic
                          : FontStyle.normal,
                      color: const Color(0xFFD1D1D6),
                    ),
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFFE2C55),
                  size: 22,
                ),
                title: const Text(
                  'Remove for you',
                  style: TextStyle(
                    color: Color(0xFFFE2C55),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Remove from chat just only me',
                  style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _confirmRemoveForYou(message);
                },
              ),
              if (message.isMe && !message.isDeletedForEveryone)
                ListTile(
                  leading: const Icon(
                    Icons.delete_forever_outlined,
                    color: Color(0xFFFE2C55),
                    size: 22,
                  ),
                  title: const Text(
                    'Remove for everyone',
                    style: TextStyle(
                      color: Color(0xFFFE2C55),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Shows "You deleted a message" to each other',
                    style: TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _confirmRemoveForEveryone(message);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _confirmRemoveForYou(ChatMessage message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Remove for you?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'Remove this message from your chat? The other person will still be able to see it.',
          style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8E8E93)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFE2C55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _messages.removeWhere((m) => m.id == message.id);
              });
              ChatManager.instance.removeMessageLocally(
                widget.thread.id,
                message.id,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message removed for you'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Remove for you',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRemoveForEveryone(ChatMessage message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Remove for everyone?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'This message will be removed for everyone in this chat and replaced with "You deleted a message".',
          style: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8E8E93)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFE2C55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                final idx = _messages.indexWhere((m) => m.id == message.id);
                if (idx != -1) {
                  _messages[idx] = _messages[idx].copyWith(
                    text: 'You deleted a message',
                    mediaUrl: null,
                    isDeletedForEveryone: true,
                  );
                }
              });
              ChatManager.instance.deleteMessage(
                widget.thread.id,
                message.id,
                forEveryone: true,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message removed for everyone'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              'Remove for everyone',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String relationLabel = widget.thread.followersCount;
    if (_isFriend) {
      relationLabel = widget.thread.followersCount.isNotEmpty
          ? 'Friends 👥 • ${widget.thread.followersCount}'
          : 'Friends 👥';
    } else if (_isFollowing) {
      relationLabel = widget.thread.followersCount.isNotEmpty
          ? 'Following • ${widget.thread.followersCount}'
          : 'Following';
    } else if (_followsYou) {
      relationLabel = widget.thread.followersCount.isNotEmpty
          ? 'Follows you • ${widget.thread.followersCount}'
          : 'Follows you';
    }

    return Scaffold(
      backgroundColor: AppColors.voidBackground,
      appBar: AppBar(
        backgroundColor: AppColors.voidBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: GestureDetector(
          onTap: _openProfile,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              // Avatar
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isFriend
                        ? const Color(0xFF2F80ED)
                        : Colors.white.withValues(alpha: 0.2),
                    width: _isFriend ? 1.5 : 1.0,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    widget.thread.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Title & Followers / Relation
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            widget.thread.username,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (widget.thread.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF2F80ED),
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    Text(
                      relationLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: _isFriend
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: _isFriend
                            ? const Color(0xFF2F80ED)
                            : AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Follow / Friends Action Pill Button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _toggleFollow,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _isFriend
                      ? const Color(0xFF1E293B)
                      : (_isFollowing
                            ? const Color(0xFF27272A)
                            : const Color(0xFF2F80ED)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isFriend
                        ? const Color(0xFF2F80ED)
                        : (_isFollowing
                              ? const Color(0xFF3F3F46)
                              : Colors.transparent),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    _isFriend
                        ? 'Friends 👥'
                        : (_isFollowing
                              ? 'Following'
                              : (_followsYou ? '+ Follow back' : '+ Follow')),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isFriend ? const Color(0xFF38BDF8) : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
              size: 22,
            ),
            onPressed: _showChatOptionsMenu,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 1. Message Bubble Timeline
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                // Account Profile Introduction Card
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24, top: 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161A),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: _openProfile,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isFriend
                                    ? const Color(0xFF2F80ED)
                                    : Colors.white.withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                widget.thread.avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white70,
                                  size: 36,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.thread.username,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            if (widget.thread.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFF2F80ED),
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${widget.thread.username.toLowerCase().replaceAll(' ', '_')} • ${widget.thread.followersCount}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _isFriend
                                ? const Color(0x262F80ED)
                                : const Color(0xFF242428),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isFriend
                                ? '👥 You and ${widget.thread.username} are friends on Vilo'
                                : (_isFollowing
                                      ? '✓ You follow ${widget.thread.username}'
                                      : (_followsYou
                                            ? '${widget.thread.username} follows you'
                                            : 'Connect with ${widget.thread.username}')),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _isFriend
                                  ? const Color(0xFF38BDF8)
                                  : Colors.white70,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: _toggleFollow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFriend
                                    ? const Color(0xFF27272A)
                                    : (_isFollowing
                                          ? const Color(0xFF27272A)
                                          : const Color(0xFF2F80ED)),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                    color: _isFriend
                                        ? const Color(0xFF2F80ED)
                                        : Colors.transparent,
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                              ),
                              child: Text(
                                _isFriend
                                    ? 'Friends 👥'
                                    : (_isFollowing
                                          ? 'Following'
                                          : (_followsYou
                                                ? 'Follow Back'
                                                : 'Follow')),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: _openProfile,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 10,
                                ),
                              ),
                              child: const Text(
                                'View Profile',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Date Header
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: const Text(
                      'Today',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                ),

                // Messages
                ...List.generate(_messages.length, (index) {
                  final message = _messages[index];
                  return _buildMessageBubble(message);
                }),
              ],
            ),
          ),

          // 2. Bottom Chat Input Bar
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              MediaQuery.of(context).padding.bottom + 10,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0E0E10),
              border: Border(
                top: BorderSide(color: Color(0xFF1E1E22), width: 1.0),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_pendingImagePaths.isNotEmpty) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    height: 84,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      itemCount: _pendingImagePaths.length + 1,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        if (index == _pendingImagePaths.length) {
                          // "Add more" card
                          return GestureDetector(
                            onTap: _pickImages,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1C1E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: Colors.white70,
                                    size: 24,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Add more',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        final path = _pendingImagePaths[index];
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            GestureDetector(
                              onTap: () => _showImagePreviewDialog(path),
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF2F80ED).withValues(alpha: 0.6),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10.5),
                                  child: Image.file(
                                    File(path),
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                            // Delete/Remove button badge in top-right
                            Positioned(
                              top: -5,
                              right: -5,
                              child: GestureDetector(
                                onTap: () => _removePendingImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE53935),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black87,
                                        blurRadius: 3,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
                Row(
                  children: [
                    // Image Gallery Button (ALWAYS gallery icon, never turns into send)
                    IconButton(
                      tooltip: 'Choose photos',
                      icon: const Icon(
                        Icons.image_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: _pickImages,
                    ),

                    // Camera Button (takes photo directly)
                    IconButton(
                      tooltip: 'Take photo',
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: _pickCameraImage,
                    ),

                    const SizedBox(width: 4),

                    // Text Input Pill
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 1.0,
                          ),
                        ),
                        child: TextField(
                          controller: _messageController,
                          textInputAction: TextInputAction.send,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 15,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Start a message...',
                            hintStyle: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF8E8E93),
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            suffixIcon: Icon(
                              Icons.sentiment_satisfied_alt_outlined,
                              color: Color(0xFF8E8E93),
                              size: 22,
                            ),
                          ),
                          onSubmitted: (_) => _handleSend(),
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // The ONLY Send Button (on the right)
                    IconButton(
                      tooltip: 'Send',
                      icon: _isUploadingImages
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF2F80ED),
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: _canSend
                                  ? const Color(0xFF2F80ED)
                                  : Colors.white.withValues(alpha: 0.3),
                              size: 22,
                            ),
                      onPressed: _canSend && !_isUploadingImages ? _handleSend : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _resolveChatMediaUrl(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    if (trimmed.startsWith('/uploads/') || trimmed.startsWith('uploads/')) {
      final base = ApiClient.baseUrl.replaceFirst('/api/v1', '');
      return '$base${trimmed.startsWith('/') ? trimmed : '/$trimmed'}';
    }
    return trimmed;
  }

  Widget _buildMessageContent(ChatMessage message) {
    if (message.isDeletedForEveryone) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.block_outlined, size: 15, color: Color(0xFF8E8E93)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.isMe
                  ? 'You deleted a message'
                  : 'This message was deleted',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
                color: Color(0xFF8E8E93),
                height: 1.3,
              ),
            ),
          ),
        ],
      );
    }
    if (message.mediaUrl != null && message.mediaUrl!.trim().isNotEmpty) {
      final url = _resolveChatMediaUrl(message.mediaUrl!);
      final isLocal = !url.startsWith('http://') && !url.startsWith('https://');

      Widget imageWidget;
      if (isLocal) {
        final file = File(url);
        if (file.existsSync()) {
          imageWidget = Image.file(
            file,
            width: 220,
            height: 220,
            fit: BoxFit.cover,
          );
        } else {
          imageWidget = Container(
            width: 220,
            height: 140,
            color: const Color(0xFF2C2C2E),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_outlined, color: Colors.white54, size: 36),
                SizedBox(height: 6),
                Text('Photo', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          );
        }
      } else {
        imageWidget = Image.network(
          url,
          width: 220,
          height: 220,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 220,
              height: 220,
              color: const Color(0xFF1E1E22),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2F80ED),
                  ),
                ),
              ),
            );
          },
          errorBuilder: (_, _, _) => Container(
            width: 220,
            height: 140,
            color: const Color(0xFF2C2C2E),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_outlined, color: Colors.white54, size: 36),
                SizedBox(height: 6),
                Text('Photo', style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTap: () => showDialog(
            context: context,
            builder: (_) => Dialog(
              backgroundColor: Colors.black,
              insetPadding: EdgeInsets.zero,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  InteractiveViewer(
                    child: Center(
                      child: isLocal
                          ? (File(url).existsSync()
                              ? Image.file(File(url), fit: BoxFit.contain)
                              : const Icon(Icons.broken_image, color: Colors.white70, size: 48))
                          : Image.network(url, fit: BoxFit.contain),
                    ),
                  ),
                  Positioned(
                    top: 40,
                    right: 20,
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          child: imageWidget,
        ),
      );
    }

    if (message.text == 'Photo' || message.text == '📷 Photo') {
      return Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_outlined, color: Colors.white70, size: 20),
            SizedBox(width: 8),
            Text(
              'Photo',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      message.text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: Colors.white,
        height: 1.3,
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    if (message.isMe) {
      final displayStatus = _displayMessageStatus(message);
      final isDeleted = message.isDeletedForEveryone;
      final showTimestamp = _shouldShowTimestamp(message);
      // Sent Message (Blue Bubble on Right, or subtle dark bubble if deleted)
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => _toggleTimestamp(message),
                onLongPress: () => _showMessageOptions(message),
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDeleted
                        ? const Color(0xFF1E1E22)
                        : const Color(0xFF2F80ED),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(4),
                    ),
                    border: isDeleted
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1.0,
                          )
                        : null,
                    boxShadow: isDeleted
                        ? null
                        : [
                            BoxShadow(
                              color: const Color(
                                0xFF2F80ED,
                              ).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildMessageContent(message),
                      if (showTimestamp && !isDeleted) ...[
                        const SizedBox(height: 4),
                        Text(
                          _messageTime(message),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (displayStatus != null && !isDeleted) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (displayStatus == 'Seen') ...[
                    const Icon(
                      Icons.done_all_rounded,
                      size: 14,
                      color: Color(0xFF38BDF8),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    displayStatus,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: displayStatus == 'Seen'
                          ? const Color(0xFF38BDF8)
                          : const Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    } else {
      final isDeleted = message.isDeletedForEveryone;
      final showTimestamp = _shouldShowTimestamp(message);
      // Received Message (White / Glass Bubble on Left with Avatar)
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Small sender avatar
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, top: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.0,
                ),
              ),
              child: ClipOval(
                child: Image.network(
                  widget.thread.avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.storefront_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Bubble
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => _toggleTimestamp(message),
                  onLongPress: () => _showMessageOptions(message),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E22),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                      border: Border.all(
                        color: isDeleted
                            ? Colors.white.withValues(alpha: 0.12)
                            : AppColors.surfaceStroke,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMessageContent(message),
                        if (showTimestamp && !isDeleted) ...[
                          const SizedBox(height: 4),
                          Text(
                            _messageTime(message),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white54,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
