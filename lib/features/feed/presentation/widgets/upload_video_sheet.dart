import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/datasources/token_storage.dart';
import '../../data/datasources/feed_remote_data_source.dart';
import '../../data/models/video_model.dart';
import '../controllers/video_feed_manager.dart';

class UploadVideoSheet extends StatefulWidget {
  final XFile? initialVideo;
  final ImagePicker? imagePicker;

  const UploadVideoSheet({
    super.key,
    this.initialVideo,
    this.imagePicker,
  });

  static Future<VideoModel?> show(BuildContext context, {XFile? initialVideo}) {
    return showModalBottomSheet<VideoModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black87,
      builder: (ctx) => UploadVideoSheet(initialVideo: initialVideo),
    );
  }

  @override
  State<UploadVideoSheet> createState() => _UploadVideoSheetState();
}

class _UploadVideoSheetState extends State<UploadVideoSheet> {
  final FeedRemoteDataSource _feedDataSource = FeedRemoteDataSource();
  final AuthRemoteDataSource _authDataSource = AuthRemoteDataSource();
  final TokenStorage _tokenStorage = TokenStorage.instance;

  late final ImagePicker _picker;
  XFile? _selectedVideo;
  int? _selectedVideoSize;

  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  bool _isUploading = false;
  bool _isLoggingIn = false;
  String? _errorMessage;

  String? _loggedInUsername;
  String? _loggedInDisplayName;
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    _picker = widget.imagePicker ?? ImagePicker();
    if (widget.initialVideo != null) {
      _selectedVideo = widget.initialVideo;
      widget.initialVideo!.length().then((size) {
        if (mounted) {
          setState(() => _selectedVideoSize = size);
        }
      }).catchError((_) {});
    }
    _checkAuthStatus();
  }

  @override
  void didUpdateWidget(UploadVideoSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialVideo != oldWidget.initialVideo && widget.initialVideo != null) {
      setState(() {
        _selectedVideo = widget.initialVideo;
      });
      widget.initialVideo!.length().then((size) {
        if (mounted) {
          setState(() => _selectedVideoSize = size);
        }
      }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _tagsController.dispose();
    super.dispose();
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

  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
      );
      if (video != null) {
        final size = await video.length().catchError((_) => 0);
        setState(() {
          _selectedVideo = video;
          _selectedVideoSize = size > 0 ? size : null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not select video: $e';
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
    if (_selectedVideo == null) {
      setState(() {
        _errorMessage = 'Please select a video file from your gallery.';
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

    // Parse tags
    final tagsText = _tagsController.text.trim();
    final List<String> tags = tagsText.isNotEmpty
        ? tagsText
            .split(RegExp(r'[, ]+'))
            .map((t) => t.replaceAll('#', '').trim())
            .where((t) => t.isNotEmpty)
            .toList()
        : [];

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      // Auto login as demo user if token is missing
      if (!_hasToken) {
        await _quickLogin();
      }

      final videoBytes = await _selectedVideo!.readAsBytes();

      final newVideo = await _feedDataSource.uploadVideo(
        caption: caption,
        videoPath: _selectedVideo!.path,
        videoBytes: videoBytes,
        videoFilename: _selectedVideo!.name,
        tags: tags,
      );

      // Prepend to active feed and trigger live sync
      VideoFeedManager.instance.prependVideo(newVideo);

      if (mounted) {
        Navigator.of(context).pop(newVideo);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1E1E24),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Video posted! Now playing at top of feed.',
                    style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
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
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Auth Status Pill / Quick Login Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                        color: _hasToken ? Colors.greenAccent : Colors.orangeAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _hasToken
                              ? 'Logged in as ${_loggedInDisplayName != null && _loggedInDisplayName!.isNotEmpty ? '$_loggedInDisplayName (@$_loggedInUsername)' : '@${_loggedInUsername ?? 'user'}'}'
                              : 'Sign in required to publish videos',
                          style: TextStyle(
                            color: _hasToken ? Colors.greenAccent : Colors.orangeAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (!_hasToken)
                        TextButton(
                          onPressed: _isLoggingIn ? null : _quickLogin,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: Colors.white.withValues(alpha: 0.12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: _isLoggingIn
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Sign In (@bunheng)',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Native Video Picker Section
                const Text(
                  'VIDEO FILE',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),

                if (_selectedVideo == null) ...[
                  // Unselected State: Native Picker Card
                  InkWell(
                    key: const Key('upload_pick_video_button'),
                    onTap: _isUploading ? null : _pickVideo,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                              Icons.video_library_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Choose Video from Gallery',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap to pick an .mp4 or .mov from your device',
                            style: TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Selected State: Preview Tile
                  Container(
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
                                _selectedVideo!.name,
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
                                _selectedVideoSize != null
                                    ? _formatFileSize(_selectedVideoSize!)
                                    : 'Video ready to upload',
                                style: const TextStyle(
                                  color: Color(0xFF8E8E93),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          key: const Key('upload_change_video_button'),
                          icon: const Icon(Icons.sync_rounded, color: Colors.white70, size: 20),
                          tooltip: 'Change video',
                          onPressed: _isUploading ? null : _pickVideo,
                        ),
                        IconButton(
                          key: const Key('upload_remove_video_button'),
                          icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                          tooltip: 'Remove',
                          onPressed: _isUploading
                              ? null
                              : () {
                                  setState(() {
                                    _selectedVideo = null;
                                    _selectedVideoSize = null;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ],

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
                    hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
                    filled: true,
                    fillColor: const Color(0xFF1E1E24),
                    counterStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11),
                    contentPadding: const EdgeInsets.all(14),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF323238), width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.white, width: 1.5),
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
                  children: ['#vilo', '#trending', '#fyp', '#viral', '#coding', '#sunset']
                      .map(
                        (tag) => InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            final current = _tagsController.text.trim();
                            final tagWord = tag.replaceAll('#', '');
                            if (!current.contains(tagWord) && !current.contains(tag)) {
                              if (current.isEmpty) {
                                _tagsController.text = tag;
                              } else {
                                _tagsController.text = '$current, $tag';
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E24),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF323238), width: 1.0),
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
                    hintStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF1E1E24),
                    prefixIcon: const Icon(Icons.tag_rounded, color: Colors.white70, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF323238), width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.white, width: 1.5),
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
                      border: Border.all(color: Colors.redAccent.withValues(alpha: 0.6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
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
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Uploading Video...',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_upward_rounded, size: 20, color: Colors.black),
                              SizedBox(width: 8),
                              Text(
                                'Post Video',
                                style: TextStyle(
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
