import 'package:flutter/material.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../data/datasources/feed_remote_data_source.dart';
import '../../data/models/comment_model.dart';

class CommentBottomSheet extends StatefulWidget {
  final int? videoId;
  final int initialCommentCount;
  final ValueChanged<int>? onCommentCountChanged;

  const CommentBottomSheet({
    super.key,
    this.videoId,
    this.initialCommentCount = 0,
    this.onCommentCountChanged,
  });

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final FeedRemoteDataSource _dataSource = FeedRemoteDataSource();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  List<CommentModel> _comments = [];
  bool _isLoading = true;
  bool _isPosting = false;
  int _commentCount = 0;
  int? _replyToParentId;
  String? _replyToUsername;

  @override
  void initState() {
    super.initState();
    _commentCount = widget.initialCommentCount;
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    if (widget.videoId == null) {
      _loadFallbackMock();
      return;
    }

    try {
      final comments = await _dataSource.getComments(widget.videoId!);
      if (mounted) {
        setState(() {
          if (comments.isNotEmpty) {
            _comments = comments;
            _commentCount = comments.length;
          } else {
            _loadFallbackMock();
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        _loadFallbackMock();
      }
    }
  }

  void _loadFallbackMock() {
    if (!mounted) return;
    setState(() {
      _comments = [
        CommentModel(
          id: 1,
          videoId: widget.videoId ?? 1,
          userId: 101,
          username: 'Ractz',
          displayName: 'Ractz',
          avatarUrl: 'https://i.pravatar.cc/150?img=14',
          content: 'លេងអន់ចឹងលុប game ចោលទៅ ah bot',
          createdAt: DateTime.now().subtract(const Duration(minutes: 9)),
        ),
        CommentModel(
          id: 2,
          videoId: widget.videoId ?? 1,
          userId: 102,
          username: 'Hengg',
          displayName: 'Hengg',
          avatarUrl: 'https://i.pravatar.cc/150?img=11',
          content: 'Your Product so good😘',
          createdAt: DateTime.now().subtract(const Duration(minutes: 32)),
        ),
        CommentModel(
          id: 3,
          videoId: widget.videoId ?? 1,
          userId: 103,
          username: 'សំពៀន',
          displayName: 'សំពៀន',
          avatarUrl: 'https://i.pravatar.cc/150?img=15',
          content: 'មុខភ័យសង្ឃឹមជួយ',
          createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        ),
      ];
      if (_commentCount == 0) {
        _commentCount = _comments.length;
      }
      _isLoading = false;
    });
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isPosting) return;

    setState(() {
      _isPosting = true;
    });

    final targetVideoId = widget.videoId ?? 1;

    try {
      final newComment = await _dataSource.postComment(
        targetVideoId,
        text,
        parentId: _replyToParentId,
      );

      if (mounted) {
        setState(() {
          if (_replyToParentId != null) {
            // Find parent and append reply
            final parentIdx = _comments.indexWhere((c) => c.id == _replyToParentId);
            if (parentIdx != -1) {
              final parent = _comments[parentIdx];
              final updatedReplies = List<CommentModel>.from(parent.replies)..add(newComment);
              _comments[parentIdx] = parent.copyWith(replies: updatedReplies);
            } else {
              _comments.insert(0, newComment);
            }
          } else {
            _comments.insert(0, newComment);
          }
          _commentCount++;
          _commentController.clear();
          _replyToParentId = null;
          _replyToUsername = null;
          _isPosting = false;
        });

        widget.onCommentCountChanged?.call(_commentCount);
      }
    } catch (e) {
      // Local optimistic fallback if offline
      if (mounted) {
        final fallbackComment = CommentModel(
          id: DateTime.now().millisecondsSinceEpoch,
          videoId: targetVideoId,
          userId: 999,
          username: 'me',
          displayName: 'You',
          content: text,
          parentId: _replyToParentId,
          createdAt: DateTime.now(),
        );

        setState(() {
          _comments.insert(0, fallbackComment);
          _commentCount++;
          _commentController.clear();
          _replyToParentId = null;
          _replyToUsername = null;
          _isPosting = false;
        });

        widget.onCommentCountChanged?.call(_commentCount);
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
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_commentCount comments',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.sort, color: Colors.white70, size: 24),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.white70, size: 24),
                    ),
                  ],
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
                : ListView.builder(
                    itemCount: _comments.length,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      return _CommentCard(
                        comment: _comments[index],
                        onReply: () => _onReplyTap(_comments[index]),
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
                // User Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=50'),
                  backgroundColor: Colors.blueAccent,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blueAccent, width: 2),
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
                        Icon(
                          Icons.emoji_emotions_outlined,
                          color: Colors.white.withValues(alpha: 0.8),
                          size: 20,
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
  final VoidCallback onReply;

  const _CommentCard({
    required this.comment,
    required this.onReply,
  });

  @override
  State<_CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<_CommentCard> {
  bool _showReplies = false;
  bool _isLiked = false;
  int _likes = 0;

  void _navigateToProfile(BuildContext context) {
    final comment = widget.comment;
    final rawName = comment.displayName.isNotEmpty ? comment.displayName : comment.username;
    final cleanUsername = comment.username.replaceAll('@', '').trim();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          displayName: rawName,
          username: cleanUsername,
          avatarUrl: comment.avatarUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final avatar = comment.avatarUrl ?? 'https://i.pravatar.cc/150?img=12';

    return Padding(
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
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: NetworkImage(avatar),
                  backgroundColor: Colors.grey[800],
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
                      child: Text(
                        comment.displayName.isNotEmpty ? comment.displayName : comment.username,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
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
                      ],
                    ),
                  ],
                ),
              ),

              // Like Heart
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isLiked = !_isLiked;
                    _likes += _isLiked ? 1 : -1;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Column(
                    children: [
                      Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isLiked ? Colors.red : Colors.white54,
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
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(
                              reply.avatarUrl ?? 'https://i.pravatar.cc/150?img=20',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reply.displayName.isNotEmpty ? reply.displayName : reply.username,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
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
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
