import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../../../shop/models/product.dart';
import '../../../shop/presentation/pages/add_product_screen.dart';
import 'upload_sound_sheet.dart';
import 'upload_video_sheet.dart';

enum CreateActionType {
  camera,
  upload,
  uploadSound,
  postProduct,
}

/// Floating action popup card docked on the right side above the bottom nav bar.
class CreateActionPopupCard extends StatelessWidget {
  final VoidCallback onCameraSelected;
  final VoidCallback onUploadSelected;
  final VoidCallback onUploadSoundSelected;
  final VoidCallback onPostProductSelected;

  const CreateActionPopupCard({
    super.key,
    required this.onCameraSelected,
    required this.onUploadSelected,
    required this.onUploadSoundSelected,
    required this.onPostProductSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 204,
        decoration: BoxDecoration(
          color: const Color(0xFF16161A).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 28,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionPill(
                    key: const Key('create_camera_option_button'),
                    title: 'Camera',
                    subtitle: 'Take a photo',
                    icon: Icons.camera_alt_rounded,
                    gradient: const [Color(0xFFFF3B30), Color(0xFFFF2D55)],
                    onTap: onCameraSelected,
                  ),
                  const SizedBox(height: 8),
                  _buildActionPill(
                    key: const Key('create_upload_option_button'),
                    title: 'Upload Video',
                    subtitle: 'From device files',
                    icon: Icons.video_library_rounded,
                    gradient: const [Color(0xFF007AFF), Color(0xFF5856D6)],
                    onTap: onUploadSelected,
                  ),
                  const SizedBox(height: 8),
                  _buildActionPill(
                    key: const Key('create_upload_sound_option_button'),
                    title: 'Upload Music / Sound',
                    subtitle: 'Standalone audio',
                    icon: Icons.library_music_rounded,
                    gradient: const [Color(0xFFFF2D55), Color(0xFFAF52DE)],
                    onTap: onUploadSoundSelected,
                  ),
                  const SizedBox(height: 8),
                  _buildActionPill(
                    key: const Key('create_post_product_option_button'),
                    title: 'Post Product',
                    subtitle: 'Sell in Vilo Shop',
                    icon: Icons.storefront_rounded,
                    gradient: const [Color(0xFF30D158), Color(0xFF00C7BE)],
                    onTap: onPostProductSelected,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionPill({
    required Key key,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF222228).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: gradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.first.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 10.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF8E8E93),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateActionSheet extends StatelessWidget {
  final VoidCallback onCameraSelected;
  final VoidCallback onUploadSelected;
  final VoidCallback? onUploadSoundSelected;
  final VoidCallback? onPostProductSelected;

  const CreateActionSheet({
    super.key,
    required this.onCameraSelected,
    required this.onUploadSelected,
    this.onUploadSoundSelected,
    this.onPostProductSelected,
  });

  /// Displays the smooth floating pop-up card positioned on the right side above the bottom nav bar.
  static Future<dynamic> show(
    BuildContext context, {
    ImagePicker? imagePicker,
    int? initialSoundId,
    String? initialSoundTitle,
    String? initialAudioUrl,
  }) async {
    final action = await showGeneralDialog<CreateActionType>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.40),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );

        final bottomInset = MediaQuery.of(dialogContext).padding.bottom;
        final double bottomPosition = bottomInset + 88.0;

        return Stack(
          children: [
            Positioned(
              right: 14.0,
              bottom: bottomPosition,
              child: AnimatedBuilder(
                animation: curvedAnimation,
                builder: (context, child) {
                  final progress = curvedAnimation.value;
                  return Transform.scale(
                    scale: (0.15 + (0.85 * progress)).clamp(0.0, 1.0),
                    alignment: Alignment.bottomRight,
                    child: Opacity(
                      opacity: progress.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: CreateActionPopupCard(
                  onCameraSelected: () => Navigator.of(dialogContext).pop(CreateActionType.camera),
                  onUploadSelected: () => Navigator.of(dialogContext).pop(CreateActionType.upload),
                  onUploadSoundSelected: () => Navigator.of(dialogContext).pop(CreateActionType.uploadSound),
                  onPostProductSelected: () => Navigator.of(dialogContext).pop(CreateActionType.postProduct),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (action == null || !context.mounted) return null;

    if (action == CreateActionType.postProduct) {
      if (!context.mounted) return null;
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AddProductScreen(),
        ),
      );
      if (result is Product) {
        ProfileSyncService.instance.productUploadedEvents.value = result;
      }
      return result;
    }

    if (action == CreateActionType.uploadSound) {
      if (!context.mounted) return null;
      return UploadSoundSheet.show(context);
    }

    if (action == CreateActionType.camera) {
      try {
        final picker = imagePicker ?? ImagePicker();
        final xFile = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 90,
        );

        if (xFile != null && context.mounted) {
          final bytes = await xFile.readAsBytes();
          final capturedFile = PlatformFile(
            name: xFile.name.isNotEmpty
                ? xFile.name
                : 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg',
            size: bytes.length,
            bytes: bytes,
            path: xFile.path,
          );

          if (!context.mounted) return null;
          return UploadVideoSheet.show(
            context,
            initialFile: capturedFile,
            initialSoundId: initialSoundId,
            initialSoundTitle: initialSoundTitle,
            initialAudioUrl: initialAudioUrl,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF2C1A1D),
              content: Text('Could not access camera: $e', style: const TextStyle(color: Colors.redAccent)),
            ),
          );
        }
      }
      return null;
    } else {
      // Flow 2: Open standard upload sheet from files
      if (!context.mounted) return null;
      return UploadVideoSheet.show(
        context,
        initialSoundId: initialSoundId,
        initialSoundTitle: initialSoundTitle,
        initialAudioUrl: initialAudioUrl,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CreateActionPopupCard(
      onCameraSelected: onCameraSelected,
      onUploadSelected: onUploadSelected,
      onUploadSoundSelected: onUploadSoundSelected ?? () {},
      onPostProductSelected: onPostProductSelected ?? () {},
    );
  }
}
