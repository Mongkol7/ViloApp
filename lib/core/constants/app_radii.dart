import 'package:flutter/material.dart';

/// Obsidian Pulse Rounded / Border Radius Tokens
class AppRadii {
  static const double sm = 4.0; // 0.25rem
  static const double defaultRadius = 8.0; // 0.5rem
  static const double md = 12.0; // 0.75rem
  static const double lg = 16.0; // 1rem
  static const double xl = 24.0; // 1.5rem
  static const double full = 9999.0;

  // BorderRadius helpers
  static final BorderRadius roundedSm = BorderRadius.circular(sm);
  static final BorderRadius roundedDefault = BorderRadius.circular(defaultRadius);
  static final BorderRadius roundedMd = BorderRadius.circular(md);
  static final BorderRadius roundedLg = BorderRadius.circular(lg);
  static final BorderRadius roundedXl = BorderRadius.circular(xl);
  static final BorderRadius roundedFull = BorderRadius.circular(full);
}
