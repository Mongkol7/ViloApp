import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/datasources/feed_remote_data_source.dart';
import '../../data/models/comment_model.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import 'comment_bottom_sheet.dart';

class VideoLikesBottomSheet extends StatefulWidget {
  final int videoId;
  final int initialLikeCount;
  final int initialCommentCount;
  final List<String>? initialUserNames;
  final List<String>? initialUserAvatars;
  final int initialTab; // 0: Comments, 1: Likes
  final String? highlightCommentText;
  final String? initialReplyTo;
  final String? initialCommentUserAvatar;
  final int? videoCreatorId;
  final String? videoCreatorUsername;
  final ValueChanged<int>? onCommentCountChanged;

  const VideoLikesBottomSheet({
    super.key,
    required this.videoId,
    this.initialLikeCount = 0,
    this.initialCommentCount = 0,
    this.initialUserNames,
    this.initialUserAvatars,
    this.initialTab = 1,
    this.highlightCommentText,
    this.initialReplyTo,
    this.initialCommentUserAvatar,
    this.videoCreatorId,
    this.videoCreatorUsername,
    this.onCommentCountChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required int videoId,
    int initialLikeCount = 0,
    int initialCommentCount = 0,
    List<String>? initialUserNames,
    List<String>? initialUserAvatars,
    int initialTab = 1,
    String? highlightCommentText,
    String? initialReplyTo,
    String? initialCommentUserAvatar,
    int? videoCreatorId,
    String? videoCreatorUsername,
    ValueChanged<int>? onCommentCountChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VideoLikesBottomSheet(
        videoId: videoId,
        initialLikeCount: initialLikeCount,
        initialCommentCount: initialCommentCount,
        initialUserNames: initialUserNames,
        initialUserAvatars: initialUserAvatars,
        initialTab: initialTab,
        highlightCommentText: highlightCommentText,
        initialReplyTo: initialReplyTo,
        initialCommentUserAvatar: initialCommentUserAvatar,
        videoCreatorId: videoCreatorId,
        videoCreatorUsername: videoCreatorUsername,
        onCommentCountChanged: onCommentCountChanged,
      ),
    );
  }

  @override
  State<VideoLikesBottomSheet> createState() => _VideoLikesBottomSheetState();
}

class _VideoLikesBottomSheetState extends State<VideoLikesBottomSheet> {
  final FeedRemoteDataSource _dataSource = FeedRemoteDataSource.instance;
  List<Map<String, dynamic>> _likers = [];
  List<CommentModel> _comments = [];
  bool _isLoading = true;
  late int _selectedTab;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _commentInputController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  bool _isPostingComment = false;
  final Set<int> _likedCommentIds = {};
  final Set<int> _dislikedCommentIds = {};

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _loadLikes();
    _loadComments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _commentInputController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  bool _computeIsFollowing(String username, int? userId) {
    final clean = username.toLowerCase().replaceAll('@', '').trim();
    if (ProfileSyncService.instance.isCurrentUser(username: clean, id: userId?.toString())) {
      return false;
    }
    final cached = ProfileSyncService.instance.cachedFollowing;
    if (cached != null) {
      if (userId != null && cached.any((u) => u.id == userId)) return true;
      if (cached.any((u) => u.username.toLowerCase().replaceAll('@', '').trim() == clean)) return true;
      return false;
    }

    final myUser = ProfileSyncService.instance.currentUsername.toLowerCase().trim();
    if (myUser == 'mongkol' || myUser == 'setkimliza' || myUser == 'trenmono' || myUser == 'bunheng' || myUser == 'rithysak') {
      if (clean == 'trenmono' || clean == 'mono' || clean == 'setkimliza' || clean == 'liza' ||
          clean == 'mongkol' || clean == 'bunheng' || clean == 'rithysak' || clean == 'sak' || clean == 's1') {
        return clean != myUser;
      }
      if (clean == 'kelly' || clean == 'gon_freecs') {
        return true;
      }
    }
    return false;
  }

  bool _computeFollowsYou(String username, int? userId) {
    final clean = username.toLowerCase().replaceAll('@', '').trim();
    if (ProfileSyncService.instance.isCurrentUser(username: clean, id: userId?.toString())) {
      return false;
    }
    final cached = ProfileSyncService.instance.cachedFollowers;
    if (cached != null) {
      if (userId != null && cached.any((u) => u.id == userId)) return true;
      if (cached.any((u) => u.username.toLowerCase().replaceAll('@', '').trim() == clean)) return true;
      return false;
    }

    final myUser = ProfileSyncService.instance.currentUsername.toLowerCase().trim();
    if (myUser == 'mongkol' || myUser == 'setkimliza' || myUser == 'trenmono' || myUser == 'bunheng' || myUser == 'rithysak') {
      if (clean == 'trenmono' || clean == 'mono' || clean == 'setkimliza' || clean == 'liza' ||
          clean == 'mongkol' || clean == 'bunheng' || clean == 'rithysak' || clean == 'sak' || clean == 's1') {
        return clean != myUser;
      }
    }
    return false;
  }

  List<CommentModel> _getFallbackComments() {
    return [
      CommentModel(
        id: 1001,
        videoId: widget.videoId,
        userId: 201,
        username: 'toki_beauty',
        displayName: 'TOki ស្រីស្អាត',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
        content: 'បងញុមសុំពែង1ញុមចង់ទិញស្គីនចង់មានស្គីនលេងដូចគេណាស់ 🥺',
        attachmentUrl: 'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=600&auto=format&fit=crop&q=80',
        createdAt: DateTime.now().subtract(const Duration(minutes: 6)),
        likesCount: 14,
      ),
      CommentModel(
        id: 1002,
        videoId: widget.videoId,
        userId: 202,
        username: 'yueer',
        displayName: 'Yue\'er',
        avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150&auto=format&fit=crop&q=80',
        content: 'serj pin rk rg ke mg player grg muy jnun',
        attachmentUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=500&auto=format&fit=crop&q=80',
        createdAt: DateTime.now().subtract(const Duration(minutes: 6)),
        likesCount: 9,
      ),
      CommentModel(
        id: 1003,
        videoId: widget.videoId,
        userId: 203,
        username: 'hokage',
        displayName: 'hOkAGE',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
        content: '',
        attachmentUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=500&auto=format&fit=crop&q=80',
        createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
        likesCount: 6,
      ),
      CommentModel(
        id: 1004,
        videoId: widget.videoId,
        userId: 2,
        username: 'setkimliza',
        displayName: 'Set Kimliza',
        avatarUrl: ProfileSyncService.getDefaultAvatarForUser('setkimliza'),
        content: 'Mechanical keyboard sound is so satisfying ⌨️',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        likesCount: 12,
      ),
      CommentModel(
        id: 1005,
        videoId: widget.videoId,
        userId: 5,
        username: 'trenmono',
        displayName: 'Tren Mono',
        avatarUrl: ProfileSyncService.getDefaultAvatarForUser('trenmono'),
        content: 'That clutch play was insane 🎯 clutch 1v3',
        createdAt: DateTime.now().subtract(const Duration(hours: 4)),
        likesCount: 8,
      ),
      CommentModel(
        id: 1006,
        videoId: widget.videoId,
        userId: 99,
        username: 's1',
        displayName: 's1',
        avatarUrl: ProfileSyncService.getDefaultAvatarForUser('s1'),
        content: 'Clean desk aesthetic and lighting 🔥',
        createdAt: DateTime.now().subtract(const Duration(hours: 7)),
        likesCount: 15,
      ),
      CommentModel(
        id: 1007,
        videoId: widget.videoId,
        userId: 7,
        username: 'sophia_art',
        displayName: 'Sophia Vance',
        avatarUrl: ProfileSyncService.getDefaultAvatarForUser('sophia_art'),
        content: 'Fluid animation and 60fps feed 🚀',
        createdAt: DateTime.now().subtract(const Duration(hours: 9)),
        likesCount: 5,
      ),
      CommentModel(
        id: 1008,
        videoId: widget.videoId,
        userId: 3,
        username: 'bunheng',
        displayName: 'Bunheng',
        avatarUrl: ProfileSyncService.getDefaultAvatarForUser('bunheng'),
        content: 'Bro the reflex timing is crazy ✨',
        createdAt: DateTime.now().subtract(const Duration(hours: 10)),
        likesCount: 7,
      ),
      CommentModel(
        id: 1009,
        videoId: widget.videoId,
        userId: 4,
        username: 'rithysak',
        displayName: 'Rithysak',
        avatarUrl: ProfileSyncService.getDefaultAvatarForUser('rithysak'),
        content: 'Build item oy khnh som 1 tv idol 🥺🔥',
        createdAt: DateTime.now().subtract(const Duration(hours: 11)),
        likesCount: 11,
      ),
    ];
  }

  Future<void> _submitComment() async {
    final text = _commentInputController.text.trim();
    if (text.isEmpty || _isPostingComment) return;
    HapticFeedback.lightImpact();

    final myUser = ProfileSyncService.instance.cachedMyProfile;
    final myDisplayName = ProfileSyncService.instance.currentUserDisplayName;
    final myUsername = ProfileSyncService.instance.currentUsername;
    final myAvatar = ProfileSyncService.instance.currentUserAvatar;
    final tempId = DateTime.now().millisecondsSinceEpoch;

    final newComment = CommentModel(
      id: tempId,
      videoId: widget.videoId,
      userId: myUser?.id ?? 0,
      username: myUsername,
      displayName: myDisplayName,
      avatarUrl: myAvatar,
      content: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _isPostingComment = true;
      _comments.insert(0, newComment);
      _commentInputController.clear();
    });

    ProfileSyncService.instance.notifyVideoInteraction(
      VideoInteractionEvent(
        videoId: widget.videoId,
        commentCount: _comments.length,
      ),
    );
    widget.onCommentCountChanged?.call(_comments.length);

    try {
      final real = await _dataSource.postComment(widget.videoId, text);
      if (mounted) {
        setState(() {
          _isPostingComment = false;
          final idx = _comments.indexWhere((c) => c.id == tempId);
          if (idx != -1) {
            _comments[idx] = real;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isPostingComment = false);
      }
    }
  }

  void _populateFallbackLikers() {
    final List<Map<String, dynamic>> fallback = [];

    // 1. First add any specific users from the activity/notification (e.g. Tren Mono, Set Kimliza)
    if (widget.initialUserNames != null && widget.initialUserNames!.isNotEmpty) {
      for (int i = 0; i < widget.initialUserNames!.length; i++) {
        final name = widget.initialUserNames![i];
        final cleanUsername = name.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '').trim();
        final effectiveUsername = cleanUsername.isNotEmpty ? cleanUsername : 'user_${100 + i}';
        final avatar = (widget.initialUserAvatars != null &&
                i < widget.initialUserAvatars!.length &&
                widget.initialUserAvatars![i].isNotEmpty)
            ? widget.initialUserAvatars![i]
            : ProfileSyncService.getDefaultAvatarForUser(name);

        final targetUid = ProfileSyncService.getUserIdForUsername(effectiveUsername) ?? (1000 + i);
        final isFollowing = _computeIsFollowing(effectiveUsername, targetUid);
        final followsYou = _computeFollowsYou(effectiveUsername, targetUid);
        final isFriend = isFollowing && followsYou;

        fallback.add({
          'userId': targetUid,
          'username': effectiveUsername,
          'displayName': name,
          'avatarUrl': avatar,
          'isVerified': true,
          'isFollowing': isFollowing,
          'followsYou': followsYou,
          'isFriend': isFriend,
          'hasActiveStory': true,
        });
      }
    }

    // Only include actual likers (e.g. from notification/initialUserNames if provided)
    if (mounted) {
      setState(() {
        _likers = fallback;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLikes() async {
    setState(() => _isLoading = true);
    try {
      final likes = await _dataSource.getVideoLikes(widget.videoId);
      if (mounted) {
        if (likes.isNotEmpty) {
          final combined = List<Map<String, dynamic>>.from(likes);
          if (widget.initialUserNames != null && widget.initialUserNames!.isNotEmpty) {
            for (int i = widget.initialUserNames!.length - 1; i >= 0; i--) {
              final n = widget.initialUserNames![i];
              final clean = n.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '').trim();
              if (!combined.any((u) => (u['username'] ?? '').toString().toLowerCase().contains(clean))) {
                final av = (widget.initialUserAvatars != null && i < widget.initialUserAvatars!.length)
                    ? widget.initialUserAvatars![i]
                    : ProfileSyncService.getDefaultAvatarForUser(n);
                final uid = ProfileSyncService.getUserIdForUsername(clean) ?? (1000 + i);
                final isFollowing = _computeIsFollowing(clean, uid);
                final followsYou = _computeFollowsYou(clean, uid);
                final isFriend = isFollowing && followsYou;

                combined.insert(0, {
                  'userId': uid,
                  'username': clean.isNotEmpty ? clean : 'user_$i',
                  'displayName': n,
                  'avatarUrl': av,
                  'isVerified': true,
                  'isFollowing': isFollowing,
                  'followsYou': followsYou,
                  'isFriend': isFriend,
                  'hasActiveStory': true,
                });
              }
            }
          }
          setState(() {
            _likers = combined;
            _isLoading = false;
          });
        } else {
          _populateFallbackLikers();
        }
      }
    } catch (_) {
      if (mounted) {
        _populateFallbackLikers();
      }
    }
  }

  bool _canDeleteComment(CommentModel comment) {
    final isAuthor = ProfileSyncService.instance.isCurrentUser(
      username: comment.username,
      id: comment.userId.toString(),
    );
    if (isAuthor) return true;
    final isPostOwner = ProfileSyncService.instance.isCurrentUser(
      username: widget.videoCreatorUsername,
      id: widget.videoCreatorId?.toString(),
    );
    if (isPostOwner) return true;
    return false;
  }

  void _ensureHighlightedCommentExists() {
    if (widget.highlightCommentText == null || widget.highlightCommentText!.trim().isEmpty) return;
    final hasMatch = _comments.any(_isCommentHighlighted);
    if (!hasMatch) {
      String cleanText = CommentBottomSheet.extractCleanCommentText(widget.highlightCommentText!);
      final commenterUsername = widget.initialReplyTo ?? 'User';
      final isCommenterMe = ProfileSyncService.instance.isCurrentUser(username: commenterUsername);
      final rawHlAvatar = widget.initialCommentUserAvatar?.trim() ?? '';
      final clean = commenterUsername.toLowerCase().replaceAll('@', '').trim();
      final resolvedAvatar = isCommenterMe
          ? ProfileSyncService.instance.currentUserAvatar
          : ((rawHlAvatar.isNotEmpty &&
                  !rawHlAvatar.contains('535713875002') &&
                  !(rawHlAvatar.contains('534528741775') && clean != 'mongkol'))
              ? rawHlAvatar
              : ProfileSyncService.getDefaultAvatarForUser(commenterUsername));

      _comments.insert(
        0,
        CommentModel(
          id: DateTime.now().millisecondsSinceEpoch,
          videoId: widget.videoId,
          userId: isCommenterMe ? (ProfileSyncService.instance.cachedMyProfile?.id ?? 0) : 0,
          username: commenterUsername,
          displayName: commenterUsername,
          avatarUrl: resolvedAvatar,
          content: cleanText,
          createdAt: DateTime.now(),
        ),
      );
    } else {
      final hlIdx = _comments.indexWhere(_isCommentHighlighted);
      if (hlIdx > 0) {
        final hlComment = _comments.removeAt(hlIdx);
        _comments.insert(0, hlComment);
      }
    }
  }

  bool _isCommentHighlighted(CommentModel comment) {
    if (widget.highlightCommentText == null || widget.highlightCommentText!.trim().isEmpty) {
      return false;
    }
    final target = CommentBottomSheet.extractCleanCommentText(widget.highlightCommentText!).toLowerCase().trim();
    final content = comment.content.toLowerCase().trim();
    if (target.isNotEmpty && content.isNotEmpty && (content.contains(target) || target.contains(content))) {
      return true;
    }
    if (widget.initialReplyTo != null && widget.initialReplyTo!.isNotEmpty) {
      final u = widget.initialReplyTo!.toLowerCase().replaceAll('@', '').trim();
      final cu = comment.username.toLowerCase().replaceAll('@', '').trim();
      final cdn = comment.displayName.toLowerCase().replaceAll('@', '').trim();
      if ((cu == u || cdn == u) && (target.isEmpty || content.contains(target) || target.contains(content))) {
        return true;
      }
    }
    return false;
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _dataSource.getComments(widget.videoId);
      if (mounted) {
        setState(() {
          _comments = comments.isNotEmpty ? comments : _getFallbackComments();
          _ensureHighlightedCommentExists();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _comments = _getFallbackComments();
          _ensureHighlightedCommentExists();
        });
      }
    }
  }

  Future<void> _toggleFollowUser(int index) async {
    final user = _likers[index];
    final userId = user['userId'] as int?;
    if (userId == null) return;

    final currentlyFollowing = user['isFollowing'] == true;
    final followsYou = user['followsYou'] == true;
    final nextFollowing = !currentlyFollowing;
    HapticFeedback.lightImpact();

    setState(() {
      _likers[index]['isFollowing'] = nextFollowing;
      _likers[index]['isFriend'] = nextFollowing && followsYou;
    });

    try {
      final isNowFollowing = await _dataSource.toggleFollow(userId);
      if (mounted) {
        setState(() {
          _likers[index]['isFollowing'] = isNowFollowing;
          _likers[index]['isFriend'] = isNowFollowing && followsYou;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _likers[index]['isFollowing'] = currentlyFollowing;
          _likers[index]['isFriend'] = currentlyFollowing && followsYou;
        });
      }
    }
  }

  String _resolveLikerAvatar(Map<String, dynamic> user) {
    final username = user['username']?.toString() ?? '';
    final userId = user['userId']?.toString();
    final isMe = ProfileSyncService.instance.isCurrentUser(
      username: username,
      id: userId,
    );
    if (isMe) {
      return ProfileSyncService.instance.currentUserAvatar;
    }
    final raw = user['avatarUrl']?.toString().trim() ?? '';
    final clean = username.toLowerCase().replaceAll('@', '').trim();
    if (raw.isNotEmpty &&
        !raw.contains('535713875002') &&
        !(raw.contains('534528741775') && clean != 'mongkol')) {
      return raw;
    }
    return ProfileSyncService.getDefaultAvatarForUser(username);
  }

  void _openUserProfile(Map<String, dynamic> user) {
    final username = user['username']?.toString() ?? 'User';
    final displayName = user['displayName']?.toString() ?? username;
    final avatarUrl = _resolveLikerAvatar(user);
    final userId = (user['userId'] as int?) ?? ProfileSyncService.getUserIdForUsername(username);

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

    final likeCount = _likers.isNotEmpty
        ? (_likers.length > widget.initialLikeCount ? _likers.length : widget.initialLikeCount)
        : widget.initialLikeCount;
    final commentCount = _comments.isNotEmpty ? _comments.length : widget.initialCommentCount;

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
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header Tabs: Comments FIRST, Likes SECOND (matching user request & screenshot)
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8, top: 2, bottom: 2),
            child: Row(
              children: [
                // 1. Comments Tab (First)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _selectedTab = 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Comments $commentCount',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: _selectedTab == 0 ? FontWeight.w700 : FontWeight.w600,
                            color: _selectedTab == 0 ? Colors.white : const Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // 2. Likes Tab (Second)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _selectedTab = 1),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Likes $likeCount',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: _selectedTab == 1 ? FontWeight.w700 : FontWeight.w600,
                            color: _selectedTab == 1 ? Colors.white : const Color(0xFF8E8E93),
                          ),
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.tune_rounded, color: Colors.white70, size: 22),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // Content based on tab
          Expanded(
            child: _selectedTab == 1 ? _buildLikesTab(filteredLikers) : _buildCommentsTab(),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsTab() {
    return Column(
      children: [
        Expanded(
          child: _comments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white24, size: 48),
                      const SizedBox(height: 12),
                      const Text(
                        'No comments yet',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Be the first to share your thoughts!',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _comments.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final c = _comments[index];
                    final avatarUrl = c.avatarUrl != null && c.avatarUrl!.isNotEmpty
                        ? c.avatarUrl!
                        : ProfileSyncService.getDefaultAvatarForUser(c.username);
                    final isLiked = _likedCommentIds.contains(c.id);
                    final isDisliked = _dislikedCommentIds.contains(c.id);
                    final likesCount = c.likesCount + (isLiked ? 1 : 0);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              final uid = c.userId > 0 ? c.userId : ProfileSyncService.getUserIdForUsername(c.username);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => PublicProfileScreen(
                                    userId: uid,
                                    username: c.username,
                                    displayName: c.displayName.isNotEmpty ? c.displayName : c.username,
                                    avatarUrl: avatarUrl,
                                  ),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF2C2C32),
                              backgroundImage: NetworkImage(avatarUrl),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    final uid = c.userId > 0 ? c.userId : ProfileSyncService.getUserIdForUsername(c.username);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => PublicProfileScreen(
                                          userId: uid,
                                          username: c.username,
                                          displayName: c.displayName.isNotEmpty ? c.displayName : c.username,
                                          avatarUrl: avatarUrl,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      Text(
                                        c.displayName.isNotEmpty ? c.displayName : c.username,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '@${c.username}',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 11.5,
                                          color: Colors.white38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  c.content,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13.5,
                                    color: Color(0xFFE5E5EA),
                                  ),
                                ),
                                if (c.attachmentUrl != null && c.attachmentUrl!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      constraints: const BoxConstraints(maxHeight: 180, maxWidth: 220),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.white12, width: 0.8),
                                      ),
                                      child: Image.network(
                                        c.attachmentUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      c.timeAgo,
                                      style: const TextStyle(color: Colors.white38, fontSize: 11.5),
                                    ),
                                    const SizedBox(width: 16),
                                    GestureDetector(
                                      onTap: () {
                                        _commentInputController.text = '@${c.username} ';
                                        _commentInputController.selection = TextSelection.fromPosition(
                                          TextPosition(offset: _commentInputController.text.length),
                                        );
                                        _commentFocusNode.requestFocus();
                                      },
                                      child: const Text(
                                        'Reply',
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    if (_canDeleteComment(c)) ...[
                                      const SizedBox(width: 16),
                                      GestureDetector(
                                        onTap: () async {
                                          setState(() => _comments.removeWhere((item) => item.id == c.id));
                                          widget.onCommentCountChanged?.call(_comments.length);
                                          try {
                                            await _dataSource.deleteComment(widget.videoId, c.id);
                                          } catch (_) {}
                                        },
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: Colors.redAccent.withValues(alpha: 0.8),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                            child: Column(
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    setState(() {
                                      if (_likedCommentIds.contains(c.id)) {
                                        _likedCommentIds.remove(c.id);
                                      } else {
                                        _likedCommentIds.add(c.id);
                                        _dislikedCommentIds.remove(c.id);
                                      }
                                    });
                                  },
                                  child: Column(
                                    children: [
                                      Icon(
                                        isLiked ? Icons.favorite : Icons.favorite_border,
                                        color: isLiked ? const Color(0xFFFE2C55) : Colors.white38,
                                        size: 16,
                                      ),
                                      if (likesCount > 0) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          '$likesCount',
                                          style: const TextStyle(color: Colors.white38, fontSize: 11),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    setState(() {
                                      if (_dislikedCommentIds.contains(c.id)) {
                                        _dislikedCommentIds.remove(c.id);
                                      } else {
                                        _dislikedCommentIds.add(c.id);
                                        _likedCommentIds.remove(c.id);
                                      }
                                    });
                                  },
                                  child: Icon(
                                    isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                                    color: isDisliked ? Colors.white70 : Colors.white24,
                                    size: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Bottom Input Bar
        Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 8,
            bottom: 8 + MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF161616),
            border: Border(top: BorderSide(color: Colors.white10)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: const Color(0xFF2C2C32),
                backgroundImage: NetworkImage(ProfileSyncService.instance.currentUserAvatar),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF26262A),
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentInputController,
                          focusNode: _commentFocusNode,
                          style: const TextStyle(color: Colors.white, fontSize: 13.5),
                          decoration: const InputDecoration(
                            hintText: 'Add comment...',
                            hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: (_) => _submitComment(),
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _commentInputController.text += '😊';
                        },
                        child: const Icon(Icons.emoji_emotions_outlined, color: Colors.white54, size: 18),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          _commentInputController.text += '@';
                        },
                        child: const Icon(Icons.alternate_email_rounded, color: Colors.white54, size: 17),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _isPostingComment ? null : _submitComment,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: _isPostingComment
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Post',
                          style: TextStyle(
                            color: Color(0xFFFE2C55),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLikesTab(List<Map<String, dynamic>> filteredLikers) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFE2C55),
          strokeWidth: 2.5,
        ),
      );
    }

    if (filteredLikers.isEmpty) {
      return Center(
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
              _searchQuery.isNotEmpty ? 'No matches found' : 'No likes yet',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Search bar when likers > 6
        if (_likers.length > 6)
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

        Expanded(
          child: ListView.builder(
            itemCount: filteredLikers.length,
            padding: const EdgeInsets.symmetric(vertical: 6),
            itemBuilder: (context, index) {
              final user = filteredLikers[index];
              final username = user['username']?.toString() ?? 'User';
              final clean = username.toLowerCase().replaceAll('@', '').trim();
              final displayName = user['displayName']?.toString() ?? username;
              final avatarUrl = _resolveLikerAvatar(user);
              final isVerified = user['isVerified'] == true;
              final bool isFollowing = user['isFollowing'] == true;
              final bool followsYou = user['followsYou'] == true;
              final bool isFriend = user['isFriend'] == true || (isFollowing && followsYou);

              final isMe = ProfileSyncService.instance.isCurrentUser(
                username: username,
                id: user['userId']?.toString(),
              );

              final bool hasActiveStory = user['hasActiveStory'] == true ||
                  clean == 's1' ||
                  clean == 'sise' ||
                  clean == 'kelly' ||
                  clean == 'kelly_art' ||
                  clean == 'setkimliza' ||
                  clean == 'trenmono' ||
                  clean == 'ching' ||
                  clean == 'gon_freecs' ||
                  clean == 'jinn' ||
                  clean == 'alanzo';

              return InkWell(
                onTap: () => _openUserProfile(user),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  child: Row(
                    children: [
                      // Avatar (with cyan story ring matching screenshot if hasActiveStory)
                      Container(
                        width: 46,
                        height: 46,
                        padding: hasActiveStory ? const EdgeInsets.all(2.0) : EdgeInsets.zero,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: hasActiveStory
                              ? Border.all(color: const Color(0xFF00E5FF), width: 2.0)
                              : Border.all(color: Colors.white12, width: 0.5),
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
                      const SizedBox(width: 14),

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
                                      fontSize: 14.5,
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

                      // Relationship Button (Friends vs Following vs Follow based on account relationship)
                      if (!isMe)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _toggleFollowUser(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(
                              horizontal: isFriend ? 14 : 20,
                              vertical: 7.5,
                            ),
                            decoration: BoxDecoration(
                              color: (isFriend || isFollowing)
                                  ? const Color(0xFF2A2A2E)
                                  : const Color(0xFFFE2C55),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isFriend) ...[
                                  const Icon(
                                    Icons.people_alt_rounded,
                                    color: Colors.white70,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  isFriend
                                      ? 'Friends'
                                      : (isFollowing ? 'Following' : 'Follow'),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: (isFriend || isFollowing)
                                        ? Colors.white70
                                        : Colors.white,
                                  ),
                                ),
                              ],
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
    );
  }
}
