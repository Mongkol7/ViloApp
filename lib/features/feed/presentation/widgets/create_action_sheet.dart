import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'upload_sound_sheet.dart';
import 'upload_video_sheet.dart';

enum CreateActionType {
  camera,
  upload,
  uploadSound,
}

class CreateActionSheet extends StatelessWidget {
  final VoidCallback onCameraSelected;
  final VoidCallback onUploadSelected;
  final VoidCallback? onUploadSoundSelected;

  const CreateActionSheet({
    super.key,
    required this.onCameraSelected,
    required this.onUploadSelected,
    this.onUploadSoundSelected,
  });

  /// Displays the TikTok-style split action chooser modal and coordinates camera capture or file upload.
  static Future<dynamic> show(
    BuildContext context, {
    ImagePicker? imagePicker,
    int? initialSoundId,
    String? initialSoundTitle,
    String? initialAudioUrl,
  }) async {
    final action = await showModalBottomSheet<CreateActionType>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black87,
      builder: (ctx) => CreateActionSheet(
        onCameraSelected: () => Navigator.of(ctx).pop(CreateActionType.camera),
        onUploadSelected: () => Navigator.of(ctx).pop(CreateActionType.upload),
        onUploadSoundSelected: () => Navigator.of(ctx).pop(CreateActionType.uploadSound),
      ),
    );

    if (action == null || !context.mounted) return null;

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
    return Material(
      color: const Color(0xFF141416),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Share a video or snapshot with the community',
                          style: TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('create_action_sheet_close_btn'),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Top Half: Camera Option Card
              InkWell(
                key: const Key('create_camera_option_button'),
                onTap: onCameraSelected,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF323238),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF3B30), Color(0xFFFF2D55)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF2D55).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Camera',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Take a photo to post directly',
                              style: TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF8E8E93),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Bottom Half: Upload Option Card
              InkWell(
                key: const Key('create_upload_option_button'),
                onTap: onUploadSelected,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF323238),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF007AFF).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.video_library_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload Video or Photo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Choose media from your device files',
                              style: TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF8E8E93),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Bottom Option: Upload Music / Sound Option Card
              InkWell(
                key: const Key('create_upload_sound_option_button'),
                onTap: onUploadSoundSelected,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF323238),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF2D55), Color(0xFFAF52DE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFAF52DE).withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.library_music_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload Music / Sound',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Upload standalone audio or music tracks',
                              style: TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF8E8E93),
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
