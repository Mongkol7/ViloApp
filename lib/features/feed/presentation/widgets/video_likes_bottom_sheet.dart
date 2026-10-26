import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/datasources/feed_remote_data_source.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';

class VideoLikesBottomSheet extends StatefulWidget {
  final int videoId;
  final int initialLikeCount;

  const VideoLikesBottomSheet({
    super.key,
    required this.videoId,
    this.initialLikeCount = 0,
  });

  static Future<void> show(
    BuildContext context, {
    required int videoId,
    int initialLikeCount = 0,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VideoLikesBottomSheet(
        videoId: videoId,
        initialLikeCount: initialLikeCount,
      ),
    );
  }

  @override
  State<VideoLikesBottomSheet> createState() => _VideoLikesBottomSheetState();
}

class _VideoLikesBottomSheetState extends State<VideoLikesBottomSheet> {
  final FeedRemoteDataSource _dataSource = FeedRemoteDataSource.instance;
  List<Map<String, dynamic>> _likers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLikes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLikes() async {
    setState(() => _isLoading = true);
    try {
      final likes = await _dataSource.getVideoLikes(widget.videoId);
      if (mounted) {
        setState(() {
          _likers = likes;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleFollowUser(int index) async {
    final user = _likers[index];
    final userId = user['userId'] as int?;
    if (userId == null) return;

    final currentlyFollowing = user['isFollowing'] == true;
    HapticFeedback.lightImpact();

    setState(() {
      _likers[index]['isFollowing'] = !currentlyFollowing;
    });

    try {
      final isNowFollowing = await _dataSource.toggleFollow(userId);
      if (mounted) {
        setState(() {
          _likers[index]['isFollowing'] = isNowFollowing;
        });
      }
    } catch (_) {
      // Revert if error
      if (mounted) {
        setState(() {
          _likers[index]['isFollowing'] = currentlyFollowing;
        });
      }
    }
  }

  void _openUserProfile(Map<String, dynamic> user) {
    final userId = user['userId'] as int?;
    final username = user['username']?.toString() ?? 'User';
    final displayName = user['displayName']?.toString() ?? username;
    final avatarUrl = user['avatarUrl']?.toString() ?? '';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          userId: userId,
          username: username,
          displayName: displayName,
          avatarUrl: avatarUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredLikers = _likers.where((u) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = (u['displayName'] ?? '').toString().toLowerCase();
      final username = (u['username'] ?? '').toString().toLowerCase();
      return name.contains(q) || username.contains(q);
    }).toList();

    final likeCount = _likers.isNotEmpty ? _likers.length : widget.initialLikeCount;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: Color(0xFF141416),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.favorite_rounded, color: Color(0xFFFE2C55), size: 20),
                const SizedBox(width: 8),
                Text(
                  '$likeCount ${likeCount == 1 ? "Like" : "Likes"}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Search bar
          if (_likers.length > 5)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFF222226),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontFamily: 'Inter', color: Colors.white, fontSize: 13),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search who liked...',
                    hintStyle: const TextStyle(fontFamily: 'Inter', color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),

          const Divider(color: Colors.white12, height: 1),

          // Likers List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFE2C55),
                      strokeWidth: 2.5,
                    ),
                  )
                : filteredLikers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                              child: const Icon(
                                Icons.favorite_border_rounded,
                                color: Colors.white38,
                                size: 44,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No matches found'
                                  : 'No likes yet',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Try a different search term'
                                  : 'Be the first to react love to this video!',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: Colors.white54,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredLikers.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          final user = filteredLikers[index];
                          final username = user['username']?.toString() ?? 'User';
                          final displayName = user['displayName']?.toString() ?? username;
                          final avatarUrl = user['avatarUrl']?.toString() ?? '';
                          final isVerified = user['isVerified'] == true;
                          final isFollowing = user['isFollowing'] == true;
                          final isMe = ProfileSyncService.instance.isCurrentUser(
                            username: username,
                            id: user['userId']?.toString(),
                          );

                          return InkWell(
                            onTap: () => _openUserProfile(user),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white24, width: 1),
                                    ),
                                    child: ClipOval(
                                      child: avatarUrl.isNotEmpty
                                          ? Image.network(
                                              avatarUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, error, stackTrace) => Container(
                                                color: const Color(0xFF2C2C2C),
                                                child: const Icon(
                                                  Icons.person_rounded,
                                                  color: Colors.white70,
                                                  size: 24,
                                                ),
                                              ),
                                            )
                                          : Container(
                                              color: const Color(0xFF2C2C2C),
                                              child: const Icon(
                                                Icons.person_rounded,
                                                color: Colors.white70,
                                                size: 24,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Names
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                displayName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            if (isVerified) ...[
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.verified_rounded,
                                                color: Color(0xFF20D5EC),
                                                size: 14,
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '@$username',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Follow Button (if not current user)
                                  if (!isMe)
                                    GestureDetector(
                                      onTap: () => _toggleFollowUser(index),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isFollowing
                                              ? const Color(0xFF2A2A2E)
                                              : const Color(0xFFFE2C55),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isFollowing ? 'Following' : 'Follow',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isFollowing
                                                ? Colors.white70
                                                : Colors.white,
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
