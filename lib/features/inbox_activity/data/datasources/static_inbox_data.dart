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

  static const List<NotificationItem> notifications = [
    NotificationItem(
      id: 'n1',
      title: 'New followers',
      subtitle: 'R.DRR and 12 others followed you',
      iconType: 'followers',
    ),
    NotificationItem(
      id: 'n2',
      title: 'Activity',
      subtitle: 'Junta liked your photos',
      iconType: 'activity',
      badgeCount: 1,
    ),
    NotificationItem(
      id: 'n3',
      title: 'System notifications',
      subtitle: 'Screen time: You spent 17% m...',
      iconType: 'system',
      hasDot: true,
    ),
  ];

  static const List<DirectMessageThread> threads = [
    DirectMessageThread(
      id: 't0',
      username: 'FashionHub',
      isVerified: true,
      followersCount: '120k followers',
      avatarUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=150&auto=format&fit=crop&q=80',
      lastMessage: 'Yes, and do you ship to the US?',
      timeAgo: 'Just now',
      messages: [
        ChatMessage(
          id: 'm1',
          text: 'Hi! I saw the new collection, do you have the floral dress in size M?',
          isMe: true,
          timestamp: 'Today',
          status: 'Sent',
        ),
        ChatMessage(
          id: 'm2',
          text: 'Hello! Yes, we have 3 pieces left in size M for the floral dress. Would you like us to reserve one for you?',
          isMe: false,
          timestamp: 'Today',
          status: null,
        ),
        ChatMessage(
          id: 'm3',
          text: 'Yes please, and do you ship to the US?',
          isMe: true,
          timestamp: 'Today',
          status: 'Sent',
        ),
      ],
    ),
    DirectMessageThread(
      id: 't1',
      username: 'jinxmo_mo',
      avatarUrl: 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=150&auto=format&fit=crop&q=80',
      lastMessage: 'sent a sticker',
      timeAgo: '16h',
      messages: [
        ChatMessage(
          id: 'jm1',
          text: 'Hey check out this new sound for your video!',
          isMe: false,
          timestamp: 'Yesterday',
        ),
        ChatMessage(
          id: 'jm2',
          text: 'sent a sticker',
          isMe: false,
          timestamp: '16h',
        ),
      ],
    ),
    DirectMessageThread(
      id: 't2',
      username: 'Udom-Omdu',
      avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150&auto=format&fit=crop&q=80',
      lastMessage: 'shared a video',
      timeAgo: '18 Jul',
      messages: [
        ChatMessage(
          id: 'uo1',
          text: 'shared a video',
          isMe: false,
          timestamp: '18 Jul',
        ),
      ],
    ),
    DirectMessageThread(
      id: 't3',
      username: '22-October',
      avatarUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=150&auto=format&fit=crop&q=80',
      lastMessage: 'Sent',
      timeAgo: '22 Oct',
      messages: [
        ChatMessage(
          id: 'to1',
          text: 'Sent photo',
          isMe: true,
          timestamp: '22 Oct',
          status: 'Sent',
        ),
      ],
    ),
    DirectMessageThread(
      id: 't4',
      username: '28-Nove',
      avatarUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80',
      lastMessage: 'Sent',
      timeAgo: '28 Nov',
      messages: [
        ChatMessage(
          id: 'tn1',
          text: 'Sent',
          isMe: true,
          timestamp: '28 Nov',
          status: 'Sent',
        ),
      ],
    ),
  ];
}
