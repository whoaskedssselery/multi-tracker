import 'package:flutter/material.dart';

import '../../app/theme/animations.dart';
import '../../app/theme/colors.dart';

/// iOS-style bottom sheet with smooth spring animation.
/// Use [showAnimatedSheet] instead of showModalBottomSheet for consistency.
class AnimatedSheet extends StatelessWidget {
  const AnimatedSheet({
    super.key,
    required this.child,
    this.showHandle = true,
    this.initialChildSize = 0.92,
    this.minChildSize = 0.5,
    this.snap = true,
  });

  final Widget child;
  final bool showHandle;
  final double initialChildSize;
  final double minChildSize;
  final bool snap;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: 0.95,
      snap: snap,
      snapSizes: snap ? [minChildSize, initialChildSize, 0.95] : null,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            if (showHandle)
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 4),
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.text4.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<T?> showAnimatedSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool showHandle = true,
  double initialSize = 0.92,
  double minSize = 0.5,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    transitionAnimationController: AnimationController(
      vsync: Navigator.of(context),
      duration: AppAnimations.sheet,
    ),
    builder: (ctx) => AnimatedSheet(
      showHandle: showHandle,
      initialChildSize: initialSize,
      minChildSize: minSize,
      child: builder(ctx),
    ),
  );
}
