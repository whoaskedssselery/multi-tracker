import 'package:flutter/material.dart';

import '../../app/theme/breakpoints.dart';
import '../../app/theme/radius.dart';
import '../../app/theme/theme_tokens.dart';

/// Presents [builder]'s content adaptively:
///   • desktop (≥ [kDesktopBreakpoint]) → centered [Dialog] capped at [maxWidth]
///   • mobile (iOS) → bottom sheet with a drag handle, rounded top and a
///     smooth slide-up (340ms easeOutCubic) — the primary mobile pattern.
///
/// The [builder] returns the SAME content Column (header / scroll body /
/// footer) for both — only the surrounding chrome differs.
Future<T?> showAppModal<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double maxWidth = 560,
}) {
  final mobile = MediaQuery.sizeOf(context).width < kDesktopBreakpoint;

  if (mobile) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: ThemeTokens.of(context).bg,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.94,
      ),
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 340),
        reverseDuration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
      builder: (ctx) => _SheetShell(child: builder(ctx)),
    );
  }

  return showDialog<T>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.40),
    builder: (ctx) {
      final t = ThemeTokens.of(ctx);
      final h = MediaQuery.sizeOf(ctx).height;
      return Dialog(
        backgroundColor: t.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: h * 0.9),
          child: builder(ctx),
        ),
      );
    },
  );
}

/// Mobile bottom-sheet wrapper: drag handle + the modal content.
class _SheetShell extends StatelessWidget {
  const _SheetShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = ThemeTokens.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 8, bottom: 2),
          width: 36,
          height: 5,
          decoration: BoxDecoration(
            color: t.text4,
            borderRadius: BorderRadius.circular(100),
          ),
        ),
        Flexible(child: child),
      ],
    );
  }
}
