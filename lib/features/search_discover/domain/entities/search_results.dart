class TrendingVideo {
  final String id;
  final String thumbnailUrl;
  final String views;

  const TrendingVideo({
    required this.id,
    required this.thumbnailUrl,
    required this.views,
  });
}

class SearchAccount {
  final String id;
  final String username;
  final String followersCount;
  final String avatarUrl;
  final bool isFollowed;

  const SearchAccount({
    required this.id,
    required this.username,
    required this.followersCount,
    required this.avatarUrl,
    this.isFollowed = false,
  });

  SearchAccount copyWith({
    String? id,
    String? username,
    String? followersCount,
    String? avatarUrl,
    bool? isFollowed,
  }) {
    return SearchAccount(
      id: id ?? this.id,
      username: username ?? this.username,
      followersCount: followersCount ?? this.followersCount,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isFollowed: isFollowed ?? this.isFollowed,
    );
  }
}

class SearchSound {
  final String id;
  final String title;
  final String videosCount;
  final String iconType; // 'music', 'equalizer', 'ambience'
  final bool isSaved;

  const SearchSound({
    required this.id,
    required this.title,
    required this.videosCount,
    required this.iconType,
    this.isSaved = false,
  });

  SearchSound copyWith({
    String? id,
    String? title,
    String? videosCount,
    String? iconType,
    bool? isSaved,
  }) {
    return SearchSound(
      id: id ?? this.id,
      title: title ?? this.title,
      videosCount: videosCount ?? this.videosCount,
      iconType: iconType ?? this.iconType,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}
