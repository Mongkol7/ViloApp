import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/inbox_message_manager.dart';
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
  bool _isRestoringConversation = true;

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.thread.messages);
    _restoreConversation();
  }

  Future<void> _restoreConversation() async {
    final manager = InboxMessageManager.instance;
    try {
      await manager.loadForCurrentUser();
    } catch (error) {
      if (mounted) {
        setState(() => _isRestoringConversation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not restore messages: $error')),
        );
      }
      return;
    }
    if (!mounted) return;
    final thread = manager.getThread(widget.thread.id);
    final draft = manager.getDraft(widget.thread.id);
    setState(() {
      if (thread != null) _messages = List.from(thread.messages);
      if (_messageController.text.isEmpty && draft != null) {
        _messageController.text = draft;
      }
      _isRestoringConversation = false;
    });
  }

  Future<void> _saveDraft(String draft) async {
    try {
      await InboxMessageManager.instance.saveDraft(widget.thread.id, draft);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save message draft: $error')),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final newMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isMe: true,
      timestamp: 'Just now',
      status: 'Sent',
    );

    setState(() {
      _messages.add(newMsg);
      _messageController.clear();
    });

    try {
      await InboxMessageManager.instance.addMessageToThread(
        widget.thread.id,
        newMsg,
      );
      await InboxMessageManager.instance.saveDraft(widget.thread.id, '');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message sent, but could not be saved: $error')),
        );
      }
    }
  }

  Future<void> _sendImageMessage(String imageAssetPath, {String? caption}) async {
    final newMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: caption ?? '',
      isMe: true,
      timestamp: 'Just now',
      status: 'Sent',
      imageUrl: imageAssetPath,
      imageUrls: [imageAssetPath],
    );

    setState(() {
      _messages.add(newMsg);
      _messageController.clear();
    });

    try {
      await InboxMessageManager.instance.addMessageToThread(
        widget.thread.id,
        newMsg,
      );
      await InboxMessageManager.instance.saveDraft(widget.thread.id, '');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Message sent, but could not be saved: $error')),
        );
      }
    }
  }

  void _openMediaAttachmentSheet() {
    final availableImages = [
      'assets/images/v_watch_ultra.jpg',
      'assets/images/canvas_tote.jpg',
      'assets/images/iphone_17_pro_max_case.jpg',
      'assets/images/v_series_headphones.jpg',
      'assets/images/midnight_hydration_serum.jpg',
      'assets/images/mini_rice_cooker.jpg',
      'assets/images/obsidian_hoodie.jpg',
      'assets/images/pocket_fill_light.jpg',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E22),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Attach Photo to Message',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: availableImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final img = availableImages[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendImageMessage(img, caption: _messageController.text.trim());
                      _messageController.clear();
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white24),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _buildMessageImage(img, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        title: Row(
          children: [
            // Avatar
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.0,
                ),
              ),
              child: ClipOval(
                child: _buildChatAvatar(widget.thread.avatarUrl),
              ),
            ),
            const SizedBox(width: 10),

            // Title & Followers
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.thread.username,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
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
                  if (widget.thread.followersCount.isNotEmpty)
                    Text(
                      widget.thread.followersCount,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.outline,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
              size: 24,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Message Bubble Timeline
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              physics: const BouncingScrollPhysics(),
              children: [
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
                  onPressed: _openMediaAttachmentSheet,
                ),

                // Camera Button
                IconButton(
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: _openMediaAttachmentSheet,
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
                      onChanged: _saveDraft,
                      enabled: !_isRestoringConversation,
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
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
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
                  maxWidth: MediaQuery.of(context).size.width * 0.78,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.hasImages)
                      _buildMessageMedia(message, isMe: true),
                    if (message.text.isNotEmpty)
                      Text(
                        message.text,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                          height: 1.35,
                        ),
                      ),
                  ],
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
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (message.hasImages)
                        _buildMessageMedia(message, isMe: false),
                      if (message.text.isNotEmpty)
                        Text(
                          message.text,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w400,
                            color: Colors.white,
                            height: 1.35,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildMessageMedia(ChatMessage message, {required bool isMe}) {
    final images = message.allImages;
    if (images.isEmpty) return const SizedBox.shrink();

    if (images.length == 1) {
      final img = images.first;
      return Padding(
        padding: EdgeInsets.only(bottom: message.text.isNotEmpty ? 10 : 0),
        child: GestureDetector(
          onTap: () => _openImagePreview(img),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(
                maxHeight: 180,
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1,
                ),
              ),
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  _buildMessageImage(img, fit: BoxFit.cover),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.fullscreen_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Multiple product images in order
    return Padding(
      padding: EdgeInsets.only(bottom: message.text.isNotEmpty ? 10 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final img = images[idx];
                return GestureDetector(
                  onTap: () => _openImagePreview(img),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: _buildMessageImage(img, fit: BoxFit.cover),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageImage(String url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    final cleanUrl = url.trim();
    if (cleanUrl.startsWith('assets/')) {
      return Image.asset(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(width, height),
      );
    }
    if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      return Image.network(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(width, height),
      );
    }
    return _buildImagePlaceholder(width, height);
  }

  Widget _buildImagePlaceholder([double? width, double? height]) {
    return Container(
      width: width,
      height: height,
      color: Colors.white.withValues(alpha: 0.08),
      child: const Center(
        child: Icon(Icons.shopping_bag_outlined, color: Colors.white38, size: 28),
      ),
    );
  }

  void _openImagePreview(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildMessageImage(imageUrl, fit: BoxFit.contain),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatAvatar(String url) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.storefront_rounded,
          color: Colors.white,
          size: 20,
        ),
      );
    }
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.storefront_rounded,
          color: Colors.white,
          size: 20,
        ),
      );
    }
    return const Icon(
      Icons.storefront_rounded,
      color: Colors.white,
      size: 20,
    );
  }
}
