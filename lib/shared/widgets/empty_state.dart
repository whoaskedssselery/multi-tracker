import 'package:flutter/material.dart';

import '../../app/theme/colors.dart';
import '../../app/theme/spacing.dart';
import 'app_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.body,
    this.action,
    this.actionLabel,
    this.icon,
  });

  final String title;
  final String? body;
  final VoidCallback? action;
  final String? actionLabel;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              IconTheme(
                data: const IconThemeData(size: 48, color: AppColors.text4),
                child: icon!,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.text2,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (body != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                body!,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.text3),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: AppSpacing.xl2),
              AppButton(label: actionLabel!, onPressed: action),
            ],
          ],
        ),
      ),
    );
  }
}
