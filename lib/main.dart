import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/db/database.dart';
import 'core/notifications/notifications_service.dart';

/// Global database instance — passed to providers via ProviderScope override
late final AppDatabase database;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Open database
  database = AppDatabase();

  // 2. Init notifications (no permission prompt yet — we ask later in Settings)
  await NotificationsService.instance.init();

  runApp(
    ProviderScope(
      overrides: [
        // Expose the database to all Riverpod providers
        dbProvider.overrideWithValue(database),
      ],
      child: const MultiTrackerApp(),
    ),
  );
}

/// Global database provider — override in main() with the real instance
final dbProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('Provide AppDatabase via main.dart override'),
);
