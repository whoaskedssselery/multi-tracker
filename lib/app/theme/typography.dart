import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Typography tokens — matched to design spec A.3
class AppTypography {
  AppTypography._();

  static TextTheme buildTextTheme(ColorScheme colors) {
    final base = GoogleFonts.interTextTheme().apply(
      bodyColor: colors.onSurface,
      displayColor: colors.onSurface,
    );
    return base.copyWith(
      // display — 32 / 700 / -2%  (weight on Home, large numbers)
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.02 * 32,
        height: 1.1,
      ),
      // h1 — 28 / 600 / -1.5%  (screen titles)
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.015 * 28,
        height: 1.15,
      ),
      // h2 — 22 / 600 / -1%  (sheet titles, settings sections)
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01 * 22,
        height: 1.2,
      ),
      // h3 — 17 / 600 / -0.5%  (exercise names, card titles)
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.005 * 17,
      ),
      // body-lg — 17 / 400  (main readable text, AI messages)
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0,
      ),
      // body — 15 / 400  (task lists, note previews)
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.5,
        letterSpacing: 0,
      ),
      // body-sm — 13 / 400
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.45,
        letterSpacing: 0,
      ),
      // caption — 12 / 500 / +4% uppercase  (section labels)
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.04 * 12,
      ),
    );
  }

  /// Monospace — JetBrains Mono, w500 by default.
  /// Use for: weights, reps, percentages, dates in tables.
  static TextStyle mono({
    double fontSize = 13,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        fontFeatures: [
          const FontFeature.tabularFigures(),
          FontFeature.stylisticSet(1), // ss01 — fixes 0/1 jumps
        ],
      );

  /// Large mono — 22 / 500 (SetInputRow, chart axes)
  static TextStyle monoLg({Color? color}) => mono(fontSize: 22, color: color);

  /// Caps label — uppercase, tracked (section headers like ИСТОРИЯ)
  static TextStyle caps({Color? color}) => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.08 * 11,
        color: color,
      );
}
