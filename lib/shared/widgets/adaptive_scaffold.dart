import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/theme/breakpoints.dart';
import '../../app/theme/colors.dart';
import '../../app/theme/radius.dart';

class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.body,
    this.onDestinationSelected,
    this.floatingActionButton,
  });

  final int selectedIndex;
  final List<AdaptiveDestination> destinations;
  final Widget body;
  final ValueChanged<int>? onDestinationSelected;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= kDesktopBreakpoint
        ? _DesktopLayout(
            selectedIndex: selectedIndex,
            destinations: destinations,
            body: body,
            onSelected: onDestinationSelected,
            fab: floatingActionButton,
          )
        : _MobileLayout(
            selectedIndex: selectedIndex,
            destinations: destinations,
            body: body,
            onSelected: onDestinationSelected,
            fab: floatingActionButton,
          );
  }
}

// ─────────────────────────────────────────────────────────────
// Mobile layout — blurred bottom bar
// ─────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.selectedIndex,
    required this.destinations,
    required this.body,
    this.onSelected,
    this.fab,
  });

  final int selectedIndex;
  final List<AdaptiveDestination> destinations;
  final Widget body;
  final ValueChanged<int>? onSelected;
  final Widget? fab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      floatingActionButton: fab,
      body: body,
      bottomNavigationBar: _BlurredTabBar(
        selectedIndex: selectedIndex,
        destinations: destinations,
        onSelected: onSelected,
      ),
    );
  }
}

class _BlurredTabBar extends StatelessWidget {
  const _BlurredTabBar({
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<AdaptiveDestination> destinations;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).padding.bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.88),
            border: Border(
              top: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: destinations.asMap().entries.map((e) {
                  final i = e.key;
                  final d = e.value;
                  final active = i == selectedIndex;
                  return Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                      onTap: () => onSelected?.call(i),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          key: ValueKey(active),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppColors.accentTint
                                    : Colors.transparent,
                                borderRadius: AppRadius.smAll,
                              ),
                              child: IconTheme(
                                data: IconThemeData(
                                  color: active
                                      ? AppColors.accentPress
                                      : theme.colorScheme.onSurfaceVariant,
                                  size: 22,
                                ),
                                child: d.icon,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              d.label,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.02 * 10,
                                color: active
                                    ? AppColors.accent
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Desktop layout — extended NavigationRail sidebar
// ─────────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.selectedIndex,
    required this.destinations,
    required this.body,
    this.onSelected,
    this.fab,
  });

  final int selectedIndex;
  final List<AdaptiveDestination> destinations;
  final Widget body;
  final ValueChanged<int>? onSelected;
  final Widget? fab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      floatingActionButton: fab,
      body: Row(
        children: [
          _DesktopSidebar(
            selectedIndex: selectedIndex,
            destinations: destinations,
            onSelected: onSelected,
          ),
          VerticalDivider(
            width: 1,
            color: theme.colorScheme.outlineVariant,
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<AdaptiveDestination> destinations;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mainDests = destinations.where((d) => !d.isFooter).toList();
    final footerDests = destinations.where((d) => d.isFooter).toList();

    return Container(
      width: 260,
      color: theme.colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 18),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accent, AppColors.accentPress],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: const Center(
                    child: Text(
                      'M',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Multi-tracker',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Main nav
          ...mainDests.map((d) {
            final i = destinations.indexOf(d);
            return _SidebarItem(
              destination: d,
              active: i == selectedIndex,
              onTap: () => onSelected?.call(i),
            );
          }),

          const Spacer(),

          // Footer nav (Settings)
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 8),
          ...footerDests.map((d) {
            final i = destinations.indexOf(d);
            return _SidebarItem(
              destination: d,
              active: i == selectedIndex,
              onTap: () => onSelected?.call(i),
            );
          }),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.destination,
    required this.active,
    required this.onTap,
    this.isFooter = false,
  });

  final AdaptiveDestination destination;
  final bool active;
  final VoidCallback onTap;
  final bool isFooter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = active ? AppColors.accentPress : AppColors.text2;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.accentTint : Colors.transparent,
          borderRadius: AppRadius.smAll,
        ),
        child: Row(
          children: [
            IconTheme(
              data: IconThemeData(color: iconColor, size: 20),
              child: destination.icon,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                destination.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: active ? AppColors.accentPress : AppColors.text2,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (destination.badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.accent
                      : AppColors.surfaceSunken,
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  '${destination.badge}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color:
                        active ? Colors.white : AppColors.text3,
                  ),
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────

class AdaptiveDestination {
  const AdaptiveDestination({
    required this.icon,
    required this.label,
    this.isFooter = false,
    this.badge,
    this.shortcut,
  });

  final Widget icon;
  final String label;
  final bool isFooter;
  final int? badge;
  final String? shortcut;
}
