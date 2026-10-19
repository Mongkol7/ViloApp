import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/data/datasources/token_storage.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import '../../../feed/presentation/pages/video_feed_page.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../data/datasources/chat_manager.dart';
import '../../data/datasources/thought_story_manager.dart';
import 'chat_detail_screen.dart';
import 'story_viewer_screen.dart';
import '../widgets/story_viewers_bottom_sheet.dart';

enum ActivityFilter { all, likes, comments, mentions }

class ActivityModel {
  final String id;
  final String userName;
  final String userHandle;
  final String userAvatarUrl;
  final String type; // 'like', 'comment', 'mention', 'message', 'story_view', 'follow'
  final String text;
  final String timeAgo;
  final String mediaThumbnailUrl;
  final int videoIndex;
  final String? commentContent;
  final int? actorId;
  final String? actorUsername;
  final String? entityId;
  bool isRead;

  ActivityModel({
    required this.id,
    required this.userName,
    required this.userHandle,
    required this.userAvatarUrl,
    required this.type,
    required this.text,
    required this.timeAgo,
    required this.mediaThumbnailUrl,
    this.videoIndex = 0,
    this.commentContent,
    this.actorId,
    this.actorUsername,
    this.entityId,
    this.isRead = false,
  });
}

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  ActivityFilter _currentFilter = ActivityFilter.all;
  late List<ActivityModel> _activities;

  static final List<ActivityModel> _demoActivities = [
    ActivityModel(
      id: 'a1',
      userName: 'Junta',
      userHandle: 'junta_art',
      userAvatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
      type: 'like',
      text: 'liked your photos.',
      timeAgo: '5m ago',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=150&auto=format&fit=crop&q=80',
      videoIndex: 0,
      isRead: false,
    ),
    ActivityModel(
      id: 'a2',
      userName: 'Sarah Jenkins',
      userHandle: 'sarah_j',
      userAvatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&auto=format&fit=crop&q=80',
      type: 'comment',
      text: 'commented: "This aesthetic is unmatched 🔥"',
      timeAgo: '25m ago',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=150&auto=format&fit=crop&q=80',
      videoIndex: 1,
      commentContent: 'This aesthetic is unmatched 🔥',
      isRead: false,
    ),
    ActivityModel(
      id: 'a3',
      userName: 'Alex Chen',
      userHandle: 'alexchen_v',
      userAvatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
      type: 'mention',
      text: 'mentioned you in a comment: "@you check this out!"',
      timeAgo: '2h ago',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=150&auto=format&fit=crop&q=80',
      videoIndex: 2,
      commentContent: '@you check this out!',
      isRead: true,
    ),
    ActivityModel(
      id: 'a4',
      userName: 'Elena Rostova',
      userHandle: 'elena_r',
      userAvatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
      type: 'like',
      text: 'and 3 others liked your video.',
      timeAgo: '6h ago',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=150&auto=format&fit=crop&q=80',
      videoIndex: 3,
      isRead: true,
    ),
    ActivityModel(
      id: 'a5',
      userName: 'Liam Vance',
      userHandle: 'liam_vance',
      userAvatarUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150&auto=format&fit=crop&q=80',
      type: 'comment',
      text: 'commented: "Where was this taken? Incredible shot!"',
      timeAgo: '1d ago',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=150&auto=format&fit=crop&q=80',
      videoIndex: 4,
      commentContent: 'Where was this taken? Incredible shot!',
      isRead: true,
    ),
    ActivityModel(
      id: 'a6',
      userName: 'Tin',
      userHandle: 'tin_99',
      userAvatarUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=150&auto=format&fit=crop&q=80',
      type: 'like',
      text: 'liked your video.',
      timeAgo: '1d ago',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=150&auto=format&fit=crop&q=80',
      videoIndex: 5,
      isRead: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final isDemo = TokenStorage.instance.isDemoUserSync;
    _activities = isDemo ? List.from(_demoActivities) : [];
    _loadRealActivities();
  }

  Future<void> _loadRealActivities() async {
    try {
      final notifications = await NotificationRemoteDataSource.instance.getNotifications();
      final isDemo = TokenStorage.instance.isDemoUserSync;
      if (!isDemo && mounted) {
        setState(() {
          _activities = notifications.map((n) {
            final lowerTitle = n.title.toLowerCase();
            final lowerBody = n.subtitle.toLowerCase();
            final typeUpper = n.type.toUpperCase();

            String type = 'like';
            if (typeUpper == 'MESSAGE' || n.iconType == 'message' || lowerTitle.contains('message') || lowerBody.contains('hi sak') || lowerBody.contains('me liza')) {
              type = 'message';
            } else if (typeUpper == 'STORY_VIEW' || n.iconType == 'story_view' || lowerTitle.contains('story view') || lowerBody.contains('thought') || lowerBody.contains('viewed your')) {
              type = 'story_view';
            } else if (typeUpper == 'FOLLOW' || n.iconType == 'followers' || lowerTitle.contains('follower') || lowerBody.contains('started following')) {
              type = 'follow';
            } else if (typeUpper == 'COMMENT' || lowerTitle.contains('comment') || lowerBody.contains('comment')) {
              type = 'comment';
            } else if (typeUpper == 'MENTION' || lowerTitle.contains('mention') || lowerBody.contains('mention')) {
              type = 'mention';
            }

            // Clean display name and text
            String userName = n.actorDisplayName ?? n.actorUsername ?? n.title;
            String text = n.subtitle;
            if (type == 'message') {
              if (lowerTitle.contains('from ')) {
                final idx = lowerTitle.indexOf('from ');
                userName = n.title.substring(idx + 5).trim();
              }
              text = 'sent you a message: "${n.subtitle}"';
            } else if (type == 'story_view') {
              if (lowerBody.contains('viewed your')) {
                userName = n.subtitle.split(' viewed').first.trim();
              }
              text = 'viewed your 24h thought';
            } else if (type == 'follow') {
              if (lowerBody.contains('started following')) {
                userName = n.subtitle.split(' started').first.trim();
              }
              text = 'started following you';
            }

            return ActivityModel(
              id: n.id,
              userName: userName,
              userHandle: n.actorUsername ?? userName.toLowerCase().replaceAll(' ', '_'),
              userAvatarUrl: n.actorAvatarUrl ?? (userName.toLowerCase() == 'liza'
                  ? 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=500&auto=format&fit=crop&q=80'
                  : 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop&q=80'),
              type: type,
              text: text,
              timeAgo: n.timeAgo ?? 'Recently',
              mediaThumbnailUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=150',
              videoIndex: 0,
              isRead: !n.hasDot,
              actorId: n.actorId,
              actorUsername: n.actorUsername ?? (userName.isNotEmpty ? userName : null),
              entityId: n.entityId,
            );
          }).toList();
        });
      }
    } catch (_) {}
  }

  void _handleActivityTap(ActivityModel activity) {
    setState(() => activity.isRead = true);
    NotificationRemoteDataSource.instance.markAsRead(activity.id);

    if (activity.type == 'message') {
      final targetUsername = activity.actorUsername ?? activity.userName;
      final targetUid = activity.actorId ?? (targetUsername.toLowerCase() == 'liza' ? 2 : (targetUsername.toLowerCase() == 'sak' ? 1 : 0));
      final thread = ChatManager.instance.getOrCreateThread(
        userId: targetUid,
        username: targetUsername,
        avatarUrl: activity.userAvatarUrl,
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(thread: thread),
        ),
      );
      return;
    }

    if (activity.type == 'story_view') {
      final currentStory = ThoughtStoryManager.instance.currentStory;
      if (currentStory != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => StoryViewerScreen(
              story: currentStory,
              openViewersOnStart: true,
            ),
          ),
        );
      } else {
        StoryViewersBottomSheet.show(
          context,
          storyId: activity.entityId,
          viewCount: 1,
        );
      }
      return;
    }

    if (activity.type == 'follow') {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PublicProfileScreen(
            userId: activity.actorId,
            username: activity.actorUsername ?? activity.userName,
          ),
        ),
      );
      return;
    }

    _navigateToVideo(activity);
  }

  List<ActivityModel> get _filteredActivities {
    switch (_currentFilter) {
      case ActivityFilter.likes:
        return _activities.where((a) => a.type == 'like').toList();
      case ActivityFilter.comments:
        return _activities.where((a) => a.type == 'comment').toList();
      case ActivityFilter.mentions:
        return _activities.where((a) => a.type == 'mention').toList();
      case ActivityFilter.all:
        return _activities;
    }
  }

  void _markAllAsRead() {
    setState(() {
      for (final a in _activities) {
        a.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All activity marked as read'),
        backgroundColor: Color(0xFF2F80ED),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Directs user straight to the video that was commented on or liked.
  void _navigateToVideo(ActivityModel activity, {bool openComments = false}) {
    setState(() => activity.isRead = true);

    final shouldOpenComments =
        openComments || activity.type == 'comment' || activity.type == 'mention';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoFeedPage(
          isActive: true,
          isStandalone: true,
          initialPage: activity.videoIndex,
          openCommentsOnStart: shouldOpenComments,
          initialCommentReplyUser: activity.userName,
          initialCommentText: activity.commentContent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredActivities;

    return Scaffold(
      backgroundColor: AppColors.voidBackground,
      appBar: AppBar(
        backgroundColor: AppColors.voidBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(true),
        ),
        title: const Text(
          'Activity',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'Read all',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2F80ED),
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('All', ActivityFilter.all),
                const SizedBox(width: 8),
                _buildFilterChip('Likes ❤️', ActivityFilter.likes),
                const SizedBox(width: 8),
                _buildFilterChip('Comments 💬', ActivityFilter.comments),
                const SizedBox(width: 8),
                _buildFilterChip('Mentions 🏷️', ActivityFilter.mentions),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Activities List
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text(
                      'No activities in this category',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF8E8E93),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const Divider(
                      color: Color(0xFF222226),
                      height: 1,
                      indent: 72,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final item = list[index];

                      Widget badgeIcon;
                      if (item.type == 'like') {
                        badgeIcon = Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFE2C55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 10),
                        );
                      } else if (item.type == 'comment') {
                        badgeIcon = Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2F80ED),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 10),
                        );
                      } else if (item.type == 'message') {
                        badgeIcon = Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2F80ED),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mail_rounded, color: Colors.white, size: 10),
                        );
                      } else if (item.type == 'story_view') {
                        badgeIcon = Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [Color(0xFFFE2C55), Color(0xFF2F80ED)]),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.visibility_rounded, color: Colors.white, size: 10),
                        );
                      } else if (item.type == 'follow') {
                        badgeIcon = Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFE2C55),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 10),
                        );
                      } else {
                        badgeIcon = Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFF9B51E0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.alternate_email_rounded, color: Colors.white, size: 10),
                        );
                      }

                      Widget trailingWidget;
                      if (item.type == 'message') {
                        trailingWidget = GestureDetector(
                          onTap: () => _handleActivityTap(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2F80ED),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Chat',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      } else if (item.type == 'story_view') {
                        trailingWidget = GestureDetector(
                          onTap: () => _handleActivityTap(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFE2C55), Color(0xFF2F80ED)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Text(
                              'Story',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      } else if (item.type == 'follow') {
                        trailingWidget = GestureDetector(
                          onTap: () => _handleActivityTap(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2A2A30),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF383842), width: 1),
                            ),
                            child: const Text(
                              'Profile',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      } else {
                        trailingWidget = GestureDetector(
                          onTap: () => _navigateToVideo(item),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0xFF2A2A30),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.network(
                                    item.mediaThumbnailUrl,
                                    width: 48,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: const Color(0xFF2A2A30),
                                      child: const Icon(Icons.videocam_rounded,
                                          color: Colors.white24, size: 22),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return InkWell(
                        onTap: () => _handleActivityTap(item),
                        splashColor: Colors.white.withValues(alpha: 0.05),
                        child: Container(
                          color: item.isRead
                              ? Colors.transparent
                              : const Color(0xFF2F80ED).withValues(alpha: 0.04),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Avatar with type badge
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: const Color(0xFF2C2C32),
                                    child: ClipOval(
                                      child: Image.network(
                                        item.userAvatarUrl,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: const Color(0xFF2C2C32),
                                          child: const Icon(Icons.person,
                                              color: Colors.white38, size: 22),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: -2,
                                    bottom: -2,
                                    child: badgeIcon,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text.rich(
                                      TextSpan(
                                        text: item.userName,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                        children: [
                                          const TextSpan(text: ' '),
                                          TextSpan(
                                            text: item.text,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xFFD1D1D6),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Text(
                                          item.timeAgo,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: Color(0xFF8E8E93),
                                          ),
                                        ),
                                        if (item.type == 'comment' || item.type == 'mention') ...[
                                          const SizedBox(width: 12),
                                          GestureDetector(
                                            onTap: () => _navigateToVideo(item, openComments: true),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.reply_rounded,
                                                  size: 13,
                                                  color: Color(0xFF2F80ED),
                                                ),
                                                SizedBox(width: 3),
                                                Text(
                                                  'Reply on video',
                                                  style: TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF2F80ED),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              trailingWidget,
                            ],
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

  Widget _buildFilterChip(String label, ActivityFilter filter) {
    final isSelected = _currentFilter == filter;
    return GestureDetector(
      onTap: () => setState(() => _currentFilter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2F80ED) : const Color(0xFF1E1E22),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2F80ED) : const Color(0xFF333338),
            width: 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF8E8E93),
          ),
        ),
      ),
    );
  }
}
