import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_settings.dart';
import 'risky_time_service.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance =
      LocalNotificationService._();

  static const int _dailyCheckInId = 1001;
  static const int _eveningSupportId = 1002;
  static const int _riskyTimeWarningId = 1003;

  static const String _channelId = 'scratchless_support';
  static const String _channelName = 'ScratchLess Support';
  static const String _channelDescription =
      'Gentle reminders to check in and pause before buying';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz_data.initializeTimeZones();

    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      // Falls back to the timezone package default if device timezone lookup fails.
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const settings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(settings);

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );

    _initialized = true;
  }

  Future<void> syncReminderSettings(
    ReminderSettings settings, {
    RiskyTimeInsight? riskyTimeInsight,
  }) async {
    await initialize();
    await cancelAllReminderNotifications();

    final shouldScheduleRiskyTime =
        settings.habitTimeWarningsEnabled &&
        riskyTimeInsight != null &&
        riskyTimeInsight.hasEnoughData &&
        riskyTimeInsight.anchorHour != null;

    if (!settings.dailyCheckInEnabled &&
        !settings.eveningSupportEnabled &&
        !shouldScheduleRiskyTime) {
      return;
    }

    final granted = await _requestNotificationPermission();
    if (granted == false) {
      return;
    }

    if (settings.dailyCheckInEnabled) {
      await _scheduleDailyCheckIn(settings.dailyCheckInHour);
    }

    if (settings.eveningSupportEnabled) {
      await _scheduleEveningSupport();
    }

    if (shouldScheduleRiskyTime) {
      await _scheduleRiskyTimeWarning(riskyTimeInsight.anchorHour!);
    }
  }

  Future<void> cancelAllReminderNotifications() async {
    await _plugin.cancel(_dailyCheckInId);
    await _plugin.cancel(_eveningSupportId);
    await _plugin.cancel(_riskyTimeWarningId);
  }

  Future<bool?> _requestNotificationPermission() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    return await androidPlugin?.requestNotificationsPermission() ?? true;
  }

  Future<void> _scheduleDailyCheckIn(int hour) async {
    await _plugin.zonedSchedule(
      _dailyCheckInId,
      'ScratchLess check-in',
      'Quick check-in: how did today go?',
      _nextInstanceOfTime(hour, 0),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleEveningSupport() async {
    await _plugin.zonedSchedule(
      _eveningSupportId,
      'Pause before you buy',
      'If the urge hits tonight, open ScratchLess first.',
      _nextInstanceOfTime(19, 0),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}
