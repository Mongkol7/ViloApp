import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../search_discover/presentation/pages/search_screen.dart';
import '../../data/datasources/static_inbox_data.dart';
import '../../domain/entities/inbox_item.dart';
import '../../domain/entities/shared_thought_story.dart';
import 'chat_detail_screen.dart';
import 'share_thought_screen.dart';
import 'story_viewer_screen.dart';

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  // Temporary in-memory stored shared thought story
  SharedThoughtStory? _myStory;

  Future<void> _handleCreateOrViewStory() async {
    if (_myStory != null) {
      // If already shared, open StoryViewerScreen and listen for delete action
      final result = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => StoryViewerScreen(story: _myStory!),
        ),
      );

      if (result == 'delete' && mounted) {
        setState(() {
          _myStory = null;
        });
      }
    } else {
      // If not shared yet, open ShareThoughtScreen
      final result = await Navigator.of(context).push<SharedThoughtStory>(
        MaterialPageRoute(
          builder: (_) => const ShareThoughtScreen(),
        ),
      );

      if (result != null && mounted) {
        setState(() {
          _myStory = result;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBackground,
      appBar: AppBar(
        backgroundColor: AppColors.voidBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.person_add_alt_1_outlined,
            color: Colors.white,
            size: 24,
          ),
          onPressed: () {},
        ),
        centerTitle: true,
        title: const Text(
          'Inbox',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 26,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SearchScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 110),
        children: [
          // 1. Stories / Memories Horizontal Row
          SizedBox(
            height: 124,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: StaticInboxData.stories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final story = StaticInboxData.stories[index];
                return _buildStoryCircle(context, story);
              },
            ),
          ),

          const SizedBox(height: 8),

          // 2. Notification Hub Items
          ...List.generate(StaticInboxData.notifications.length, (index) {
            final notification = StaticInboxData.notifications[index];
            return _buildNotificationTile(notification);
          }),

          const SizedBox(height: 20),

          // 3. "MESSAGES" Section Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'MESSAGES',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF8E8E93),
                letterSpacing: 1.2,
              ),
            ),
          ),

          // 4. Direct Messages Thread List
          ...List.generate(StaticInboxData.threads.length, (index) {
            final thread = StaticInboxData.threads[index];
            return _buildMessageThreadTile(context, thread);
          }),
        ],
      ),
    );
  }

  Widget _buildStoryCircle(BuildContext context, StoryItem story) {
    if (story.isCreate) {
      final isStoryActive = _myStory != null;
      final messageText = isStoryActive ? _myStory!.message : 'Share a thought...';
      final hasMusic = isStoryActive && _myStory!.musicTrack != null;

      // "Create / Active Story" Bubble with Floating Thought Box & Music Wave
      return GestureDetector(
        onTap: _handleCreateOrViewStory,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating Thought Message Box (with animated music wave if attached)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              constraints: const BoxConstraints(maxWidth: 95),
              decoration: BoxDecoration(
                color: isStoryActive ? const Color(0xFF222228) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: isStoryActive
                    ? Border.all(color: const Color(0xFF383842), width: 1.0)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      messageText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isStoryActive ? Colors.white : const Color(0xFF141416),
                      ),
                    ),
                  ),
                  if (hasMusic) ...[
                    const SizedBox(width: 4),
                    const _AnimatedMiniMusicWave(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Cloud Avatar with Story Ring (if active) or Plus Badge
            SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    padding: isStoryActive ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isStoryActive
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFE2C55),
                                Color(0xFFFF9F43),
                                Color(0xFF9B51E0),
                                Color(0xFF2F80ED),
                              ],
                            )
                          : const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                            ),
                      border: isStoryActive
                          ? null
                          : Border.all(
                              color: const Color(0xFF2F80ED),
                              width: 2.0,
                            ),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.cloud_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  if (!isStoryActive)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2F80ED),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2.0),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              isStoryActive ? 'Your story' : story.title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top Spacer to align avatars with the create item
        const SizedBox(height: 23),
        Container(
          width: 58,
          height: 58,
          padding: const EdgeInsets.all(2.5),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF56CCF2), Color(0xFF2F80ED), Color(0xFF9B51E0)],
            ),
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black,
            ),
            padding: const EdgeInsets.all(2.0),
            child: ClipOval(
              child: Image.network(
                story.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surface,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          story.title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationTile(NotificationItem item) {
    Widget leadingIcon;
    if (item.iconType == 'activity') {
      leadingIcon = Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Color(0xFFFE2C55),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.favorite_rounded,
          color: Colors.white,
          size: 26,
        ),
      );
    } else if (item.iconType == 'followers') {
      leadingIcon = Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Color(0xFF333336),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person_rounded,
          color: Colors.white,
          size: 28,
        ),
      );
    } else {
      leadingIcon = Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Color(0xFF333336),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.notifications_none_rounded,
          color: Colors.white,
          size: 26,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          leadingIcon,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF8E8E93),
                  ),
                ),
              ],
            ),
          ),
          if (item.badgeCount != null)
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFF2F80ED),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  item.badgeCount.toString(),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else if (item.hasDot)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF2F80ED),
                shape: BoxShape.circle,
              ),
            )
          else
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF2F80ED),
              size: 24,
            ),
        ],
      ),
    );
  }

  Widget _buildMessageThreadTile(BuildContext context, DirectMessageThread thread) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatDetailScreen(thread: thread),
            ),
          );
        },
        splashColor: Colors.white.withValues(alpha: 0.05),
        highlightColor: Colors.white.withValues(alpha: 0.03),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.0,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    thread.avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.surface,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Username & Last Message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          thread.username,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (thread.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF2F80ED),
                            size: 15,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      thread.timeAgo.isNotEmpty
                          ? '${thread.lastMessage} • ${thread.timeAgo}'
                          : thread.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF8E8E93),
                      ),
                    ),
                  ],
                ),
              ),

              // Right Camera Action Icon
              IconButton(
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedMiniMusicWave extends StatefulWidget {
  const _AnimatedMiniMusicWave();

  @override
  State<_AnimatedMiniMusicWave> createState() => _AnimatedMiniMusicWaveState();
}

class _AnimatedMiniMusicWaveState extends State<_AnimatedMiniMusicWave>
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
              width: 2.0,
              height: 3.5 + (v * 7),
              decoration: BoxDecoration(
                color: const Color(0xFF2F80ED),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 1.5),
            Container(
              width: 2.0,
              height: 3.5 + ((1.0 - v) * 8),
              decoration: BoxDecoration(
                color: const Color(0xFF56CCF2),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            const SizedBox(width: 1.5),
            Container(
              width: 2.0,
              height: 4.0 + (v * 5),
              decoration: BoxDecoration(
                color: const Color(0xFF9B51E0),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        );
      },
    );
  }
}
