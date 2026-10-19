import 'package:flutter/material.dart';
import '../../data/datasources/story_remote_data_source.dart';
import '../../domain/entities/shared_thought_story.dart';
import '../widgets/story_viewers_bottom_sheet.dart';

class StoryViewerItem {
  final SharedThoughtStory story;
  final bool isOwner;
  final String authorName;
  final String? authorAvatarUrl;

  const StoryViewerItem({
    required this.story,
    this.isOwner = false,
    required this.authorName,
    this.authorAvatarUrl,
  });
}

class StoryViewerScreen extends StatefulWidget {
  final List<StoryViewerItem>? stories;
  final int initialIndex;
  final SharedThoughtStory? story;
  final bool isOwner;
  final String authorName;
  final String? authorAvatarUrl;
  final bool openViewersOnStart;

  const StoryViewerScreen({
    super.key,
    this.stories,
    this.initialIndex = 0,
    this.story,
    this.isOwner = true,
    this.authorName = 'Your Story',
    this.authorAvatarUrl,
    this.openViewersOnStart = false,
  });

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  final TextEditingController _replyController = TextEditingController();

  late List<StoryViewerItem> _activeStories;
  late int _currentIndex;

  StoryViewerItem get _currentItem => _activeStories[_currentIndex];

  @override
  void initState() {
    super.initState();

    if (widget.stories != null && widget.stories!.isNotEmpty) {
      _activeStories = List.from(widget.stories!);
      _currentIndex = widget.initialIndex.clamp(0, _activeStories.length - 1);
    } else if (widget.story != null) {
      _activeStories = [
        StoryViewerItem(
          story: widget.story!,
          isOwner: widget.isOwner,
          authorName: widget.authorName,
          authorAvatarUrl: widget.authorAvatarUrl,
        ),
      ];
      _currentIndex = 0;
    } else {
      _activeStories = [];
      _currentIndex = 0;
    }

    if (_activeStories.isNotEmpty) {
      StoryRemoteDataSource.instance.recordView(_currentItem.story.id);
    }

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..forward();

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    if (widget.openViewersOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openViewersSheet();
        }
      });
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  void _nextStory() {
    if (!mounted || _activeStories.isEmpty) return;
    if (_currentIndex < _activeStories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      StoryRemoteDataSource.instance.recordView(_currentItem.story.id);
      _replyController.clear();
      _progressController.reset();
      _progressController.forward();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (!mounted || _activeStories.isEmpty) return;
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      StoryRemoteDataSource.instance.recordView(_currentItem.story.id);
      _replyController.clear();
      _progressController.reset();
      _progressController.forward();
    } else {
      _progressController.reset();
      _progressController.forward();
    }
  }

  void _openViewersSheet() {
    _progressController.stop();
    StoryViewersBottomSheet.show(
      context,
      viewCount: _currentItem.story.viewCount,
      storyId: _currentItem.story.id,
    ).then((_) {
      if (mounted && _progressController.status != AnimationStatus.completed) {
        _progressController.forward();
      }
    });
  }

  void _showStoryOptionsMenu() {
    _progressController.stop();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return Material(
          color: const Color(0xFF1E1E22),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            padding: const EdgeInsets.only(bottom: 24),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: Color(0xFF333338), width: 1.0),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF48484E),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 14),

                if (_currentItem.isOwner) ...[
                  // 1. Delete Story Option (Red)
                  ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEB5757).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFFEB5757),
                        size: 22,
                      ),
                    ),
                    title: const Text(
                      'Delete story',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEB5757),
                      ),
                    ),
                    subtitle: const Text(
                      'Remove this thought from your story',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                    onTap: () {
                      StoryRemoteDataSource.instance.deleteStory(_currentItem.story.id);
                      Navigator.of(modalContext).pop();
                      Navigator.of(context).pop('delete');
                    },
                  ),
                  const Divider(color: Color(0xFF2C2C32), height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2A2A30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_downward_rounded, color: Colors.white, size: 20),
                    ),
                    title: const Text(
                      'Save story',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(modalContext).pop();
                      if (mounted && _progressController.status != AnimationStatus.completed) {
                        _progressController.forward();
                      }
                    },
                  ),
                ] else ...[
                  // Other User's Story Options
                  ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2A2A30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.volume_off_rounded, color: Colors.white, size: 20),
                    ),
                    title: Text(
                      'Mute @${_currentItem.authorName}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(modalContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Muted stories from ${_currentItem.authorName}')),
                      );
                    },
                  ),
                  const Divider(color: Color(0xFF2C2C32), height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2A2A30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.link_rounded, color: Colors.white, size: 20),
                    ),
                    title: const Text(
                      'Copy link',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    onTap: () {
                      Navigator.of(modalContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Story link copied to clipboard')),
                      );
                    },
                  ),
                  const Divider(color: Color(0xFF2C2C32), height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEB5757).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.report_problem_outlined, color: Color(0xFFEB5757), size: 20),
                    ),
                    title: const Text(
                      'Report story',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFEB5757),
                      ),
                    ),
                    onTap: () {
                      Navigator.of(modalContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Story reported. Thank you for keeping Vilo safe.')),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    ).then((_) {
      if (mounted && _progressController.status != AnimationStatus.completed) {
        _progressController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_activeStories.isEmpty) {
      return const Scaffold(backgroundColor: Colors.black);
    }

    final item = _currentItem;

    return Scaffold(
      backgroundColor: item.story.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Layer 0: Background Media (Photo / Video / Color Gradient)
            Positioned.fill(
              child: _buildStoryMediaBackground(item.story),
            ),

            // Layer 1: Left / Right Tap and Long-press gesture areas
            Positioned.fill(
              child: Row(
                children: [
                  // Left 35% zone: Previous Story
                  Expanded(
                    flex: 35,
                    child: GestureDetector(
                      key: const Key('story_left_tap_zone'),
                      behavior: HitTestBehavior.translucent,
                      onTap: _previousStory,
                      onLongPressStart: (_) => _progressController.stop(),
                      onLongPressEnd: (_) {
                        if (mounted && _progressController.status != AnimationStatus.completed) {
                          _progressController.forward();
                        }
                      },
                      onVerticalDragEnd: (details) {
                        if (details.primaryVelocity != null && details.primaryVelocity! < -100) {
                          if (item.isOwner) _openViewersSheet();
                        }
                      },
                      child: const SizedBox.expand(),
                    ),
                  ),
                  // Right 65% zone: Next Story
                  Expanded(
                    flex: 65,
                    child: GestureDetector(
                      key: const Key('story_right_tap_zone'),
                      behavior: HitTestBehavior.translucent,
                      onTap: _nextStory,
                      onLongPressStart: (_) => _progressController.stop(),
                      onLongPressEnd: (_) {
                        if (mounted && _progressController.status != AnimationStatus.completed) {
                          _progressController.forward();
                        }
                      },
                      onVerticalDragEnd: (details) {
                        if (details.primaryVelocity != null && details.primaryVelocity! < -100) {
                          if (item.isOwner) _openViewersSheet();
                        }
                      },
                      child: const SizedBox.expand(),
                    ),
                  ),
                ],
              ),
            ),

            // Layer 2: Main Story Viewer UI
            Column(
              children: [
                // 1. Top Story Progress Bar (Multi-Segment)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: List.generate(_activeStories.length, (index) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2.5),
                          height: 2.5,
                          child: AnimatedBuilder(
                            animation: _progressController,
                            builder: (context, _) {
                              double value;
                              if (index < _currentIndex) {
                                value = 1.0;
                              } else if (index == _currentIndex) {
                                value = _progressController.value;
                              } else {
                                value = 0.0;
                              }
                              return LinearProgressIndicator(
                                value: value,
                                backgroundColor: Colors.white.withValues(alpha: 0.25),
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                minHeight: 2.5,
                                borderRadius: BorderRadius.circular(2),
                              );
                            },
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // 2. Top User Info Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      if (!item.isOwner && item.authorAvatarUrl != null && item.authorAvatarUrl!.isNotEmpty)
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white24, width: 1.0),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              item.authorAvatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.cloud_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                item.authorName,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              if (item.story.privacy == 'FRIENDS') ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF27AE60).withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF27AE60), width: 0.8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.favorite_rounded, size: 10, color: Color(0xFF2ECC71)),
                                      SizedBox(width: 3),
                                      Text(
                                        'Friends',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          color: Color(0xFF2ECC71),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else if (item.story.privacy == 'FOLLOWERS') ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2F80ED).withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF56CCF2), width: 0.8),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.people_outline_rounded, size: 10, color: Color(0xFF56CCF2)),
                                      SizedBox(width: 3),
                                      Text(
                                        'Followers',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          color: Color(0xFF56CCF2),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            item.story.timestamp,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF9E9EA4),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 2),

                // 3. Center Content: Photo / Video Caption OR Text Thought Balloon
                if (item.story.isImage || item.story.isVideo) ...[
                  // Media Story layout: clear view with caption pill and music chip at bottom
                  if (item.story.message.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        item.story.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          height: 1.35,
                        ),
                      ),
                    ),
                  if (item.story.musicTrack != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF222228).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF383842),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.music_note_rounded,
                            color: Color(0xFF56CCF2),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${item.story.musicTrack!.title} • ${item.story.musicTrack!.artist}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const _ViewerAudioWaveform(),
                        ],
                      ),
                    ),
                  ],
                ] else ...[
                  // Text Thought Story: Speech Balloon & Avatar
                  IgnorePointer(
                    ignoring: true,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Speech Balloon
                        CustomPaint(
                          painter: _ViewerBubblePainter(),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(28, 16, 28, 22),
                            constraints: const BoxConstraints(minWidth: 170, maxWidth: 280),
                            child: Text(
                              item.story.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF141416),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),

                        if (item.story.musicTrack != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF222228),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF383842),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.music_note_rounded,
                                  color: Color(0xFF56CCF2),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${item.story.musicTrack!.title} • ${item.story.musicTrack!.artist}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const _ViewerAudioWaveform(),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // Center Avatar
                        if (!item.isOwner && item.authorAvatarUrl != null && item.authorAvatarUrl!.isNotEmpty)
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2F80ED).withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.network(
                                item.authorAvatarUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: const Color(0xFF222228),
                                  child: const Icon(Icons.person, color: Colors.white, size: 48),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF2F80ED).withValues(alpha: 0.35),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.cloud_rounded, color: Colors.white, size: 48),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                const Spacer(flex: 3),

                // 4. Bottom Action Bar (Viewers button for Owner, Reply/Heart for viewers)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: item.isOwner
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: _openViewersSheet,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.visibility_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${item.story.viewCount} views',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.keyboard_arrow_up_rounded,
                                      color: Colors.white70,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 24),
                              onPressed: _showStoryOptionsMenu,
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            // Quick Reply Input Field
                            Expanded(
                              child: Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1C1C1E).withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    width: 1.0,
                                  ),
                                ),
                                child: TextField(
                                  controller: _replyController,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Reply to ${item.authorName}...',
                                    hintStyle: const TextStyle(
                                      fontFamily: 'Inter',
                                      color: Color(0xFF8E8E93),
                                      fontSize: 13,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: const Icon(
                                        Icons.send_rounded,
                                        color: Color(0xFF2F80ED),
                                        size: 18,
                                      ),
                                      onPressed: () {
                                        final text = _replyController.text.trim();
                                        if (text.isEmpty) return;
                                        _replyController.clear();
                                        FocusScope.of(context).unfocus();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Reply sent to ${item.authorName}! ✨'),
                                            backgroundColor: const Color(0xFF2F80ED),
                                            duration: const Duration(seconds: 2),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  onSubmitted: (text) {
                                    if (text.trim().isEmpty) return;
                                    _replyController.clear();
                                    FocusScope.of(context).unfocus();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Reply sent to ${item.authorName}! ✨'),
                                        backgroundColor: const Color(0xFF2F80ED),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Quick Heart Reaction Button
                            IconButton(
                              icon: const Icon(
                                Icons.favorite_rounded,
                                color: Color(0xFFFE2C55),
                                size: 26,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Sent ❤️ to ${item.authorName}!'),
                                    backgroundColor: const Color(0xFFFE2C55),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),

                            IconButton(
                              icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 24),
                              onPressed: _showStoryOptionsMenu,
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryMediaBackground(SharedThoughtStory story) {
    if (story.isImage && story.mediaUrl != null && story.mediaUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            story.mediaUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: story.backgroundColor),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.22, 0.65, 1.0],
              ),
            ),
          ),
        ],
      );
    } else if (story.isVideo && story.mediaUrl != null && story.mediaUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            story.mediaUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF0F172A),
              child: const Center(
                child: Icon(Icons.movie_creation_outlined, color: Colors.white24, size: 70),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.22, 0.65, 1.0],
              ),
            ),
          ),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white38, width: 2.0),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ],
      );
    }

    return Container(color: story.backgroundColor);
  }
}

class _ViewerBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    final path = Path();
    const double radius = 18.0;
    const double arrowWidth = 14.0;
    const double arrowHeight = 8.0;
    final double bodyHeight = size.height - arrowHeight;

    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, bodyHeight),
        const Radius.circular(radius),
      ),
    );

    final arrowPath = Path()
      ..moveTo(size.width / 2 - arrowWidth / 2, bodyHeight)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width / 2 + arrowWidth / 2, bodyHeight)
      ..close();

    path.addPath(arrowPath, Offset.zero);

    canvas.drawPath(path, shadowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ViewerAudioWaveform extends StatefulWidget {
  const _ViewerAudioWaveform();

  @override
  State<_ViewerAudioWaveform> createState() => _ViewerAudioWaveformState();
}

class _ViewerAudioWaveformState extends State<_ViewerAudioWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final v = _waveController.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 2.2,
              height: 4.0 + (v * 7),
              decoration: BoxDecoration(
                color: const Color(0xFF56CCF2),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 2.0),
            Container(
              width: 2.2,
              height: 4.0 + ((1.0 - v) * 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2F80ED),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 2.0),
            Container(
              width: 2.2,
              height: 5.0 + (v * 5),
              decoration: BoxDecoration(
                color: const Color(0xFF56CCF2),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        );
      },
    );
  }
}
