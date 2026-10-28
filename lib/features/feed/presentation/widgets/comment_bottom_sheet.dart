import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../profile/data/datasources/profile_remote_data_source.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../data/datasources/feed_remote_data_source.dart';
import '../../data/models/comment_model.dart';
import 'video_likes_bottom_sheet.dart';

class CommentBottomSheet extends StatefulWidget {
  final int? videoId;
  final int? videoCreatorId;
  final String? videoCreatorUsername;
  final int initialCommentCount;
  final int initialLikeCount;
  final ValueChanged<int>? onCommentCountChanged;
  final String? initialReplyTo;
  final String? initialCommentUserAvatar;
  final String? highlightCommentText;

  const CommentBottomSheet({
    super.key,
    this.videoId,
    this.videoCreatorId,
    this.videoCreatorUsername,
    this.initialCommentCount = 0,
    this.initialLikeCount = 0,
    this.onCommentCountChanged,
    this.initialReplyTo,
    this.initialCommentUserAvatar,
    this.highlightCommentText,
  });

  static String extractCleanCommentText(String raw) {
    String cleanText = raw.trim();
    if (cleanText.contains('replied to your comment: "')) {
      final start = cleanText.indexOf('replied to your comment: "') + 26;
      final end = cleanText.lastIndexOf('"');
      if (end > start) return cleanText.substring(start, end).trim();
    }
    if (cleanText.contains('replied to your comment: \'')) {
      final start = cleanText.indexOf('replied to your comment: \'') + 26;
      final end = cleanText.lastIndexOf('\'');
      if (end > start) return cleanText.substring(start, end).trim();
    }
    if (cleanText.contains('replied to your comment:')) {
      final start = cleanText.indexOf('replied to your comment:') + 24;
      final sub = cleanText.substring(start).trim().replaceAll('"', '').replaceAll("'", "");
      if (sub.isNotEmpty) return sub;
    }
    if (cleanText.contains('commented: "')) {
      final start = cleanText.indexOf('commented: "') + 12;
      final end = cleanText.lastIndexOf('"');
      if (end > start) return cleanText.substring(start, end).trim();
    }
    if (cleanText.contains('commented: \'')) {
      final start = cleanText.indexOf('commented: \'') + 12;
      final end = cleanText.lastIndexOf('\'');
      if (end > start) return cleanText.substring(start, end).trim();
    }
    if (cleanText.contains('commented:')) {
      final start = cleanText.indexOf('commented:') + 10;
      final sub = cleanText.substring(start).trim().replaceAll('"', '').replaceAll("'", "");
      if (sub.isNotEmpty) return sub;
    }
    if (cleanText.contains('"')) {
      final start = cleanText.indexOf('"') + 1;
      final end = cleanText.lastIndexOf('"');
      if (end > start) return cleanText.substring(start, end).trim();
    }
    if (cleanText.contains('\'')) {
      final start = cleanText.indexOf('\'') + 1;
      final end = cleanText.lastIndexOf('\'');
      if (end > start) return cleanText.substring(start, end).trim();
    }
    return cleanText;
  }

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final FeedRemoteDataSource _dataSource = FeedRemoteDataSource();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _highlightKey = GlobalKey();

  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isPosting = false;
  int _commentCount = 0;
  late int _likeCount;
  int? _replyToParentId;
  String? _replyToUsername;

  @override
  void initState() {
    super.initState();
    _commentCount = widget.initialCommentCount;
    _likeCount = widget.initialLikeCount;
    if (widget.initialReplyTo != null && widget.initialReplyTo!.isNotEmpty) {
      _replyToUsername = widget.initialReplyTo;
      _commentController.text = '@${widget.initialReplyTo} ';
    }
    _loadComments();
    _loadLikesCount();
    _ensureUserProfile();
  }

  Future<void> _loadLikesCount() async {
    if (widget.videoId == null) return;
    try {
      final likes = await _dataSource.getVideoLikes(widget.videoId!);
      if (mounted && likes.isNotEmpty) {
        setState(() {
          if (likes.length > _likeCount) {
            _likeCount = likes.length;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _ensureUserProfile() async {
    if (ProfileSyncService.instance.cachedMyProfile == null) {
      try {
        final profile = await ProfileRemoteDataSource.instance.getMyProfile();
        ProfileSyncService.instance.cachedMyProfile = profile;
        if (mounted) {
          setState(() {});
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool _canDeleteComment(CommentModel comment) {
    // 1. Author of the comment
    final isAuthor = ProfileSyncService.instance.isCurrentUser(
      username: comment.username,
      id: comment.userId.toString(),
    );
    if (isAuthor) return true;

    // 2. Creator of the post / video
    final isPostOwner = ProfileSyncService.instance.isCurrentUser(
      username: widget.videoCreatorUsername,
      id: widget.videoCreatorId?.toString(),
    );
    if (isPostOwner) return true;

    return false;
  }

  static String extractCleanCommentText(String raw) => CommentBottomSheet.extractCleanCommentText(raw);

  void _ensureHighlightedCommentExists() {
    if (widget.highlightCommentText == null || widget.highlightCommentText!.trim().isEmpty) return;
    final hasMatch = _comments.any(_isCommentHighlighted);
    if (!hasMatch) {
      String cleanText = extractCleanCommentText(widget.highlightCommentText!);
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
          videoId: widget.videoId ?? 0,
          userId: isCommenterMe ? (ProfileSyncService.instance.cachedMyProfile?.id ?? 0) : 0,
          username: commenterUsername,
          displayName: commenterUsername,
          avatarUrl: resolvedAvatar,
          content: cleanText,
          createdAt: DateTime.now(),
        ),
      );
    } else {
      // Bring their comment directly to the top so the user immediately sees it
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
    final target = extractCleanCommentText(widget.highlightCommentText!).toLowerCase().trim();
    final content = comment.content.toLowerCase().trim();
    if (target.isNotEmpty && content.isNotEmpty && (content.contains(target) || target.contains(content))) {
      return true;
    }
    // Also match if any nested reply matches
    for (final reply in comment.replies) {
      final rContent = reply.content.toLowerCase().trim();
      if (target.isNotEmpty && rContent.isNotEmpty && (rContent.contains(target) || target.contains(rContent))) {
        return true;
      }
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

  void _scrollToHighlightedComment() {
    void tryScroll() {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
      if (_highlightKey.currentContext != null) {
        Scrollable.ensureVisible(
          _highlightKey.currentContext!,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.15,
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      tryScroll();
      Future.delayed(const Duration(milliseconds: 150), tryScroll);
      Future.delayed(const Duration(milliseconds: 350), tryScroll);
    });
  }

  List<CommentModel> _getFallbackComments() {
    return [
      CommentModel(
        id: 1001,
        videoId: widget.videoId ?? 1,
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
        videoId: widget.videoId ?? 1,
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
        videoId: widget.videoId ?? 1,
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
        videoId: widget.videoId ?? 1,
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
        videoId: widget.videoId ?? 1,
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
        videoId: widget.videoId ?? 1,
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
        videoId: widget.videoId ?? 1,
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
        videoId: widget.videoId ?? 1,
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
        videoId: widget.videoId ?? 1,
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

  Future<void> _loadComments() async {
    if (widget.videoId == null) {
      if (mounted) {
        setState(() {
          _comments = _getFallbackComments();
          _ensureHighlightedCommentExists();
          _commentCount = _comments.length;
          _isLoading = false;
        });
        if (widget.highlightCommentText != null && widget.highlightCommentText!.isNotEmpty) {
          _scrollToHighlightedComment();
        }
      }
      return;
    }

    try {
      final comments = await _dataSource.getComments(widget.videoId!);
      if (mounted) {
        setState(() {
          _comments = comments.isNotEmpty
              ? List<CommentModel>.from(comments)
              : _getFallbackComments();
          _ensureHighlightedCommentExists();
          _commentCount = _comments.length;
          _isLoading = false;
        });
        if (widget.highlightCommentText != null && widget.highlightCommentText!.isNotEmpty) {
          _scrollToHighlightedComment();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _comments = _getFallbackComments();
          _ensureHighlightedCommentExists();
          _commentCount = _comments.length;
          _isLoading = false;
        });
        if (widget.highlightCommentText != null && widget.highlightCommentText!.isNotEmpty) {
          _scrollToHighlightedComment();
        }
      }
    }
  }

  Future<void> _deleteComment(CommentModel comment) async {
    if (widget.videoId == null) return;
    try {
      final success = await _dataSource.deleteComment(widget.videoId!, comment.id);
      if (success && mounted) {
        final newCount = (_commentCount - 1).clamp(0, 999999);
        setState(() {
          _comments.removeWhere((c) => c.id == comment.id);
          _commentCount = newCount;
        });
        widget.onCommentCountChanged?.call(newCount);
        ProfileSyncService.instance.notifyVideoInteraction(
          VideoInteractionEvent(
            videoId: widget.videoId!,
            commentCount: newCount,
          ),
        );
      }
    } catch (e) {
      debugPrint('[CommentBottomSheet] Delete comment error: $e');
    }
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isPosting) return;

    HapticFeedback.lightImpact();

    final targetVideoId = widget.videoId ?? 1;
    final currentParentId = _replyToParentId;
    final tempId = DateTime.now().millisecondsSinceEpoch;

    // Current authenticated user details
    final myUser = ProfileSyncService.instance.cachedMyProfile;
    final myDisplayName = ProfileSyncService.instance.currentUserDisplayName;
    final myUsername = ProfileSyncService.instance.currentUsername;
    final myAvatar = ProfileSyncService.instance.currentUserAvatar;

    final optimisticComment = CommentModel(
      id: tempId,
      videoId: targetVideoId,
      userId: myUser?.id ?? 0,
      username: myUsername,
      displayName: myDisplayName,
      avatarUrl: myAvatar,
      content: text,
      parentId: currentParentId,
      createdAt: DateTime.now(),
    );

    // 1. IMMEDIATELY update UI: insert comment, clear text, update counters
    setState(() {
      _isPosting = true;
      if (currentParentId != null) {
        final parentIdx = _comments.indexWhere((c) => c.id == currentParentId);
        if (parentIdx != -1) {
          final parent = _comments[parentIdx];
          final updatedReplies = List<CommentModel>.from(parent.replies)..add(optimisticComment);
          _comments[parentIdx] = parent.copyWith(replies: updatedReplies);
        } else {
          _comments.insert(0, optimisticComment);
        }
      } else {
        _comments.insert(0, optimisticComment);
      }
      _commentCount++;
      _commentController.clear();
      _replyToParentId = null;
      _replyToUsername = null;
    });

    // 2. IMMEDIATELY notify video feed card and global profile service
    widget.onCommentCountChanged?.call(_commentCount);
    ProfileSyncService.instance.notifyVideoInteraction(
      VideoInteractionEvent(
        videoId: targetVideoId,
        commentCount: _commentCount,
      ),
    );

    // 3. Post to backend in background and sync real server ID
    try {
      final realComment = await _dataSource.postComment(
        targetVideoId,
        text,
        parentId: currentParentId,
      );

      if (mounted) {
        setState(() {
          _isPosting = false;
          if (currentParentId != null) {
            final parentIdx = _comments.indexWhere((c) => c.id == currentParentId);
            if (parentIdx != -1) {
              final parent = _comments[parentIdx];
              final replies = parent.replies.map((r) => r.id == tempId ? realComment : r).toList();
              _comments[parentIdx] = parent.copyWith(replies: replies);
            }
          } else {
            final idx = _comments.indexWhere((c) => c.id == tempId);
            if (idx != -1) {
              _comments[idx] = realComment;
            }
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  void _onReplyTap(CommentModel comment) {
    setState(() {
      _replyToParentId = comment.id;
      _replyToUsername = comment.displayName.isNotEmpty ? comment.displayName : comment.username;
      _commentController.text = '@$_replyToUsername ';
      _commentController.selection = TextSelection.fromPosition(
        TextPosition(offset: _commentController.text.length),
      );
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header Tabs matching screenshot
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 8.0, top: 4.0, bottom: 4.0),
            child: Row(
              children: [
                // Comments Tab (Active)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'Comments $_commentCount',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      width: 38,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                // Likes Tab (Tappable)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    Navigator.pop(context);
                    if (widget.videoId != null) {
                      VideoLikesBottomSheet.show(
                        context,
                        videoId: widget.videoId!,
                        initialLikeCount: _likeCount,
                        initialCommentCount: _commentCount,
                      );
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Likes $_likeCount',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF8E8E93),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
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
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),

          // Comments List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : _comments.isEmpty
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
                        controller: _scrollController,
                        itemCount: _comments.length,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          final canDelete = _canDeleteComment(comment);
                          final isHighlighted = _isCommentHighlighted(comment);
                          return _CommentCard(
                            comment: comment,
                            isHighlighted: isHighlighted,
                            highlightKey: isHighlighted ? _highlightKey : null,
                            highlightText: widget.highlightCommentText,
                            onReply: () => _onReplyTap(comment),
                            onDelete: canDelete ? () => _deleteComment(comment) : null,
                          );
                        },
                      ),
          ),

          // Reply Indicator Banner
          if (_replyToUsername != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: const Color(0xFF1E1E24),
              child: Row(
                children: [
                  Text(
                    'Replying to @$_replyToUsername',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _replyToParentId = null;
                        _replyToUsername = null;
                        _commentController.clear();
                      });
                    },
                    child: const Icon(Icons.close, color: Colors.white54, size: 16),
                  ),
                ],
              ),
            ),

          // Bottom Input Bar
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom: 10 + MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF161616),
              border: Border(top: BorderSide(color: Colors.white10)),
            ),
            child: Row(
              children: [
                // Active Account Profile Avatar
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PublicProfileScreen(
                          displayName: ProfileSyncService.instance.currentUserDisplayName,
                          username: ProfileSyncService.instance.currentUsername,
                          avatarUrl: ProfileSyncService.instance.currentUserAvatar,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 1.2),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        ProfileSyncService.instance.currentUserAvatar,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFF2C2C2C),
                          child: const Icon(
                            Icons.person_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Interactive Text Input Field
                Expanded(
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(21),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            focusNode: _focusNode,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Add comment...',
                              hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
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
                            _commentController.text += '😊';
                          },
                          child: Icon(
                            Icons.emoji_emotions_outlined,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            _commentController.text += '@';
                          },
                          child: Icon(
                            Icons.alternate_email_rounded,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 19,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Post Button
                GestureDetector(
                  onTap: _isPosting ? null : _submitComment,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: _isPosting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Post',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatefulWidget {
  final CommentModel comment;
  final bool isHighlighted;
  final GlobalKey? highlightKey;
  final String? highlightText;
  final VoidCallback onReply;
  final VoidCallback? onDelete;

  const _CommentCard({
    required this.comment,
    this.isHighlighted = false,
    this.highlightKey,
    this.highlightText,
    required this.onReply,
    this.onDelete,
  });

  @override
  State<_CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<_CommentCard> {
  bool _showReplies = false;
  bool _isLiked = false;
  bool _isDisliked = false;
  int _likes = 0;

  @override
  void initState() {
    super.initState();
    _likes = widget.comment.likesCount;
    _isDisliked = widget.comment.isDisliked;
    _checkAndExpandReplies();
  }

  @override
  void didUpdateWidget(covariant _CommentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.isHighlighted && !oldWidget.isHighlighted) ||
        (widget.highlightText != oldWidget.highlightText)) {
      _checkAndExpandReplies();
    }
  }

  void _checkAndExpandReplies() {
    final target = widget.highlightText != null
        ? CommentBottomSheet.extractCleanCommentText(widget.highlightText!).toLowerCase().trim()
        : '';
    final hasMatchingReply = target.isNotEmpty &&
        widget.comment.replies.any((r) {
          final rContent = r.content.toLowerCase().trim();
          return rContent.contains(target) || target.contains(rContent);
        });
    if (hasMatchingReply || (widget.isHighlighted && widget.comment.replies.isNotEmpty)) {
      _showReplies = true;
    }
  }

  String _resolveAvatar(CommentModel c) {
    final isUserMe = ProfileSyncService.instance.isCurrentUser(
      username: c.username,
      id: c.userId.toString(),
    );
    if (isUserMe) {
      return ProfileSyncService.instance.currentUserAvatar;
    }
    final raw = c.avatarUrl?.trim() ?? '';
    final clean = c.username.toLowerCase().replaceAll('@', '').trim();
    if (raw.isNotEmpty &&
        !raw.contains('535713875002') &&
        !(raw.contains('534528741775') && clean != 'mongkol')) {
      return raw;
    }
    return ProfileSyncService.getDefaultAvatarForUser(c.username);
  }

  void _navigateToProfile(BuildContext context) {
    final comment = widget.comment;
    final rawName = comment.displayName.isNotEmpty ? comment.displayName : comment.username;
    final cleanUsername = comment.username.replaceAll('@', '').trim();
    final avatar = _resolveAvatar(comment);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          userId: comment.userId > 0 ? comment.userId : null,
          displayName: rawName,
          username: cleanUsername,
          avatarUrl: avatar,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final avatar = _resolveAvatar(comment);

    final cleanHighlight = widget.highlightText != null
        ? CommentBottomSheet.extractCleanCommentText(widget.highlightText!).toLowerCase().trim()
        : '';
    final hasMatchingReply = cleanHighlight.isNotEmpty &&
        comment.replies.any((r) {
          final rContent = r.content.toLowerCase().trim();
          return rContent.contains(cleanHighlight) || cleanHighlight.contains(rContent);
        });

    final contentWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              GestureDetector(
                onTap: () => _navigateToProfile(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white12, width: 1),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      avatar,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[850],
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white60,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => _navigateToProfile(context),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              comment.displayName.isNotEmpty ? comment.displayName : comment.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '@${comment.username.replaceAll('@', '')}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white38,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (comment.content.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        comment.content,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                    if (comment.attachmentUrl != null && comment.attachmentUrl!.isNotEmpty) ...[
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
                            comment.attachmentUrl!,
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
                          comment.timeAgo,
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: widget.onReply,
                          child: const Text(
                            'Reply',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (widget.onDelete != null) ...[
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: widget.onDelete,
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.redAccent.withValues(alpha: 0.8),
                                fontSize: 12,
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

              // Like Heart & Thumbs Down Dislike
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                child: Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        setState(() {
                          _isLiked = !_isLiked;
                          _likes += _isLiked ? 1 : -1;
                          if (_isLiked) _isDisliked = false;
                        });
                      },
                      child: Column(
                        children: [
                          Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked ? const Color(0xFFFE2C55) : Colors.white54,
                            size: 16,
                          ),
                          if (_likes > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              '$_likes',
                              style: const TextStyle(color: Colors.white54, fontSize: 11),
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
                          _isDisliked = !_isDisliked;
                          if (_isDisliked && _isLiked) {
                            _isLiked = false;
                            _likes = (_likes - 1).clamp(0, 999999);
                          }
                        });
                      },
                      child: Icon(
                        _isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                        color: _isDisliked ? Colors.white70 : Colors.white38,
                        size: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Nested Replies Toggle
          if (comment.replies.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 48.0, top: 8.0),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showReplies = !_showReplies;
                  });
                },
                child: Row(
                  children: [
                    Container(width: 24, height: 1, color: Colors.white24),
                    const SizedBox(width: 8),
                    Text(
                      _showReplies
                          ? 'Hide replies'
                          : 'View ${comment.replies.length} ${comment.replies.length == 1 ? "reply" : "replies"}',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _showReplies ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.white54,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            if (_showReplies)
              Padding(
                padding: const EdgeInsets.only(left: 48.0, top: 8.0),
                child: Column(
                  children: comment.replies.map((reply) {
                    final replyAvatar = _resolveAvatar(reply);
                    final rName = reply.displayName.isNotEmpty ? reply.displayName : reply.username;
                    final rClean = reply.username.replaceAll('@', '').trim();
                    final rContent = reply.content.toLowerCase().trim();
                    final isThisReplyHighlighted = cleanHighlight.isNotEmpty &&
                        (rContent.contains(cleanHighlight) || cleanHighlight.contains(rContent));

                    final replyRow = Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PublicProfileScreen(
                                  userId: reply.userId > 0 ? reply.userId : null,
                                  displayName: rName,
                                  username: rClean,
                                  avatarUrl: replyAvatar,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white10, width: 1),
                            ),
                            child: ClipOval(
                              child: Image.network(
                                replyAvatar,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey[850],
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: Colors.white60,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PublicProfileScreen(
                                        userId: reply.userId > 0 ? reply.userId : null,
                                        displayName: rName,
                                        username: rClean,
                                        avatarUrl: replyAvatar,
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        rName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          color: Colors.white,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '@$rClean',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        color: Colors.white38,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                reply.content,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    if (isThisReplyHighlighted) {
                      return Container(
                        key: widget.highlightKey,
                        margin: const EdgeInsets.symmetric(vertical: 4.0),
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: const Color(0x1F2F80ED),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF2F80ED), width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.reply_rounded, size: 14, color: Color(0xFF2F80ED)),
                                SizedBox(width: 4),
                                Text(
                                  'Replied comment',
                                  style: TextStyle(
                                    color: Color(0xFF2F80ED),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            replyRow,
                          ],
                        ),
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: replyRow,
                    );
                  }).toList(),
                ),
              ),
          ],
        ],
      ),
    );

    if (widget.isHighlighted) {
      return Container(
        key: widget.highlightKey,
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: const Color(0x1F2F80ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2F80ED), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 14.0, top: 8.0, bottom: 2.0),
              child: Row(
                children: [
                  Icon(
                    hasMatchingReply ? Icons.reply_rounded : Icons.stars_rounded,
                    size: 14,
                    color: const Color(0xFF2F80ED),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasMatchingReply ? 'Replied thread' : 'Highlighted comment',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF2F80ED),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            contentWidget,
          ],
        ),
      );
    }

    return contentWidget;
  }
}
