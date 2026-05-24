import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:multi_tracker/l10n/app_localizations.dart';

import 'router.dart';
import 'theme/light_theme.dart';
import 'theme/dark_theme.dart';

class MultiTrackerApp extends StatelessWidget {
  const MultiTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Multi-tracker',
      debugShowCheckedModeBanner: false,

      // Themes
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.light, // TODO: read from settings provider

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
      locale: const Locale('ru'), // TODO: read from settings provider
    );
  }
}
