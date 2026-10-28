import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../app/app.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../search_discover/presentation/pages/search_screen.dart';
import '../../data/datasources/inbox_message_manager.dart';
import '../../data/datasources/notification_manager.dart';
import '../../data/datasources/static_inbox_data.dart';
import '../../data/datasources/thought_story_manager.dart';
import '../../domain/entities/inbox_item.dart';
import '../../domain/entities/shared_thought_story.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../../feed/data/datasources/feed_remote_data_source.dart';
import '../../../feed/presentation/pages/video_feed_page.dart';
import '../widgets/animated_mini_music_wave.dart';
import 'chat_detail_screen.dart';
import 'share_thought_screen.dart';
import 'story_viewer_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> with RouteAware {
  Timer? _remoteSyncTimer;
  bool _routeSubscribed = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _remoteSyncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      InboxMessageManager.instance.loadForCurrentUser().catchError((_) {});
      NotificationManager.instance.loadForCurrentUser().catchError((_) {});
    });
  }

  @override
  void dispose() {
    if (_routeSubscribed) {
      routeObserver.unsubscribe(this);
    }
    _remoteSyncTimer?.cancel();
    super.dispose();
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
    // A profile or chat route was closed. Reload immediately so an order
    // created there is visible without leaving and reopening Inbox.
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      await Future.wait([
        InboxMessageManager.instance.loadForCurrentUser(),
        NotificationManager.instance.loadForCurrentUser(),
      ]);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not restore messages: $error')),
      );
    }
  }

  Future<void> _openNotification(NotificationItem item) async {
    try {
      await NotificationManager.instance.markRead(item);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update notification: $error')),
        );
      }
    }

    if (!mounted) return;
    if (item.type == 'FOLLOW') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PublicProfileScreen(
            userId: item.actorId,
            username: item.actorUsername,
            displayName: item.actorDisplayName,
            avatarUrl: item.actorAvatarUrl,
          ),
        ),
      );
      return;
    }

    if (item.videoId == null) return;
    try {
      final video = await FeedRemoteDataSource.instance.getVideoById(
        item.videoId!,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              VideoFeedPage(initialVideos: [video], hasBottomNav: false),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the related video: $error')),
        );
      }
    }
  }

  Future<void> _deleteConversationForMe(DirectMessageThread thread) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E22),
            title: const Text(
              'Delete conversation?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'This conversation will be hidden from your inbox. New messages can make it visible again.',
              style: TextStyle(color: Colors.white70),
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
      await InboxMessageManager.instance.deleteConversationForMe(thread.id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete conversation: $error')),
        );
      }
    }
  }

  Future<void> _handleCreateOrViewStory() async {
    final currentStory = ThoughtStoryManager.instance.currentStory;
    if (currentStory != null) {
      // If already shared, open StoryViewerScreen and listen for delete action
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => StoryViewerScreen(story: currentStory),
        ),
      );

      if (result == 'delete' && mounted) {
        ThoughtStoryManager.instance.deleteStory();
      }
    } else {
      // If not shared yet, open ShareThoughtScreen
      final result = await Navigator.of(context).push<SharedThoughtStory>(
        MaterialPageRoute(builder: (_) => const ShareThoughtScreen()),
      );

      if (result != null && mounted) {
        ThoughtStoryManager.instance.setStory(result);
      }
    }
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
            Icons.person_add_alt_1_outlined,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () {},
        ),
        centerTitle: true,
        title: const Text(
          'Inbox',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 26,
            ),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SearchScreen()));
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.white,
        backgroundColor: const Color(0xFF1E1E22),
        onRefresh: _loadMessages,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            // 1. Stories / Memories Horizontal Row
            SizedBox(
              height: 124,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: StaticInboxData.stories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final story = StaticInboxData.stories[index];
                  return _buildStoryCircle(context, story);
                },
              ),
            ),

            const SizedBox(height: 8),

            // 2. Real notification activity
            ValueListenableBuilder<List<NotificationItem>>(
              valueListenable:
                  NotificationManager.instance.notificationsNotifier,
              builder: (context, notifications, _) {
                if (notifications.isEmpty) return const SizedBox.shrink();
                return Column(
                  children: notifications
                      .map(
                        (notification) => _buildNotificationTile(notification),
                      )
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 20),

            // 3. "MESSAGES" Section Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'MESSAGES',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8E8E93),
                  letterSpacing: 1.2,
                ),
              ),
            ),

            // 4. Direct Messages Thread List (Dynamically synced via InboxMessageManager)
            ValueListenableBuilder<List<DirectMessageThread>>(
              valueListenable: InboxMessageManager.instance.threadsNotifier,
              builder: (context, threads, _) {
                if (threads.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 38,
                            color: Color(0xFF4A4A52),
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No messages yet',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final thread in threads)
                      _buildMessageThreadTile(context, thread),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCircle(BuildContext context, StoryItem story) {
    if (story.isCreate) {
      return ValueListenableBuilder<SharedThoughtStory?>(
        valueListenable: ThoughtStoryManager.instance.storyNotifier,
        builder: (context, myStory, _) {
          final isStoryActive = myStory != null;
          final messageText = isStoryActive
              ? myStory.message
              : 'Share a thought...';
          final hasMusic = isStoryActive && myStory.musicTrack != null;

          // "Create / Active Story" Bubble with Floating Thought Box & Music Wave
          return GestureDetector(
            onTap: _handleCreateOrViewStory,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Floating Thought Message Box (with animated music wave if attached)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3.5,
                  ),
                  constraints: const BoxConstraints(maxWidth: 95),
                  decoration: BoxDecoration(
                    color: isStoryActive
                        ? const Color(0xFF222228)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: isStoryActive
                        ? Border.all(color: const Color(0xFF383842), width: 1.0)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          messageText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isStoryActive
                                ? Colors.white
                                : const Color(0xFF141416),
                          ),
                        ),
                      ),
                      if (hasMusic) ...[
                        const SizedBox(width: 4),
                        const AnimatedMiniMusicWave(),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Cloud Avatar with Story Ring (if active) or Plus Badge
                SizedBox(
                  width: 58,
                  height: 58,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        padding: isStoryActive
                            ? const EdgeInsets.all(2.5)
                            : EdgeInsets.zero,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isStoryActive
                              ? const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFE2C55),
                                    Color(0xFFFF9F43),
                                    Color(0xFF9B51E0),
                                    Color(0xFF2F80ED),
                                  ],
                                )
                              : const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF56CCF2),
                                    Color(0xFF2F80ED),
                                  ],
                                ),
                          border: isStoryActive
                              ? null
                              : Border.all(
                                  color: const Color(0xFF2F80ED),
                                  width: 2.0,
                                ),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.cloud_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                      if (!isStoryActive)
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2F80ED),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: 2.0,
                              ),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isStoryActive ? 'Your story' : story.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Spacer to align avatars with the create item
        const SizedBox(height: 23),
        Container(
          width: 58,
          height: 58,
          padding: const EdgeInsets.all(2.5),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF56CCF2), Color(0xFF2F80ED), Color(0xFF9B51E0)],
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
            padding: const EdgeInsets.all(2.0),
            child: ClipOval(
              child: Image.network(
                story.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surface,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          story.title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTile(NotificationItem item) {
    Widget leadingIcon;
    if (item.iconType == 'activity') {
      leadingIcon = Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Color(0xFFFE2C55),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.favorite_rounded,
          color: Colors.white,
          size: 26,
        ),
      );
    } else if (item.iconType == 'comment') {
      leadingIcon = Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Color(0xFF2F80ED),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.comment_rounded, color: Colors.white, size: 26),
      );
    } else if (item.iconType == 'followers') {
      leadingIcon = Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Color(0xFF333336),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
      );
    } else {
      leadingIcon = Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Color(0xFF333336),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.notifications_none_rounded,
          color: Colors.white,
          size: 26,
        ),
      );
    }

    return Material(
      color: item.isRead ? Colors.transparent : const Color(0xFF111116),
      child: InkWell(
        onTap: () => _openNotification(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              leadingIcon,
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),
              if (item.hasDot)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2F80ED),
                    shape: BoxShape.circle,
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF2F80ED),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageThreadTile(
    BuildContext context,
    DirectMessageThread thread,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => ChatDetailScreen(thread: thread)),
          );
        },
        splashColor: Colors.white.withValues(alpha: 0.05),
        highlightColor: Colors.white.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Avatar
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  final cleanHandle = thread.username
                      .replaceAll('@', '')
                      .trim();
                  if (cleanHandle.isEmpty) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PublicProfileScreen(
                        username: thread.username,
                        displayName: thread.username,
                        avatarUrl: thread.avatarUrl,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1.0,
                    ),
                  ),
                  child: ClipOval(child: _buildAvatarImage(thread.avatarUrl)),
                ),
              ),
              const SizedBox(width: 14),

              // Username & Last Message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          thread.username,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (thread.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF2F80ED),
                            size: 15,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      thread.timeAgo.isNotEmpty
                          ? '${thread.lastMessage} • ${thread.timeAgo}'
                          : thread.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),

              // Right Camera Action Icon
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                color: const Color(0xFF2A2A2E),
                onSelected: (value) {
                  if (value == 'delete') _deleteConversationForMe(thread);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      'Delete conversation for me',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage(String url) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.surface,
          child: const Icon(Icons.storefront_rounded, color: Colors.white),
        ),
      );
    }
    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.surface,
          child: const Icon(Icons.person, color: Colors.white),
        ),
      );
    }
    return Container(
      color: const Color(0xFF2F80ED),
      child: const Icon(Icons.storefront_rounded, color: Colors.white),
    );
  }
}
