class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String albumArtUrl;
  final String? reelsCount;
  final String? duration;
  final bool isExplicit;
  final String? rankType; // '1', '2', 'up', 'new', 'none'
  final int? rankNumber;
  final bool isSaved;

  const MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.albumArtUrl,
    this.reelsCount,
    this.duration,
    this.isExplicit = false,
    this.rankType,
    this.rankNumber,
    this.isSaved = false,
  });

  MusicTrack copyWith({
    String? id,
    String? title,
    String? artist,
    String? albumArtUrl,
    String? reelsCount,
    String? duration,
    bool? isExplicit,
    String? rankType,
    int? rankNumber,
    bool? isSaved,
  }) {
    return MusicTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
      reelsCount: reelsCount ?? this.reelsCount,
      duration: duration ?? this.duration,
      isExplicit: isExplicit ?? this.isExplicit,
      rankType: rankType ?? this.rankType,
      rankNumber: rankNumber ?? this.rankNumber,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}
