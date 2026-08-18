import 'package:flutter/material.dart';

/// Obsidian Pulse design tokens — scoped to `profile` for now so this can be
/// built in isolation without touching shared files.
///
/// TODO(team): once approved, migrate the shared values (colors, type scale,
/// spacing) into `core/theme/app_theme.dart` / `core/theme/app_typography.dart`
/// so every feature reads from one source of truth instead of duplicating it.
class PulseColors {
  PulseColors._();

  // Surfaces
  static const surface = Color(0xFF141414);
  static const surfaceDim = Color(0xFF131313);
  static const surfaceBright = Color(0xFF3A3939);
  static const surfaceContainerLowest = Color(0xFF0E0E0E);
  static const surfaceContainerLow = Color(0xFF1C1B1B);
  static const surfaceContainer = Color(0xFF201F1F);
  static const surfaceContainerHigh = Color(0xFF2A2A2A);
  static const surfaceContainerHighest = Color(0xFF353534);

  // Content on surfaces
  static const onSurface = Color(0xFFE5E2E1);
  static const onSurfaceVariant = Color(0xFFC4C7C8);

  // Outlines
  static const outline = Color(0xFF8E9192);
  static const outlineVariant = Color(0xFF444748);
  static const surfaceStroke = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const avatarStroke = Color(0x26FFFFFF); // rgba(255,255,255,0.15)

  // Actions
  static const primary = Color(0xFFFFFFFF);
  static const onPrimary = Color(0xFF2F3131);
  static const actionSecondary = Color(0xFF242426);

  // Base canvas
  static const background = Color(0xFF131313);
  static const onBackground = Color(0xFFE5E2E1);

  // Glass
  static const glassDark = Color(0xBF1C1C1E); // rgba(28,28,30,0.75)
  static const glassLight = Color(0xD9FFFFFF); // rgba(255,255,255,0.85)
}

class PulseTypography {
  PulseTypography._();

  static const _fontFamily = 'Inter';

  static const headlineLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 34 / 28,
    letterSpacing: -0.5,
    color: PulseColors.onSurface,
  );

  static const headlineSm = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    color: PulseColors.onSurface,
  );

  static const bodyLg = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 20 / 15,
    color: PulseColors.onSurface,
  );

  static const bodyMd = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
    color: PulseColors.onSurfaceVariant,
  );

  static const labelCaps = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 12 / 11,
    letterSpacing: 0.5,
    color: PulseColors.onSurfaceVariant,
  );
}

class PulseSpacing {
  PulseSpacing._();

  static const containerPadding = 16.0;
  static const stackGap = 12.0;
  static const inlineGap = 8.0;
  static const edgeMargin = 24.0;
  static const sectionMargin = 32.0;
}

class PulseRadius {
  PulseRadius._();

  static const sm = 4.0;
  static const defaultRadius = 8.0;
  static const md = 12.0;
  static const cardRadius = 20.0; // explicit "Standard Containers" spec
  static const xl = 24.0;
  static const full = 999.0;
}
