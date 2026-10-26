import '../../../feed/data/models/video_model.dart';

class TrendingVideo {
  final String id;
  final String thumbnailUrl;
  final String views;
  final String title;
  final String authorUsername;
  final String authorName;
  final List<String> tags;
  final String videoUrl;
  final String caption;
  final int? creatorId;
  final String? avatarUrl;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final int saveCount;
  final String musicTitle;

  const TrendingVideo({
    required this.id,
    required this.thumbnailUrl,
    required this.views,
    this.title = '',
    this.authorUsername = '',
    this.authorName = '',
    this.tags = const [],
    this.videoUrl = '',
    this.caption = '',
    this.creatorId,
    this.avatarUrl,
    this.viewCount = 0,
    this.likeCount = 0,
    this.commentCount = 0,
    this.saveCount = 0,
    this.musicTitle = 'Original Sound',
  });

  /// Converts this search result video into a full VideoModel ready for playback in VideoFeedPage
  VideoModel toVideoModel() {
    final int vidId = int.tryParse(id) ?? id.hashCode;
    final int authorId = creatorId ?? (vidId > 0 ? vidId : 1);
    final String cleanUsername = authorUsername.replaceAll('@', '');
    final String cleanDisplayName = authorName.isNotEmpty ? authorName : cleanUsername;

    return VideoModel(
      id: vidId,
      creatorId: authorId,
      username: cleanUsername,
      displayName: cleanDisplayName,
      avatarUrl: avatarUrl,
      caption: caption.isNotEmpty ? caption : title,
      videoUrl: videoUrl.isNotEmpty ? videoUrl : (thumbnailUrl.endsWith('.mp4') ? thumbnailUrl : 'assets/videos/vid1.mp4'),
      thumbnailUrl: thumbnailUrl,
      musicTitle: musicTitle,
      viewCount: viewCount > 0 ? viewCount : 1200,
      likeCount: likeCount,
      commentCount: commentCount,
      saveCount: saveCount,
      tags: tags,
    );
  }
}

class SearchAccount {
  final String id;
  final String username;
  final String displayName;
  final String followersCount;
  final String avatarUrl;
  final bool isFollowed;
  final bool followsYou;
  final bool isVerified;

  const SearchAccount({
    required this.id,
    required this.username,
    this.displayName = '',
    required this.followersCount,
    required this.avatarUrl,
    this.isFollowed = false,
    this.followsYou = false,
    this.isVerified = false,
  });

  bool get isFriend => isFollowed && followsYou;

  SearchAccount copyWith({
    String? id,
    String? username,
    String? displayName,
    String? followersCount,
    String? avatarUrl,
    bool? isFollowed,
    bool? followsYou,
    bool? isVerified,
  }) {
    return SearchAccount(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      followersCount: followersCount ?? this.followersCount,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isFollowed: isFollowed ?? this.isFollowed,
      followsYou: followsYou ?? this.followsYou,
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
