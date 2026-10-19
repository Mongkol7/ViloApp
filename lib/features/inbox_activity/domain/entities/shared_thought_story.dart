import 'package:flutter/material.dart';
import 'music_track.dart';

class SharedThoughtStory {
  final String id;
  final String message;
  final String? mediaUrl;
  final String mediaType; // 'TEXT', 'IMAGE', 'VIDEO'
  final String privacy; // 'PUBLIC', 'FOLLOWERS', 'FRIENDS'
  final MusicTrack? musicTrack;
  final Color backgroundColor;
  final String timestamp;
  final int viewCount;
  final String? authorName;
  final String? authorAvatarUrl;
  final String? authorUsername;
  final bool isOwner;

  const SharedThoughtStory({
    required this.id,
    required this.message,
    this.mediaUrl,
    this.mediaType = 'TEXT',
    this.privacy = 'PUBLIC',
    this.musicTrack,
    this.backgroundColor = const Color(0xFF141416),
    this.timestamp = 'Just now',
    this.viewCount = 0,
    this.authorName,
    this.authorAvatarUrl,
    this.authorUsername,
    this.isOwner = true,
  });

  bool get isVideo {
    if (mediaType.toUpperCase() == 'VIDEO') return true;
    if (mediaUrl != null && mediaUrl!.isNotEmpty) {
      final lower = mediaUrl!.toLowerCase();
      if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi') || lower.endsWith('.mkv')) {
        return true;
      }
    }
    return false;
  }

  bool get isImage {
    if (isVideo) return false;
    if (mediaType.toUpperCase() == 'IMAGE') return true;
    if (mediaUrl != null && mediaUrl!.isNotEmpty) {
      return true;
    }
    return false;
  }

  bool get isText => !isImage && !isVideo;
}

class StoryViewer {
  final String id;
  final String username;
  final String fullName;
  final String avatarUrl;
  final bool hasStoryRing;
  final String actionType; // 'add', 'following', 'follow'
  final String timeAgo;

  const StoryViewer({
    required this.id,
    required this.username,
    required this.fullName,
    required this.avatarUrl,
    this.hasStoryRing = false,
    this.actionType = 'follow',
    this.timeAgo = 'Just now',
  });

  StoryViewer copyWith({
    String? id,
    String? username,
    String? fullName,
    String? avatarUrl,
    bool? hasStoryRing,
    String? actionType,
    String? timeAgo,
  }) {
    return StoryViewer(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      hasStoryRing: hasStoryRing ?? this.hasStoryRing,
      actionType: actionType ?? this.actionType,
      timeAgo: timeAgo ?? this.timeAgo,
    );
  }
}
