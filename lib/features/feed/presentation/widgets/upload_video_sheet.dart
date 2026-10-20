import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/datasources/token_storage.dart';
import '../../../profile/presentation/mock/profile_mock_data.dart';
import '../../data/datasources/feed_remote_data_source.dart';
import '../../data/models/video_model.dart';
import '../controllers/video_feed_manager.dart';
import '../../../profile/data/datasources/profile_sync_service.dart';

class UploadVideoSheet extends StatefulWidget {
  final PlatformFile? initialFile;
  final List<PlatformFile>? initialFiles;
  final PlatformFile? initialThumbnail;
  final int? initialSoundId;
  final String? initialSoundTitle;
  final String? initialAudioUrl;

  const UploadVideoSheet({
    super.key,
    this.initialFile,
    this.initialFiles,
    this.initialThumbnail,
    this.initialSoundId,
    this.initialSoundTitle,
    this.initialAudioUrl,
  });

  static Future<VideoModel?> show(
    BuildContext context, {
    PlatformFile? initialFile,
    List<PlatformFile>? initialFiles,
    PlatformFile? initialThumbnail,
    int? initialSoundId,
    String? initialSoundTitle,
    String? initialAudioUrl,
  }) {
    return showModalBottomSheet<VideoModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black87,
      builder: (ctx) => UploadVideoSheet(
        initialFile: initialFile,
        initialFiles: initialFiles,
        initialThumbnail: initialThumbnail,
        initialSoundId: initialSoundId,
        initialSoundTitle: initialSoundTitle,
        initialAudioUrl: initialAudioUrl,
      ),
    );
  }

  @override
  State<UploadVideoSheet> createState() => _UploadVideoSheetState();
}

class _UploadVideoSheetState extends State<UploadVideoSheet> {
  final FeedRemoteDataSource _feedDataSource = FeedRemoteDataSource();
  final AuthRemoteDataSource _authDataSource = AuthRemoteDataSource();
  final TokenStorage _tokenStorage = TokenStorage.instance;

  PlatformFile? _selectedFile;
  List<PlatformFile> _selectedFiles = [];
  PlatformFile? _selectedThumbnail;
  PlatformFile? _selectedAudioFile;
  String _selectedSound = 'None';
  int? _selectedSoundId;
  List<SoundTrack> _availableSounds = [];

  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _customSoundController = TextEditingController();

  bool _isUploading = false;
  bool _isLoggingIn = false;
  String? _errorMessage;

  String? _loggedInUsername;
  String? _loggedInDisplayName;
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialFiles != null && widget.initialFiles!.isNotEmpty) {
      _selectedFiles = List.from(widget.initialFiles!);
      _selectedFile = _selectedFiles.first;
    } else if (widget.initialFile != null) {
      _selectedFile = widget.initialFile;
      _selectedFiles = [widget.initialFile!];
    }
    if (widget.initialThumbnail != null) {
      _selectedThumbnail = widget.initialThumbnail;
    }
    if (widget.initialSoundTitle != null && widget.initialSoundTitle!.isNotEmpty) {
      _selectedSound = widget.initialSoundTitle!;
      _selectedSoundId = widget.initialSoundId;
      _customSoundController.text = widget.initialSoundTitle!;
    } else if (widget.initialSoundId != null) {
      _selectedSoundId = widget.initialSoundId;
    }
    _checkAuthStatus();
    _loadAvailableSounds();
  }

  Future<void> _loadAvailableSounds() async {
    try {
      final sounds = await _feedDataSource.getSounds();
      if (mounted && sounds.isNotEmpty) {
        setState(() {
          _availableSounds = sounds;
          if (_selectedSoundId != null) {
            final match = sounds.where((s) => s.id == _selectedSoundId).firstOrNull;
            if (match != null) {
              _selectedSound = match.title;
            }
          } else if (_selectedSound != 'None' && _selectedSound.isNotEmpty) {
            final match = sounds.where((s) => s.title.toLowerCase() == _selectedSound.toLowerCase()).firstOrNull;
            if (match != null) {
              _selectedSoundId = match.id;
              _selectedSound = match.title;
            }
          }
        });
      }
    } catch (e) {
      debugPrint('[UploadVideoSheet] Load sounds error: $e');
    }
  }

  @override
  void didUpdateWidget(UploadVideoSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFiles != null &&
        widget.initialFiles != oldWidget.initialFiles) {
      setState(() {
        _selectedFiles = List.from(widget.initialFiles!);
        _selectedFile = _selectedFiles.isNotEmpty ? _selectedFiles.first : null;
      });
    } else if (widget.initialFile != oldWidget.initialFile &&
        widget.initialFile != null) {
      setState(() {
        _selectedFile = widget.initialFile;
        _selectedFiles = [widget.initialFile!];
      });
    }
    if (widget.initialThumbnail != oldWidget.initialThumbnail &&
        widget.initialThumbnail != null) {
      setState(() {
        _selectedThumbnail = widget.initialThumbnail;
      });
    }
    if (widget.initialSoundTitle != null && widget.initialSoundTitle != oldWidget.initialSoundTitle) {
      setState(() {
        _selectedSound = widget.initialSoundTitle!;
        _selectedSoundId = widget.initialSoundId;
        _customSoundController.text = widget.initialSoundTitle!;
      });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _tagsController.dispose();
    _customSoundController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'aac', 'm4a', 'ogg'],
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final picked = result.files.first;
        setState(() {
          _selectedAudioFile = picked;
          _selectedSound = picked.name;
          _selectedSoundId = null;
          _customSoundController.text = picked.name;
        });
      }
    } catch (e) {
      debugPrint('[UploadVideoSheet] Pick audio error: $e');
    }
  }

  Future<void> _checkAuthStatus() async {
    final hasToken = await _tokenStorage.hasValidToken();
    final username = await _tokenStorage.getUsername();
    final displayName = await _tokenStorage.getDisplayName();

    if (mounted) {
      setState(() {
        _hasToken = hasToken;
        _loggedInUsername = username;
        _loggedInDisplayName = displayName;
      });
    }
  }

  Future<void> _quickLogin() async {
    setState(() {
      _isLoggingIn = true;
      _errorMessage = null;
    });

    try {
      final user = await _authDataSource.login(
        usernameOrEmail: 'bunheng',
        password: 'password123',
      );
      if (mounted) {
        setState(() {
          _hasToken = true;
          _loggedInUsername = user.username;
          _loggedInDisplayName = user.displayName;
          _isLoggingIn = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
          _errorMessage = 'Login failed: $e';
        });
      }
    }
  }

  bool _isImageFile(PlatformFile file) => RegExp(
    r'\.(jpg|jpeg|png|webp|gif)$',
    caseSensitive: false,
  ).hasMatch(file.name);

  bool get _isSelectedFileImage {
    if (_selectedFiles.isNotEmpty) {
      return _isImageFile(_selectedFiles.first);
    }
    return _selectedFile != null && _isImageFile(_selectedFile!);
  }

  bool get _isMultiImage => _isSelectedFileImage && _selectedFiles.length > 1;

  Future<void> _pickVideo() async {
    try {
      // 1. Try ImagePicker first (native Gallery / Media Library on mobile & web)
      try {
        final picker = ImagePicker();
        List<XFile> pickedList = [];

        try {
          pickedList = await picker.pickMultipleMedia();
        } catch (_) {
          // Fallback to pickMedia if pickMultipleMedia is unsupported
          final singleMedia = await picker.pickMedia();
          if (singleMedia != null) {
            pickedList = [singleMedia];
          }
        }

        if (pickedList.isNotEmpty) {
          final List<PlatformFile> parsed = [];
          for (final xFile in pickedList) {
            int size = 0;
            Uint8List? bytes;
            if (xFile.path.isNotEmpty) {
              final file = File(xFile.path);
              if (file.existsSync()) {
                size = file.lengthSync();
                if (size <= 25 * 1024 * 1024) {
                  bytes = await file.readAsBytes();
                }
              }
            }
            if (bytes == null && size == 0) {
              bytes = await xFile.readAsBytes();
              size = bytes.length;
            }

            parsed.add(
              PlatformFile(
                name: xFile.name.isNotEmpty ? xFile.name : 'media_upload.mp4',
                size: size,
                bytes: bytes,
                path: xFile.path.isNotEmpty ? xFile.path : null,
              ),
            );
          }

          // Invariant: Video uploads are strictly single file at a time!
          final hasVideo = parsed.any((f) => !_isImageFile(f));
          if (hasVideo) {
            final firstVideo = parsed.firstWhere(
              (f) => !_isImageFile(f),
              orElse: () => parsed.first,
            );
            setState(() {
              _selectedFiles = [firstVideo];
              _selectedFile = firstVideo;
              _errorMessage = parsed.length > 1
                  ? 'Videos can only be posted one at a time. The first video was selected.'
                  : null;
            });
          } else {
            // All images: take up to 10 photos
            final limited = parsed.take(10).toList();
            setState(() {
              _selectedFiles = limited;
              _selectedFile = limited.first;
              _errorMessage = null;
            });
          }
          return;
        } else {
          return;
        }
      } catch (pickerErr) {
        debugPrint(
          '[UploadVideoSheet] ImagePicker fell back or unavailable: $pickerErr',
        );
      }

      // 2. Fallback to FilePicker (desktop or alternate picker)
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'mp4',
          'mov',
          'mkv',
          'webm',
          'jpg',
          'jpeg',
          'png',
          'webp',
          'gif',
        ],
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final List<PlatformFile> parsed = [];
        for (final picked in result.files) {
          Uint8List? bytes = picked.bytes;
          if ((bytes == null || bytes.isEmpty) && picked.path != null) {
            final file = File(picked.path!);
            if (file.existsSync() && file.lengthSync() <= 25 * 1024 * 1024) {
              bytes = await file.readAsBytes();
            }
          }
          parsed.add(
            PlatformFile(
              name: picked.name,
              size: picked.size,
              bytes: bytes,
              path: picked.path,
            ),
          );
        }

        final hasVideo = parsed.any((f) => !_isImageFile(f));
        if (hasVideo) {
          final firstVideo = parsed.firstWhere(
            (f) => !_isImageFile(f),
            orElse: () => parsed.first,
          );
          setState(() {
            _selectedFiles = [firstVideo];
            _selectedFile = firstVideo;
            _errorMessage = parsed.length > 1
                ? 'Videos can only be posted one at a time. The first video was selected.'
                : null;
          });
        } else {
          final limited = parsed.take(10).toList();
          setState(() {
            _selectedFiles = limited;
            _selectedFile = limited.first;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Could not select file: $e';
        if (e.toString().contains('MissingPluginException')) {
          msg =
              'File picker plugin requires an app restart. Please rebuild/restart the app or pick from Gallery.';
        }
        setState(() {
          _errorMessage = msg;
        });
      }
    }
  }

  Future<void> _pickMorePhotos() async {
    try {
      try {
        final picker = ImagePicker();
        final xFiles = await picker.pickMultiImage();
        if (xFiles.isNotEmpty) {
          for (final xFile in xFiles) {
            if (_selectedFiles.length >= 10) break;
            int size = 0;
            Uint8List? bytes;
            if (xFile.path.isNotEmpty) {
              final file = File(xFile.path);
              if (file.existsSync()) {
                size = file.lengthSync();
                if (size <= 25 * 1024 * 1024) {
                  bytes = await file.readAsBytes();
                }
              }
            }
            if (bytes == null && size == 0) {
              bytes = await xFile.readAsBytes();
              size = bytes.length;
            }
            _selectedFiles.add(
              PlatformFile(
                name: xFile.name.isNotEmpty
                    ? xFile.name
                    : 'photo_${_selectedFiles.length + 1}.jpg',
                size: size,
                bytes: bytes,
                path: xFile.path.isNotEmpty ? xFile.path : null,
              ),
            );
          }
          setState(() {
            _selectedFile = _selectedFiles.first;
            _errorMessage = null;
          });
          return;
        }
      } catch (pickerErr) {
        debugPrint('[UploadVideoSheet] ImagePicker pickMultiImage fell back: $pickerErr');
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final picked in result.files) {
            if (_selectedFiles.length >= 10) break;
            Uint8List? bytes = picked.bytes;
            if ((bytes == null || bytes.isEmpty) && picked.path != null) {
              final file = File(picked.path!);
              if (file.existsSync() && file.lengthSync() <= 25 * 1024 * 1024) {
                bytes = file.readAsBytesSync();
              }
            }
            _selectedFiles.add(PlatformFile(
              name: picked.name,
              size: picked.size,
              bytes: bytes,
              path: picked.path,
            ));
          }
          if (_selectedFiles.isNotEmpty) {
            _selectedFile = _selectedFiles.first;
          }
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not select more photos: $e';
        });
      }
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      // 1. Try ImagePicker first
      try {
        final picker = ImagePicker();
        final xFile = await picker.pickImage(source: ImageSource.gallery);
        if (xFile != null) {
          final bytes = await xFile.readAsBytes();
          setState(() {
            _selectedThumbnail = PlatformFile(
              name: xFile.name.isNotEmpty ? xFile.name : 'thumbnail.jpg',
              size: bytes.length,
              bytes: bytes,
              path: xFile.path.isNotEmpty ? xFile.path : null,
            );
            _errorMessage = null;
          });
          return;
        } else {
          return;
        }
      } catch (pickerErr) {
        debugPrint(
          '[UploadVideoSheet] ImagePicker pickThumbnail fell back: $pickerErr',
        );
      }

      // 2. Fallback to FilePicker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final picked = result.files.first;
        Uint8List? bytes = picked.bytes;
        if ((bytes == null || bytes.isEmpty) && picked.path != null) {
          final file = File(picked.path!);
          if (file.existsSync() && file.lengthSync() <= 10 * 1024 * 1024) {
            bytes = await file.readAsBytes();
          }
        }
        setState(() {
          _selectedThumbnail = PlatformFile(
            name: picked.name,
            size: picked.size,
            bytes: bytes,
            path: picked.path,
          );
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not select thumbnail: $e';
        });
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _handleUpload() async {
    final currentFile = _selectedFiles.isNotEmpty
        ? _selectedFiles.first
        : _selectedFile;
    if (currentFile == null) {
      setState(() {
        _errorMessage = 'Please select a video or photo file.';
      });
      return;
    }

    final caption = _captionController.text.trim();
    if (caption.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a caption for your video.';
      });
      return;
    }

    // Parse tags and append them into finalCaption so hashtags show on the posted content
    final tagsText = _tagsController.text.trim();
    final List<String> tags = tagsText.isNotEmpty
        ? tagsText
              .split(RegExp(r'[, ]+'))
              .map((t) => t.replaceAll('#', '').trim())
              .where((t) => t.isNotEmpty)
              .toList()
        : [];

    String finalCaption = caption;
    if (tags.isNotEmpty) {
      final missingTags = tags.where((t) {
        final tLower = t.toLowerCase();
        return !finalCaption.toLowerCase().contains('#$tLower');
      }).toList();
      if (missingTags.isNotEmpty) {
        final hashtagsStr = missingTags.map((t) => '#$t').join(' ');
        finalCaption = finalCaption.isEmpty
            ? hashtagsStr
            : '$finalCaption $hashtagsStr';
      }
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // Auto login as demo user if token is missing
      if (!_hasToken) {
        await _quickLogin();
      }

      final hasTokenNow = await _tokenStorage.hasValidToken();
      if (!hasTokenNow) {
        setState(() {
          _isUploading = false;
          _errorMessage = 'Authentication required. Please sign in to upload.';
        });
        return;
      }

      int? soundIdToSend = _selectedSoundId;
      String? musicTitleToSend;
      if (_selectedSound != 'None' && _selectedSound.trim().isNotEmpty) {
        musicTitleToSend = _selectedSound.trim();
      }

      List<int>? audioBytes = _selectedAudioFile?.bytes;
      if ((audioBytes == null || audioBytes.isEmpty) && _selectedAudioFile?.path != null) {
        final localAudio = File(_selectedAudioFile!.path!);
        if (localAudio.existsSync()) {
          try {
            audioBytes = await localAudio.readAsBytes();
          } catch (_) {}
        }
      }

      if (_isMultiImage) {
        // Multi-image carousel upload
        final List<String> paths = [];
        final List<List<int>> bytesList = [];
        final List<String> filenames = [];

        for (final file in _selectedFiles) {
          filenames.add(file.name);
          if (file.path != null && file.path!.isNotEmpty) {
            paths.add(file.path!);
          } else if (file.bytes != null && file.bytes!.isNotEmpty) {
            bytesList.add(file.bytes!);
          }
        }

        final newVideo = await _feedDataSource.uploadVideo(
          caption: finalCaption,
          soundId: soundIdToSend,
          musicTitle: musicTitleToSend,
          audioUrl: widget.initialAudioUrl,
          audioPath: _selectedAudioFile?.path,
          audioBytes: audioBytes,
          audioFilename: _selectedAudioFile?.name ?? 'music.mp3',
          imagePaths: paths.isNotEmpty ? paths : null,
          imageBytesList: bytesList.isNotEmpty ? bytesList : null,
          imageFilenames: filenames,
          tags: tags,
        );

        VideoFeedManager.instance.prependVideo(newVideo);
        ProfileSyncService.instance.notifyVideoUploaded(newVideo);

        if (mounted) {
          Navigator.of(context).pop(newVideo);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1E1E24),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.greenAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Photo carousel posted (${_selectedFiles.length} photos)! Now appearing in feed.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return;
      }

      final isImage = _isSelectedFileImage;

      List<int>? videoBytes = currentFile.bytes;
      if ((videoBytes == null || videoBytes.isEmpty) &&
          currentFile.path != null) {
        final localFile = File(currentFile.path!);
        if (localFile.existsSync() &&
            localFile.lengthSync() <= 25 * 1024 * 1024) {
          videoBytes = await localFile.readAsBytes();
        }
      }

      List<int>? thumbnailBytes = isImage ? null : _selectedThumbnail?.bytes;
      if (!isImage &&
          (thumbnailBytes == null || thumbnailBytes.isEmpty) &&
          _selectedThumbnail?.path != null) {
        final localThumb = File(_selectedThumbnail!.path!);
        if (localThumb.existsSync() &&
            localThumb.lengthSync() <= 10 * 1024 * 1024) {
          thumbnailBytes = await localThumb.readAsBytes();
        }
      }

      final newVideo = await _feedDataSource.uploadVideo(
        caption: finalCaption,
        soundId: soundIdToSend,
        musicTitle: musicTitleToSend,
        audioUrl: widget.initialAudioUrl,
        audioPath: _selectedAudioFile?.path,
        audioBytes: audioBytes,
        audioFilename: _selectedAudioFile?.name ?? 'music.mp3',
        videoPath: currentFile.path,
        videoBytes: videoBytes,
        videoFilename: currentFile.name,
        thumbnailPath: isImage ? null : _selectedThumbnail?.path,
        thumbnailBytes: thumbnailBytes,
        thumbnailFilename: isImage
            ? 'thumbnail.jpg'
            : (_selectedThumbnail?.name ?? 'thumbnail.jpg'),
        tags: tags,
      );

      // Prepend to active feed and trigger live sync across feeds and profile
      VideoFeedManager.instance.prependVideo(newVideo);
      ProfileSyncService.instance.notifyVideoUploaded(newVideo);

      if (mounted) {
        Navigator.of(context).pop(newVideo);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E1E24),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.greenAccent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isImage
                        ? 'Photo posted! Now appearing in feed.'
                        : 'Video posted! Now playing at top of feed.',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
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

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Material(
      color: const Color(0xFF141416),
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: bottomInset + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header: Drag handle bar + "Upload Video" title + close (X) button
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

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.video_call_rounded,
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
                            'Upload Video',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Post to Vilo Community & For You feed',
                            style: TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: const Key('upload_video_sheet_close_btn'),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Auth Status Pill / Quick Login Banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _hasToken
                        ? const Color(0xFF1B241E)
                        : const Color(0xFF261D1D),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _hasToken
                          ? Colors.greenAccent.withValues(alpha: 0.4)
                          : Colors.orangeAccent.withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _hasToken
                            ? Icons.verified_user_rounded
                            : Icons.account_circle_outlined,
                        color: _hasToken
                            ? Colors.greenAccent
                            : Colors.orangeAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _hasToken
                              ? 'Logged in as ${_loggedInDisplayName != null && _loggedInDisplayName!.isNotEmpty ? '$_loggedInDisplayName (@$_loggedInUsername)' : '@${_loggedInUsername ?? 'user'}'}'
                              : 'Sign in required to publish videos',
                          style: TextStyle(
                            color: _hasToken
                                ? Colors.greenAccent
                                : Colors.orangeAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!_hasToken)
                        TextButton(
                          onPressed: _isLoggingIn ? null : _quickLogin,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoggingIn
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Sign In (@bunheng)',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // System Video / Photo Picker Section
                const Text(
                  'VIDEO OR PHOTO',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),

                if (_selectedFile == null && _selectedFiles.isEmpty) ...[
                  // Unselected State: Files / Downloads Picker Card
                  InkWell(
                    key: const Key('upload_pick_video_button'),
                    onTap: _isUploading ? null : _pickVideo,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E24),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF323238),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.folder_open_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Choose Video or Photo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Pick an .mp4, .mov, .jpg, or .png from your device',
                            style: TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else if (_isMultiImage) ...[
                  // Multi-Image Carousel Selected State
                  Container(
                    key: const Key('upload_selected_video_tile'),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.blueAccent.withValues(alpha: 0.4),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.blueAccent.withValues(
                                    alpha: 0.4,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.view_carousel_rounded,
                                    color: Colors.blueAccent,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Photo Carousel (${_selectedFiles.length}/10)',
                                    style: const TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (_selectedFiles.length < 10)
                              TextButton.icon(
                                key: const Key('upload_add_more_photos_button'),
                                onPressed: _isUploading
                                    ? null
                                    : _pickMorePhotos,
                                icon: const Icon(
                                  Icons.add_rounded,
                                  size: 16,
                                  color: Colors.white70,
                                ),
                                label: const Text(
                                  'Add',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            IconButton(
                              key: const Key('upload_change_video_button'),
                              icon: const Icon(
                                Icons.sync_rounded,
                                color: Colors.white70,
                                size: 20,
                              ),
                              tooltip: 'Reselect photos',
                              onPressed: _isUploading ? null : _pickVideo,
                            ),
                            IconButton(
                              key: const Key('upload_remove_video_button'),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white70,
                                size: 20,
                              ),
                              tooltip: 'Clear all',
                              onPressed: _isUploading
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedFile = null;
                                        _selectedFiles.clear();
                                      });
                                    },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 74,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedFiles.length + (_selectedFiles.length < 10 ? 1 : 0),
                            separatorBuilder: (_, _) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              if (index == _selectedFiles.length) {
                                return InkWell(
                                  onTap: _isUploading ? null : _pickMorePhotos,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 64,
                                    height: 74,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_rounded,
                                          color: Colors.white70,
                                          size: 22,
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Add',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              final file = _selectedFiles[index];
                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: 64,
                                      height: 74,
                                      color: const Color(0xFF2B2B36),
                                      child:
                                          file.bytes != null &&
                                              file.bytes!.isNotEmpty
                                          ? Image.memory(
                                              file.bytes!,
                                              fit: BoxFit.cover,
                                            )
                                          : (file.path != null &&
                                                File(file.path!).existsSync())
                                          ? Image.file(
                                              File(file.path!),
                                              fit: BoxFit.cover,
                                            )
                                          : const Icon(
                                              Icons.image_rounded,
                                              color: Colors.white54,
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    left: 4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.7,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: InkWell(
                                      key: Key('upload_carousel_remove_$index'),
                                      onTap: _isUploading
                                          ? null
                                          : () {
                                              setState(() {
                                                _selectedFiles.removeAt(index);
                                                if (_selectedFiles.isNotEmpty) {
                                                  _selectedFile =
                                                      _selectedFiles.first;
                                                } else {
                                                  _selectedFile = null;
                                                }
                                              });
                                            },
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.75,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close_rounded,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_selectedFiles.first.name} (+${_selectedFiles.length - 1} more)',
                          style: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Selected State: Single File Preview Tile
                  Builder(
                    builder: (context) {
                      final currentDisplayFile = _selectedFiles.isNotEmpty
                          ? _selectedFiles.first
                          : _selectedFile!;
                      return Container(
                        key: const Key('upload_selected_video_tile'),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E24),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (_isSelectedFileImage)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  color: const Color(0xFF2B2B36),
                                  child: currentDisplayFile.bytes != null
                                      ? Image.memory(
                                          currentDisplayFile.bytes!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const Icon(
                                            Icons.image_outlined,
                                            color: Colors.white70,
                                            size: 24,
                                          ),
                                        )
                                      : (currentDisplayFile.path != null &&
                                              File(currentDisplayFile.path!).existsSync())
                                          ? Image.file(
                                              File(currentDisplayFile.path!),
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) => const Icon(
                                                Icons.image_outlined,
                                                color: Colors.white70,
                                                size: 24,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.image_rounded,
                                              color: Colors.white70,
                                              size: 24,
                                            ),
                                ),
                              )
                            else
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.movie_creation_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    currentDisplayFile.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatFileSize(currentDisplayFile.size),
                                    style: const TextStyle(
                                      color: Color(0xFF8E8E93),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_isSelectedFileImage)
                              IconButton(
                                key: const Key('upload_add_more_photos_button'),
                                icon: const Icon(
                                  Icons.add_photo_alternate_rounded,
                                  color: Colors.blueAccent,
                                  size: 20,
                                ),
                                tooltip: 'Add more photos to make carousel',
                                onPressed: _isUploading
                                    ? null
                                    : _pickMorePhotos,
                              ),
                            IconButton(
                              key: const Key('upload_change_video_button'),
                              icon: const Icon(
                                Icons.sync_rounded,
                                color: Colors.white70,
                                size: 20,
                              ),
                              tooltip: _isSelectedFileImage
                                  ? 'Change photo'
                                  : 'Change video',
                              onPressed: _isUploading ? null : _pickVideo,
                            ),
                            IconButton(
                              key: const Key('upload_remove_video_button'),
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white70,
                                size: 20,
                              ),
                              tooltip: 'Remove',
                              onPressed: _isUploading
                                  ? null
                                  : () {
                                      setState(() {
                                        _selectedFile = null;
                                        _selectedFiles.clear();
                                      });
                                    },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],

                if (!_isSelectedFileImage) ...[
                  const SizedBox(height: 18),

                  // Thumbnail Image Picker Section (Optional)
                  const Text(
                    'THUMBNAIL (OPTIONAL)',
                    style: TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_selectedThumbnail == null) ...[
                    // Unselected Thumbnail Card
                    InkWell(
                      key: const Key('upload_pick_thumbnail_button'),
                      onTap: _isUploading ? null : _pickThumbnail,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E24),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF323238),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Choose Thumbnail Image',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Pick a .jpg, .png, or .webp cover image',
                                    style: TextStyle(
                                      color: Color(0xFF8E8E93),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Color(0xFF8E8E93),
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    // Selected Thumbnail Preview Tile
                    Container(
                      key: const Key('upload_selected_thumbnail_tile'),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E24),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 48,
                              height: 48,
                              color: const Color(0xFF2B2B36),
                              child: _selectedThumbnail!.bytes != null
                                  ? Image.memory(
                                      _selectedThumbnail!.bytes!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => const Icon(
                                        Icons.image_outlined,
                                        color: Colors.white70,
                                        size: 22,
                                      ),
                                    )
                                  : (_selectedThumbnail!.path != null &&
                                          File(_selectedThumbnail!.path!).existsSync())
                                      ? Image.file(
                                          File(_selectedThumbnail!.path!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => const Icon(
                                            Icons.image_outlined,
                                            color: Colors.white70,
                                            size: 22,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.image_rounded,
                                          color: Colors.white70,
                                          size: 22,
                                        ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedThumbnail!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatFileSize(_selectedThumbnail!.size),
                                  style: const TextStyle(
                                    color: Color(0xFF8E8E93),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            key: const Key('upload_change_thumbnail_button'),
                            icon: const Icon(
                              Icons.sync_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                            tooltip: 'Change thumbnail',
                            onPressed: _isUploading ? null : _pickThumbnail,
                          ),
                          IconButton(
                            key: const Key('upload_remove_thumbnail_button'),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.white70,
                              size: 20,
                            ),
                            tooltip: 'Remove thumbnail',
                            onPressed: _isUploading
                                ? null
                                : () {
                                    setState(() {
                                      _selectedThumbnail = null;
                                    });
                                  },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 18),

                // Music / Sound Section (Optional)
                const Text(
                  'MUSIC / SOUND (OPTIONAL)',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Option 1: None (Default)
                    () {
                      final isSelected = _selectedSound == 'None' || _selectedSound.isEmpty;
                      return InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() {
                            _selectedSound = 'None';
                            _selectedSoundId = null;
                            _customSoundController.clear();
                            _selectedAudioFile = null;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : const Color(0xFF1E1E24),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? Colors.white : const Color(0xFF323238),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.music_off_rounded,
                                size: 14,
                                color: isSelected ? Colors.black : Colors.white70,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'None',
                                style: TextStyle(
                                  color: isSelected ? Colors.black : Colors.white,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }(),

                    // Option 2: Dynamic Available Sounds from DB
                    if (_availableSounds.isNotEmpty)
                      ..._availableSounds.map((sound) {
                        final isSelected = _selectedSoundId == sound.id ||
                            (_selectedSound.toLowerCase() == sound.title.toLowerCase() && _selectedSound != 'None');
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() {
                              _selectedSound = sound.title;
                              _selectedSoundId = sound.id;
                              _customSoundController.clear();
                              _selectedAudioFile = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : const Color(0xFF1E1E24),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Colors.white : const Color(0xFF323238),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.music_note_rounded,
                                  size: 14,
                                  color: isSelected ? Colors.black : Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  sound.title,
                                  style: TextStyle(
                                    color: isSelected ? Colors.black : Colors.white,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      })
                    else
                      ...[
                        'Phnom Penh Sunset Lo-Fi',
                        'Seven7 Team Anthem',
                        'Obsidian Pulse Beat',
                        'Lo-Fi Chill',
                      ].map((sound) {
                        final isSelected = _selectedSound == sound;
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            setState(() {
                              _selectedSound = sound;
                              _selectedSoundId = null;
                              _customSoundController.clear();
                              _selectedAudioFile = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : const Color(0xFF1E1E24),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? Colors.white : const Color(0xFF323238),
                                width: 1.0,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.music_note_rounded,
                                  size: 14,
                                  color: isSelected ? Colors.black : Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  sound,
                                  style: TextStyle(
                                    color: isSelected ? Colors.black : Colors.white,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('upload_custom_sound_field'),
                        controller: _customSoundController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Or enter custom sound title...',
                          hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFF1E1E24),
                          prefixIcon: const Icon(Icons.audiotrack_rounded, color: Colors.white70, size: 18),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF323238), width: 1.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Colors.white, width: 1.5),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (val.trim().isNotEmpty) {
                              _selectedSound = val.trim();
                              _selectedSoundId = null;
                            } else {
                              _selectedSound = 'None';
                              _selectedSoundId = null;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Pick audio file from device',
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF1E1E24),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFF323238), width: 1.0),
                        ),
                        padding: const EdgeInsets.all(12),
                      ),
                      icon: const Icon(Icons.file_upload_outlined, color: Colors.white, size: 20),
                      onPressed: _pickAudioFile,
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Caption Input Form Field
                const Text(
                  'CAPTION',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const Key('upload_caption_field'),
                  controller: _captionController,
                  maxLines: 3,
                  maxLength: 250,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Write a caption...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1E1E24),
                    counterStyle: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 11,
                    ),
                    contentPadding: const EdgeInsets.all(14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF323238),
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // Tags Input & Quick Chips
                const Text(
                  'TAGS',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                            '#vilo',
                            '#trending',
                            '#fyp',
                            '#viral',
                            '#coding',
                            '#sunset',
                          ]
                          .map(
                            (tag) => InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                final current = _tagsController.text.trim();
                                final tagWord = tag.replaceAll('#', '');
                                if (!current.contains(tagWord) &&
                                    !current.contains(tag)) {
                                  if (current.isEmpty) {
                                    _tagsController.text = tag;
                                  } else {
                                    _tagsController.text = '$current, $tag';
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E1E24),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFF323238),
                                    width: 1.0,
                                  ),
                                ),
                                child: Text(
                                  tag,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const Key('upload_tags_field'),
                  controller: _tagsController,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '#vilo, #trending',
                    hintStyle: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF1E1E24),
                    prefixIcon: const Icon(
                      Icons.tag_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Color(0xFF323238),
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C1A1D),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          color: Colors.redAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    key: const Key('upload_post_video_button'),
                    onPressed: _isUploading ? null : _handleUpload,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white38,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isUploading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isMultiImage
                                    ? 'Uploading Carousel...'
                                    : (_isSelectedFileImage
                                          ? 'Uploading Photo...'
                                          : 'Uploading Video...'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.arrow_upward_rounded,
                                size: 20,
                                color: Colors.black,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isMultiImage
                                    ? 'Post Carousel (${_selectedFiles.length} Photos)'
                                    : (_isSelectedFileImage
                                          ? 'Post Photo'
                                          : 'Post Video'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
