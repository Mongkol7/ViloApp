import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

enum ActivityFilter { all, likes, comments, mentions }

class ActivityModel {
  final String id;
  final String userName;
  final String userHandle;
  final String userAvatarUrl;
  final String type; // 'like', 'comment', 'mention'
  final String text;
  final String timeAgo;
  final String mediaThumbnailUrl;
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

  final List<ActivityModel> _activities = [
    ActivityModel(
      id: 'a1',
      userName: 'Junta',
      userHandle: 'junta_art',
      userAvatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
      type: 'like',
      text: 'liked your photos.',
      timeAgo: '5m ago',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=150&auto=format&fit=crop&q=80',
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
      isRead: true,
    ),
    ActivityModel(
      id: 'a6',
      userName: 'Tin',
      userHandle: 'tin_99',
      userAvatarUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=150&auto=format&fit=crop&q=80',
      type: 'like',
      text: 'liked your 24h thought story.',
      timeAgo: '1d ago',
      mediaThumbnailUrl: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=150&auto=format&fit=crop&q=80',
      isRead: true,
    ),
  ];

  List<ActivityModel> get _filteredActivities {
    switch (_currentFilter) {
      case ActivityFilter.likes:
        return _activities.where((a) => a.type == 'like').toList();
      case ActivityFilter.comments:
        return _activities.where((a) => a.type == 'comment').toList();
      case ActivityFilter.mentions:
        return _activities.where((a) => a.type == 'mention').toList();
      case ActivityFilter.all:
      default:
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

  void _openQuickReply(ActivityModel activity) {
    final replyController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Material(
            color: const Color(0xFF1E1E22),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFF48484E),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Reply to @${activity.userHandle}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity.text,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A30),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF383842)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: replyController,
                            autofocus: true,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Add a reply...',
                              hintStyle: TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, color: Color(0xFF2F80ED)),
                          onPressed: () {
                            final text = replyController.text.trim();
                            if (text.isEmpty) return;
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Replied to @${activity.userHandle}: "$text"'),
                                backgroundColor: const Color(0xFF2F80ED),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _previewPost(ActivityModel activity) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: const Color(0xFF16161A),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Image.network(
                      activity.mediaThumbnailUrl,
                      height: 320,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(activity.userAvatarUrl),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${activity.userName} ${activity.text}',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                    separatorBuilder: (_, __) => const Divider(
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

                      return InkWell(
                        onTap: () {
                          setState(() => item.isRead = true);
                          if (item.type == 'comment') {
                            _openQuickReply(item);
                          } else {
                            _previewPost(item);
                          }
                        },
                        splashColor: Colors.white.withValues(alpha: 0.05),
                        child: Container(
                          color: item.isRead ? Colors.transparent : const Color(0xFF2F80ED).withValues(alpha: 0.04),
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
                                          child: const Icon(Icons.person, color: Colors.white38, size: 22),
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
                                        if (item.type == 'comment') ...[
                                          const SizedBox(width: 12),
                                          GestureDetector(
                                            onTap: () => _openQuickReply(item),
                                            child: const Text(
                                              'Reply',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF2F80ED),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Post preview thumbnail
                              GestureDetector(
                                onTap: () => _previewPost(item),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: const Color(0xFF2A2A30),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      item.mediaThumbnailUrl,
                                      width: 44,
                                      height: 44,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: const Color(0xFF2A2A30),
                                        child: const Icon(Icons.image, color: Colors.white24, size: 20),
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
