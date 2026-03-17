import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'progress_service.dart';

class NotificationService extends ChangeNotifier {
  NotificationService(this._prefs);

  static const String _enabledKey = 'daily_reminder_enabled';
  static const String _hourKey = 'daily_reminder_hour';
  static const String _minuteKey = 'daily_reminder_minute';

  final SharedPreferences _prefs;
  bool _initialized = false;

  // Notifications are temporarily disabled project-wide.
  bool get isReminderEnabled => false;

  TimeOfDay get reminderTime {
    final hour = _prefs.getInt(_hourKey) ?? 19;
    final minute = _prefs.getInt(_minuteKey) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> initialize({required ProgressService progressService}) async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    debugPrint(
      '[NotificationService] disabled: initialize skipped (notifications off)',
    );
  }

  Future<void> setReminderEnabled(bool enabled) async {
    // Keep preference write only to preserve existing settings compatibility.
    await _prefs.setBool(_enabledKey, enabled);
    notifyListeners();
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    // Keep preference write only to preserve existing settings compatibility.
    await _prefs.setInt(_hourKey, time.hour);
    await _prefs.setInt(_minuteKey, time.minute);
    notifyListeners();
  }

  Future<void> syncDailyReminder() async {
    // Intentionally no-op while notifications are disabled.
    debugPrint('[NotificationService] disabled: syncDailyReminder no-op');
  }
}
