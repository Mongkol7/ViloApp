import 'package:flutter/material.dart';
import '../../../auth/data/datasources/token_storage.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/story_remote_data_source.dart';
import '../../domain/entities/shared_thought_story.dart';
import '../../../profile/presentation/screens/public_profile_screen.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';

class StoryViewersBottomSheet extends StatefulWidget {
  final int viewCount;
  final String? storyId;
  final String? authorId;
  final String? authorUsername;

  const StoryViewersBottomSheet({
    super.key,
    this.viewCount = 0,
    this.storyId,
    this.authorId,
    this.authorUsername,
  });

  static Future<void> show(
    BuildContext context, {
    int viewCount = 0,
    String? storyId,
    String? authorId,
    String? authorUsername,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StoryViewersBottomSheet(
        viewCount: viewCount,
        storyId: storyId,
        authorId: authorId,
        authorUsername: authorUsername,
      ),
    );
  }

  @override
  State<StoryViewersBottomSheet> createState() => _StoryViewersBottomSheetState();
}

class _StoryViewersBottomSheetState extends State<StoryViewersBottomSheet> {
  List<StoryViewer> _viewers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLiveViewers();
  }

  Future<void> _loadLiveViewers() async {
    if (widget.storyId != null) {
      final liveViewers = await StoryRemoteDataSource.instance.getStoryViewers(widget.storyId!);
      final myUid = TokenStorage.instance.currentUserIdSync?.toString();
      final myUsername = TokenStorage.instance.currentUsernameSync?.toLowerCase();
      final authId = widget.authorId?.toString();
      final authName = widget.authorUsername?.toLowerCase();

      final filtered = liveViewers.where((v) {
        final vId = v.id;
        final vName = v.username.replaceAll('@', '').toLowerCase();
        if (myUid != null && vId == myUid) return false;
        if (myUsername != null && (vName == myUsername || vName == 'me' || vName == 'you')) return false;
        if (ProfileSyncService.instance.isCurrentUser(username: vName, id: vId)) return false;
        if (authId != null && vId == authId) return false;
        if (authName != null && (vName == authName || v.fullName.toLowerCase() == authName)) return false;
        return true;
      }).toList();

      if (mounted) {
        setState(() {
          _viewers = filtered;
          _isLoading = false;
        });
        return;
      }
    }
    if (mounted) {
      setState(() {
        _viewers = [];
        _isLoading = false;
      });
    }
  }

  void _toggleAction(int index) {
    setState(() {
      final current = _viewers[index];
      String nextAction;
      if (current.actionType == 'follow') {
        nextAction = 'following';
      } else if (current.actionType == 'following') {
        nextAction = 'follow';
      } else {
        nextAction = 'following';
      }
      _viewers[index] = current.copyWith(actionType: nextAction);
    });
  }

  void _openViewerProfile(StoryViewer viewer) {
    final parsedId = int.tryParse(viewer.id);
    final cleanUsername = viewer.username.replaceAll('@', '');
    final userId = parsedId ?? (cleanUsername == 'liza' ? 22 : (cleanUsername == 'sak' ? 23 : null));

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicProfileScreen(
          userId: userId,
          username: cleanUsername,
          displayName: viewer.fullName,
          avatarUrl: viewer.avatarUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final displayCount = _viewers.isNotEmpty ? _viewers.length : widget.viewCount;

    return Container(
      height: screenHeight * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF161618),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF2C2C32), width: 1.0),
        ),
      ),
      child: Column(
        children: [
          // 1. Drag Handle
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: const Color(0xFF48484E),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Title Header
          const Text(
            'Story Viewers',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // 3. Views Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$displayCount ${displayCount == 1 ? "view" : "views"}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF24242A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_rounded, color: Color(0xFF56CCF2), size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Live',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF56CCF2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 4. Viewers List or Empty State
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2F80ED)),
                  )
                : _viewers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.remove_red_eye_outlined,
                                color: Color(0xFF8E8E93),
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'No viewers yet',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'When friends or followers view this story,\nthey will show up here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: Color(0xFF8E8E93),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: _viewers.length,
                        itemBuilder: (context, index) {
                          final viewer = _viewers[index];
                          return InkWell(
                            onTap: () => _openViewerProfile(viewer),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 48,
                                    height: 48,
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF2F80ED), Color(0xFF56CCF2)],
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: Image.network(
                                        viewer.avatarUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: AppColors.surface,
                                          child: const Icon(Icons.person, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Username & Full Name
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          viewer.username,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${viewer.fullName} • ${viewer.timeAgo}',
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

                                  // Action Button (Follow / Following)
                                  GestureDetector(
                                    onTap: () => _toggleAction(index),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: viewer.actionType == 'following'
                                            ? const Color(0xFF26262B)
                                            : const Color(0xFF2F80ED),
                                        borderRadius: BorderRadius.circular(16),
                                        border: viewer.actionType == 'following'
                                            ? Border.all(color: const Color(0xFF383840), width: 1.0)
                                            : null,
                                      ),
                                      child: Text(
                                        viewer.actionType == 'following' ? 'Following' : 'Follow',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: viewer.actionType == 'following'
                                              ? Colors.white
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
