import 'package:flutter/material.dart';
import 'music_track.dart';

class SharedThoughtStory {
  final String id;
  final String message;
  final MusicTrack? musicTrack;
  final Color backgroundColor;
  final String timestamp;
  final int viewCount;

  const SharedThoughtStory({
    required this.id,
    required this.message,
    this.musicTrack,
    this.backgroundColor = const Color(0xFF141416),
    this.timestamp = 'Just now',
    this.viewCount = 418,
  });
}

class StoryViewer {
  final String id;
  final String username;
  final String fullName;
  final String avatarUrl;
  final bool hasStoryRing;
  final String actionType; // 'add', 'following', 'follow'

  const StoryViewer({
    required this.id,
    required this.username,
    required this.fullName,
    required this.avatarUrl,
    this.hasStoryRing = false,
    this.actionType = 'follow',
  });

  StoryViewer copyWith({
    String? id,
    String? username,
    String? fullName,
    String? avatarUrl,
    bool? hasStoryRing,
    String? actionType,
  }) {
    return StoryViewer(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      hasStoryRing: hasStoryRing ?? this.hasStoryRing,
      actionType: actionType ?? this.actionType,
    );
  }
}
