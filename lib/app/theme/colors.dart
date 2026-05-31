import 'package:flutter/material.dart';

/// Design tokens — colour palette (from design spec A.1)
class AppColors {
  AppColors._();

  // ── Light surfaces ───────────────────────────────────────────
  static const Color bg            = Color(0xFFFAF7F0);
  static const Color surface       = Color(0xFFFFFDF7);
  static const Color surfaceSunken = Color(0xFFF0EBDD);
  static const Color surfaceRaised = Color(0xFFE6E0CE);

  // ── Light text ───────────────────────────────────────────────
  static const Color text1 = Color(0xFF17150F);
  static const Color text2 = Color(0xFF4D4A41);
  static const Color text3 = Color(0xFF85806F);
  static const Color text4 = Color(0xFFB8B19C);

  // ── Light lines ──────────────────────────────────────────────
  static const Color border     = Color(0xFFD9D2BE);
  static const Color borderSoft = Color(0xFFE5DFCA);
  static const Color divider    = Color(0xFFE8E2CF);

  // ── Accent — sage green ──────────────────────────────────────
  static const Color accent      = Color(0xFF6B8F71);
  static const Color accentPress = Color(0xFF4A6E51);
  static const Color accentSoft  = Color(0xFFE8E5D2);
  static const Color accentTint  = Color(0xFFDFE9DD);

  // ── Light semantic ───────────────────────────────────────────
  static const Color success = Color(0xFF5C8A6E);
  static const Color warning = Color(0xFFC97A3A);
  static const Color danger  = Color(0xFFB04B3F);

  // ── Dark surfaces — warm charcoal w/ tan undertone (theme.css) ─
  // Steps: sunken (#100E0A) < bg (#15130E) < surface (#1E1B15) < raised.
  static const Color darkBg             = Color(0xFF15130E);
  static const Color darkSurface        = Color(0xFF1E1B15);
  static const Color darkSurfaceRaised  = Color(0xFF2A2620);
  static const Color darkSurfaceSunken  = Color(0xFF100E0A);
  static const Color darkSurfaceOverlay = Color(0xFF2A2620);

  // ── Dark text — warm cream → muted tan ───────────────────────
  static const Color darkText1 = Color(0xFFF2EEE3);
  static const Color darkText2 = Color(0xFFB8B19C);
  static const Color darkText3 = Color(0xFF85806F);
  static const Color darkText4 = Color(0xFF524D43);

  // ── Dark lines ───────────────────────────────────────────────
  static const Color darkBorder     = Color(0xFF322D23);
  static const Color darkBorderSoft = Color(0xFF26221A);
  static const Color darkDivider    = Color(0xFF26221A);

  // ── Dark accent — sage, lifted for dark surfaces ─────────────
  static const Color darkAccent      = Color(0xFF8FB295);
  static const Color darkAccentPress = Color(0xFFA8C7AD);
  static const Color darkAccentSoft  = Color(0xFF2A332B);
  static const Color darkAccentTint  = Color(0xFF202B22);

  // ── Dark semantic ────────────────────────────────────────────
  static const Color darkSuccess = Color(0xFF8FB295);
  static const Color darkWarning = Color(0xFFD8956A);
  static const Color darkDanger  = Color(0xFFD17468);
}
