import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Floating Bottom Navigation Bar with Apple Liquid Glass / Fluid Spring motion model
class ViloFloatingBottomBar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddPressed;
  final bool isAddActive;

  const ViloFloatingBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onAddPressed,
    this.isAddActive = false,
  });

  @override
  State<ViloFloatingBottomBar> createState() => _ViloFloatingBottomBarState();
}

class _TabItemData {
  final String label;
  final IconData filledIcon;
  final IconData outlinedIcon;

  const _TabItemData({
    required this.label,
    required this.filledIcon,
    required this.outlinedIcon,
  });
}

class _ViloFloatingBottomBarState extends State<ViloFloatingBottomBar>
    with SingleTickerProviderStateMixin {
  static const List<_TabItemData> _tabs = [
    _TabItemData(
      label: 'Home',
      filledIcon: Icons.home_rounded,
      outlinedIcon: Icons.home_outlined,
    ),
    _TabItemData(
      label: 'People',
      filledIcon: Icons.people_alt_rounded,
      outlinedIcon: Icons.people_alt_outlined,
    ),
    _TabItemData(
      label: 'Chat',
      filledIcon: Icons.chat_bubble_rounded,
      outlinedIcon: Icons.chat_bubble_outline_rounded,
    ),
    _TabItemData(
      label: 'Profile',
      filledIcon: Icons.person_rounded,
      outlinedIcon: Icons.person_outline_rounded,
    ),
  ];

  late AnimationController _fluidController;
  late Animation<double> _leadingAnimation;
  late Animation<double> _trailingAnimation;

  int _fromIndex = 0;
  int _toIndex = 0;
  int? _pressedIndex;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.currentIndex;
    _toIndex = widget.currentIndex;

    _fluidController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _setupAnimations();
  }

  void _setupAnimations() {
    // 1. Leading edge accelerates fast (high initial velocity spring)
    _leadingAnimation = CurvedAnimation(
      parent: _fluidController,
      curve: const Interval(0.0, 0.72, curve: Curves.fastLinearToSlowEaseIn),
    );

    // 2. Trailing edge resists & snaps forward with overshoot
    _trailingAnimation = CurvedAnimation(
      parent: _fluidController,
      curve: const Interval(0.20, 1.0, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(covariant ViloFloatingBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _triggerTransition(oldWidget.currentIndex, widget.currentIndex);
    }
  }

  void _triggerTransition(int from, int to) {
    setState(() {
      _fromIndex = from;
      _toIndex = to;
      _pressedIndex = null;
    });
    _fluidController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _fluidController.dispose();
    super.dispose();
  }

  void _onTabTapDown(int index) {
    if (index != widget.currentIndex) {
      setState(() {
        _pressedIndex = index;
      });
      HapticFeedback.selectionClick();
    }
  }

  void _onTabTapCancel() {
    if (_pressedIndex != null) {
      setState(() {
        _pressedIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Main Navigation Capsule
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5E5E62).withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final totalWidth = constraints.maxWidth;
                      final tabWidth = totalWidth / _tabs.length;
                      const double restingPillWidth = 56.0;
                      const double restingPillHeight = 56.0;

                      return AnimatedBuilder(
                        animation: _fluidController,
                        builder: (context, child) {
                          // Compute dynamic fluid pill coordinates
                          final fromCenter = (_fromIndex * tabWidth) + (tabWidth / 2);
                          final toCenter = (_toIndex * tabWidth) + (tabWidth / 2);
                          final isMovingRight = toCenter >= fromCenter;

                          // Anticipation / Tension pull if user is pressing down on another tab
                          double anticipationPull = 0.0;
                          if (_pressedIndex != null && !_fluidController.isAnimating) {
                            final pullDir = _pressedIndex! > widget.currentIndex ? 1.0 : -1.0;
                            anticipationPull = pullDir * 6.0;
                          }

                          double leftEdge;
                          double rightEdge;

                          if (_fluidController.isAnimating) {
                            final leadProgress = _leadingAnimation.value;
                            final trailProgress = _trailingAnimation.value;

                            if (isMovingRight) {
                              final startRight = fromCenter + (restingPillWidth / 2);
                              final endRight = toCenter + (restingPillWidth / 2);
                              final startLeft = fromCenter - (restingPillWidth / 2);
                              final endLeft = toCenter - (restingPillWidth / 2);

                              rightEdge = startRight + (endRight - startRight) * leadProgress;
                              leftEdge = startLeft + (endLeft - startLeft) * trailProgress;
                            } else {
                              final startLeft = fromCenter - (restingPillWidth / 2);
                              final endLeft = toCenter - (restingPillWidth / 2);
                              final startRight = fromCenter + (restingPillWidth / 2);
                              final endRight = toCenter + (restingPillWidth / 2);

                              leftEdge = startLeft + (endLeft - startLeft) * leadProgress;
                              rightEdge = startRight + (endRight - startRight) * trailProgress;
                            }
                          } else {
                            final center = toCenter + anticipationPull;
                            leftEdge = center - (restingPillWidth / 2);
                            rightEdge = center + (restingPillWidth / 2);
                          }

                          final pillLeft = math.min(leftEdge, rightEdge);
                          final pillWidth = math.max((rightEdge - leftEdge).abs(), restingPillWidth * 0.85);

                          // Volume conservation: vertical compression during horizontal stretch (5-8%)
                          final stretchAmount = math.max(0.0, (pillWidth - restingPillWidth) / (totalWidth * 0.6));
                          final pillHeight = restingPillHeight * (1.0 - (0.08 * stretchAmount));
                          final pillTop = (64 - pillHeight) / 2;

                          // Opacity modulation: drops ~12% during high velocity stretch for liquid translucency
                          final liquidOpacity = (0.18 - (0.05 * stretchAmount)).clamp(0.10, 0.22);

                          // Bottom glowing pill coordinate
                          final indicatorCenter = (leftEdge + rightEdge) / 2;
                          const indicatorWidth = 18.0;
                          final indicatorLeft = indicatorCenter - (indicatorWidth / 2);

                          return Stack(
                            children: [
                              // 1. Fluid Liquid Glass Moving Capsule
                              Positioned(
                                left: pillLeft,
                                top: pillTop,
                                width: pillWidth,
                                height: pillHeight,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: widget.isAddActive ? 0.0 : 1.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: isMovingRight
                                            ? Alignment.topLeft
                                            : Alignment.topRight,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.white.withValues(alpha: liquidOpacity + 0.05),
                                          Colors.white.withValues(alpha: 0.04),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(pillHeight / 2),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.24),
                                        width: 0.8,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withValues(alpha: 0.08 * (1.0 - stretchAmount)),
                                          blurRadius: 12,
                                          spreadRadius: 0.5,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // 2. Synchronized Fluid Glowing Bottom Pill Indicator
                              Positioned(
                                left: indicatorLeft,
                                bottom: 6,
                                width: indicatorWidth,
                                height: 3.5,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: widget.isAddActive ? 0.0 : 1.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withValues(alpha: 0.95),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // 3. Tab Items Row
                              Row(
                                children: List.generate(_tabs.length, (index) {
                                  final tab = _tabs[index];
                                  final isCurrent = !widget.isAddActive && widget.currentIndex == index;
                                  final isPressed = _pressedIndex == index;

                                  return Expanded(
                                    child: _LiquidNavItem(
                                      tabData: tab,
                                      isSelected: isCurrent,
                                      isPressed: isPressed,
                                      onTapDown: () => _onTabTapDown(index),
                                      onTapCancel: _onTabTapCancel,
                                      onTap: () {
                                        _onTabTapCancel();
                                        widget.onTabSelected(index);
                                      },
                                    ),
                                  );
                                }),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Action Plus Button
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onAddPressed();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isAddActive
                    ? Colors.white
                    : const Color(0xFF5E5E62).withValues(alpha: 0.88),
                border: Border.all(
                  color: widget.isAddActive
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.12),
                  width: 1.0,
                ),
                boxShadow: widget.isAddActive
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.45),
                          blurRadius: 24,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: AnimatedRotation(
                duration: const Duration(milliseconds: 260),
                turns: widget.isAddActive ? 0.125 : 0.0,
                child: Icon(
                  Icons.add,
                  size: 32,
                  color: widget.isAddActive ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidNavItem extends StatelessWidget {
  final _TabItemData tabData;
  final bool isSelected;
  final bool isPressed;
  final VoidCallback onTapDown;
  final VoidCallback onTapCancel;
  final VoidCallback onTap;

  const _LiquidNavItem({
    required this.tabData,
    required this.isSelected,
    required this.isPressed,
    required this.onTapDown,
    required this.onTapCancel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Colors.white;
    final inactiveColor = const Color(0xFFD1D1D6).withValues(alpha: 0.85);

    // Scale calculation: 0.92x on touch-down anticipation, 1.15x micro-bounce on select, 1.0x at rest
    final double targetScale = isPressed ? 0.92 : (isSelected ? 1.08 : 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onTap(),
      onTapCancel: onTapCancel,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 200),
        scale: targetScale,
        curve: Curves.easeOutBack,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Morphing Icon
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1.0).animate(anim),
                  child: child,
                ),
              ),
              child: Icon(
                isSelected ? tabData.filledIcon : tabData.outlinedIcon,
                key: ValueKey(isSelected),
                size: 24,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 2),

            // Text Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
                height: 1.1,
              ),
              child: Text(tabData.label),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
