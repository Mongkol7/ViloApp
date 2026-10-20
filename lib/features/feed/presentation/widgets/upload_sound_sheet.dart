import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';
import '../../../profile/presentation/mock/profile_mock_data.dart';
import '../../data/datasources/feed_remote_data_source.dart';

class UploadSoundSheet extends StatefulWidget {
  const UploadSoundSheet({super.key});

  /// Opens the standalone music/sound upload modal.
  static Future<SoundTrack?> show(BuildContext context) {
    return showModalBottomSheet<SoundTrack>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black87,
      builder: (ctx) => const UploadSoundSheet(),
    );
  }

  @override
  State<UploadSoundSheet> createState() => _UploadSoundSheetState();
}

class _UploadSoundSheetState extends State<UploadSoundSheet> {
  PlatformFile? _selectedAudioFile;
  PlatformFile? _selectedCoverFile;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();

  bool _isUploading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final myDisplayName = ProfileSyncService.instance.currentUserDisplayName;
    _artistController.text = myDisplayName;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'mp4'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final picked = result.files.first;
        setState(() {
          _selectedAudioFile = picked;
          _errorMessage = null;
          if (_titleController.text.trim().isEmpty) {
            final rawName = picked.name;
            final cleanTitle = rawName.contains('.')
                ? rawName.substring(0, rawName.lastIndexOf('.'))
                : rawName;
            _titleController.text = cleanTitle;
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not access file picker: $e';
      });
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedCoverFile = result.files.first;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not pick image: $e';
      });
    }
  }

  Future<void> _handleUpload() async {
    if (_selectedAudioFile == null) {
      setState(() {
        _errorMessage = 'Please select an audio file (MP3, WAV, M4A, etc.)';
      });
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _errorMessage = 'Please provide a title for the sound track';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      List<int>? audioBytes = _selectedAudioFile!.bytes;
      if ((audioBytes == null || audioBytes.isEmpty) && _selectedAudioFile!.path != null) {
        final fileOnDisk = File(_selectedAudioFile!.path!);
        if (fileOnDisk.existsSync()) {
          audioBytes = await fileOnDisk.readAsBytes();
        }
      }

      List<int>? coverBytes = _selectedCoverFile?.bytes;
      if (_selectedCoverFile != null && (coverBytes == null || coverBytes.isEmpty) && _selectedCoverFile!.path != null) {
        final coverOnDisk = File(_selectedCoverFile!.path!);
        if (coverOnDisk.existsSync()) {
          coverBytes = await coverOnDisk.readAsBytes();
        }
      }

      final artist = _artistController.text.trim().isNotEmpty
          ? _artistController.text.trim()
          : null;

      final newSound = await FeedRemoteDataSource.instance.uploadSound(
        audioPath: _selectedAudioFile!.path,
        audioBytes: audioBytes,
        audioFilename: _selectedAudioFile!.name,
        title: title,
        artist: artist,
        coverPath: _selectedCoverFile?.path,
        coverBytes: coverBytes,
        coverFilename: _selectedCoverFile?.name ?? 'cover.jpg',
      );

      // Notify profile and system to refresh sounds list immediately
      ProfileSyncService.instance.notifySoundUploaded(newSound);

      if (mounted) {
        Navigator.of(context).pop(newSound);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E1E24),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sound "${newSound.title}" uploaded successfully! Now appearing in Sounds tab and Music Picker.',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: const Color(0xFF141416),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: 24 + bottomInset,
          ),
          child: SingleChildScrollView(
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
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF2D55), Color(0xFFAF52DE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.library_music_rounded,
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
                            'Upload Music / Sound',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Share audio tracks for creators to use in their videos',
                            style: TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('upload_sound_sheet_close_btn'),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Error message banner
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3A1C20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 1. Audio File Picker (Required)
                InkWell(
                  key: const Key('upload_sound_pick_audio_button'),
                  onTap: _isUploading ? null : _pickAudioFile,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _selectedAudioFile != null
                            ? const Color(0xFFAF52DE).withValues(alpha: 0.7)
                            : const Color(0xFF323238),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _selectedAudioFile != null
                                ? const Color(0xFFAF52DE).withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _selectedAudioFile != null
                                ? Icons.graphic_eq_rounded
                                : Icons.audio_file_rounded,
                            color: _selectedAudioFile != null
                                ? const Color(0xFFAF52DE)
                                : Colors.white70,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _selectedAudioFile != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedAudioFile!.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _formatFileSize(_selectedAudioFile!.size),
                                      style: const TextStyle(
                                        color: Color(0xFF8E8E93),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                              : const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Select Audio File *',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'MP3, WAV, M4A, AAC, OGG (Required)',
                                      style: TextStyle(
                                        color: Color(0xFF8E8E93),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _selectedAudioFile != null ? 'Change' : 'Browse',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Sound Title Input (Required)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF323238), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sound Title *',
                        style: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        key: const Key('upload_sound_title_field'),
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'e.g., Midnight City Beat',
                          hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Artist / Creator Label Input (Optional)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E24),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF323238), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Artist / Author (Optional)',
                        style: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        key: const Key('upload_sound_artist_field'),
                        controller: _artistController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'e.g., @yourname or Artist Name',
                          hintStyle: TextStyle(color: Colors.white30, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 3. Cover Image Picker (Optional)
                InkWell(
                  key: const Key('upload_sound_pick_cover_button'),
                  onTap: _isUploading ? null : _pickCoverImage,
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _selectedCoverFile != null
                            ? const Color(0xFFFF2D55).withValues(alpha: 0.7)
                            : const Color(0xFF323238),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Cover Preview or Placeholder
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 52,
                            height: 52,
                            color: Colors.white.withValues(alpha: 0.08),
                            child: _selectedCoverFile != null
                                ? (_selectedCoverFile!.bytes != null
                                    ? Image.memory(
                                        _selectedCoverFile!.bytes!,
                                        fit: BoxFit.cover,
                                        width: 52,
                                        height: 52,
                                      )
                                    : (_selectedCoverFile!.path != null
                                        ? Image.file(
                                            File(_selectedCoverFile!.path!),
                                            fit: BoxFit.cover,
                                            width: 52,
                                            height: 52,
                                          )
                                        : const Icon(Icons.image_rounded, color: Colors.white70)))
                                : const Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: Colors.white70,
                                    size: 26,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _selectedCoverFile != null
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedCoverFile!.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    const Text(
                                      'Custom cover art selected',
                                      style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                              : const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cover Artwork (Optional)',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'JPG, PNG, WebP or GIF',
                                      style: TextStyle(
                                        color: Color(0xFF8E8E93),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        if (_selectedCoverFile != null)
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.white60, size: 20),
                            onPressed: () {
                              setState(() {
                                _selectedCoverFile = null;
                              });
                            },
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Choose',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 4. Upload Button ("Upload Sound")
                ElevatedButton(
                  key: const Key('upload_sound_submit_button'),
                  onPressed: _isUploading ? null : _handleUpload,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF007AFF).withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Uploading sound...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Upload Sound',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
