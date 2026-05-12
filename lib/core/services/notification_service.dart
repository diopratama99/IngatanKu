import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  static const _channelId = 'ingatanku_streak';
  static const _channelName = 'Streak reminders';
  static const _streakNotifId = 1001;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Create the Android channel
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Reminders to keep your save-streak alive',
          importance: Importance.high,
        ));

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    // Android 13+: POST_NOTIFICATIONS runtime permission
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.notification.request();
      if (!status.isGranted) return false;
    }
    // iOS
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final ok = await ios.requestPermissions(alert: true, badge: true, sound: true);
      if (ok != true) return false;
    }
    return true;
  }

  /// Schedules a daily streak reminder at [hour]:[minute] local time.
  /// Cancels any previously scheduled streak notif first.
  Future<void> scheduleStreakReminder({
    required int currentStreak,
    int hour = 20,
    int minute = 0,
  }) async {
    await init();
    if (!await requestPermissions()) return;

    await _plugin.cancel(_streakNotifId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    final body = currentStreak > 0
        ? 'Jangan putuskan streak $currentStreak harimu! Simpan satu reel hari ini.'
        : 'Mulai streak-mu hari ini — simpan satu ilmu tech.';

    await _plugin.zonedSchedule(
      _streakNotifId,
      'IngatanKu',
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: 'Reminders to keep your save-streak alive',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }

  Future<void> cancelStreakReminder() async {
    await _plugin.cancel(_streakNotifId);
  }
}
