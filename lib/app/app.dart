import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multi_tracker/l10n/app_localizations.dart';

import '../core/sync/sync_service.dart';
import 'providers/providers.dart';
import 'router.dart';
import 'theme/light_theme.dart';
import 'theme/dark_theme.dart';

class MultiTrackerApp extends ConsumerWidget {
  const MultiTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    // Instantiate the sync controller at app start (without rebuilding on its
    // state changes) so a restored session auto-syncs on launch.
    ref.listen(syncControllerProvider, (_, __) {});

    return MaterialApp.router(
      title: 'Multi-tracker',
      debugShowCheckedModeBanner: false,

      // Themes
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,

      // Router
      routerConfig: appRouter,

      // Localisation
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
    );
  }
}
