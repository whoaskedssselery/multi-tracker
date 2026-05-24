import 'package:flutter/material.dart';

import '../../app/theme/animations.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/radius.dart';

enum AppButtonVariant { primary, secondary, ghost, icon }

/// Press-to-scale tappable button matching the design system
class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.loading = false,
    this.fullWidth = false,
    this.minHeight = 44.0,
  });

  const AppButton.icon({
    super.key,
    required Widget icon,
    VoidCallback? onPressed,
    bool loading = false,
  })  : label = '',
        leadingIcon = icon,
        trailingIcon = null,
        onPressed = onPressed,
        variant = AppButtonVariant.icon,
        loading = loading,
        fullWidth = false,
        minHeight = 44;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final bool loading;
  final bool fullWidth;
  final double minHeight;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppAnimations.fast,
      value: 1,
    );
    _scale = Tween<double>(begin: 1, end: AppAnimations.pressScale)
        .animate(CurvedAnimation(parent: _ctrl, curve: AppAnimations.standard));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ctrl.reverse();
  void _onTapUp(_) => _ctrl.forward();
  void _onTapCancel() => _ctrl.forward();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = widget.onPressed != null && !widget.loading;

    return GestureDetector(
      onTapDown: enabled ? _onTapDown : null,
      onTapUp: enabled ? _onTapUp : null,
      onTapCancel: enabled ? _onTapCancel : null,
      onTap: enabled ? widget.onPressed : null,
      child: ScaleTransition(
        scale: _scale,
        child: _buildInner(theme, enabled),
      ),
    );
  }

  Widget _buildInner(ThemeData theme, bool enabled) {
    final v = widget.variant;

    Color bg;
    Color fg;
    Border? border;

    switch (v) {
      case AppButtonVariant.primary:
        bg = enabled ? AppColors.accent : AppColors.accentSoft;
        fg = Colors.white;
      case AppButtonVariant.secondary:
        bg = theme.colorScheme.surface;
        fg = enabled ? theme.colorScheme.onSurface : AppColors.text3;
        border = Border.all(color: AppColors.border);
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        fg = enabled ? AppColors.text2 : AppColors.text4;
      case AppButtonVariant.icon:
        bg = Colors.transparent;
        fg = enabled ? AppColors.text2 : AppColors.text4;
    }

    final isIcon = v == AppButtonVariant.icon;

    return AnimatedContainer(
      duration: AppAnimations.fast,
      width: isIcon ? widget.minHeight : (widget.fullWidth ? double.infinity : null),
      height: isIcon ? widget.minHeight : null,
      constraints: isIcon ? null : BoxConstraints(minHeight: widget.minHeight),
      padding: isIcon
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.mdAll,
        border: border,
      ),
      child: _content(fg),
    );
  }

  Widget _content(Color fg) {
    if (widget.loading) {
      return SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: fg,
        ),
      );
    }

    if (widget.variant == AppButtonVariant.icon) {
      return Center(
        child: IconTheme(data: IconThemeData(color: fg, size: 20), child: widget.leadingIcon!),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leadingIcon != null) ...[
          IconTheme(data: IconThemeData(color: fg, size: 18), child: widget.leadingIcon!),
          const SizedBox(width: 8),
        ],
        if (widget.label.isNotEmpty)
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: 8),
          IconTheme(data: IconThemeData(color: fg, size: 16), child: widget.trailingIcon!),
        ],
      ],
    );
  }
}
