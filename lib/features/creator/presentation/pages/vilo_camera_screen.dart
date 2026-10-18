import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_typography.dart';
import '../widgets/vilo_media_picker_sheet.dart';

enum CameraMode {
  photo,
  video15s,
  video60s,
  video10m,
}

class ViloCameraScreen extends StatefulWidget {
  final CameraMode initialMode;

  const ViloCameraScreen({
    super.key,
    this.initialMode = CameraMode.video15s,
  });

  @override
  State<ViloCameraScreen> createState() => _ViloCameraScreenState();
}

class _ViloCameraScreenState extends State<ViloCameraScreen>
    with TickerProviderStateMixin {
  late CameraMode _currentMode;
  bool _isFrontCamera = false;
  bool _isFlashOn = false;
  bool _isRecording = false;
  double _recordingProgress = 0.0;
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  // Tools state
  String _selectedSpeed = '1x';
  bool _beautyOn = false;
  int _timerSeconds = 0; // 0 = off, 3 = 3s, 10 = 10s

  late AnimationController _shutterPulseController;
  late Animation<double> _shutterPulseAnimation;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;

    _shutterPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _shutterPulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _shutterPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _shutterPulseController.dispose();
    super.dispose();
  }

  int get _maxDurationSeconds {
    switch (_currentMode) {
      case CameraMode.photo:
        return 0;
      case CameraMode.video15s:
        return 15;
      case CameraMode.video60s:
        return 60;
      case CameraMode.video10m:
        return 600;
    }
  }

  void _toggleRecording() {
    HapticFeedback.heavyImpact();

    if (_currentMode == CameraMode.photo) {
      // Photo snap simulation
      _takePhoto();
      return;
    }

    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _takePhoto() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
            const SizedBox(width: 8),
            Text('Photo captured!', style: AppTypography.bodyMd.copyWith(color: Colors.white)),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E22),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
      _recordingProgress = 0.0;
    });
    _shutterPulseController.repeat(reverse: true);

    final maxSec = _maxDurationSeconds;
    _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _recordingProgress += 0.1 / maxSec;
        if (_recordingProgress >= 1.0) {
          _stopRecording();
        } else {
          _recordingSeconds = (_recordingProgress * maxSec).toInt();
        }
      });
    });
  }

  void _stopRecording() {
    _recordingTimer?.cancel();
    _shutterPulseController.stop();
    _shutterPulseController.reset();

    setState(() {
      _isRecording = false;
      _recordingProgress = 0.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.videocam_rounded, color: Color(0xFFFE2C55), size: 20),
            const SizedBox(width: 8),
            Text('Clip recorded successfully!', style: AppTypography.bodyMd.copyWith(color: Colors.white)),
          ],
        ),
        backgroundColor: const Color(0xFF1E1E22),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1600),
      ),
    );
  }

  void _openGalleryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ViloMediaPickerBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Viewfinder Camera Simulation Background ─────────────────────
            _buildCameraViewfinder(),

            // ── Top Bar Controls ───────────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 16,
              right: 16,
              child: _buildTopBar(),
            ),

            // ── Right Sidebar Tools (Speed, Filters, Beauty, Timer) ─────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 80,
              right: 16,
              child: _buildRightSidebar(),
            ),

            // ── Recording Duration Progress Bar ────────────────────────────
            if (_isRecording)
              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                left: 20,
                right: 20,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _recordingProgress.clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFE2C55)),
                    minHeight: 4,
                  ),
                ),
              ),

            // ── Bottom Studio Controls (Shutter, Modes, Gallery) ────────────
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 0,
              right: 0,
              child: _buildBottomControls(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraViewfinder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            const Color(0xFF141416),
            const Color(0xFF0C0C0E),
            Colors.black.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isFrontCamera ? Icons.person_rounded : Icons.camera_alt_outlined,
              size: 72,
              color: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 12),
            Text(
              _isFrontCamera ? 'Front Camera Viewfinder' : 'Main Lens Viewfinder',
              style: AppTypography.bodyMd.copyWith(color: Colors.white.withValues(alpha: 0.3)),
            ),
            if (_isRecording) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFE2C55).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '00:${_recordingSeconds.toString().padLeft(2, '0')} / 00:$_maxDurationSeconds',
                      style: AppTypography.bodyLg.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Close Button
        _buildCircleButton(
          icon: Icons.close_rounded,
          onTap: () => Navigator.pop(context),
        ),

        // Sound Picker Pill
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Music catalogue opened', style: AppTypography.bodyMd.copyWith(color: Colors.white)),
                backgroundColor: const Color(0xFF1E1E22),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.music_note_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Add sound',
                  style: AppTypography.bodyLg.copyWith(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),

        // Flash Toggle Button
        _buildCircleButton(
          icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
          iconColor: _isFlashOn ? Colors.amberAccent : Colors.white,
          onTap: () {
            setState(() => _isFlashOn = !_isFlashOn);
            HapticFeedback.selectionClick();
          },
        ),
      ],
    );
  }

  Widget _buildRightSidebar() {
    return Column(
      children: [
        // Flip Camera
        _buildSidebarAction(
          icon: Icons.flip_camera_ios_outlined,
          label: 'Flip',
          onTap: () {
            setState(() => _isFrontCamera = !_isFrontCamera);
            HapticFeedback.mediumImpact();
          },
        ),
        const SizedBox(height: 18),

        // Speed Control
        _buildSidebarAction(
          icon: Icons.speed_rounded,
          label: _selectedSpeed,
          onTap: () {
            setState(() {
              if (_selectedSpeed == '1x') _selectedSpeed = '2x';
              else if (_selectedSpeed == '2x') _selectedSpeed = '3x';
              else if (_selectedSpeed == '3x') _selectedSpeed = '0.5x';
              else _selectedSpeed = '1x';
            });
            HapticFeedback.selectionClick();
          },
        ),
        const SizedBox(height: 18),

        // Beauty / Retouch
        _buildSidebarAction(
          icon: Icons.face_retouching_natural_rounded,
          label: 'Beauty',
          isActive: _beautyOn,
          onTap: () {
            setState(() => _beautyOn = !_beautyOn);
            HapticFeedback.selectionClick();
          },
        ),
        const SizedBox(height: 18),

        // Timer
        _buildSidebarAction(
          icon: Icons.timer_outlined,
          label: _timerSeconds == 0 ? 'Timer' : '${_timerSeconds}s',
          isActive: _timerSeconds > 0,
          onTap: () {
            setState(() {
              if (_timerSeconds == 0) _timerSeconds = 3;
              else if (_timerSeconds == 3) _timerSeconds = 10;
              else _timerSeconds = 0;
            });
            HapticFeedback.selectionClick();
          },
        ),
        const SizedBox(height: 18),

        // Filters
        _buildSidebarAction(
          icon: Icons.auto_awesome_rounded,
          label: 'Filters',
          onTap: () {
            HapticFeedback.selectionClick();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Filter presets activated', style: AppTypography.bodyMd.copyWith(color: Colors.white)),
                backgroundColor: const Color(0xFF1E1E22),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 1),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSidebarAction({
    required IconData icon,
    required String label,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.2),
                width: 0.8,
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isActive ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.bodyMd.copyWith(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              shadows: [
                const Shadow(color: Colors.black, blurRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mode Selector Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildModePill('Photo', CameraMode.photo),
              _buildModePill('15s', CameraMode.video15s),
              _buildModePill('60s', CameraMode.video60s),
              _buildModePill('10m', CameraMode.video10m),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Shutter Action Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Gallery / Upload Thumbnail
              GestureDetector(
                onTap: _openGalleryPicker,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF222226),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: const Icon(Icons.photo_library_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 4),
                    Text('Upload', style: AppTypography.bodyMd.copyWith(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),

              // Main Shutter Button
              GestureDetector(
                onTap: _toggleRecording,
                child: AnimatedBuilder(
                  animation: _shutterPulseAnimation,
                  builder: (context, child) {
                    final scale = _isRecording ? _shutterPulseAnimation.value : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _isRecording ? const Color(0xFFFE2C55) : Colors.white,
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: _isRecording ? 32 : 68,
                            height: _isRecording ? 32 : 68,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFE2C55),
                              borderRadius: BorderRadius.circular(_isRecording ? 8 : 40),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Effects Button
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Effects library opened', style: AppTypography.bodyMd.copyWith(color: Colors.white)),
                      backgroundColor: const Color(0xFF1E1E22),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFE2C55), Color(0xFFFF9F43), Color(0xFF2F80ED)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.mood_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 4),
                    Text('Effects', style: AppTypography.bodyMd.copyWith(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModePill(String title, CameraMode mode) {
    final isSelected = _currentMode == mode;
    return GestureDetector(
      onTap: () {
        if (_isRecording) return;
        HapticFeedback.selectionClick();
        setState(() => _currentMode = mode);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: AppTypography.bodyLg.copyWith(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.55),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    Color iconColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.8),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}
