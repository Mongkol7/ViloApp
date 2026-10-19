import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/inbox_item.dart';
import 'chat_detail_screen.dart';

class FollowerUserItem {
  final String id;
  final String name;
  final String username;
  final String avatarUrl;
  final String timeAgo;
  final String? mutualText;
  final bool isVerified;
  bool isFollowing;

  FollowerUserItem({
    required this.id,
    required this.name,
    required this.username,
    required this.avatarUrl,
    required this.timeAgo,
    this.mutualText,
    this.isVerified = false,
    this.isFollowing = false,
  });
}

class NewFollowersScreen extends StatefulWidget {
  const NewFollowersScreen({super.key});

  @override
  State<NewFollowersScreen> createState() => _NewFollowersScreenState();
}

class _NewFollowersScreenState extends State<NewFollowersScreen> {
  final List<FollowerUserItem> _followers = [
    FollowerUserItem(
      id: 'f1',
      name: 'R.DRR',
      username: 'rdrr_official',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
      timeAgo: '2h ago',
      mutualText: 'Followed by Junta + 2 others',
      isVerified: true,
      isFollowing: false,
    ),
    FollowerUserItem(
      id: 'f2',
      name: 'Sarah Jenkins',
      username: 'sarah_j',
      avatarUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&auto=format&fit=crop&q=80',
      timeAgo: '5h ago',
      mutualText: 'Followed by Elena.R',
      isFollowing: false,
    ),
    FollowerUserItem(
      id: 'f3',
      name: 'Alex Chen',
      username: 'alexchen_v',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
      timeAgo: '1d ago',
      isVerified: true,
      isFollowing: true,
    ),
    FollowerUserItem(
      id: 'f4',
      name: 'Liam Vance',
      username: 'liam_vance',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
      timeAgo: '2d ago',
      mutualText: 'Followed by Junta',
      isFollowing: false,
    ),
    FollowerUserItem(
      id: 'f5',
      name: 'Elena Rostova',
      username: 'elena_r',
      avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
      timeAgo: '3d ago',
      isFollowing: false,
    ),
    FollowerUserItem(
      id: 'f6',
      name: 'David Kim',
      username: 'david_k',
      avatarUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150&auto=format&fit=crop&q=80',
      timeAgo: '4d ago',
      isFollowing: true,
    ),
    FollowerUserItem(
      id: 'f7',
      name: 'Mia Wong',
      username: 'mia_wong',
      avatarUrl: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=150&auto=format&fit=crop&q=80',
      timeAgo: '5d ago',
      isFollowing: false,
    ),
  ];

  String _searchQuery = '';

  List<FollowerUserItem> get _filteredFollowers {
    if (_searchQuery.isEmpty) return _followers;
    return _followers.where((f) {
      return f.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          f.username.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _toggleFollow(FollowerUserItem item) {
    setState(() {
      item.isFollowing = !item.isFollowing;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          item.isFollowing
              ? 'You are now following @${item.username}'
              : 'Unfollowed @${item.username}',
        ),
        backgroundColor: item.isFollowing ? const Color(0xFF2F80ED) : const Color(0xFF333338),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openUserProfileModal(FollowerUserItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return Material(
          color: const Color(0xFF1E1E22),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF48484E),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 18),
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF2C2C32),
                  child: ClipOval(
                    child: Image.network(
                      item.avatarUrl,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.person,
                        color: Colors.white38,
                        size: 36,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (item.isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded, color: Color(0xFF2F80ED), size: 18),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '@${item.username}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Content creator • Photography & Travel ✨ Living between Tokyo & NYC',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFFD1D1D6),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: item.isFollowing
                              ? const Color(0xFF2C2C32)
                              : const Color(0xFF2F80ED),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: item.isFollowing
                                ? const BorderSide(color: Color(0xFF48484E))
                                : BorderSide.none,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.of(modalCtx).pop();
                          _toggleFollow(item);
                        },
                        child: Text(
                          item.isFollowing ? 'Following' : 'Follow back',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF48484E)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.of(modalCtx).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                thread: DirectMessageThread(
                                  id: 't_${item.id}',
                                  username: item.name,
                                  avatarUrl: item.avatarUrl,
                                  lastMessage: 'Say hi to your new follower!',
                                  timeAgo: 'Just now',
                                  isVerified: item.isVerified,
                                  followersCount: '12.4k followers',
                                  messages: const [],
                                ),
                              ),
                            ),
                          );
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Message',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredFollowers;

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
          'New followers',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E22),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2E2E34), width: 1.0),
              ),
              child: TextField(
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Search followers...',
                  hintStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF8E8E93),
                  ),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF8E8E93), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  isDense: true,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF8E8E93), size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
          ),

          // Header summary banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1A2433), Color(0xFF141416)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF2F80ED).withValues(alpha: 0.25),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F80ED).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Color(0xFF2F80ED),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '13 new followers this week',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Follow back to become mutual friends',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Color(0xFF8E8E93),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Follower list
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text(
                      'No followers found',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF8E8E93),
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(
                      color: Color(0xFF222226),
                      height: 1,
                      indent: 72,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final item = list[index];
                      return InkWell(
                        onTap: () => _openUserProfileModal(item),
                        splashColor: Colors.white.withValues(alpha: 0.05),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFF2C2C32),
                                child: ClipOval(
                                  child: Image.network(
                                    item.avatarUrl,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.person,
                                      color: Colors.white38,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (item.isVerified) ...[
                                          const SizedBox(width: 4),
                                          const Icon(Icons.verified_rounded, color: Color(0xFF2F80ED), size: 15),
                                        ],
                                        const SizedBox(width: 6),
                                        Text(
                                          '• ${item.timeAgo}',
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: Color(0xFF8E8E93),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '@${item.username}',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        color: Color(0xFF8E8E93),
                                      ),
                                    ),
                                    if (item.mutualText != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.mutualText!,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11,
                                          color: Color(0xFF56CCF2),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Follow toggle button
                              SizedBox(
                                height: 34,
                                child: item.isFollowing
                                    ? OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFFD1D1D6),
                                          side: const BorderSide(color: Color(0xFF3E3E46)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                        ),
                                        onPressed: () => _toggleFollow(item),
                                        child: const Text(
                                          'Following',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    : ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF2F80ED),
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                        ),
                                        onPressed: () => _toggleFollow(item),
                                        child: const Text(
                                          'Follow back',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
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
}
