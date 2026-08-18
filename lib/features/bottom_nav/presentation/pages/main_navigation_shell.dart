import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/vilo_floating_bottom_bar.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  bool _isAddActive = false;

  final List<Widget> _pages = const [
    _PlaceholderPage(title: 'Home Feed', icon: Icons.home_rounded),
    _PlaceholderPage(title: 'People & Friends', icon: Icons.people_alt_rounded),
    _PlaceholderPage(title: 'Chat & Messages', icon: Icons.chat_bubble_rounded),
    _PlaceholderPage(title: 'User Profile', icon: Icons.person_rounded),
  ];

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
      _isAddActive = false;
    });
  }

  void _onAddPressed() {
    setState(() {
      _isAddActive = !_isAddActive;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Current Page content
          Positioned.fill(
            child: _pages[_currentIndex],
          ),

          // Floating Bottom Navigation Bar Dock
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 8,
            child: ViloFloatingBottomBar(
              currentIndex: _currentIndex,
              isAddActive: _isAddActive,
              onTabSelected: _onTabSelected,
              onAddPressed: _onAddPressed,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderPage({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: AppColors.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
