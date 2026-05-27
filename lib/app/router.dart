import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/home/presentation/home_screen.dart';
import '../features/train/presentation/week_grid_screen.dart';
import '../features/tasks/presentation/tasks_screen.dart';
import '../features/notes/presentation/notes_screen.dart';
import '../features/ai_chat/presentation/ai_chat_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../shared/widgets/adaptive_scaffold.dart';

// ─────────────────────────────────────────────────────────────
// Route paths
// ─────────────────────────────────────────────────────────────

class AppRoutes {
  AppRoutes._();
  static const home     = '/';
  static const train    = '/train';
  static const tasks    = '/tasks';
  static const notes    = '/notes';
  static const ai       = '/ai';
  static const settings = '/settings';
}

// ─────────────────────────────────────────────────────────────
// Router
// ─────────────────────────────────────────────────────────────

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellKey          = GlobalKey<NavigatorState>(debugLabel: 'shell');

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: false,
  routes: [
    ShellRoute(
      navigatorKey: _shellKey,
      builder: (context, state, child) =>
          _AppShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (ctx, s) => _fade(const HomeScreen(), s),
        ),
        GoRoute(
          path: AppRoutes.train,
          pageBuilder: (ctx, s) => _fade(const WeekGridScreen(), s),
        ),
        GoRoute(
          path: AppRoutes.tasks,
          pageBuilder: (ctx, s) => _fade(const TasksScreen(), s),
        ),
        GoRoute(
          path: AppRoutes.notes,
          pageBuilder: (ctx, s) => _fade(const NotesScreen(), s),
        ),
        GoRoute(
          path: AppRoutes.ai,
          pageBuilder: (ctx, s) => _fade(const AiChatScreen(), s),
        ),
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (ctx, s) => _fade(const SettingsScreen(), s),
        ),
      ],
    ),
  ],
);

Page<dynamic> _fade(Widget child, GoRouterState state) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      ),
    );

// ─────────────────────────────────────────────────────────────
// Shell widget
// ─────────────────────────────────────────────────────────────

class _AppShell extends StatelessWidget {
  const _AppShell({required this.location, required this.child});

  final String location;
  final Widget child;

  static const _routes = [
    AppRoutes.home,
    AppRoutes.train,
    AppRoutes.tasks,
    AppRoutes.notes,
    AppRoutes.ai,
    AppRoutes.settings,
  ];

  int get _selectedIndex {
    // Exact match for '/', prefix match for others
    for (var i = 0; i < _routes.length; i++) {
      final r = _routes[i];
      if (r == '/' ? location == '/' : location.startsWith(r)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: replace string literals with AppLocalizations once generated
    return AdaptiveScaffold(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (i) => context.go(_routes[i]),
      destinations: const [
        AdaptiveDestination(
          icon: Icon(Icons.home_outlined),
          label: 'Главная',
        ),
        AdaptiveDestination(
          icon: Icon(Icons.fitness_center_outlined),
          label: 'Тренировки',
        ),
        AdaptiveDestination(
          icon: Icon(Icons.checklist_outlined),
          label: 'Задачи',
        ),
        AdaptiveDestination(
          icon: Icon(Icons.sticky_note_2_outlined),
          label: 'Заметки',
        ),
        AdaptiveDestination(
          icon: Icon(Icons.auto_awesome_outlined),
          label: 'AI',
        ),
        AdaptiveDestination(
          icon: Icon(Icons.settings_outlined),
          label: 'Настройки',
          isFooter: true,
        ),
      ],
      body: child,
    );
  }
}
