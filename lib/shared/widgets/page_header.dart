import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/spacing.dart';
import '../../app/theme/theme_tokens.dart';
import '../../app/theme/typography.dart';

// ─────────────────────────────────────────────────────────────────────────────
// iOS large-title style header — NOT a fixed bar, embedded in scroll content.
// Use this on iOS instead of AppPageHeader.
// ─────────────────────────────────────────────────────────────────────────────

class IosPageHeader extends StatelessWidget {
  const IosPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  // Optional widget rendered below the title row (e.g. filter chips)
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final t = ThemeTokens.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: t.text1,
                          height: 1.1,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: TextStyle(fontSize: 14, color: t.text3),
                        ),
                      ],
                    ],
                  ),
                ),
                if (action != null) ...[
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: action!,
                  ),
                ],
              ],
            ),
            if (bottom != null) ...[
              const SizedBox(height: 14),
              bottom!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Unified page header bar — fixed height across every screen so the
/// app chrome lines up (design `.main-head`, 64–72px, bottom divider).
///
/// Title stays [TextTheme.headlineLarge]; an optional [subtitle] renders in
/// mono below it. [actions] sit at the trailing edge, vertically centred —
/// so a one-line page (Tasks) and a two-line page (Train) are the same height.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  /// Fixed bar height — identical on all screens.
  static const double height = 72;

  @override
  Widget build(BuildContext context) {
    final t = ThemeTokens.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Status-bar icons: light on the dark theme, dark on the light theme.
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl3),
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(bottom: BorderSide(color: t.divider)),
      ),
      child: Row(
        children: [
          // Expanded fills the bar so actions are pushed to the right edge;
          // the title text ellipsizes on narrow widths instead of overflowing.
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.mono(fontSize: 13, color: t.text3)),
                ],
              ],
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 16),
            ...actions,
          ],
        ],
      ),
      ),
    );
  }
}
