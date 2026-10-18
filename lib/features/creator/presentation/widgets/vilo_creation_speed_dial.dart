import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../inbox_activity/presentation/pages/share_thought_screen.dart';
import '../pages/vilo_camera_screen.dart';
import '../pages/vilo_live_screen.dart';
import 'vilo_media_picker_sheet.dart';

class ViloCreationSpeedDial extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final double bottomOffset;

  const ViloCreationSpeedDial({
    super.key,
    required this.isOpen,
    required this.onClose,
    this.bottomOffset = 88.0,
  });

  @override
  State<ViloCreationSpeedDial> createState() => _ViloCreationSpeedDialState();
}

class _CreationActionItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _CreationActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
  });
}

class _ViloCreationSpeedDialState extends State<ViloCreationSpeedDial>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _backdropAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed || status == AnimationStatus.completed) {
        if (mounted) setState(() {});
      }
    });

    _backdropAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    if (widget.isOpen) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant ViloCreationSpeedDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openCamera(CameraMode mode) {
    _controller.reset();
    widget.onClose();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ViloCameraScreen(initialMode: mode)),
    );
  }

  void _openUpload() {
    _controller.reset();
    widget.onClose();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ViloMediaPickerBottomSheet(),
    );
  }

  void _openStory() {
    _controller.reset();
    widget.onClose();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ShareThoughtScreen()),
    );
  }

  void _openLive() {
    _controller.reset();
    widget.onClose();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ViloLiveScreen()),
    );
  }

  List<_CreationActionItem> get _actions => [
    _CreationActionItem(
      title: 'Go LIVE',
      subtitle: 'Stream broadcast',
      icon: Icons.sensors_rounded,
      gradient: const [Color(0xFFFF416C), Color(0xFFFF4B2B)],
      onTap: _openLive,
    ),
    _CreationActionItem(
      title: 'Story',
      subtitle: 'Share your mind',
      icon: Icons.auto_awesome_rounded,
      gradient: const [Color(0xFF8A2387), Color(0xFFE94057)],
      onTap: _openStory,
    ),
    _CreationActionItem(
      title: 'Upload',
      subtitle: 'From your gallery',
      icon: Icons.photo_library_rounded,
      gradient: const [Color(0xFF00B4DB), Color(0xFF0083B0)],
      onTap: _openUpload,
    ),
    _CreationActionItem(
      title: 'Photo',
      subtitle: 'Snap instant photo',
      icon: Icons.camera_alt_rounded,
      gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
      onTap: () => _openCamera(CameraMode.photo),
    ),
    _CreationActionItem(
      title: 'Camera',
      subtitle: 'Record video clip',
      icon: Icons.videocam_rounded,
      gradient: const [Color(0xFFFE2C55), Color(0xFFFF6B8B)],
      onTap: () => _openCamera(CameraMode.video15s),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen && (_controller.isDismissed || _controller.value == 0.0)) {
      return const SizedBox.shrink();
    }

    final actions = _actions;

    return Stack(
      children: [
        // ── Backdrop Blur & Dim ──────────────────────────────────────────
        Positioned.fill(
          child: GestureDetector(
            key: const Key('vilo_speed_dial_backdrop'),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onClose();
            },
            child: AnimatedBuilder(
              animation: _backdropAnimation,
              builder: (context, child) {
                return BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 14.0 * _backdropAnimation.value,
                    sigmaY: 14.0 * _backdropAnimation.value,
                  ),
                  child: Container(
                    color: Colors.black.withValues(
                      alpha: 0.58 * _backdropAnimation.value,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // ── Animated Staggered Speed Dial Items Stack ────────────────────
        Positioned(
          right: 20,
          bottom: widget.bottomOffset + 12,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(actions.length, (index) {
              final action = actions[index];

              // Staggered interval per item
              final double startInterval = (index * 0.10).clamp(0.0, 0.60);
              final double endInterval = (startInterval + 0.40).clamp(0.0, 1.0);

              final itemAnimation = CurvedAnimation(
                parent: _controller,
                curve: Interval(startInterval, endInterval, curve: Curves.easeOutBack),
                reverseCurve: const Interval(0.0, 0.7, curve: Curves.easeIn),
              );

              return AnimatedBuilder(
                animation: itemAnimation,
                builder: (context, child) {
                  final progress = itemAnimation.value;
                  final double translateY = 36.0 * (1.0 - progress);

                  return Opacity(
                    opacity: progress.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, translateY),
                      child: Transform.scale(
                        scale: 0.75 + (0.25 * progress),
                        alignment: Alignment.centerRight,
                        child: child,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      action.onTap();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Glassmorphism Label Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16161A).withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.16),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                action.title,
                                style: AppTypography.bodyLg.copyWith(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                action.subtitle,
                                style: AppTypography.bodyMd.copyWith(
                                  color: Colors.white60,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Glowing Action Icon Button
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: action.gradient,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: action.gradient.first.withValues(alpha: 0.5),
                                blurRadius: 16,
                                spreadRadius: 1,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                          ),
                          child: Icon(
                            action.icon,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
