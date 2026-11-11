import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Daily reminders shown by the phone. The only words on a reminder are the
/// ones the girl chose, so nothing on her lock screen says PEP, HIV or GirlCare72.
class Reminders {
  Reminders._();
  static final instance = Reminders._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  /// True when this phone can show reminders while the app is closed.
  bool get available => _ready;

  Future<void> init() async {
    if (_ready || kIsWeb) return; // in a browser the reminder shows only inside the app
    try {
      tzdata.initializeTimeZones();
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
        ),
      );
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  /// Asks the phone to allow notifications. True when allowed.
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) return await android.requestNotificationsPermission() ?? false;
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) return await ios.requestPermissions(alert: true, sound: true) ?? false;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// One reminder a day for [days] days from [first], at [hour]:[minute].
  /// Each day is scheduled on its own, so no repeat rule can drift.
  Future<void> scheduleDaily({required String label, required DateTime first, required int hour, required int minute, required int days}) async {
    if (!_ready) return;
    await cancelAll();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'daily',
        'Daily reminders',
        channelDescription: 'Reminders you set in the app',
        visibility: NotificationVisibility.private,
      ),
      iOS: DarwinNotificationDetails(),
    );
    final now = DateTime.now();
    for (var i = 0; i < days; i++) {
      final at = DateTime(first.year, first.month, first.day + i, hour, minute);
      if (at.isBefore(now)) continue;
      try {
        await _plugin.zonedSchedule(
          id: 100 + i,
          title: label,
          scheduledDate: tz.TZDateTime.from(at.toUtc(), tz.UTC),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (_) {
        // One failed day should not stop the others.
      }
    }
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
