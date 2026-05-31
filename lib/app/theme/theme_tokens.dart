import 'package:flutter/material.dart';
import 'colors.dart';

/// Semantic colour tokens resolved from the current [ColorScheme].
/// Widgets should obtain one via [ThemeTokens.of] and read colours from it —
/// never from hardcoded [AppColors] constants.
class ThemeTokens {
  const ThemeTokens._(this._cs);

  factory ThemeTokens.of(BuildContext context) =>
      ThemeTokens._(Theme.of(context).colorScheme);

  final ColorScheme _cs;

  bool get _isDark => _cs.brightness == Brightness.dark;

  // ── Surfaces ─────────────────────────────────────────────────
  Color get bg            => _cs.surfaceContainerLow;
  Color get surface       => _cs.surface;
  Color get surfaceRaised => _cs.surfaceContainerHigh;
  Color get surfaceSunken => _cs.surfaceContainerHighest;

  // ── Borders / lines ──────────────────────────────────────────
  Color get border     => _cs.outline;
  Color get borderSoft => _cs.outlineVariant;
  Color get divider    => _cs.outlineVariant;

  // ── Text ─────────────────────────────────────────────────────
  Color get text1 => _cs.onSurface;
  Color get text2 => _cs.onSurface.withValues(alpha: 0.72);
  Color get text3 => _cs.onSurfaceVariant;
  Color get text4 => _cs.onSurface.withValues(alpha: 0.35);

  // ── Accent — theme-aware (light: sage #6B8F71 / dark: #8AAE90) ─
  Color get accent      => _cs.primary;
  Color get accentPress => _cs.onPrimaryContainer;
  Color get accentTint  => _cs.primaryContainer;

  // ── Semantic — brightness-aware ──────────────────────────────
  Color get success => _isDark ? AppColors.darkSuccess : AppColors.success;
  Color get warning => _isDark ? AppColors.darkWarning : AppColors.warning;
  Color get danger  => _isDark ? AppColors.darkDanger  : AppColors.danger;
}
