import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/datasources/token_storage.dart';
import '../../../profile/presentation/pages/people_screen.dart';
import '../../../search_discover/presentation/pages/search_screen.dart';
import '../../data/datasources/chat_manager.dart';
import '../../data/datasources/static_inbox_data.dart';
import '../../data/datasources/thought_story_manager.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/datasources/chat_stomp_service.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import '../../data/datasources/story_remote_data_source.dart';
import '../../domain/entities/inbox_item.dart';
import '../../domain/entities/music_track.dart';
import '../../domain/entities/shared_thought_story.dart';
import '../widgets/animated_mini_music_wave.dart';
import 'chat_detail_screen.dart';
import 'share_thought_screen.dart';
import 'story_viewer_screen.dart';
import 'upload_story_screen.dart';
import 'activity_screen.dart';
import 'new_followers_screen.dart';
import 'system_notifications_screen.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../../feed/presentation/pages/video_feed_page.dart';
import '../widgets/story_viewers_bottom_sheet.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  late List<StoryItem> _stories;
  late List<NotificationItem> _notifications;
  late List<DirectMessageThread> _threads;
  String _messageFilter = 'all'; // 'all' or 'friends'

  @override
  void initState() {
    super.initState();
    final isDemo = TokenStorage.instance.isDemoUserSync;
    _stories = isDemo
        ? List.from(StaticInboxData.stories)
        : const [
            StoryItem(
              id: 'create_story',
              title: 'Share a thought...',
              imageUrl: '',
              isCreate: true,
            ),
          ];
    _notifications = isDemo ? List.from(StaticInboxData.notifications) : const [];
    _threads = isDemo ? List.from(StaticInboxData.threads) : List.from(ChatManager.instance.threads);
    _loadAllData();
    ChatStompService.instance.connect();
  }

  Future<void> _loadAllData() async {
    try {
      final stories = await StoryRemoteDataSource.instance.getActiveStories();
      final notifications = await NotificationRemoteDataSource.instance.getNotifications();
      final threads = await ChatRemoteDataSource.instance.getConversations();

      if (mounted) {
        setState(() {
          _stories = List.from(stories);
          _notifications = List.from(notifications);
          _threads = List.from(threads);
        });
        ChatManager.instance.init(threads);
      }
    } catch (_) {}
  }

  List<StoryViewerItem> _buildStoryViewerList() {
    final List<StoryViewerItem> items = [];

    final myStory = ThoughtStoryManager.instance.currentStory;
    if (myStory != null) {
      items.add(
        StoryViewerItem(
          story: myStory,
          isOwner: true,
          authorName: 'Your Story',
        ),
      );
    }

    for (final s in _stories) {
      if (s.isCreate) continue;
      if (s.isMyStory) {
        if (myStory == null) {
          final myBackendStory = SharedThoughtStory(
            id: s.id,
            message: s.message ?? '',
            mediaUrl: s.mediaUrl,
            mediaType: s.mediaType,
            privacy: s.privacy,
            timestamp: s.timestamp ?? 'Just now',
            viewCount: s.viewCount,
            authorUsername: s.authorUsername,
            authorName: s.title,
          );
          ThoughtStoryManager.instance.setStory(myBackendStory);
          items.insert(
            0,
            StoryViewerItem(
              story: myBackendStory,
              isOwner: true,
              authorName: 'Your Story',
              authorAvatarUrl: s.imageUrl,
            ),
          );
        }
        continue;
      }
      items.add(
        StoryViewerItem(
          story: SharedThoughtStory(
            id: s.id,
            message: s.message ?? "Living the moment ✨",
            mediaUrl: s.mediaUrl,
            mediaType: s.mediaType,
            privacy: s.privacy,
            musicTrack: s.musicTitle != null
                ? MusicTrack(
                    id: 'm_${s.id}',
                    title: s.musicTitle!,
                    artist: s.musicArtist ?? 'Unknown Artist',
                    albumArtUrl: s.imageUrl,
                    duration: '0:30',
                  )
                : null,
            timestamp: s.timestamp ?? '2h ago',
            viewCount: s.viewCount,
            backgroundColor: const Color(0xFF141416),
            authorUsername: s.authorUsername,
            authorName: s.title,
          ),
          isOwner: false,
          authorName: s.title,
          authorAvatarUrl: s.imageUrl,
        ),
      );
    }

    return items;
  }

  List<StoryItem> get _uniqueTrayStories {
    final List<StoryItem> tray = [];
    final Set<String> seenAuthors = {};

    for (final s in _stories) {
      if (s.isCreate) {
        tray.add(s);
        continue;
      }
      if (s.isMyStory) {
        continue;
      }
      final authorKey = (s.authorUsername != null && s.authorUsername!.isNotEmpty)
          ? s.authorUsername!.toLowerCase().trim()
          : s.title.toLowerCase().trim();

      if (!seenAuthors.contains(authorKey)) {
        seenAuthors.add(authorKey);
        tray.add(s);
      }
    }
    return tray;
  }

  void _openOtherUserStory(StoryItem story) {
    final authorKey = (story.authorUsername != null && story.authorUsername!.isNotEmpty)
        ? story.authorUsername!.toLowerCase().trim()
        : story.title.toLowerCase().trim();

    // Group all stories belonging to this specific user so they can be viewed in 1 viewer
    final authorStories = _stories.where((s) {
      if (s.isCreate || s.isMyStory) return false;
      final k = (s.authorUsername != null && s.authorUsername!.isNotEmpty)
          ? s.authorUsername!.toLowerCase().trim()
          : s.title.toLowerCase().trim();
      return k == authorKey;
    }).toList();

    if (authorStories.isEmpty) {
      authorStories.add(story);
    }

    final items = authorStories.map((s) => StoryViewerItem(
      story: SharedThoughtStory(
        id: s.id,
        message: s.message ?? "Living the moment ✨",
        mediaUrl: s.mediaUrl,
        mediaType: (s.mediaType.isNotEmpty && s.mediaType != 'TEXT')
            ? s.mediaType
            : ((s.mediaUrl != null &&
                    (s.mediaUrl!.toLowerCase().endsWith('.mp4') ||
                        s.mediaUrl!.toLowerCase().endsWith('.mov')))
                ? 'VIDEO'
                : (s.mediaUrl != null && s.mediaUrl!.isNotEmpty ? 'IMAGE' : 'TEXT')),
        privacy: s.privacy,
        musicTrack: s.musicTitle != null
            ? MusicTrack(
                id: 'm_${s.id}',
                title: s.musicTitle!,
                artist: s.musicArtist ?? 'Unknown Artist',
                albumArtUrl: s.imageUrl,
                duration: '0:30',
              )
            : null,
        timestamp: s.timestamp ?? 'Recently',
        viewCount: s.viewCount,
        backgroundColor: const Color(0xFF141416),
        authorUsername: s.authorUsername,
        authorName: s.title,
      ),
      isOwner: false,
      authorName: s.title,
      authorAvatarUrl: s.imageUrl,
    )).toList();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => StoryViewerScreen(
          stories: items,
          initialIndex: 0,
        ),
      ),
    );
  }

  List<DirectMessageThread> _deduplicateThreads(List<DirectMessageThread> threads) {
    final List<DirectMessageThread> result = [];
    for (final t in threads) {
      final existingIdx = result.indexWhere((it) {
        if (it.userId != null && t.userId != null && it.userId! > 0 && t.userId! > 0) {
          if (it.userId == t.userId) return true;
        }
        if (it.id.isNotEmpty && t.id.isNotEmpty && it.id == t.id) return true;
        final uA = it.username.replaceAll('@', '').toLowerCase().trim();
        final uB = t.username.replaceAll('@', '').toLowerCase().trim();
        return uA.isNotEmpty && uB.isNotEmpty && uA == uB;
      });

      if (existingIdx == -1) {
        result.add(t);
      } else {
        final existing = result[existingIdx];
        final combined = List<ChatMessage>.from(existing.messages);
        for (final m in t.messages) {
          if (!combined.any((cm) => cm.id == m.id || (cm.text == m.text && cm.timestamp == m.timestamp))) {
            combined.add(m);
          }
        }
        result[existingIdx] = existing.copyWith(
          lastMessage: t.lastMessage.isNotEmpty ? t.lastMessage : existing.lastMessage,
          timeAgo: (t.timeAgo.isNotEmpty && t.timeAgo != 'Just now') ? t.timeAgo : existing.timeAgo,
          messages: combined,
        );
      }
    }
    return result;
  }

  Future<void> _openNotificationHub(NotificationItem item) async {
    setState(() {
      final idx = _notifications.indexWhere((n) => n.id == item.id);
      if (idx != -1) {
        _notifications[idx] = NotificationItem(
          id: item.id,
          title: item.title,
          subtitle: item.subtitle,
          iconType: item.iconType,
          type: item.type,
          entityId: item.entityId,
          entityType: item.entityType,
          actorId: item.actorId,
          actorUsername: item.actorUsername,
          actorDisplayName: item.actorDisplayName,
          actorAvatarUrl: item.actorAvatarUrl,
          timeAgo: item.timeAgo,
          badgeCount: null,
          hasDot: false,
        );
      }
    });

    NotificationRemoteDataSource.instance.markAsRead(item.id);

    final titleLower = item.title.toLowerCase();
    final subLower = item.subtitle.toLowerCase();
    final typeUpper = item.type.toUpperCase();

    // 1. Direct Message notification -> Open chat with sender
    final isMessage = typeUpper == 'MESSAGE' ||
        item.iconType == 'message' ||
        titleLower.contains('message') ||
        subLower.contains('hi sak') ||
        subLower.contains('me liza');

    if (isMessage) {
      String targetUsername = item.actorUsername ?? '';
      if (targetUsername.isEmpty) {
        if (titleLower.contains('from ')) {
          final idx = titleLower.indexOf('from ');
          targetUsername = item.title.substring(idx + 5).trim();
        } else if (subLower.contains('me ')) {
          final idx = subLower.indexOf('me ');
          targetUsername = item.subtitle.substring(idx + 3).trim();
        } else {
          targetUsername = 'User';
        }
      }

      final targetUid = item.actorId ?? (targetUsername.toLowerCase() == 'liza' ? 2 : (targetUsername.toLowerCase() == 'sak' ? 1 : 0));
      final thread = ChatManager.instance.getOrCreateThread(
        userId: targetUid,
        username: targetUsername,
        avatarUrl: item.actorAvatarUrl ?? (targetUsername.toLowerCase() == 'liza'
            ? 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&auto=format&fit=crop&q=80'
            : 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop&q=80'),
      );

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(thread: thread),
        ),
      );
      if (mounted) setState(() {});
      return;
    }

    // 2. Story View notification -> Open Story Viewer with viewers sheet or StoryViewersBottomSheet
    final isStoryView = typeUpper == 'STORY_VIEW' ||
        item.iconType == 'story_view' ||
        titleLower.contains('story view') ||
        subLower.contains('viewed your') ||
        subLower.contains('24h thought');

    if (isStoryView) {
      final currentStory = ThoughtStoryManager.instance.currentStory;
      final items = _buildStoryViewerList();
      if (items.isNotEmpty && items.first.isOwner) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StoryViewerScreen(
              stories: items,
              initialIndex: 0,
              story: currentStory,
              openViewersOnStart: true,
            ),
          ),
        );
      } else {
        await StoryViewersBottomSheet.show(
          context,
          storyId: item.entityId,
          viewCount: 1,
        );
      }
      if (mounted) setState(() {});
      return;
    }

    // 3. Follow notification -> Open PublicProfileScreen for specific follower, or NewFollowersScreen if general hub
    final isFollow = typeUpper == 'FOLLOW' ||
        item.iconType == 'followers' ||
        titleLower.contains('follower') ||
        subLower.contains('started following');

    if (isFollow) {
      String targetUsername = item.actorUsername ?? '';
      if (targetUsername.isEmpty && subLower.contains(' started following')) {
        targetUsername = item.subtitle.split(' started following').first.trim();
      }

      if (targetUsername.isNotEmpty && !targetUsername.contains('others')) {
        final targetUid = item.actorId ?? (targetUsername.toLowerCase() == 'liza' ? 2 : (targetUsername.toLowerCase() == 'sak' ? 1 : null));
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PublicProfileScreen(
              userId: targetUid,
              username: targetUsername,
            ),
          ),
        );
        if (mounted) setState(() {});
        return;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NewFollowersScreen()),
      );
      if (mounted) setState(() {});
      return;
    }

    // 4. Video Like, Comment, Mention -> VideoFeedPage
    if (typeUpper == 'COMMENT' || typeUpper == 'MENTION' || titleLower.contains('comment') || titleLower.contains('mention')) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoFeedPage(
            isActive: true,
            isStandalone: true,
            initialPage: 0,
            openCommentsOnStart: true,
            initialCommentReplyUser: item.actorUsername,
            initialCommentText: item.subtitle,
          ),
        ),
      );
      if (mounted) setState(() {});
      return;
    }

    // 5. Activity hub screen
    if (item.iconType == 'activity' || titleLower == 'activity') {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ActivityScreen()),
      );
      if (mounted) setState(() {});
      return;
    }

    // 6. Default: System Notifications
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SystemNotificationsScreen()),
    );
    if (mounted) setState(() {});
  }

  Future<void> _openUploadStory() async {
    final result = await Navigator.of(context).push<SharedThoughtStory>(
      MaterialPageRoute(
        builder: (_) => const UploadStoryScreen(),
      ),
    );

    if (result != null && mounted) {
      ThoughtStoryManager.instance.setStory(result);
      _loadAllData();
    }
  }

  Future<void> _openNoteStory() async {
    final result = await Navigator.of(context).push<SharedThoughtStory>(
      MaterialPageRoute(
        builder: (_) => const ShareThoughtScreen(),
      ),
    );

    if (result != null && mounted) {
      ThoughtStoryManager.instance.setStory(result);
      _loadAllData();
    }
  }

  Future<void> _handleCreateOrViewStory() async {
    final currentStory = ThoughtStoryManager.instance.currentStory;
    if (currentStory != null) {
      final items = _buildStoryViewerList();
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => StoryViewerScreen(
            stories: items,
            initialIndex: 0,
            story: currentStory,
          ),
        ),
      );

      if (result == 'delete' && mounted) {
        ThoughtStoryManager.instance.deleteStory();
        _loadAllData();
      }
    } else {
      _openUploadStory();
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
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PeopleScreen()),
            );
          },
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
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SearchScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        color: const Color(0xFF2F80ED),
        backgroundColor: const Color(0xFF161618),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.only(bottom: 110),
          children: [
            // 1. Stories / Memories Horizontal Row
            SizedBox(
              height: 124,
              child: Builder(
                builder: (context) {
                  final trayStories = _uniqueTrayStories;
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: trayStories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final story = trayStories[index];
                      return _buildStoryCircle(context, story);
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // 2. Notification Hub Items
            ...List.generate(_notifications.length, (index) {
              final notification = _notifications[index];
              return _buildNotificationTile(notification);
            }),

            const SizedBox(height: 20),

            // 3. "MESSAGES" Section Header & Quick Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'MESSAGES',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8E8E93),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  // Filter Chips: All vs Friends
                  InkWell(
                    key: const Key('inbox_filter_all'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _messageFilter = 'all'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _messageFilter == 'all'
                            ? const Color(0xFF2F80ED)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'All',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: _messageFilter == 'all' ? FontWeight.w700 : FontWeight.w500,
                          color: _messageFilter == 'all' ? Colors.white : const Color(0xFF8E8E93),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    key: const Key('inbox_filter_friends'),
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _messageFilter = 'friends'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _messageFilter == 'friends'
                            ? const Color(0xFF2F80ED)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people_alt_rounded, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Friends',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: _messageFilter == 'friends' ? FontWeight.w700 : FontWeight.w500,
                              color: _messageFilter == 'friends' ? Colors.white : const Color(0xFF8E8E93),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 4. Direct Messages Thread List
            ValueListenableBuilder<List<DirectMessageThread>>(
              valueListenable: ChatManager.instance.threadsNotifier,
              builder: (context, activeThreads, _) {
                final isDemo = TokenStorage.instance.isDemoUserSync;
                final sourceThreads = activeThreads.isNotEmpty
                    ? activeThreads
                    : (_threads.isNotEmpty ? _threads : (isDemo ? StaticInboxData.threads : const <DirectMessageThread>[]));
                final filteredThreads = _messageFilter == 'friends'
                    ? sourceThreads.where((t) => t.isFriend).toList()
                    : sourceThreads;
                final displayThreads = _deduplicateThreads(filteredThreads);

                if (displayThreads.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Color(0xFF8E8E93),
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _messageFilter == 'friends'
                              ? 'No mutual friends with messages yet'
                              : 'No direct messages yet',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _messageFilter == 'friends'
                              ? 'Follow back accounts that follow you to chat with friends.'
                              : 'Search and follow users to start chatting.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: List.generate(displayThreads.length, (index) {
                    final thread = displayThreads[index];
                    return _buildMessageThreadTile(context, thread);
                  }),
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
          final messageText = isStoryActive ? myStory.message : 'Share a thought...';
          final hasMusic = isStoryActive && myStory.musicTrack != null;

          // Separate handlers: Note box opens note story; + badge opens photo/video upload; avatar views active story
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Floating Thought Message Box (tap opens Note story with note and song)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openNoteStory,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  constraints: const BoxConstraints(maxWidth: 105),
                  decoration: BoxDecoration(
                    color: isStoryActive ? const Color(0xFF222228) : Colors.white,
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
                            color: isStoryActive ? Colors.white : const Color(0xFF141416),
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
              ),
              const SizedBox(height: 4),

              // 2. Avatar with Story Ring (if active) and Plus Badge
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Avatar Circle (tap views active story if active, or opens upload if not)
                    Align(
                      alignment: Alignment.center,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: isStoryActive ? _handleCreateOrViewStory : _openUploadStory,
                        child: Container(
                          width: 56,
                          height: 56,
                          padding: isStoryActive ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
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
                                    colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
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
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Plus Badge: Clicking + opens Photo/Video Upload Story with reliable hit test
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _openUploadStory,
                        child: Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                          ),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2F80ED),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2.0),
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: isStoryActive ? _handleCreateOrViewStory : _openUploadStory,
                child: Text(
                  isStoryActive ? 'Your story' : story.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return GestureDetector(
      onTap: () => _openOtherUserStory(story),
      child: Column(
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
      ),
    );
  }

  Widget _buildNotificationTile(NotificationItem item) {
    final titleLower = item.title.toLowerCase();
    final subLower = item.subtitle.toLowerCase();
    final typeUpper = item.type.toUpperCase();

    final isMessage = typeUpper == 'MESSAGE' ||
        item.iconType == 'message' ||
        titleLower.contains('message') ||
        subLower.contains('hi sak') ||
        subLower.contains('me liza');

    final isStoryView = typeUpper == 'STORY_VIEW' ||
        item.iconType == 'story_view' ||
        titleLower.contains('story view') ||
        subLower.contains('viewed your') ||
        subLower.contains('24h thought');

    final isFollow = typeUpper == 'FOLLOW' ||
        item.iconType == 'followers' ||
        titleLower.contains('follower') ||
        subLower.contains('started following');

    final isComment = typeUpper == 'COMMENT' || titleLower.contains('comment') || subLower.contains('comment');
    final isLike = typeUpper == 'LIKE' || (!isMessage && !isStoryView && !isFollow && !isComment && (item.iconType == 'activity' || titleLower.contains('liked')));

    Widget leadingIcon;
    if (item.actorAvatarUrl != null && item.actorAvatarUrl!.isNotEmpty && (isMessage || isStoryView || isFollow)) {
      Widget miniBadge;
      if (isMessage) {
        miniBadge = Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(color: Color(0xFF2F80ED), shape: BoxShape.circle),
          child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 10),
        );
      } else if (isStoryView) {
        miniBadge = Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFFE2C55), Color(0xFF2F80ED)]),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.visibility_rounded, color: Colors.white, size: 10),
        );
      } else {
        miniBadge = Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(color: Color(0xFFFE2C55), shape: BoxShape.circle),
          child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 10),
        );
      }

      leadingIcon = Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFF2C2C32),
            child: ClipOval(
              child: Image.network(
                item.actorAvatarUrl!,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white38, size: 26),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: miniBadge,
          ),
        ],
      );
    } else if (isMessage) {
      leadingIcon = Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Color(0xFF2F80ED),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.chat_bubble_rounded,
          color: Colors.white,
          size: 24,
        ),
      );
    } else if (isStoryView) {
      leadingIcon = Container(
        width: 52,
        height: 52,
        padding: const EdgeInsets.all(2.5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFE2C55), Color(0xFFFF9F43), Color(0xFF2F80ED)],
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF161618),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.visibility_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      );
    } else if (isFollow) {
      leadingIcon = Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Color(0xFF333336),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person_add_rounded,
          color: Colors.white,
          size: 26,
        ),
      );
    } else if (isLike) {
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
    } else if (isComment) {
      leadingIcon = Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Color(0xFF2F80ED),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.comment_rounded,
          color: Colors.white,
          size: 24,
        ),
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
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openNotificationHub(item),
        splashColor: Colors.white.withValues(alpha: 0.05),
        highlightColor: Colors.white.withValues(alpha: 0.03),
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
              if (item.badgeCount != null)
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2F80ED),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      item.badgeCount.toString(),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else if (item.hasDot)
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

  Widget _buildMessageThreadTile(BuildContext context, DirectMessageThread thread) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatDetailScreen(thread: thread),
            ),
          );
        },
        splashColor: Colors.white.withValues(alpha: 0.05),
        highlightColor: Colors.white.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    thread.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
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
                        Flexible(
                          child: Text(
                            thread.username,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
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
                        if (thread.isFriend) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0x262F80ED),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0x4D2F80ED)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.people_alt_rounded, size: 10, color: Color(0xFF38BDF8)),
                                SizedBox(width: 3),
                                Text(
                                  'Friends',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF38BDF8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (thread.isFollowing) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0x1AFFFFFF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Following',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFA1A1AA),
                              ),
                            ),
                          ),
                        ] else if (thread.followsYou) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0x263B82F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Follows you',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF60A5FA),
                              ),
                            ),
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
}
