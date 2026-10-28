import '../../domain/entities/inbox_item.dart';

class StaticInboxData {
  static const List<StoryItem> stories = [
    StoryItem(
      id: 's0',
      title: 'Create',
      imageUrl: 'https://images.unsplash.com/photo-1534447677768-be436bb09401?w=150&auto=format&fit=crop&q=80',
      isCreate: true,
    ),
    StoryItem(
      id: 's1',
      title: 'On this day',
      imageUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=150&auto=format&fit=crop&q=80',
    ),
    StoryItem(
      id: 's2',
      title: '.uzi07',
      imageUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80',
    ),
    StoryItem(
      id: 's3',
      title: 'Tin',
      imageUrl: 'https://images.unsplash.com/photo-1514565131-fce0801e5785?w=150&auto=format&fit=crop&q=80',
    ),
    StoryItem(
      id: 's4',
      title: 'Elena.R',
      imageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150&auto=format&fit=crop&q=80',
    ),
  ];

  static const List<DirectMessageThread> threads = [];
}
