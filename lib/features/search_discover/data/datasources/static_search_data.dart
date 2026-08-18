import '../../domain/entities/search_results.dart';

class StaticSearchData {
  static const List<TrendingVideo> trendingVideos = [
    TrendingVideo(
      id: 'v1',
      thumbnailUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=300&auto=format&fit=crop&q=80',
      views: '12.4K',
    ),
    TrendingVideo(
      id: 'v2',
      thumbnailUrl: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=300&auto=format&fit=crop&q=80',
      views: '85.2K',
    ),
    TrendingVideo(
      id: 'v3',
      thumbnailUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=300&auto=format&fit=crop&q=80',
      views: '2.1M',
    ),
    TrendingVideo(
      id: 'v4',
      thumbnailUrl: 'https://images.unsplash.com/photo-1508739773434-c26b3d09e071?w=300&auto=format&fit=crop&q=80',
      views: '440K',
    ),
    TrendingVideo(
      id: 'v5',
      thumbnailUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=300&auto=format&fit=crop&q=80',
      views: '12.1K',
    ),
    TrendingVideo(
      id: 'v6',
      thumbnailUrl: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=300&auto=format&fit=crop&q=80',
      views: '99.8K',
    ),
  ];

  static const List<SearchAccount> accounts = [
    SearchAccount(
      id: 'a1',
      username: '@noir_pulse',
      followersCount: '45.8K followers',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
      isFollowed: false,
    ),
    SearchAccount(
      id: 'a2',
      username: '@obsidian_cinemas',
      followersCount: '122.4K followers',
      avatarUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=150&auto=format&fit=crop&q=80',
      isFollowed: false,
    ),
  ];

  static const List<SearchSound> sounds = [
    SearchSound(
      id: 's1',
      title: 'Midnight Echoes - Noir Edit',
      videosCount: '12.4K videos',
      iconType: 'music',
      isSaved: false,
    ),
    SearchSound(
      id: 's2',
      title: 'Pulse Bass Drop (Original)',
      videosCount: '1.2M videos',
      iconType: 'equalizer',
      isSaved: false,
    ),
    SearchSound(
      id: 's3',
      title: 'City Ambience: Shibuya Rainy',
      videosCount: '345K videos',
      iconType: 'ambience',
      isSaved: false,
    ),
  ];
}
