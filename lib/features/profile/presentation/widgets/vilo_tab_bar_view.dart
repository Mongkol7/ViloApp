import 'package:flutter/material.dart';

/// A robust TabBarView replacement designed for NestedScrollView.
/// It eliminates the Flutter layout bug where initialPage != 0 gets clamped to 0
/// when the viewport width is zero on initial layout or route animation.
class ViloTabBarView extends StatefulWidget {
  final TabController controller;
  final List<Widget> children;
  final ScrollPhysics? physics;

  const ViloTabBarView({
    super.key,
    required this.controller,
    required this.children,
    this.physics,
  });

  @override
  State<ViloTabBarView> createState() => _ViloTabBarViewState();
}

class _ViloTabBarViewState extends State<ViloTabBarView> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.controller.index;
    _pageController = PageController(initialPage: _currentIndex);
    widget.controller.addListener(_handleTabControllerChange);
  }

  @override
  void didUpdateWidget(covariant ViloTabBarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleTabControllerChange);
      _currentIndex = widget.controller.index;
      widget.controller.addListener(_handleTabControllerChange);
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_currentIndex);
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    widget.controller.removeListener(_handleTabControllerChange);
    _pageController.dispose();
    super.dispose();
  }

  void _handleTabControllerChange() {
    if (_isDisposed || !mounted) return;
    final newIndex = widget.controller.index;
    if (_currentIndex != newIndex) {
      _currentIndex = newIndex;
      if (_pageController.hasClients) {
        if (widget.controller.indexIsChanging) {
          _pageController.animateToPage(
            newIndex,
            duration: kTabScrollDuration,
            curve: Curves.ease,
          );
        } else {
          _pageController.jumpToPage(newIndex);
        }
      }
    }
  }

  void _onPageChanged(int index) {
    if (_isDisposed || !mounted) return;
    _currentIndex = index;
    if (widget.controller.index != index) {
      widget.controller.animateTo(index);
    }
  }

  void _ensurePageSynced() {
    if (_isDisposed || !mounted || !_pageController.hasClients) return;
    if (_pageController.position.hasContentDimensions) {
      final target = widget.controller.index;
      final currentPage = _pageController.page?.round();
      if (currentPage != null && currentPage != target && !widget.controller.indexIsChanging) {
        _pageController.jumpToPage(target);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Post-frame check ensures page aligns with controller after layout calculations
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensurePageSynced());

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollEndNotification) {
          _ensurePageSynced();
        }
        return false;
      },
      child: PageView(
        controller: _pageController,
        physics: widget.physics,
        onPageChanged: _onPageChanged,
        children: widget.children,
      ),
    );
  }
}
