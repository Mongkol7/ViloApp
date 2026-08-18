import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/datasources/static_story_viewers_data.dart';
import '../../domain/entities/shared_thought_story.dart';

class StoryViewersBottomSheet extends StatefulWidget {
  final int viewCount;

  const StoryViewersBottomSheet({
    super.key,
    this.viewCount = 418,
  });

  static Future<void> show(BuildContext context, {int viewCount = 418}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StoryViewersBottomSheet(viewCount: viewCount),
    );
  }

  @override
  State<StoryViewersBottomSheet> createState() => _StoryViewersBottomSheetState();
}

class _StoryViewersBottomSheetState extends State<StoryViewersBottomSheet> {
  late List<StoryViewer> _viewers;

  @override
  void initState() {
    super.initState();
    _viewers = List.from(StaticStoryViewersData.viewers);
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

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

          // 3. Views Count & Search Icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.viewCount} views',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF24242A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF34343E),
                      width: 1.0,
                    ),
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 4. Viewers List
          Expanded(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              itemCount: _viewers.length,
              itemBuilder: (context, index) {
                final viewer = _viewers[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      // Avatar (with story ring if enabled)
                      if (viewer.hasStoryRing)
                        Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFFE2C55), Color(0xFFFF9F43), Color(0xFF9B51E0)],
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
                        )
                      else
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1.0,
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
                              viewer.fullName,
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

                      // Action Button (Add / Follow / Following)
                      GestureDetector(
                        onTap: () => _toggleAction(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7.5),
                          decoration: BoxDecoration(
                            color: viewer.actionType == 'following'
                                ? const Color(0xFF26262B)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: viewer.actionType == 'following'
                                ? Border.all(color: const Color(0xFF383840), width: 1.0)
                                : null,
                          ),
                          child: Text(
                            viewer.actionType == 'add'
                                ? 'Add'
                                : viewer.actionType == 'following'
                                    ? 'Following'
                                    : 'Follow',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: viewer.actionType == 'following'
                                  ? Colors.white
                                  : const Color(0xFF141416),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // More options horizontal dots
                      const Icon(
                        Icons.more_horiz_rounded,
                        color: Color(0xFF8E8E93),
                        size: 22,
                      ),
                    ],
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
