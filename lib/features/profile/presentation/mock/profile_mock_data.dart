import '../../../../core/network/api_client.dart';

/// A single stat displayed in the profile header (e.g. Followers: 12800).
class ProfileStat {
  final String label;
  final int value;

  const ProfileStat({required this.label, required this.value});
}

/// A track shown in the "Sounds" tab.
class SoundTrack {
  final int? id;
  final String coverUrl;
  final String title;
  final String usedByLabel; // pre-formatted, e.g. "260.1K"
  final String? artist;
  final String? audioUrl;
  final int? creatorId;
  final String? creatorUsername;
  final int similarCount;

  const SoundTrack({
    this.id,
    required this.coverUrl,
    required this.title,
    required this.usedByLabel,
    this.artist,
    this.audioUrl,
    this.creatorId,
    this.creatorUsername,
    this.similarCount = 0,
  });

  static String resolveUrl(String? url) {
    if (url == null || url.trim().isEmpty) return '';
    final clean = url.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://') || clean.startsWith('assets/')) {
      return clean;
    }
    final host = ApiClient.baseUrl.replaceAll('/api/v1', '');
    if (clean.startsWith('/')) {
      return '$host$clean';
    }
    return '$host/$clean';
  }

  SoundTrack copyWith({
    int? id,
    String? coverUrl,
    String? title,
    String? usedByLabel,
    String? artist,
    String? audioUrl,
    int? creatorId,
    String? creatorUsername,
    int? similarCount,
  }) {
    return SoundTrack(
      id: id ?? this.id,
      coverUrl: coverUrl ?? this.coverUrl,
      title: title ?? this.title,
      usedByLabel: usedByLabel ?? this.usedByLabel,
      artist: artist ?? this.artist,
      audioUrl: audioUrl ?? this.audioUrl,
      creatorId: creatorId ?? this.creatorId,
      creatorUsername: creatorUsername ?? this.creatorUsername,
      similarCount: similarCount ?? this.similarCount,
    );
  }

  factory SoundTrack.fromJson(Map<String, dynamic> json) {
    final rawUsage = json['usageCount'] ?? json['usage_count'];
    String formatted = json['usedByLabel'] ?? json['formattedUsageCount'] ?? '';
    if (formatted.isEmpty && rawUsage != null) {
      final count = rawUsage is int ? rawUsage : int.tryParse(rawUsage.toString()) ?? 0;
      formatted = count >= 1000 ? '${(count / 1000).toStringAsFixed(1)}K' : '$count videos';
    }
    final rawCover = (json['coverUrl'] != null && json['coverUrl'].toString().isNotEmpty)
        ? json['coverUrl'].toString()
        : ((json['albumArtUrl'] != null && json['albumArtUrl'].toString().isNotEmpty)
            ? json['albumArtUrl'].toString()
            : 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=200');
    final rawAudio = json['audioUrl']?.toString();

    return SoundTrack(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      coverUrl: resolveUrl(rawCover),
      title: json['title']?.toString() ?? 'Original Sound',
      usedByLabel: formatted.isNotEmpty ? formatted : '1 video',
      artist: json['artist']?.toString() ?? json['creatorUsername']?.toString(),
      audioUrl: rawAudio != null ? resolveUrl(rawAudio) : null,
      creatorId: json['creatorId'] is int ? json['creatorId'] : int.tryParse(json['creatorId']?.toString() ?? ''),
      creatorUsername: json['creatorUsername']?.toString() ?? json['artist']?.toString(),
      similarCount: 0,
    );
  }
}

/// A product shown in the "Shop" tab.
class ShopProduct {
  final String imageUrl;
  final String name;
  final String price;

  const ShopProduct({
    required this.imageUrl,
    required this.name,
    required this.price,
  });
}

/// Static placeholder data for the Profile main screen.
class ProfileMockData {
  ProfileMockData._();

  static const String name = 'Thoeung Sereymongkol';
  static const String username = 'mongkol';
  static const String bio =
      'Flutter & Spring Boot Engineer | Vilo Core Team 🚀 Building in public';
  static const String avatarUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80';
  static const bool isVerified = true;

  static const List<ProfileStat> stats = [
    ProfileStat(label: 'Following', value: 2),
    ProfileStat(label: 'Followers', value: 4),
    ProfileStat(label: 'Likes', value: 0),
  ];

  // --- Tab content -----------------------------------------------------

  static const List<SoundTrack> sounds = [
    SoundTrack(
      coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=200&auto=format&fit=crop&q=80',
      title: 'I KNOW ?',
      usedByLabel: '260.1K',
      similarCount: 2,
    ),
    SoundTrack(
      coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=200&auto=format&fit=crop&q=80',
      title: 'TELEKINESIS (feat. SZA & Future)',
      usedByLabel: '125.9K',
      similarCount: 2,
    ),
    SoundTrack(
      coverUrl: 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=200&auto=format&fit=crop&q=80',
      title: 'ZEZE (feat. Travis Scott & Offset)',
      usedByLabel: '84.5K',
      similarCount: 0,
    ),
  ];

  static const List<ShopProduct> products = [
    ShopProduct(
      imageUrl: 'https://images.unsplash.com/photo-1587829741301-dc798b83add3?w=300&auto=format&fit=crop&q=80',
      name: 'Stealth THL Keyboard',
      price: '\$149.00',
    ),
    ShopProduct(
      imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=300&auto=format&fit=crop&q=80',
      name: 'Lumin Wireless Audio',
      price: '\$189.00',
    ),
    ShopProduct(
      imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=300&auto=format&fit=crop&q=80',
      name: 'Aura Smart Watch Pro',
      price: '\$299.00',
    ),
  ];

  // Postings / Videos (Tab 1)
  static const List<String> videoThumbnails = [
    'https://images.unsplash.com/photo-1518770660439-4636190af475?w=500&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=500&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=500&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=500&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=500&auto=format&fit=crop&q=80',
  ];

  // Saved / Bookmarks (Tab 3)
  static const List<String> savedThumbnails = [
    'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=500&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=500&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1508739773434-c26b3d09e071?w=500&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=500&auto=format&fit=crop&q=80',
  ];

  // Liked / Favorites (Tab 4)
  static const List<String> likedThumbnails = [
    'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=500&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=500&auto=format&fit=crop&q=80',
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=500&auto=format&fit=crop&q=80',
  ];
}
