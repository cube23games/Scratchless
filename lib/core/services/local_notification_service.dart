import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_settings.dart';
import 'risky_time_service.dart';

typedef LiveAlertLaunchHandler = Future<void> Function({
  required String placeLabel,
  required bool autoStartTenMinutePause,
});

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance =
      LocalNotificationService._();

  static const int _dailyCheckInId = 1001;
  static const int _eveningSupportId = 1002;
  static const int _riskyTimeWarningId = 1003;
  static const int _livePlaceAlertId = 1004;

  static const String _channelId = 'scratchless_support';
  static const String _channelName = 'ScratchLess Support';
  static const String _channelDescription =
      'Gentle reminders to check in and pause before buying';

  static const String _liveAlertPayloadPrefix = 'live-alert:';
  static const String _wait10ActionId = 'wait10';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  LiveAlertLaunchHandler? _liveAlertLaunchHandler;
  String? _pendingLiveAlertPlaceLabel;
  String? _pendingLiveAlertActionId;
  bool _initialized = false;

  void registerLiveAlertLauncher(LiveAlertLaunchHandler launcher) {
    _liveAlertLaunchHandler = launcher;
    _drainPendingLiveAlertNavigation();
  }

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

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

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

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.notificationResponse?.payload;
    final launchActionId = launchDetails?.notificationResponse?.actionId;

    if (launchPayload != null &&
        launchPayload.startsWith(_liveAlertPayloadPrefix)) {
      _pendingLiveAlertPlaceLabel = Uri.decodeComponent(
        launchPayload.substring(_liveAlertPayloadPrefix.length),
      );
      _pendingLiveAlertActionId = launchActionId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _drainPendingLiveAlertNavigation();
      });
    }

    _initialized = true;
  }

  Future<void> syncReminderSettings(
    ReminderSettings settings, {
    RiskyTimeInsight? riskyTimeInsight,
  }) async {
    await initialize();
    await cancelAllReminderNotifications();

    final shouldScheduleRiskyTime = settings.habitTimeWarningsEnabled &&
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

  Future<void> _scheduleRiskyTimeWarning(int anchorHour) async {
    final scheduledHour = (anchorHour + 23) % 24;

    await _plugin.zonedSchedule(
      _riskyTimeWarningId,
      'Harder window ahead',
      'This is one of your riskier times. Open ScratchLess before the usual stop.',
      _nextInstanceOfTime(scheduledHour, 0),
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

  NotificationDetails _liveAlertNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            _wait10ActionId,
            'Wait 10 min',
            showsUserInterface: true,
          ),
        ],
      ),
    );
  }

  void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || !payload.startsWith(_liveAlertPayloadPrefix)) {
      return;
    }

    final encoded = payload.substring(_liveAlertPayloadPrefix.length);
    _pendingLiveAlertPlaceLabel = Uri.decodeComponent(encoded);
    _pendingLiveAlertActionId = response.actionId;
    _drainPendingLiveAlertNavigation();
  }

  void _drainPendingLiveAlertNavigation() {
    final pendingPlace = _pendingLiveAlertPlaceLabel;
    final pendingAction = _pendingLiveAlertActionId;
    final launcher = _liveAlertLaunchHandler;

    if (pendingPlace == null || launcher == null) {
      return;
    }

    _pendingLiveAlertPlaceLabel = null;
    _pendingLiveAlertActionId = null;

    launcher(
      placeLabel: pendingPlace,
      autoStartTenMinutePause: pendingAction == _wait10ActionId,
    );
  }

  Future<void> showLivePlaceAlert({
    required String headline,
    required String body,
    required String placeLabel,
  }) async {
    await initialize();

    final granted = await _requestNotificationPermission();
    if (granted == false) {
      return;
    }

    await _plugin.show(
      _livePlaceAlertId,
      headline,
      body,
      _liveAlertNotificationDetails(),
      payload: '$_liveAlertPayloadPrefix${Uri.encodeComponent(placeLabel)}',
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
