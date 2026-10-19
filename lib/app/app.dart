import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../features/bottom_nav/presentation/pages/main_navigation_shell.dart';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

class ViloApp extends StatelessWidget {
  const ViloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vilo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      navigatorObservers: [routeObserver],
      home: const MainNavigationShell(initialIndex: 2),
    );
  }
}
