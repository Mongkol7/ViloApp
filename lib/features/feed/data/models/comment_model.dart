class CommentModel {
  final int id;
  final int videoId;
  final int userId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final int? parentId;
  final String content;
  final DateTime? createdAt;
  final List<CommentModel> replies;
  final int likesCount;

  const CommentModel({
    required this.id,
    required this.videoId,
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.parentId,
    required this.content,
    this.createdAt,
    this.replies = const [],
    this.likesCount = 0,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    var rawReplies = json['replies'];
    List<CommentModel> repliesList = [];
    if (rawReplies is List) {
      repliesList = rawReplies
          .whereType<Map<String, dynamic>>()
          .map((r) => CommentModel.fromJson(r))
          .toList();
    }

    return CommentModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      videoId: (json['videoId'] as num?)?.toInt() ?? 0,
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      username: json['username']?.toString() ?? 'User',
      displayName: json['displayName']?.toString() ?? 'User',
      avatarUrl: json['avatarUrl']?.toString(),
      parentId: (json['parentId'] as num?)?.toInt(),
      content: json['content']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      replies: repliesList,
      likesCount: (json['likesCount'] as num?)?.toInt() ??
          (json['likes'] as num?)?.toInt() ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoId': videoId,
      'userId': userId,
      'username': username,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'parentId': parentId,
      'content': content,
      'createdAt': createdAt?.toIso8601String(),
      'replies': replies.map((r) => r.toJson()).toList(),
      'likesCount': likesCount,
    };
  }

  CommentModel copyWith({
    int? id,
    int? videoId,
    int? userId,
    String? username,
    String? displayName,
    String? avatarUrl,
    int? parentId,
    String? content,
    DateTime? createdAt,
    List<CommentModel>? replies,
    int? likesCount,
  }) {
    return CommentModel(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      parentId: parentId ?? this.parentId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      replies: replies ?? this.replies,
      likesCount: likesCount ?? this.likesCount,
    );
  }

  String get timeAgo {
    if (createdAt == null) return 'just now';
    final diff = DateTime.now().difference(createdAt!);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo';
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'just now';
  }
}
