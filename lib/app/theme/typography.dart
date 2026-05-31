import 'dart:ui';

import 'package:flutter/material.dart';

/// Typography tokens — matched to design spec A.3.
///
/// Fonts are bundled locally (see pubspec `flutter > fonts`):
///   • Manrope       — body / headings (sans)
///   • IBM Plex Mono — numbers (weights, reps, %, dates in tables)
/// No runtime fetching — identical rendering on every platform, offline.
class AppTypography {
  AppTypography._();

  static const String fontSans = 'Manrope';
  static const String fontMono = 'IBM Plex Mono';

  static TextTheme buildTextTheme(ColorScheme colors) {
    final c = colors.onSurface;
    return TextTheme(
      // display — 32 / 700 / -2%  (weight on Home, large numbers)
      displayLarge: TextStyle(
        fontFamily: fontSans,
        color: c,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 32,
        height: 1.1,
      ),
      // h1 — 28 / 600 / -1.5%  (screen titles)
      headlineLarge: TextStyle(
        fontFamily: fontSans,
        color: c,
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.015 * 28,
        height: 1.15,
      ),
      // h2 — 22 / 600 / -1%  (sheet titles, settings sections)
      headlineMedium: TextStyle(
        fontFamily: fontSans,
        color: c,
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01 * 22,
        height: 1.2,
      ),
      // h3 — 17 / 600 / -0.5%  (exercise names, card titles)
      titleLarge: TextStyle(
        fontFamily: fontSans,
        color: c,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.005 * 17,
      ),
      // body-lg — 17 / 400  (main readable text, AI messages)
      titleMedium: TextStyle(
        fontFamily: fontSans,
        color: c,
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0,
      ),
      // body — 15 / 400  (task lists, note previews)
      bodyLarge: TextStyle(
        fontFamily: fontSans,
        color: c,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0,
      ),
      // body-sm — 13 / 400
      bodyMedium: TextStyle(
        fontFamily: fontSans,
        color: c,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.45,
        letterSpacing: 0,
      ),
      // caption — 12 / 500 / +4% uppercase  (section labels)
      labelSmall: TextStyle(
        fontFamily: fontSans,
        color: c,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.04 * 12,
      ),
    );
  }

  // Default JetBrains Mono glyphs + tabular figures, matching the web mockups.
  // (No stylistic set — ss01 swaps glyph shapes and diverges from the design.)
  static const List<FontFeature> _monoFeatures = [
    FontFeature.tabularFigures(),
  ];

  /// Monospace — JetBrains Mono, w500 by default.
  /// Use for: weights, reps, percentages, dates in tables.
  static TextStyle mono({
    double fontSize = 13,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) =>
      TextStyle(
        fontFamily: fontMono,
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        fontFeatures: _monoFeatures,
      );

  /// Large mono — 22 / 500 (SetInputRow, chart axes)
  static TextStyle monoLg({Color? color}) => mono(fontSize: 22, color: color);

  /// Caps label — uppercase, tracked (section headers like ИСТОРИЯ)
  static TextStyle caps({Color? color}) => TextStyle(
        fontFamily: fontSans,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.08 * 11,
        color: color,
      );
}
