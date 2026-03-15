import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'progress_service.dart';

class NotificationService extends ChangeNotifier {
  NotificationService(this._prefs);

  static const String _enabledKey = 'daily_reminder_enabled';
  static const String _hourKey = 'daily_reminder_hour';
  static const String _minuteKey = 'daily_reminder_minute';
  static const String _permissionAskedKey = 'daily_reminder_permission_asked';
  static const int _dailyNotificationId = 7001;

  final SharedPreferences _prefs;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  ProgressService? _progressService;
  bool _initialized = false;

  bool get isReminderEnabled => _prefs.getBool(_enabledKey) ?? true;

  TimeOfDay get reminderTime {
    final hour = _prefs.getInt(_hourKey) ?? 19;
    final minute = _prefs.getInt(_minuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> initialize({required ProgressService progressService}) async {
    if (_initialized) {
      _attachProgress(progressService);
      return;
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const init = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(init);

    tz.initializeTimeZones();

    _attachProgress(progressService);
    await _requestPermissionIfNeeded();
    await syncDailyReminder();
    _initialized = true;
  }

  Future<void> setReminderEnabled(bool enabled) async {
    await _prefs.setBool(_enabledKey, enabled);
    await syncDailyReminder();
    notifyListeners();
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    await _prefs.setInt(_hourKey, time.hour);
    await _prefs.setInt(_minuteKey, time.minute);
    await syncDailyReminder();
    notifyListeners();
  }

  Future<void> syncDailyReminder() async {
    await _plugin.cancel(_dailyNotificationId);
    if (!isReminderEnabled) {
      return;
    }

    final progress = _progressService;
    final now = DateTime.now();
    final time = reminderTime;
    var trigger = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    final completedToday = progress?.isDailyCompleted(now: now) ?? false;
    if (completedToday || !trigger.isAfter(now)) {
      trigger = trigger.add(const Duration(days: 1));
    }

    final scheduled = tz.TZDateTime.from(trigger, tz.local);
    await _plugin.zonedSchedule(
      _dailyNotificationId,
      'Zip Path',
      'Your daily puzzle is ready 🔥',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'zip_daily_channel',
          'Daily reminders',
          channelDescription: 'Daily puzzle reminder notifications',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> _requestPermissionIfNeeded() async {
    final asked = _prefs.getBool(_permissionAskedKey) ?? false;
    if (asked) {
      return;
    }
    await _prefs.setBool(_permissionAskedKey, true);

    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();

    final ios =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void _attachProgress(ProgressService progressService) {
    if (_progressService == progressService) {
      return;
    }
    _progressService?.removeListener(_onProgressChanged);
    _progressService = progressService;
    _progressService?.addListener(_onProgressChanged);
  }

  void _onProgressChanged() {
    syncDailyReminder();
  }

  @override
  void dispose() {
    _progressService?.removeListener(_onProgressChanged);
    super.dispose();
  }
}
