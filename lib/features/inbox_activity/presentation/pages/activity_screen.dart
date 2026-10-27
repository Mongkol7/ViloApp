import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import '../../domain/entities/inbox_item.dart';
import '../../../feed/presentation/pages/video_feed_page.dart';
import '../../../feed/presentation/widgets/video_likes_bottom_sheet.dart';
import '../../../feed/presentation/widgets/comment_bottom_sheet.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../../../auth/data/datasources/token_storage.dart';
import '../../data/datasources/static_inbox_data.dart';
import '../../../feed/data/datasources/feed_remote_data_source.dart';
import '../../data/datasources/chat_manager.dart';
import '../../data/datasources/thought_story_manager.dart';
import 'chat_detail_screen.dart';
import 'story_viewer_screen.dart';
import '../widgets/story_viewers_bottom_sheet.dart';
import 'new_followers_screen.dart';

enum ActivityFilter { all, likes, comments, mentions, followers }

class ActivityModel {
  final String id;
  final List<String> userNames;
  final List<String> userAvatarUrls;
  final int othersCount;
  final String actionText; // e.g. 'liked your comment.', 'liked your video.', 'commented: "..."'
  final String timeAgo; // e.g. '4h', '6h', '7h'
  final String mediaThumbnailUrl;
  final bool hasActiveStory;
  final String type; // 'like_comment', 'like_video', 'comment', 'mention', 'follow', 'message'
  final int videoIndex;
  final int? videoId;
  final String? commentContent;
  final int? actorId;
  final String? actorUsername;
  final String? entityId;
  bool isRead;

  ActivityModel({
    required this.id,
    required this.userNames,
    required this.userAvatarUrls,
    this.othersCount = 0,
    required this.actionText,
    required this.timeAgo,
    required this.mediaThumbnailUrl,
    this.hasActiveStory = false,
    required this.type,
    this.videoIndex = 0,
    this.videoId,
    this.commentContent,
    this.actorId,
    this.actorUsername,
    this.entityId,
    this.isRead = false,
  });

  String get userName => userNames.isNotEmpty ? userNames.first : 'Someone';
  String get userAvatarUrl => userAvatarUrls.isNotEmpty ? userAvatarUrls.first : '';
  String get text => actionText;
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
      id: 'mono_liza_like_video',
      userNames: ['Tren Mono', 'Set Kimliza'],
      userAvatarUrls: [
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
      ],
      othersCount: 0,
      hasActiveStory: true,
      actionText: 'liked your video.',
      timeAgo: '2m',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=200&auto=format&fit=crop&q=80',
      type: 'like_video',
      videoIndex: 0,
      videoId: 1,
      actorUsername: 'trenmono',
      actorId: 5,
    ),
    ActivityModel(
      id: 'liza_comment_video',
      userNames: ['Set Kimliza'],
      userAvatarUrls: [
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
      ],
      othersCount: 0,
      hasActiveStory: true,
      actionText: 'commented: "Mechanical keyboard sound is so satisfying ⌨️"',
      timeAgo: '2h',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=200&auto=format&fit=crop&q=80',
      type: 'comment',
      videoIndex: 0,
      videoId: 1,
      commentContent: 'Mechanical keyboard sound is so satisfying ⌨️',
      actorUsername: 'setkimliza',
      actorId: 2,
    ),
    ActivityModel(
      id: 'mono_comment_video',
      userNames: ['Tren Mono'],
      userAvatarUrls: [
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=80',
      ],
      othersCount: 0,
      hasActiveStory: true,
      actionText: 'commented: "That clutch play was insane 🎯"',
      timeAgo: '4h',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=200&auto=format&fit=crop&q=80',
      type: 'comment',
      videoIndex: 0,
      videoId: 1,
      commentContent: 'That clutch play was insane 🎯',
      actorUsername: 'trenmono',
      actorId: 5,
    ),
    ActivityModel(
      id: 's1_like_video',
      userNames: ['s1'],
      userAvatarUrls: [
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80',
      ],
      othersCount: 0,
      hasActiveStory: true,
      actionText: 'liked your video.',
      timeAgo: '7h',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=200&auto=format&fit=crop&q=80',
      type: 'like_video',
      videoIndex: 0,
      videoId: 1,
      actorUsername: 's1',
      actorId: 99,
    ),
    ActivityModel(
      id: 'c1',
      userNames: ['Spey juu🤪', 'Ly_xie★'],
      userAvatarUrls: [
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
      ],
      othersCount: 6,
      actionText: 'liked your comment.',
      timeAgo: '4h',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=200&auto=format&fit=crop&q=80',
      type: 'like_comment',
      commentContent: 'Clean desk aesthetic 🔥',
      videoIndex: 0,
      videoId: 1,
    ),
    ActivityModel(
      id: 'c2',
      userNames: ['Yes, and?', 'Chris diva'],
      userAvatarUrls: [
        'https://images.unsplash.com/photo-1566492031773-4f4e44671857?w=150&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
      ],
      othersCount: 0,
      actionText: 'liked your comment.',
      timeAgo: '6h',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=200&auto=format&fit=crop&q=80',
      type: 'like_comment',
      commentContent: 'That clutch play was insane 🎯',
      videoIndex: 1,
      videoId: 2,
    ),
    ActivityModel(
      id: 'c3',
      userNames: ['SISE'],
      userAvatarUrls: [
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=150&auto=format&fit=crop&q=80',
      ],
      othersCount: 0,
      hasActiveStory: true,
      actionText: 'liked your video.',
      timeAgo: '7h',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=200&auto=format&fit=crop&q=80',
      type: 'like_video',
      videoIndex: 2,
      videoId: 3,
    ),
    ActivityModel(
      id: 'c4',
      userNames: ['🕷'],
      userAvatarUrls: [
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=80',
      ],
      othersCount: 0,
      hasActiveStory: true,
      actionText: 'liked your comment.',
      timeAgo: '7h',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=200&auto=format&fit=crop&q=80',
      type: 'like_comment',
      commentContent: 'Mechanical keyboard sound is so satisfying ⌨️',
      videoIndex: 0,
      videoId: 1,
    ),
    ActivityModel(
      id: 'c5',
      userNames: ['Theyneverchange.', '><'],
      userAvatarUrls: [
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
      ],
      othersCount: 18,
      actionText: 'liked your comment.',
      timeAgo: '8h',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=200&auto=format&fit=crop&q=80',
      type: 'like_comment',
      commentContent: 'Facts right here 💯',
      videoIndex: 3,
      videoId: 4,
    ),
    ActivityModel(
      id: 'c6',
      userNames: ['thy❤️nha'],
      userAvatarUrls: [
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80',
      ],
      othersCount: 0,
      actionText: 'liked your comment.',
      timeAgo: '9h',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=200&auto=format&fit=crop&q=80',
      type: 'like_comment',
      commentContent: 'Legendary comeback!',
      videoIndex: 1,
      videoId: 2,
    ),
    ActivityModel(
      id: 'c7',
      userNames: ['Panhapor•|បញ្ញាពណ៌', 'PRO PLAYER'],
      userAvatarUrls: [
        'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=150&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150&auto=format&fit=crop&q=80',
      ],
      othersCount: 2,
      actionText: 'liked your comment.',
      timeAgo: '9h',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=200&auto=format&fit=crop&q=80',
      type: 'like_comment',
      commentContent: 'Fluid animation and 60fps feed 🚀',
      videoIndex: 0,
      videoId: 1,
    ),
    ActivityModel(
      id: 'c8',
      userNames: ['Niki bee 🐝', 'Berkki', 'GECH'],
      userAvatarUrls: [
        'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=150&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=80',
      ],
      othersCount: 0,
      actionText: 'liked your comment.',
      timeAgo: '10h',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=200&auto=format&fit=crop&q=80',
      type: 'like_comment',
      commentContent: 'Amazing workspace inspiration ✨',
      videoIndex: 4,
      videoId: 5,
    ),
    ActivityModel(
      id: 'c9',
      userNames: ['Arura💫', 'Smey Koko'],
      userAvatarUrls: [
        'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=150&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
      ],
      othersCount: 0,
      actionText: 'liked your comment.',
      timeAgo: '10h',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=200&auto=format&fit=crop&q=80',
      type: 'like_comment',
      commentContent: '10/10 quality and lighting!',
      videoIndex: 0,
      videoId: 1,
    ),
    ActivityModel(
      id: 'c10',
      userNames: ['=-'],
      userAvatarUrls: [
        'https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?w=150&auto=format&fit=crop&q=80',
      ],
      othersCount: 0,
      actionText: 'liked your comment.',
      timeAgo: '10h',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=200&auto=format&fit=crop&q=80',
      type: 'like_comment',
      commentContent: 'Clean build goals',
      videoIndex: 2,
      videoId: 3,
    ),
    ActivityModel(
      id: 'c11',
      userNames: ['Sunny Stormy', 'Mona', 'DiZz_1'],
      userAvatarUrls: [
        'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
      ],
      othersCount: 0,
      actionText: 'liked your comment.',
      timeAgo: '11h',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=200&auto=format&fit=crop&q=80',
      type: 'like_comment',
      commentContent: 'Top comment energy 🔥',
      videoIndex: 0,
      videoId: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _activities = List.from(_demoActivities);
    _loadRealActivities();
  }

  bool _userHasStory(String? username) {
    if (username == null || username.isEmpty) return false;
    final lower = username.toLowerCase().replaceAll('@', '').trim();
    if (lower == 's1' || lower == 'sise' || lower == 'kimliza' || lower == 'setkimliza') {
      return true;
    }
    final currentStory = ThoughtStoryManager.instance.currentStory;
    if (currentStory != null) {
      final myUser = (TokenStorage.instance.currentUsernameSync ?? '').toLowerCase().replaceAll('@', '').trim();
      if (lower == myUser) return true;
    }
    return StaticInboxData.stories.any((s) => s.title.toLowerCase().replaceAll('@', '').trim() == lower);
  }

  String _resolveVideoThumbnail(int? videoId) {
    if (videoId != null && videoId > 0) {
      for (final type in ['foryou', 'following', 'trending']) {
        final cached = FeedRemoteDataSource.instance.getCachedFeed(type);
        if (cached != null) {
          final found = cached.where((v) => v.id == videoId).firstOrNull;
          if (found != null && found.thumbnailUrl != null && found.thumbnailUrl!.trim().isNotEmpty) {
            return found.thumbnailUrl!.trim();
          }
        }
      }
      final thumbs = [
        'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=200&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=200&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1518770660439-4636190af475?w=200&auto=format&fit=crop&q=80',
        'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=200&auto=format&fit=crop&q=80',
      ];
      return thumbs[(videoId - 1).abs() % thumbs.length];
    }
    return 'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=200&auto=format&fit=crop&q=80';
  }

  Future<void> _loadRealActivities() async {
    try {
      final notifications = await NotificationRemoteDataSource.instance.getNotifications();
      if (!mounted) return;

      if (notifications.isNotEmpty) {
        final List<ActivityModel> realItems = [];

        // Group notifications by type and entity (keep comments/replies and video likes individual so each liker like s1 gets their own row)
        final Map<String, List<NotificationItem>> grouped = {};
        for (final n in notifications) {
          final isComment = n.type.toUpperCase() == 'COMMENT' ||
              n.title.toLowerCase().contains('comment') ||
              n.title.toLowerCase().contains('reply');
          final isLike = n.type.toUpperCase() == 'LIKE' ||
              n.title.toLowerCase().contains('liked') ||
              n.subtitle.toLowerCase().contains('liked');
          final groupKey = (isComment || isLike) ? '${n.type}_${n.id}' : '${n.type}_${n.entityId ?? "0"}';
          grouped.putIfAbsent(groupKey, () => []).add(n);
        }

        for (final entry in grouped.entries) {
          final items = entry.value;
          final first = items.first;
          final typeUpper = first.type.toUpperCase();

          final userNames = <String>[];
          final avatarUrls = <String>[];

          for (final it in items) {
            final name = it.actorDisplayName ?? it.actorUsername ?? it.title;
            if (name.isNotEmpty && !userNames.contains(name)) {
              userNames.add(name);
            }
            var av = it.actorAvatarUrl;
            if (av == null || av.isEmpty) {
              av = ProfileSyncService.getDefaultAvatarForUser(it.actorUsername ?? name);
            }
            if (av.isNotEmpty && !avatarUrls.contains(av)) {
              avatarUrls.add(av);
            }
          }

          if (avatarUrls.isEmpty) {
            final actorName = userNames.isNotEmpty ? userNames.first : 's1';
            avatarUrls.add(ProfileSyncService.getDefaultAvatarForUser(actorName));
          }

          String actionText = 'liked your comment.';
          String actType = 'like_comment';
          final subLower = first.subtitle.toLowerCase();
          final titleLower = first.title.toLowerCase();

          if (typeUpper == 'LIKE') {
            if (first.entityType == 'COMMENT' || subLower.contains('comment')) {
              actionText = 'liked your comment.';
              actType = 'like_comment';
            } else {
              actionText = 'liked your video.';
              actType = 'like_video';
            }
          } else if (typeUpper == 'COMMENT' || titleLower.contains('comment') || titleLower.contains('reply')) {
            final clean = CommentBottomSheet.extractCleanCommentText(first.subtitle);
            if (first.title.toLowerCase().contains('reply') || subLower.contains('replied')) {
              actionText = 'replied to your comment: "$clean"';
            } else {
              actionText = 'commented: "$clean"';
            }
            actType = 'comment';
          } else if (typeUpper == 'FOLLOW') {
            actionText = 'started following you.';
            actType = 'follow';
          } else if (typeUpper == 'MESSAGE') {
            actionText = 'sent you a message.';
            actType = 'message';
          }

          final others = userNames.length > 2 ? userNames.length - 2 : 0;
          final displayNames = userNames.take(2).toList();
          final actorUser = (first.actorUsername ?? (userNames.isNotEmpty ? userNames.first : '')).toLowerCase().replaceAll('@', '').trim();
          final bool hasStory = actorUser == 's1' ||
                                actorUser == 'sise' ||
                                _userHasStory(actorUser);
          final parsedVidId = int.tryParse(first.entityId ?? '1');
          final resolvedThumb = _resolveVideoThumbnail(parsedVidId);

          realItems.add(
            ActivityModel(
              id: 'real_${first.id}',
              userNames: displayNames.isNotEmpty ? displayNames : ['Someone'],
              userAvatarUrls: avatarUrls.take(2).toList(),
              othersCount: others,
              actionText: actionText,
              timeAgo: first.timeAgo ?? 'Recently',
              mediaThumbnailUrl: resolvedThumb,
              hasActiveStory: hasStory,
              type: actType,
              videoId: parsedVidId,
              commentContent: first.subtitle,
              actorId: first.actorId,
              actorUsername: first.actorUsername,
              entityId: first.entityId,
              isRead: !first.hasDot,
            ),
          );
        }

        setState(() {
          // Put fresh real notifications first, then append demo activities without duplicates
          _activities = [
            ...realItems,
            ..._demoActivities.where((demo) => !realItems.any((r) => r.id == demo.id)),
          ];
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

    if (activity.type == 'like_video') {
      final vidId = activity.videoId ?? (int.tryParse(activity.entityId ?? '0') ?? 0);
      VideoLikesBottomSheet.show(
        context,
        videoId: vidId,
        initialLikeCount: (activity.userNames.length + activity.othersCount).clamp(1, 99999),
        initialUserNames: activity.userNames,
        initialUserAvatars: activity.userAvatarUrls,
      );
      return;
    }

    // Default for 'like_comment', 'comment', 'mention': Navigate directly to video and open comments
    _navigateToVideo(activity, openComments: true);
  }

  void _openUserProfile(String username, int? userId, String? avatarUrl) {
    final clean = username.trim().replaceAll('@', '');
    final effectiveId = userId ?? ProfileSyncService.getUserIdForUsername(clean);
    final effectiveAvatar = (avatarUrl != null && avatarUrl.isNotEmpty)
        ? avatarUrl
        : ProfileSyncService.getDefaultAvatarForUser(clean);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          userId: effectiveId,
          username: clean,
          avatarUrl: effectiveAvatar,
        ),
      ),
    );
  }

  void _navigateToVideo(ActivityModel activity, {bool openComments = true}) {
    setState(() => activity.isRead = true);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VideoFeedPage(
          isActive: true,
          isStandalone: true,
          initialVideoId: activity.videoId ?? (int.tryParse(activity.entityId ?? '0') ?? 0),
          initialPage: activity.videoIndex,
          openCommentsOnStart: openComments,
          initialCommentReplyUser: activity.actorUsername ?? activity.userName,
          initialCommentUserAvatar: activity.userAvatarUrl,
          initialCommentText: activity.commentContent,
        ),
      ),
    );
  }

  List<ActivityModel> get _filteredActivities {
    switch (_currentFilter) {
      case ActivityFilter.likes:
        return _activities.where((a) => a.type == 'like_comment' || a.type == 'like_video').toList();
      case ActivityFilter.comments:
        return _activities.where((a) => a.type == 'comment' || a.type == 'like_comment').toList();
      case ActivityFilter.mentions:
        return _activities.where((a) => a.type == 'mention').toList();
      case ActivityFilter.followers:
        return _activities.where((a) => a.type == 'follow').toList();
      case ActivityFilter.all:
        return _activities;
    }
  }

  String get _filterTitle {
    switch (_currentFilter) {
      case ActivityFilter.likes:
        return 'Likes';
      case ActivityFilter.comments:
        return 'Comments';
      case ActivityFilter.mentions:
        return 'Mentions';
      case ActivityFilter.followers:
        return 'Followers';
      case ActivityFilter.all:
        return 'Activity';
    }
  }

  void _showActivityFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161618),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF383842),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Activity',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                _buildFilterItem(ctx, 'All activity', ActivityFilter.all),
                _buildFilterItem(ctx, 'Likes', ActivityFilter.likes),
                _buildFilterItem(ctx, 'Comments', ActivityFilter.comments),
                _buildFilterItem(ctx, 'Mentions and tags', ActivityFilter.mentions),
                _buildFilterItem(ctx, 'Followers', ActivityFilter.followers),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterItem(BuildContext ctx, String label, ActivityFilter filter) {
    final isSelected = _currentFilter == filter;
    return ListTile(
      dense: true,
      onTap: () {
        Navigator.of(ctx).pop();
        setState(() => _currentFilter = filter);
      },
      title: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFFD1D1D6),
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_rounded, color: Color(0xFF2F80ED), size: 20)
          : null,
    );
  }

  Widget _buildAvatar(ActivityModel item) {
    if (item.userAvatarUrls.length >= 2) {
      // Overlapping stacked avatars
      final name1 = item.userNames.isNotEmpty ? item.userNames[0] : 'User';
      final name2 = item.userNames.length > 1 ? item.userNames[1] : 'User';
      final av1 = item.userAvatarUrls[0];
      final av2 = item.userAvatarUrls[1];

      return SizedBox(
        width: 48,
        height: 44,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Primary left avatar (User 1)
            Positioned(
              left: 0,
              top: 2,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openUserProfile(name1, item.actorId, av1),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2.0),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      av1,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFF2A2A30),
                        child: const Icon(Icons.person, color: Colors.white38, size: 16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 2. Secondary right overlapping avatar (User 2)
            Positioned(
              left: 14,
              top: 8,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openUserProfile(name2, null, av2),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2.0),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      av2,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFF2A2A30),
                        child: const Icon(Icons.person, color: Colors.white38, size: 16),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Single circular avatar
    final avatarUrl = item.userAvatarUrls.isNotEmpty ? item.userAvatarUrls[0] : '';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openUserProfile(item.userName, item.actorId, avatarUrl),
      child: SizedBox(
        width: 48,
        height: 44,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 44,
            height: 44,
            padding: item.hasActiveStory ? const EdgeInsets.all(2.0) : EdgeInsets.zero,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: item.hasActiveStory
                  ? Border.all(color: const Color(0xFF00E5FF), width: 2.0)
                  : null,
            ),
            child: ClipOval(
              child: avatarUrl.startsWith('assets/')
                  ? Image.asset(avatarUrl, fit: BoxFit.cover)
                  : Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFF2A2A30),
                        child: const Icon(Icons.person, color: Colors.white38, size: 22),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRichText(ActivityModel item) {
    final spans = <TextSpan>[];

    if (item.userNames.isEmpty) {
      spans.add(const TextSpan(
        text: 'Someone',
        style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13.5),
      ));
    } else if (item.userNames.length == 1) {
      final name0 = item.userNames[0];
      final av0 = item.userAvatarUrls.isNotEmpty ? item.userAvatarUrls[0] : null;
      spans.add(TextSpan(
        text: name0,
        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13.5),
        recognizer: TapGestureRecognizer()..onTap = () => _openUserProfile(name0, item.actorId, av0),
      ));
      if (item.othersCount > 0) {
        spans.add(const TextSpan(text: ' and ', style: TextStyle(fontWeight: FontWeight.w400, color: Color(0xFFD1D1D6), fontSize: 13.5)));
        spans.add(TextSpan(
          text: '${item.othersCount} ${item.othersCount == 1 ? "other" : "others"}',
          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13.5),
          recognizer: TapGestureRecognizer()..onTap = () => _handleActivityTap(item),
        ));
      }
    } else if (item.userNames.length >= 2) {
      final name0 = item.userNames[0];
      final name1 = item.userNames[1];
      final av0 = item.userAvatarUrls.isNotEmpty ? item.userAvatarUrls[0] : null;
      final av1 = item.userAvatarUrls.length > 1 ? item.userAvatarUrls[1] : null;

      spans.add(TextSpan(
        text: name0,
        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13.5),
        recognizer: TapGestureRecognizer()..onTap = () => _openUserProfile(name0, item.actorId, av0),
      ));
      spans.add(TextSpan(
        text: item.othersCount > 0 ? ', ' : ' and ',
        style: const TextStyle(fontWeight: FontWeight.w400, color: Color(0xFFD1D1D6), fontSize: 13.5),
      ));
      spans.add(TextSpan(
        text: name1,
        style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13.5),
        recognizer: TapGestureRecognizer()..onTap = () => _openUserProfile(name1, null, av1),
      ));
      if (item.othersCount > 0) {
        spans.add(const TextSpan(text: ' and ', style: TextStyle(fontWeight: FontWeight.w400, color: Color(0xFFD1D1D6), fontSize: 13.5)));
        spans.add(TextSpan(
          text: '${item.othersCount} ${item.othersCount == 1 ? "other" : "others"}',
          style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13.5),
          recognizer: TapGestureRecognizer()..onTap = () => _handleActivityTap(item),
        ));
      }
    }

    spans.add(TextSpan(
      text: ' ${item.actionText} ',
      style: const TextStyle(
        fontWeight: FontWeight.w400,
        color: Color(0xFFD1D1D6),
        fontSize: 13.5,
      ),
      recognizer: TapGestureRecognizer()..onTap = () => _handleActivityTap(item),
    ));

    spans.add(TextSpan(
      text: item.timeAgo,
      style: const TextStyle(
        fontWeight: FontWeight.w400,
        color: Color(0xFF8E8E93),
        fontSize: 13.0,
      ),
    ));

    return Text.rich(
      TextSpan(children: spans),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Activity Dropdown Tab (Active)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _showActivityFilterModal,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _filterTitle,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_drop_down_rounded, color: Colors.white, size: 22),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Container(
                    width: 36,
                    height: 2.5,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // 2. New Followers Tab (Inactive)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NewFollowersScreen()),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'New followers',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  SizedBox(height: 5.5),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: list.isEmpty
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
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];

                return InkWell(
                  onTap: () => _handleActivityTap(item),
                  splashColor: Colors.white.withValues(alpha: 0.05),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Single or Overlapping Avatars
                        _buildAvatar(item),
                        const SizedBox(width: 12),

                        // Middle: Rich Formatted Text
                        Expanded(
                          child: _buildRichText(item),
                        ),
                        const SizedBox(width: 12),

                        // Right: Clean Video Thumbnail
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _navigateToVideo(item, openComments: item.type != 'like_video'),
                          child: Container(
                            width: 44,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: const Color(0xFF1E1E22),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                                width: 0.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: item.mediaThumbnailUrl.startsWith('assets/')
                                  ? Image.asset(item.mediaThumbnailUrl, fit: BoxFit.cover)
                                  : Image.network(
                                      item.mediaThumbnailUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: const Color(0xFF1E1E22),
                                        child: const Icon(
                                          Icons.videocam_rounded,
                                          color: Colors.white24,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
