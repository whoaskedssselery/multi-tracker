import 'package:flutter/material.dart';
import 'colors.dart';

/// Semantic color tokens resolved from the current [ColorScheme].
/// Each content widget should obtain one via [ThemeTokens.of] and
/// read colors from it — never from hardcoded [AppColors] constants.
class ThemeTokens {
  const ThemeTokens._(this._cs);

  factory ThemeTokens.of(BuildContext context) =>
      ThemeTokens._(Theme.of(context).colorScheme);

  final ColorScheme _cs;

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

  // ── Accent (same in both themes) ─────────────────────────────
  Color get accent      => AppColors.accent;
  Color get accentPress => AppColors.accentPress;
  Color get accentTint  => _cs.primaryContainer;

  // ── Semantic ─────────────────────────────────────────────────
  Color get success => AppColors.success;
  Color get warning => AppColors.warning;
  Color get danger  => AppColors.danger;
}
