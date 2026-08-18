import 'package:flutter/foundation.dart';
import '../../domain/entities/shared_thought_story.dart';

/// Centralized in-memory manager for active user's shared thought story.
///
/// Ensures real-time state synchronization across both InboxScreen and ProfileScreen.
class ThoughtStoryManager {
  ThoughtStoryManager._internal();
  static final ThoughtStoryManager instance = ThoughtStoryManager._internal();

  final ValueNotifier<SharedThoughtStory?> storyNotifier =
      ValueNotifier<SharedThoughtStory?>(null);

  SharedThoughtStory? get currentStory => storyNotifier.value;

  void setStory(SharedThoughtStory? story) {
    storyNotifier.value = story;
  }

  void deleteStory() {
    storyNotifier.value = null;
  }
}
