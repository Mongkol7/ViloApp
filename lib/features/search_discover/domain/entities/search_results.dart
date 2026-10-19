class TrendingVideo {
  final String id;
  final String thumbnailUrl;
  final String views;
  final String title;

  const TrendingVideo({
    required this.id,
    required this.thumbnailUrl,
    required this.views,
    this.title = '',
  });
}

class SearchAccount {
  final String id;
  final String username;
  final String displayName;
  final String followersCount;
  final String avatarUrl;
  final bool isFollowed;
  final bool isVerified;

  const SearchAccount({
    required this.id,
    required this.username,
    this.displayName = '',
    required this.followersCount,
    required this.avatarUrl,
    this.isFollowed = false,
    this.isVerified = false,
  });

  SearchAccount copyWith({
    String? id,
    String? username,
    String? displayName,
    String? followersCount,
    String? avatarUrl,
    bool? isFollowed,
    bool? isVerified,
  }) {
    return SearchAccount(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      followersCount: followersCount ?? this.followersCount,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isFollowed: isFollowed ?? this.isFollowed,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}

class SearchSound {
  final String id;
  final String title;
  final String videosCount;
  final String iconType; // 'music', 'equalizer', 'ambience'
  final bool isSaved;
  final String artist;
  final String audioUrl;
  final String albumArtUrl;

  const SearchSound({
    required this.id,
    required this.title,
    required this.videosCount,
    required this.iconType,
    this.isSaved = false,
    this.artist = 'Original Artist',
    this.audioUrl = '',
    this.albumArtUrl = '',
  });

  SearchSound copyWith({
    String? id,
    String? title,
    String? videosCount,
    String? iconType,
    bool? isSaved,
    String? artist,
    String? audioUrl,
    String? albumArtUrl,
  }) {
    return SearchSound(
      id: id ?? this.id,
      title: title ?? this.title,
      videosCount: videosCount ?? this.videosCount,
      iconType: iconType ?? this.iconType,
      isSaved: isSaved ?? this.isSaved,
      artist: artist ?? this.artist,
      audioUrl: audioUrl ?? this.audioUrl,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
    );
  }
}
