/// A single stat displayed in the profile header (e.g. Followers: 12800).
class ProfileStat {
  final String label;
  final int value;

  const ProfileStat({required this.label, required this.value});
}

/// A track shown in the "Sounds" tab.
class SoundTrack {
  final String coverUrl;
  final String title;
  final String usedByLabel; // pre-formatted, e.g. "260.1K"
  final int similarCount;

  const SoundTrack({
    required this.coverUrl,
    required this.title,
    required this.usedByLabel,
    this.similarCount = 0,
  });
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
/// Replace with real data once `profile/data` + `profile/domain` are wired up.
class ProfileMockData {
  ProfileMockData._();

  static const String name = 'Alex Rivera';
  static const String username = '@alex.codes';
  static const String bio =
      'Full-stack dev turned creator 🚀 Building in public · Flutter & Dart tips daily';
  static const String avatarUrl = 'https://i.pravatar.cc/300?img=12';
  static const bool isVerified = true;

  static const List<ProfileStat> stats = [
    ProfileStat(label: 'Following', value: 284),
    ProfileStat(label: 'Followers', value: 12800),
    ProfileStat(label: 'Likes', value: 154000),
  ];

  // --- Tab content -----------------------------------------------------

  static const List<SoundTrack> sounds = [
    SoundTrack(
      coverUrl: 'https://picsum.photos/seed/sound1/100',
      title: 'I KNOW ?',
      usedByLabel: '260.1K',
      similarCount: 2,
    ),
    SoundTrack(
      coverUrl: 'https://picsum.photos/seed/sound2/100',
      title: 'TELEKINESIS (feat. SZA & Future)',
      usedByLabel: '125.9K',
      similarCount: 2,
    ),
    SoundTrack(
      coverUrl: 'https://picsum.photos/seed/sound3/100',
      title: 'ZEZE (feat. Travis Scott & Offset)',
      usedByLabel: '84.5K',
      similarCount: 0,
    ),
  ];

  static const List<ShopProduct> products = [
    ShopProduct(
      imageUrl: 'https://picsum.photos/seed/prod1/120',
      name: 'Stealth THL Keyboard',
      price: '\$149.00',
    ),
    ShopProduct(
      imageUrl: 'https://picsum.photos/seed/prod2/120',
      name: 'Lumin Signature Bread',
      price: '\$30.00',
    ),
    ShopProduct(
      imageUrl: 'https://picsum.photos/seed/prod3/120',
      name: 'Aura Core Module',
      price: '\$899.00',
    ),
  ];

  static const List<String> videoThumbnails = [
    'https://picsum.photos/seed/vid1/300/500',
    'https://picsum.photos/seed/vid2/300/500',
    'https://picsum.photos/seed/vid3/300/500',
    'https://picsum.photos/seed/vid4/300/500',
    'https://picsum.photos/seed/vid5/300/500',
    'https://picsum.photos/seed/vid6/300/500',
  ];
}
