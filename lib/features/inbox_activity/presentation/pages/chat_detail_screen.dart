import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../data/datasources/chat_manager.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/datasources/chat_stomp_service.dart';
import '../../domain/entities/inbox_item.dart';

class ChatDetailScreen extends StatefulWidget {
  final DirectMessageThread thread;

  const ChatDetailScreen({
    super.key,
    required this.thread,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  late List<ChatMessage> _messages;
  final ScrollController _scrollController = ScrollController();
  bool _canSend = false;
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
      final canSend = _messageController.text.trim().isNotEmpty;
      if (canSend != _canSend) {
        setState(() => _canSend = canSend);
      }
    });
    _loadMessages();
    ChatStompService.instance.addMessageListener(_handleIncomingMessage);
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
        final profile = await ProfileRemoteDataSource.instance.getUserById(userId);
        if (mounted) {
          setState(() {
            _isFollowing = profile.isFollowing;
            _followsYou = profile.followsYou;
          });
          ChatManager.instance.updateFollowState(userId, profile.isFollowing);
        }
      } catch (_) {}

      final remoteMessages = await ChatRemoteDataSource.instance.getMessages(userId);
      if (mounted && remoteMessages.isNotEmpty) {
        final existingTexts = remoteMessages.map((m) => m.text).toSet();
        final unsynced = _messages.where((m) => m.isMe && !existingTexts.contains(m.text)).toList();
        setState(() {
          _messages = [...remoteMessages, ...unsynced];
        });
        _scrollToBottom();
      }
    }
  }

  void _handleIncomingMessage(ChatMessage msg) {
    if (!mounted) return;
    setState(() {
      _messages.add(msg);
    });
    _scrollToBottom();
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

    final optimisticMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isMe: true,
      timestamp: 'Just now',
      status: 'Sent',
    );

    setState(() {
      _messages.add(optimisticMsg);
      _messageController.clear();
      _canSend = false;
    });
    _scrollToBottom();

    // Persist to database via ChatManager without auto-reply
    ChatManager.instance.sendMessage(
      threadId: widget.thread.id,
      text: text,
    );
  }

  int? get _resolvedUserId => widget.thread.userId ?? int.tryParse(widget.thread.id);

  void _openProfile() {
    final uid = _resolvedUserId;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          userId: uid,
          username: widget.thread.username.toLowerCase().replaceAll(' ', '_'),
          displayName: widget.thread.username,
          avatarUrl: widget.thread.avatarUrl,
          isFollowing: _isFollowing,
          followsYou: _followsYou,
        ),
      ),
    ).then((_) {
      // Re-sync follow state if changed in profile
      if (uid != null && mounted) {
        final currentThread = ChatManager.instance.getThread(widget.thread.id);
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
                        fontWeight: _isFriend ? FontWeight.w600 : FontWeight.w400,
                        color: _isFriend ? const Color(0xFF2F80ED) : AppColors.outline,
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                      color: _isFriend
                          ? const Color(0xFF38BDF8)
                          : Colors.white,
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
            onPressed: _openProfile,
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
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
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              ),
                              child: Text(
                                _isFriend
                                    ? 'Friends 👥'
                                    : (_isFollowing
                                        ? 'Following'
                                        : (_followsYou ? 'Follow Back' : 'Follow')),
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
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
            child: Row(
              children: [
                // Image Gallery Button
                IconButton(
                  icon: const Icon(
                    Icons.image_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {},
                ),

                // Camera Button
                IconButton(
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {},
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
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Send Button
                IconButton(
                  tooltip: 'Send',
                  icon: Icon(
                    Icons.send_rounded,
                    color: _canSend ? const Color(0xFF2F80ED) : Colors.white,
                    size: 22,
                  ),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    if (message.isMe) {
      // Sent Message (Blue Bubble on Right)
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F80ED),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2F80ED).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
              ),
            ),
            if (message.status != null) ...[
              const SizedBox(height: 4),
              Text(
                message.status!,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF8E8E93),
                ),
              ),
            ],
          ],
        ),
      );
    } else {
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
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E22),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(
                      color: AppColors.surfaceStroke,
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
                  child: Text(
                    message.text,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.3,
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
