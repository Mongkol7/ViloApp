import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../feed/presentation/pages/home_feed_page.dart';
import '../../../inbox_activity/presentation/pages/inbox_screen.dart';
import '../../../profile/presentation/pages/people_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../widgets/vilo_floating_bottom_bar.dart';

class MainNavigationShell extends StatefulWidget {
  final int initialIndex;

  const MainNavigationShell({
    super.key,
    this.initialIndex = 0, // Default to Home Feed Page (Index 0)
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;
  bool _isAddActive = false;
  bool _isCompact = false;

  // Scroll Tracking & Hysteresis State
  double _lastScrollOffset = 0.0;
  double _accumulatedDelta = 0.0;

  List<Widget> get _pages => [
    HomeFeedPage(isActive: _currentIndex == 0),
    const PeopleScreen(),
    const InboxScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
      _isAddActive = false;
      // Return to expanded state on tab change
      _isCompact = false;
      _accumulatedDelta = 0.0;
    });
  }

  void _onAddPressed() {
    setState(() {
      _isAddActive = !_isAddActive;
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    final currentOffset = notification.metrics.pixels;

    // 1. Immediate return to expanded state if at top or overscrolled at top
    if (currentOffset <= 0) {
      if (_isCompact) {
        setState(() {
          _isCompact = false;
          _accumulatedDelta = 0.0;
        });
      }
      _lastScrollOffset = currentOffset;
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      final delta = currentOffset - _lastScrollOffset;

      if (delta > 0) {
        // Scrolling DOWN
        if (_accumulatedDelta < 0) _accumulatedDelta = 0.0;
        _accumulatedDelta += delta;

        // Threshold: Downward displacement > 20pt
        if (_accumulatedDelta > 20.0 && !_isCompact) {
          setState(() {
            _isCompact = true;
          });
        }
      } else if (delta < 0) {
        // Scrolling UP
        if (_accumulatedDelta > 0) _accumulatedDelta = 0.0;
        _accumulatedDelta += delta;

        // Immediate expansion: Upward delta < -6pt
        if (_accumulatedDelta < -6.0 && _isCompact) {
          setState(() {
            _isCompact = false;
          });
        }
      }
      _lastScrollOffset = currentOffset;
    } else if (notification is UserScrollNotification) {
      // Velocity / gesture end checks
      if (notification.direction == ScrollDirection.forward && _isCompact) {
        setState(() {
          _isCompact = false;
          _accumulatedDelta = 0.0;
        });
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final double bottomMargin = bottomInset + (_isCompact ? 16.0 : 8.0);

    return Scaffold(
      backgroundColor: AppColors.voidBackground,
      body: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: Stack(
          children: [
            // Current Page Content with IndexedStack
            Positioned.fill(
              child: IndexedStack(
                index: _currentIndex,
                children: _pages,
              ),
            ),

            // Dynamic Scroll-Aware Floating Bottom Navigation Bar Dock
            AnimatedPositioned(
              duration: const Duration(milliseconds: 320),
              curve: Curves.fastEaseInToSlowEaseOut,
              left: 0,
              right: 0,
              bottom: bottomMargin,
              child: ViloFloatingBottomBar(
                currentIndex: _currentIndex,
                isAddActive: _isAddActive,
                isCompact: _isCompact,
                onTabSelected: _onTabSelected,
                onAddPressed: _onAddPressed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
