import 'package:flutter/material.dart';

class CommentBottomSheet extends StatefulWidget {
  final String? initialReplyTo;
  final String? highlightCommentText;

  const CommentBottomSheet({
    super.key,
    this.initialReplyTo,
    this.highlightCommentText,
  });

  @override
  State<CommentBottomSheet> createState() => _CommentBottomSheetState();
}

class _CommentBottomSheetState extends State<CommentBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  String? _replyingTo;
  late List<Map<String, dynamic>> _comments;

  @override
  void initState() {
    super.initState();
    _comments = [
      if (widget.highlightCommentText != null && widget.highlightCommentText!.isNotEmpty)
        {
          'id': 'c_highlight',
          'name': widget.initialReplyTo ?? 'Viewer',
          'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&auto=format&fit=crop&q=80',
          'text': widget.highlightCommentText!,
          'time': 'Just now',
          'likes': 12,
          'isLiked': false,
          'replies': <Map<String, dynamic>>[],
          'isHighlighted': true,
        },
      {
        'id': 'c1',
        'name': 'Sarah Jenkins',
        'avatar': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150&auto=format&fit=crop&q=80',
        'text': 'This aesthetic is unmatched 🔥',
        'time': '25m',
        'likes': 34,
        'isLiked': false,
        'replies': <Map<String, dynamic>>[
          {
            'name': 'Thoeung Sereymongkol',
            'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
            'text': 'Thank you Sarah! Appreciate the support 🙌',
            'time': '10m',
            'likes': 3,
            'isLiked': false,
          }
        ],
        'isHighlighted': false,
      },
      {
        'id': 'c2',
        'name': 'Liam Vance',
        'avatar': 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150&auto=format&fit=crop&q=80',
        'text': 'Where was this taken? Incredible shot!',
        'time': '1h',
        'likes': 18,
        'isLiked': false,
        'replies': <Map<String, dynamic>>[],
        'isHighlighted': false,
      },
      {
        'id': 'c3',
        'name': 'Ractz',
        'avatar': 'https://i.pravatar.cc/150?img=14',
        'text': 'Super clean video transitions and color grading 🎥✨',
        'time': '2h',
        'likes': 8,
        'isLiked': false,
        'replies': <Map<String, dynamic>>[],
        'isHighlighted': false,
      },
      {
        'id': 'c4',
        'name': 'Hengg',
        'avatar': 'https://i.pravatar.cc/150?img=11',
        'text': 'Your Product so good😘',
        'time': '3h',
        'likes': 4,
        'isLiked': false,
        'replies': <Map<String, dynamic>>[],
        'isHighlighted': false,
      },
    ];

    if (widget.initialReplyTo != null) {
      _replyingTo = widget.initialReplyTo;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startReply(String username) {
    setState(() {
      _replyingTo = username;
    });
    _focusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  void _postComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      if (_replyingTo != null) {
        // Add as reply to target comment or top comment
        final replyTarget = _replyingTo!;
        final targetIndex = _comments.indexWhere((c) => c['name'] == replyTarget);
        final newReply = {
          'name': 'Thoeung Sereymongkol',
          'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
          'text': '@$replyTarget $text',
          'time': 'Just now',
          'likes': 0,
          'isLiked': false,
        };

        if (targetIndex != -1) {
          final replies = List<Map<String, dynamic>>.from(_comments[targetIndex]['replies'] as List);
          replies.add(newReply);
          _comments[targetIndex]['replies'] = replies;
        } else {
          _comments.insert(0, {
            'id': 'c_${DateTime.now().millisecondsSinceEpoch}',
            'name': 'Thoeung Sereymongkol',
            'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
            'text': '@$replyTarget $text',
            'time': 'Just now',
            'likes': 0,
            'isLiked': false,
            'replies': <Map<String, dynamic>>[],
            'isHighlighted': true,
          });
        }
        _replyingTo = null;
      } else {
        // New top-level comment
        _comments.insert(0, {
          'id': 'c_${DateTime.now().millisecondsSinceEpoch}',
          'name': 'Thoeung Sereymongkol',
          'avatar': 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
          'text': text,
          'time': 'Just now',
          'likes': 0,
          'isLiked': false,
          'replies': <Map<String, dynamic>>[],
          'isHighlighted': true,
        });
      }

      _commentController.clear();
    });

    // Scroll to top to see newly created comment
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleLike(Map<String, dynamic> comment) {
    setState(() {
      final isLiked = comment['isLiked'] == true;
      comment['isLiked'] = !isLiked;
      final currentLikes = (comment['likes'] as num?)?.toInt() ?? 0;
      comment['likes'] = isLiked ? (currentLikes - 1).clamp(0, 999999) : currentLikes + 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF141416),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header Drag Handle
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_comments.length} comments',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.sort_rounded, color: Colors.white70, size: 22),
                      onPressed: () {},
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 22),
                      onPressed: () => Navigator.pop(context),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),

          // Comments List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _comments.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final comment = _comments[index];
                return _buildCommentTile(comment);
              },
            ),
          ),

          // Replying banner
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF1F1F24),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded, color: Color(0xFF2F80ED), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Replying to @$_replyingTo',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF2F80ED),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: const Icon(Icons.close_rounded, color: Colors.white54, size: 18),
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
              bottom: 12 + bottomInset,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF18181C),
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
            ),
            child: Row(
              children: [
                // User Avatar
                CircleAvatar(
                  radius: 17,
                  backgroundImage: const NetworkImage(
                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
                  ),
                  backgroundColor: const Color(0xFF2F80ED),
                ),
                const SizedBox(width: 12),

                // Real Text Field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF26262B),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            focusNode: _focusNode,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            onSubmitted: (_) => _postComment(),
                            decoration: InputDecoration(
                              hintText: _replyingTo != null
                                  ? 'Reply to @$_replyingTo...'
                                  : 'Add a comment...',
                              hintStyle: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 13,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.emoji_emotions_outlined,
                          color: Colors.white.withValues(alpha: 0.6),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Post Button
                TextButton(
                  onPressed: _postComment,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Post',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF2F80ED),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
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

  Widget _buildCommentTile(Map<String, dynamic> data) {
    final bool isHighlighted = data['isHighlighted'] == true;
    final bool isLiked = data['isLiked'] == true;
    final int likes = (data['likes'] as num?)?.toInt() ?? 0;
    final List<Map<String, dynamic>> replies =
        (data['replies'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return Container(
      color: isHighlighted ? const Color(0xFF2F80ED).withValues(alpha: 0.08) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(data['avatar'] ?? ''),
                backgroundColor: const Color(0xFF2A2A30),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author username
                    Text(
                      data['name'] ?? 'User',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Comment Text
                    Text(
                      data['text'] ?? '',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Row (Time, Reply Action)
                    Row(
                      children: [
                        Text(
                          data['time'] ?? 'Just now',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _startReply(data['name'] ?? 'User'),
                          child: const Text(
                            'Reply',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF2F80ED),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Like Button
              GestureDetector(
                onTap: () => _toggleLike(data),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isLiked ? const Color(0xFFFE2C55) : Colors.white38,
                      size: 18,
                    ),
                    if (likes > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '$likes',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: isLiked ? const Color(0xFFFE2C55) : Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          // Replies list if any
          if (replies.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 8),
              child: Column(
                children: replies.map((reply) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundImage: NetworkImage(reply['avatar'] ?? ''),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reply['name'] ?? 'User',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                reply['text'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
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
