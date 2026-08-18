import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/person_suggestion.dart';
import '../screens/public_profile_screen.dart';

class PersonCard extends StatelessWidget {
  final PersonSuggestion person;
  final VoidCallback onRemove;
  final VoidCallback onFollowToggle;

  const PersonCard({
    super.key,
    required this.person,
    required this.onRemove,
    required this.onFollowToggle,
  });

  @override
  Widget build(BuildContext context) {
    void goToProfile() {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PublicProfileScreen()),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.surfaceStroke,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          // 1. Avatar with subtle 1px border
          GestureDetector(
            onTap: goToProfile,
            child: Container(
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
                  person.avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.surfaceElevated,
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.onSurfaceVariant,
                        size: 28,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: AppColors.surfaceElevated,
                      child: const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.outline,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // 2. Name & Subtitle
          Expanded(
            child: GestureDetector(
              onTap: goToProfile,
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    person.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    person.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.outline,
                    ),
                  ),
                  if (person.followsYou) ...[
                    const SizedBox(height: 2),
                    const Text(
                      'Follows you',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // 3. Action Buttons (Remove & Follow / Follow back)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Remove Pill Button
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.actionSecondary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Text(
                    'Remove',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Follow / Follow Back Primary Pill Button (Inverted White)
              GestureDetector(
                onTap: onFollowToggle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                  decoration: BoxDecoration(
                    color: person.isFollowed ? AppColors.surfaceElevated : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: person.isFollowed
                        ? Border.all(color: AppColors.surfaceStroke, width: 1.0)
                        : null,
                  ),
                  child: Text(
                    person.isFollowed
                        ? 'Following'
                        : (person.followsYou ? 'Follow back' : 'Follow'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: person.isFollowed ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
