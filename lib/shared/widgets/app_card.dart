import 'package:flutter/material.dart';

import '../../app/theme/animations.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/radius.dart';
import '../../app/theme/spacing.dart';

enum AppCardVariant { regular, muted, hero }

/// Design-system card with optional press animation
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.regular,
    this.onTap,
    this.padding,
    this.margin,
  });

  final Widget child;
  final AppCardVariant variant;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppAnimations.fast, value: 1);
    _scale = Tween<double>(begin: 1, end: 0.985)
        .animate(CurvedAnimation(parent: _ctrl, curve: AppAnimations.standard));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tappable = widget.onTap != null;

    Color bg;
    BoxBorder? border;
    double elevation = 0;

    switch (widget.variant) {
      case AppCardVariant.regular:
        bg = theme.colorScheme.surface;
        border = Border.all(color: AppColors.borderSoft);
      case AppCardVariant.muted:
        bg = theme.colorScheme.surfaceContainerHighest;
        border = null;
      case AppCardVariant.hero:
        bg = theme.colorScheme.surface;
        border = Border.all(color: AppColors.accent, width: 2);
    }

    final card = AnimatedContainer(
      duration: AppAnimations.normal,
      margin: widget.margin ?? EdgeInsets.zero,
      padding: widget.padding ?? const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.lgAll,
        border: border,
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: widget.child,
    );

    if (!tappable) return card;

    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.forward(),
      onTap: widget.onTap,
      child: ScaleTransition(scale: _scale, child: card),
    );
  }
}
