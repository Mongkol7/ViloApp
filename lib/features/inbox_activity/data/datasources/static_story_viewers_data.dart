import '../../domain/entities/shared_thought_story.dart';

class StaticStoryViewersData {
  static const List<StoryViewer> viewers = [
    StoryViewer(
      id: 'v1',
      username: 'alex.smith1',
      fullName: 'Alex Smith',
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
      actionType: 'add',
    ),
    StoryViewer(
      id: 'v2',
      username: 'travel_guru',
      fullName: 'Sarah Chen',
      avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150&auto=format&fit=crop&q=80',
      actionType: 'following',
    ),
    StoryViewer(
      id: 'v3',
      username: 'fashion_finds',
      fullName: 'Lisa K.',
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
      actionType: 'follow',
    ),
    StoryViewer(
      id: 'v4',
      username: 'music_lover',
      fullName: 'Mike Davis',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80',
      hasStoryRing: true,
      actionType: 'follow',
    ),
    StoryViewer(
      id: 'v5',
      username: 'art_fanatic',
      fullName: 'Chloe R.',
      avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80',
      actionType: 'follow',
    ),
    StoryViewer(
      id: 'v6',
      username: 'pixel_pusher',
      fullName: 'Jason Lee',
      avatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150&auto=format&fit=crop&q=80',
      actionType: 'following',
    ),
  ];
}
