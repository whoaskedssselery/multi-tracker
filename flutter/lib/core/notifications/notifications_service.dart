import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Unified local notifications — iOS + Android (Windows: no-op in this version)
class NotificationsService {
  NotificationsService._();
  static final NotificationsService instance = NotificationsService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Platforms with a flutter_local_notifications implementation we use.
  static bool get _supported => Platform.isIOS || Platform.isAndroid;

  // ── channel ids ──────────────────────────────────────────────
  static const _channelTasks   = 'tasks';
  static const _channelWorkout = 'workout';
  static const _channelWeight  = 'weight';

  // ── init ─────────────────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    if (!_supported) {
      _initialized = true;
      return; // no Windows implementation in v18
    }

    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    // Uses the app launcher icon for the status-bar notification.
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    try {
      await _plugin.initialize(
        const InitializationSettings(iOS: ios, android: android),
        onDidReceiveNotificationResponse: _onTap,
      );
    } catch (e) {
      // e.g. NSCocoaErrorDomain 3840 on iOS from a corrupt pending-notification
      // cache. Mark initialized so we don't retry every call; notifications
      // silently no-op this session.
      debugPrint('flutter_local_notifications init failed: $e');
      _initialized = true;
      return;
    }

    _initialized = true;
  }

  // ── permissions ──────────────────────────────────────────────
  Future<bool> requestPermissions() async {
    if (!_supported) return true;
    await _ensureInit();
    if (Platform.isIOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }
    // Android 13+ requires runtime POST_NOTIFICATIONS consent.
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return granted ?? true; // older Android grants at install time
  }

  // ── schedule task reminder ────────────────────────────────────
  Future<void> scheduleTask({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAt,
  }) async {
    if (!_supported) return;
    await _ensureInit();
    final tzTime = tz.TZDateTime.from(scheduledAt, tz.local);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      _details(_channelTasks, 'Task Reminders', 'Reminders for your tasks'),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  // ── daily weight reminder ─────────────────────────────────────
  Future<void> scheduleWeightReminder({
    required int id,
    required int hour,
    required int minute,
  }) async {
    if (!_supported) return;
    await _ensureInit();
    await _plugin.zonedSchedule(
      id,
      'Time to weigh in',
      'Log your weight to keep the streak going',
      _nextInstanceOfTime(hour, minute),
      _details(_channelWeight, 'Weight Reminders', 'Daily weight log reminder'),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ── workout reminder ─────────────────────────────────────────
  Future<void> scheduleWorkoutReminder({
    required int id,
    required String workoutName,
    required DateTime scheduledAt,
  }) async {
    if (!_supported) return;
    await _ensureInit();
    final tzTime = tz.TZDateTime.from(scheduledAt, tz.local);
    await _plugin.zonedSchedule(
      id,
      'Workout time: $workoutName',
      "Don't skip today's session",
      tzTime,
      _details(
          _channelWorkout, 'Workout Reminders', 'Training session reminders'),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancel(int id) async {
    if (!_supported) return;
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    if (!_supported) return;
    await _plugin.cancelAll();
  }

  // ── helpers ───────────────────────────────────────────────────
  NotificationDetails _details(
    String channelId,
    String channelName,
    String channelDesc,
  ) =>
      NotificationDetails(
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        android: AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
      );

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  void _onTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> _ensureInit() async {
    if (!_initialized) await init();
  }
}
