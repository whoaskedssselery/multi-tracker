import 'package:flutter/material.dart';

/// Design tokens — light palette (from design spec)
class AppColors {
  AppColors._();

  // Surfaces
  static const Color bg            = Color(0xFFFAF7F0);
  static const Color surface       = Color(0xFFFFFDF7);
  static const Color surfaceSunken = Color(0xFFF0EBDD);
  static const Color surfaceRaised = Color(0xFFE6E0CE);

  // Text
  static const Color text1 = Color(0xFF17150F);
  static const Color text2 = Color(0xFF4D4A41);
  static const Color text3 = Color(0xFF85806F);
  static const Color text4 = Color(0xFFB8B19C);

  // Lines
  static const Color border     = Color(0xFFD9D2BE);
  static const Color borderSoft = Color(0xFFE5DFCA);
  static const Color divider    = Color(0xFFE8E2CF);

  // Accent — sage green
  static const Color accent      = Color(0xFF6B8F71);
  static const Color accentPress = Color(0xFF4A6E51);
  static const Color accentSoft  = Color(0xFFE8DFC8);
  static const Color accentTint  = Color(0xFFDFE9DD);

  // Semantic
  static const Color success = Color(0xFF5C8A6E);
  static const Color warning = Color(0xFFC97A3A);
  static const Color danger  = Color(0xFFB04B3F);

  // Dark palette
  static const Color darkBg            = Color(0xFF111009);
  static const Color darkSurface       = Color(0xFF1A1814);
  static const Color darkSurfaceSunken = Color(0xFF13120E);
  static const Color darkSurfaceRaised = Color(0xFF232118);

  static const Color darkText1 = Color(0xFFF0EDE6);
  static const Color darkText2 = Color(0xFFB5B09E);
  static const Color darkText3 = Color(0xFF736E5E);
  static const Color darkText4 = Color(0xFF4A4740);

  static const Color darkBorder     = Color(0xFF2E2B22);
  static const Color darkBorderSoft = Color(0xFF252219);
  static const Color darkDivider    = Color(0xFF27241B);

  // Accent same in dark
  static const Color darkAccent      = Color(0xFF6B8F71);
  static const Color darkAccentPress = Color(0xFF4A6E51);
  static const Color darkAccentSoft  = Color(0xFF1F2B20);
  static const Color darkAccentTint  = Color(0xFF1A2A1C);
}
