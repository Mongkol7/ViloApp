import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/app.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../shop/models/product.dart';
import '../../../shop/data/datasources/shop_remote_data_source.dart';
import '../../../auth/data/datasources/token_storage.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../data/datasources/inbox_message_manager.dart';
import '../../domain/entities/inbox_item.dart';
import '../../../feed/data/datasources/feed_remote_data_source.dart';
import '../../../feed/data/models/video_model.dart';
import '../../../feed/presentation/pages/video_feed_page.dart';

class ChatDetailScreen extends StatefulWidget {
  final DirectMessageThread thread;

  const ChatDetailScreen({super.key, required this.thread});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> with RouteAware {
  final TextEditingController _messageController = TextEditingController();
  late DirectMessageThread _thread;
  late List<ChatMessage> _messages;
  bool _isRestoringConversation = true;
  Timer? _countdownTimer;
  Timer? _remoteSyncTimer;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _messageKeys = <String, GlobalKey>{};
  bool _routeSubscribed = false;
  bool _isChatVisible = true;
  bool _isUploadingPhoto = false;

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            0.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(0.0);
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _thread = InboxMessageManager.resolveThreadForActiveUser(widget.thread);
    _messages = List.from(_thread.messages);
    _restoreConversation();
    final bool isTestEnv = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('Test');
    if (!isTestEnv) {
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) setState(() {});
      });
      // InboxScreen is not active while this route is open, so keep the
      // current conversation synchronized for the other participant too.
      _remoteSyncTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
        if (!_isChatVisible) return;
        try {
          await InboxMessageManager.instance.refreshFromRemote();
        } catch (_) {
          // Keep the open chat usable if the backend is temporarily offline.
        }
        if (mounted) _refreshConversationFromManager();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_routeSubscribed) {
      final route = ModalRoute.of(context);
      if (route != null) {
        routeObserver.subscribe(this, route);
        _routeSubscribed = true;
      }
    }
  }

  @override
  void didPopNext() {
    _isChatVisible = true;
    _refreshConversationFromManager();
  }

  @override
  void didPushNext() {
    _isChatVisible = false;
  }

  void _refreshConversationFromManager() {
    final manager = InboxMessageManager.instance;
    final updated =
        manager.getThread(_thread.id) ??
        manager.getThreadByUsername(_thread.username);
    if (!mounted || updated == null) return;
    setState(() {
      _thread = updated;
      _messages = List.from(updated.messages);
    });
  }

  String _getMyHandle() {
    final activeProfile =
        ProfileSyncService.instance.cachedMyProfile ??
        TokenStorage.instance.getUserModel();
    final raw =
        (activeProfile?.username ?? ProfileSyncService.instance.currentUsername)
            .trim();
    if (raw.isEmpty) return '@me';
    return raw.startsWith('@') ? raw : '@$raw';
  }

  /// Navigate to the peer's public profile page.
  void _navigateToPeerProfile() {
    final cleanPeer = _thread.username.replaceAll('@', '').trim();
    if (cleanPeer.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          username: _thread.username,
          displayName: _thread.username,
          avatarUrl: _thread.avatarUrl,
        ),
      ),
    );
  }

  /// Navigate to a profile by handle (for message bubble avatar taps).
  void _navigateToProfile(String handle, String avatarUrl) {
    final myHandle = _getMyHandle();
    final cleanHandle = handle.replaceAll('@', '').trim().toLowerCase();
    final cleanMy = myHandle.replaceAll('@', '').trim().toLowerCase();
    // If tapping own avatar, go to own profile (pop to it or push public view).
    if (cleanHandle == cleanMy) {
      // Navigate to peer's profile is not applicable for self; just return.
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          username: handle,
          displayName: handle,
          avatarUrl: avatarUrl,
        ),
      ),
    );
  }

  void _restoreConversation() {
    final manager = InboxMessageManager.instance;
    final thread = manager.getThread(widget.thread.id);
    final draft = manager.getDraft(widget.thread.id);
    if (thread != null) {
      _thread = thread;
      _messages = List.from(thread.messages);
    }
    if (_messageController.text.isEmpty && draft != null) {
      _messageController.text = draft;
    }
    _isRestoringConversation = false;

    // Background sync so screen opens immediately without lag or jump
    manager
        .loadForCurrentUser()
        .then((_) {
          if (mounted) {
            final updated =
                manager.getThread(widget.thread.id) ??
                manager.getThreadByUsername(widget.thread.username);
            if (updated != null) {
              setState(() {
                _thread = updated;
                _messages = List.from(updated.messages);
              });
            }
          }
        })
        .catchError((_) {});
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
    if (_routeSubscribed) {
      routeObserver.unsubscribe(this);
    }
    _countdownTimer?.cancel();
    _remoteSyncTimer?.cancel();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final myHandle = _getMyHandle();
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final parsedUri = Uri.tryParse(text);
    final isLink =
        parsedUri != null &&
        (parsedUri.scheme == 'http' || parsedUri.scheme == 'https') &&
        parsedUri.host.isNotEmpty;

    final newMsg = ChatMessage(
      id: nowMs.toString(),
      text: text,
      isMe: true,
      senderHandle: myHandle,
      timestamp: 'Just now',
      status: 'Sent',
      contentType: isLink ? 'LINK' : 'TEXT',
      linkUrl: isLink ? text : null,
      // Free-form chat is never an order. Order cards are created by the
      // shop/profile flows, which attach a unique orderReference.
      isOrder: false,
      orderCreatedAtMs: null,
      orderStatus: null,
    );

    setState(() {
      _messages.add(newMsg);
      _messageController.clear();
    });
    _scrollToBottom(animated: true);

    try {
      await InboxMessageManager.instance.addMessageToThread(
        widget.thread.id,
        newMsg,
      );
      await InboxMessageManager.instance.saveDraft(widget.thread.id, '');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message sent, but could not be saved: $error'),
          ),
        );
      }
    }
  }

  Future<void> _sendImageUrls(List<String> imageUrls, {String? caption}) async {
    if (imageUrls.isEmpty) return;
    final myHandle = _getMyHandle();
    final newMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: (caption == null || caption.trim().isEmpty)
          ? (imageUrls.length == 1 ? 'Photo' : '${imageUrls.length} photos')
          : caption.trim(),
      isMe: true,
      senderHandle: myHandle,
      timestamp: 'Just now',
      status: 'Sent',
      imageUrl: imageUrls.first,
      imageUrls: imageUrls,
      contentType: 'IMAGE',
    );

    setState(() {
      _messages.add(newMsg);
      _messageController.clear();
    });
    _scrollToBottom(animated: true);

    try {
      await InboxMessageManager.instance.addMessageToThread(
        widget.thread.id,
        newMsg,
      );
      await InboxMessageManager.instance.saveDraft(widget.thread.id, '');
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message sent, but could not be saved: $error'),
          ),
        );
      }
    }
  }

  Future<void> _pickAndSendPhoto(ImageSource source) async {
    Navigator.of(context).pop();
    if (!await TokenStorage.instance.hasValidToken()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in before sending photos.'),
          ),
        );
      }
      return;
    }
    final picker = ImagePicker();
    final files = source == ImageSource.gallery
        ? await picker.pickMultiImage(
            imageQuality: 82,
            maxWidth: 2000,
            maxHeight: 2000,
          )
        : <XFile>[
            ?await picker.pickImage(
              source: source,
              imageQuality: 82,
              maxWidth: 2000,
              maxHeight: 2000,
            ),
          ];
    if (files.isEmpty) return;
    if (mounted) setState(() => _isUploadingPhoto = true);
    final uploadedUrls = <String>[];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      if (bytes.length > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${file.name} is larger than 10 MB.')),
          );
        }
        if (mounted) setState(() => _isUploadingPhoto = false);
        return;
      }
      try {
        uploadedUrls.add(
          await InboxMessageManager.instance.uploadChatPhoto(
            bytes,
            filename: file.name.isEmpty ? 'chat-photo.jpg' : file.name,
          ),
        );
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not upload photo: $error')),
          );
        }
        if (mounted) setState(() => _isUploadingPhoto = false);
        return;
      }
    }
    if (uploadedUrls.isEmpty) {
      if (mounted) setState(() => _isUploadingPhoto = false);
      return;
    }
    try {
      await _sendImageUrls(
        uploadedUrls,
        caption: _messageController.text.trim(),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not send photo: $error')));
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _openMediaAttachmentSheet() {
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
              'Attach photo to message',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: Colors.white,
              ),
              title: const Text(
                'Choose from gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => _pickAndSendPhoto(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt_outlined,
                color: Colors.white,
              ),
              title: const Text(
                'Take a photo',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => _pickAndSendPhoto(ImageSource.camera),
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
        title: GestureDetector(
          onTap: _navigateToPeerProfile,
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
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.0,
                  ),
                ),
                child: ClipOval(child: _buildChatAvatar(_thread.avatarUrl)),
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
                          _thread.username,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (_thread.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF2F80ED),
                            size: 16,
                          ),
                        ],
                      ],
                    ),
                    if (_thread.followersCount.isNotEmpty)
                      Text(
                        _thread.followersCount,
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
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              physics: const BouncingScrollPhysics(),
              children: [
                // Messages in reverse order so newest is at the bottom (index 0)
                ...List.generate(_messages.length, (index) {
                  final messageIndex = _messages.length - 1 - index;
                  final message = _messages[messageIndex];
                  return _buildMessageBubble(message, occurrence: messageIndex);
                }),

                // Date Header at top of conversation
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
                  onPressed: _isUploadingPhoto
                      ? null
                      : _openMediaAttachmentSheet,
                ),

                // Camera Button
                IconButton(
                  icon: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: _isUploadingPhoto
                      ? null
                      : _openMediaAttachmentSheet,
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

  Widget _buildMessageBubble(ChatMessage message, {required int occurrence}) {
    final activeProfile =
        ProfileSyncService.instance.cachedMyProfile ??
        TokenStorage.instance.getUserModel();
    final rawUsername =
        (activeProfile?.username ?? ProfileSyncService.instance.currentUsername)
            .trim();
    final cleanMy = rawUsername.replaceAll('@', '').toLowerCase();

    final bool isFromMe =
        (message.senderHandle != null &&
            message.senderHandle!.trim().isNotEmpty &&
            cleanMy.isNotEmpty)
        ? (message.senderHandle!.replaceAll('@', '').trim().toLowerCase() ==
              cleanMy)
        : message.isMe;

    final bool isOrder = message.isOrderMessage;
    final bool isCancellation = _isCancellationMessage(message);

    if (isFromMe) {
      // Sent Message (Blue Bubble on Right)
      return Padding(
        key: _messageKeyFor(message, occurrence: occurrence),
        padding: const EdgeInsets.only(bottom: 16),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isCancellation ? () => _openRelatedOrder(message) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.82,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isOrder
                        ? (message.isCancelled
                              ? const Color(0xFF332025)
                              : const Color(0xFF1E3A8A))
                        : const Color(0xFF2F80ED),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(4),
                    ),
                    border: isOrder
                        ? Border.all(
                            color: message.isCancelled
                                ? const Color(0xFFEF4444).withValues(alpha: 0.4)
                                : const Color(
                                    0xFF38BDF8,
                                  ).withValues(alpha: 0.5),
                            width: 1.0,
                          )
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (isOrder
                                    ? (message.isCancelled
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF2563EB))
                                    : const Color(0xFF2F80ED))
                                .withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isOrder) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: message.isCancelled
                                    ? const Color(
                                        0xFFEF4444,
                                      ).withValues(alpha: 0.25)
                                    : const Color(
                                        0xFF38BDF8,
                                      ).withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    message.isCancelled
                                        ? Icons.cancel_outlined
                                        : Icons.shopping_bag_outlined,
                                    color: message.isCancelled
                                        ? const Color(0xFFEF4444)
                                        : const Color(0xFF38BDF8),
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    message.isCancelled
                                        ? 'CANCELLED ORDER'
                                        : 'ORDER INQUIRY',
                                    style: TextStyle(
                                      color: message.isCancelled
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF38BDF8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Three dots menu on order messages only
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _showOrderActionsSheet(message),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                child: Icon(
                                  Icons.more_horiz_rounded,
                                  color: Colors.white70,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (!isOrder && !message.deletedForEveryone)
                        Align(
                          alignment: Alignment.centerRight,
                          child: _buildMessageOverflow(message, isFromMe: true),
                        ),
                      if (message.isVideoShare && !message.deletedForEveryone)
                        _buildSharedVideoCard(message),
                      if (message.hasImages &&
                          !message.isVideoShare &&
                          !message.deletedForEveryone)
                        _buildMessageMedia(message, isMe: true),
                      if (message.text.isNotEmpty && !message.isVideoShare)
                        _buildMessageText(message),
                    ],
                  ),
                ),
              ),
              if (isOrder &&
                  (message.isCancelled ||
                      (message.orderCreatedAtMs != null &&
                          message.cancelRemainingSeconds > 0))) ...[
                const SizedBox(height: 5),
                _buildOrderCountdown(message),
              ],
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
        ),
      );
    } else {
      // Received Message (White / Glass Bubble on Left with Avatar)
      final String peerHandle = message.senderHandle?.isNotEmpty == true
          ? message.senderHandle!
          : _thread.username;
      final String peerAvatarUrl = InboxMessageManager.resolveUserAvatar(
        peerHandle,
        candidateAvatar: _thread.avatarUrl,
      );
      return Padding(
        key: _messageKeyFor(message, occurrence: occurrence),
        padding: const EdgeInsets.only(bottom: 16),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: isCancellation ? () => _openRelatedOrder(message) : null,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => _navigateToProfile(peerHandle, peerAvatarUrl),
                child: Container(
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
                  child: ClipOval(child: _buildChatAvatar(peerAvatarUrl)),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.82,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isOrder
                              ? (message.isCancelled
                                    ? const Color(0xFF281E20)
                                    : const Color(0xFF1E2433))
                              : const Color(0xFF1E1E22),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(18),
                            bottomLeft: Radius.circular(18),
                            bottomRight: Radius.circular(18),
                          ),
                          border: Border.all(
                            color: isOrder
                                ? (message.isCancelled
                                      ? const Color(
                                          0xFFEF4444,
                                        ).withValues(alpha: 0.4)
                                      : const Color(
                                          0xFF38BDF8,
                                        ).withValues(alpha: 0.4))
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isOrder) ...[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: message.isCancelled
                                          ? const Color(
                                              0xFFEF4444,
                                            ).withValues(alpha: 0.25)
                                          : const Color(
                                              0xFF38BDF8,
                                            ).withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          message.isCancelled
                                              ? Icons.cancel_outlined
                                              : Icons.shopping_bag_outlined,
                                          color: message.isCancelled
                                              ? const Color(0xFFEF4444)
                                              : const Color(0xFF38BDF8),
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          message.isCancelled
                                              ? 'CANCELLED ORDER'
                                              : 'ORDER INQUIRY',
                                          style: TextStyle(
                                            color: message.isCancelled
                                                ? const Color(0xFFEF4444)
                                                : const Color(0xFF38BDF8),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Three dots menu on order messages only
                                  InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () =>
                                        _showOrderActionsSheet(message),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                      child: Icon(
                                        Icons.more_horiz_rounded,
                                        color: Colors.white70,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (!isOrder && !message.deletedForEveryone)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _buildMessageOverflow(
                                  message,
                                  isFromMe: false,
                                ),
                              ),
                            if (message.isVideoShare &&
                                !message.deletedForEveryone)
                              _buildSharedVideoCard(message),
                            if (message.hasImages &&
                                !message.isVideoShare &&
                                !message.deletedForEveryone)
                              _buildMessageMedia(message, isMe: false),
                            if (message.text.isNotEmpty &&
                                !message.isVideoShare)
                              _buildMessageText(message),
                          ],
                        ),
                      ),
                      if (isOrder &&
                          (message.isCancelled ||
                              (message.orderCreatedAtMs != null &&
                                  message.cancelRemainingSeconds > 0))) ...[
                        const SizedBox(height: 5),
                        _buildOrderCountdown(message),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildMessageOverflow(ChatMessage message, {required bool isFromMe}) {
    if (message.deletedForEveryone) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_horiz_rounded,
        color: Colors.white70,
        size: 19,
      ),
      color: const Color(0xFF2A2A2E),
      padding: EdgeInsets.zero,
      onSelected: (value) => _handleMessageAction(message, value),
      itemBuilder: (context) => [
        const PopupMenuItem<String>(
          value: 'ME',
          child: Text('Delete for me', style: TextStyle(color: Colors.white)),
        ),
        if (isFromMe)
          const PopupMenuItem<String>(
            value: 'EVERYONE',
            child: Text(
              'Delete for everyone',
              style: TextStyle(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageText(ChatMessage message) {
    final text = message.deletedForEveryone ? 'Message deleted' : message.text;
    final link = message.linkUrl ?? (message.isLinkMessage ? text : null);
    final style = TextStyle(
      fontFamily: 'Inter',
      fontSize: 14.5,
      fontWeight: FontWeight.w400,
      color: message.deletedForEveryone ? Colors.white54 : Colors.white,
      decoration: link == null ? TextDecoration.none : TextDecoration.underline,
      height: 1.35,
    );
    if (link == null) return Text(text, style: style);
    return GestureDetector(
      onTap: () => _openMessageLink(link),
      child: Text(text, style: style.copyWith(color: const Color(0xFF93C5FD))),
    );
  }

  Future<void> _handleMessageAction(ChatMessage message, String scope) async {
    final title = scope == 'EVERYONE'
        ? 'Delete for everyone?'
        : 'Delete for me?';
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E22),
            title: Text(title, style: const TextStyle(color: Colors.white)),
            content: Text(
              scope == 'EVERYONE'
                  ? 'This will replace the message for both participants.'
                  : 'This message will be hidden from your inbox.',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text(
                  'Keep',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    try {
      await InboxMessageManager.instance.deleteMessage(
        _thread.id,
        message,
        forEveryone: scope == 'EVERYONE',
      );
      _refreshConversationFromManager();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete message: $error')),
        );
      }
    }
  }

  Widget _buildSharedVideoCard(ChatMessage message) {
    return GestureDetector(
      onTap: () => _openSharedVideo(message),
      child: Container(
        width: 240,
        margin: const EdgeInsets.only(bottom: 8),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildMessageImage(
                    message.sharedVideoThumbnailUrl ?? '',
                    fit: BoxFit.cover,
                  ),
                  const Center(
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Text(
                message.sharedVideoCaption?.isNotEmpty == true
                    ? message.sharedVideoCaption!
                    : 'Shared video',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSharedVideo(ChatMessage message) async {
    VideoModel? video;
    if (message.sharedVideoId != null && message.sharedVideoId! > 0) {
      try {
        video = await FeedRemoteDataSource.instance.getVideoById(
          message.sharedVideoId!,
        );
      } catch (_) {}
    }
    video ??= VideoModel(
      id: message.sharedVideoId ?? 0,
      creatorId: 0,
      username: message.sharedVideoCreator ?? '@creator',
      displayName: message.sharedVideoCreator ?? 'Creator',
      caption: message.sharedVideoCaption ?? '',
      videoUrl: message.sharedVideoUrl ?? '',
      thumbnailUrl: message.sharedVideoThumbnailUrl,
    );
    if (!mounted || video.videoUrl.trim().isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            VideoFeedPage(initialVideos: [video!], hasBottomNav: false),
      ),
    );
  }

  Future<void> _openMessageLink(String value) async {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !await canLaunchUrl(uri)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  bool _isCancellationMessage(ChatMessage message) {
    return message.text.trim().toLowerCase().startsWith('order cancelled by ');
  }

  GlobalKey _messageKeyFor(ChatMessage message, {required int occurrence}) {
    final keyId = '${message.id}::$occurrence';
    return _messageKeys.putIfAbsent(keyId, GlobalKey.new);
  }

  void _openRelatedOrder(ChatMessage cancellationMessage) {
    final reference = cancellationMessage.orderReference?.trim() ?? '';
    final title =
        cancellationMessage.orderProductTitle?.trim().toLowerCase() ?? '';
    final orderIndex = _messages.lastIndexWhere((message) {
      if (!message.isOrderMessage || message.id == cancellationMessage.id)
        return false;
      if (reference.isNotEmpty) {
        return message.orderReference?.trim() == reference;
      }
      final messageTitle =
          message.orderProductTitle?.trim().toLowerCase() ?? '';
      return title.isNotEmpty && messageTitle == title;
    });

    if (orderIndex == -1) return;
    final related = _messages[orderIndex];
    final targetContext =
        _messageKeys['${related.id}::$orderIndex']?.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
        alignment: 0.45,
      );
    }
  }

  Widget _buildOrderCountdown(ChatMessage message) {
    if (message.isCancelled) {
      final who = message.cancelledBy ?? 'Buyer';
      final when = message.cancellationTime != null
          ? ' • ${message.cancellationTime}'
          : '';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cancel_rounded,
              color: Color(0xFFEF4444),
              size: 13,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                'Cancelled by $who$when',
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (message.orderCreatedAtMs == null) {
      return const SizedBox.shrink();
    }
    final int remainingSec = message.cancelRemainingSeconds;
    if (remainingSec <= 0) {
      return const SizedBox.shrink();
    }

    final hours = (remainingSec ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((remainingSec % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (remainingSec % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: Color(0xFFFBBF24), size: 13),
          const SizedBox(width: 5),
          Text(
            'Can cancel within: $hours:$minutes:$seconds',
            style: const TextStyle(
              color: Color(0xFFFBBF24),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderActionsSheet(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141416),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final remainingSec = message.cancelRemainingSeconds;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  message.orderProductTitle != null
                      ? 'Order: ${message.orderProductTitle}'
                      : 'Order Options',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (message.isCancelled) ...[
                  const ListTile(
                    leading: Icon(Icons.info_outline, color: Color(0xFFEF4444)),
                    title: Text(
                      'Order Already Cancelled',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Stock and sold count have been restored.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ] else if (remainingSec <= 0) ...[
                  const ListTile(
                    leading: Icon(
                      Icons.timer_off_outlined,
                      color: Colors.white38,
                    ),
                    title: Text(
                      'Cancellation Window Expired',
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'Orders can only be cancelled within 4 hours of ordering.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ),
                ] else ...[
                  ListTile(
                    leading: const Icon(
                      Icons.cancel_outlined,
                      color: Color(0xFFEF4444),
                    ),
                    title: const Text(
                      'Cancel Order',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Return stock and deduct sold count in real time',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmCancelOrder(message);
                    },
                  ),
                ],
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.white70,
                  ),
                  title: const Text(
                    'Delete for me',
                    style: TextStyle(color: Colors.white),
                  ),
                  subtitle: const Text(
                    'Hide this order message from your chat',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _handleMessageAction(message, 'ME');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmCancelOrder(ChatMessage message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Cancel Order?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to cancel this order for ${message.orderProductTitle ?? "this item"}? The deducted stock will be returned and sold count updated in real time.',
          style: const TextStyle(color: Colors.white70, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Keep Order',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _performOrderCancellation(message);
            },
            child: const Text(
              'Confirm Cancel',
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

  Future<void> _performOrderCancellation(ChatMessage message) async {
    // 1. Restore stock and deduct sold count
    if (message.orderItems != null && message.orderItems!.isNotEmpty) {
      for (final item in message.orderItems!) {
        final pId = item['id']?.toString() ?? '';
        final pTitle = item['title']?.toString();
        final pQty = (item['quantity'] as num?)?.toInt() ?? 1;
        Product.restoreStock(pId, pQty, productName: pTitle);
        Product.deductSoldCount(pId, pQty, productName: pTitle);
      }
    } else {
      final pId = message.orderProductId ?? '';
      final pTitle = message.orderProductTitle;
      final pQty = message.orderQuantity ?? 1;
      Product.restoreStock(pId, pQty, productName: pTitle);
      Product.deductSoldCount(pId, pQty, productName: pTitle);

      // Best effort text matching for legacy or profile message orders
      if (pTitle == null && message.text.contains('order ')) {
        final match = RegExp(r'order ([^(]+)').firstMatch(message.text);
        if (match != null) {
          final parsed = match.group(1)?.trim();
          if (parsed != null && parsed.isNotEmpty) {
            Product.restoreStock(parsed, 1, productName: parsed);
            Product.deductSoldCount(parsed, 1, productName: parsed);
          }
        }
      }
    }

    // Phnom Penh time calculation (UTC+7)
    final nowUtc = DateTime.now().toUtc();
    final phnomPenh = nowUtc.add(const Duration(hours: 7));
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour12 = phnomPenh.hour % 12 == 0 ? 12 : phnomPenh.hour % 12;
    final period = phnomPenh.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = phnomPenh.minute.toString().padLeft(2, '0');
    final formattedTime =
        '${months[phnomPenh.month - 1]} ${phnomPenh.day}, ${phnomPenh.year} at ${hour12.toString().padLeft(2, '0')}:$minuteStr $period (Phnom Penh)';

    final myHandle = _getMyHandle();
    final cleanMy = myHandle.replaceAll('@', '').trim().toLowerCase();
    final sender = (message.senderHandle ?? '')
        .replaceAll('@', '')
        .trim()
        .toLowerCase();
    final bool isBuyerCancelling =
        (sender.isNotEmpty && sender == cleanMy) ||
        (sender.isEmpty && message.isMe);
    final String cancelledRole = isBuyerCancelling ? 'Buyer' : 'Seller';
    final String cancelledDisplay = '$cancelledRole ($myHandle)';

    // 2. Mark this message as Cancelled in InboxMessageManager
    final cancelledMessage = message.copyWith(
      orderStatus: 'Cancelled',
      cancelledBy: cancelledDisplay,
      cancellationTime: formattedTime,
    );
    await InboxMessageManager.instance.updateMessageInThread(
      _thread.id,
      cancelledMessage,
    );

    // Sync only this exact order. Fall back to legacy title/message matching
    // for older messages that were created before order references existed.
    final orderReference = message.orderReference?.trim() ?? '';
    if (orderReference.isNotEmpty) {
      ShopRemoteDataSource.instance.updateOrderStatus(
        orderReference,
        'CANCELLED',
      );
    } else {
      if (message.orderProductTitle != null &&
          message.orderProductTitle!.isNotEmpty) {
        ShopRemoteDataSource.instance.updateOrderStatus(
          message.orderProductTitle!,
          'CANCELLED',
        );
      }
      ShopRemoteDataSource.instance.updateOrderStatus(message.id, 'CANCELLED');
    }

    // 3. Update local state directly without auto-sending new system message
    final updatedThread = InboxMessageManager.instance.getThread(_thread.id);
    if (mounted) {
      setState(() {
        if (updatedThread != null) {
          _thread = updatedThread;
          _messages = List.from(updatedThread.messages);
        } else {
          final idx = _messages.indexWhere((m) => m.id == message.id);
          if (idx != -1) {
            _messages[idx] = cancelledMessage;
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF1E1E22),
          content: Text(
            'Order cancelled. Stock and sold count restored in real time.',
          ),
          duration: Duration(seconds: 2),
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
              constraints: const BoxConstraints(maxHeight: 180),
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
              separatorBuilder: (context, _) => const SizedBox(width: 8),
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

  Widget _buildMessageImage(
    String url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    var cleanUrl = url.trim();
    if (cleanUrl.startsWith('/')) {
      cleanUrl = '${ApiClient.baseUrl.replaceAll('/api/v1', '')}$cleanUrl';
    }
    if (cleanUrl.startsWith('assets/')) {
      return Image.asset(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            _buildImagePlaceholder(width, height),
      );
    }
    if (cleanUrl.startsWith('uploads/')) {
      cleanUrl = '${ApiClient.baseUrl.replaceAll('/api/v1', '')}/$cleanUrl';
    }
    if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
      return Image.network(
        cleanUrl,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            _buildImagePlaceholder(width, height),
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
        child: Icon(
          Icons.shopping_bag_outlined,
          color: Colors.white38,
          size: 28,
        ),
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
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 26,
                ),
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
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
      );
    }
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
      );
    }
    return const Icon(Icons.storefront_rounded, color: Colors.white, size: 20);
  }
}
