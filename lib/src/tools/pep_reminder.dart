import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../format.dart';
import '../notifications.dart';

/// PEP is one pill a day for 28 days. This remembers her start day, the
/// reminder time, the neutral words on the reminder, and the days she marked
/// as taken. All of it stays on this phone.
class PepReminder extends ChangeNotifier {
  static const days = 28;
  static const labels = ['Daily reminder', 'Take your vitamins', 'Drink water', 'Study time'];
  static const _key = 'pep';

  SharedPreferences? _prefs;
  DateTime? start;
  int hour = 20;
  int minute = 0;
  String label = labels.first;
  Set<int> taken = {};

  /// Whether the phone agreed to show reminders when the app is closed.
  bool phoneReminds = false;

  bool get active => start != null;
  int get today => active ? dayNumber(start!, DateTime.now()) : 0;
  bool get finished => active && today > days;
  bool get takenToday => taken.contains(today);
  DateTime? get lastDay => start?.add(const Duration(days: days - 1));

  /// Day 1 is the start day itself.
  static int dayNumber(DateTime start, DateTime date) => dateOnly(date).difference(dateOnly(start)).inDays + 1;

  void attach(SharedPreferences prefs) {
    _prefs = prefs;
    final raw = prefs.getString(_key);
    if (raw != null) {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      start = DateTime.tryParse(j['start'] as String? ?? '');
      hour = (j['hour'] as num?)?.toInt() ?? hour;
      minute = (j['minute'] as num?)?.toInt() ?? minute;
      label = j['label'] as String? ?? label;
      taken = ((j['taken'] as List?) ?? []).map((e) => (e as num).toInt()).toSet();
      phoneReminds = j['phone'] == true;
    }
    notifyListeners();
  }

  /// Starts (or changes) the 28 days and sets the phone reminders.
  Future<void> begin({required DateTime firstDay, required int hour, required int minute, required String label}) async {
    final first = dateOnly(firstDay);
    if (start != first) taken = {};
    start = first;
    this.hour = hour;
    this.minute = minute;
    this.label = label;
    final r = Reminders.instance;
    await r.init();
    phoneReminds = await r.requestPermission();
    await r.scheduleDaily(label: label, first: first, hour: hour, minute: minute, days: days);
    await _save();
  }

  Future<void> setTakenToday(bool value) async {
    if (!active) return;
    value ? taken.add(today) : taken.remove(today);
    await _save();
  }

  Future<void> stop() async {
    start = null;
    taken = {};
    phoneReminds = false;
    await Reminders.instance.cancelAll();
    await _prefs?.remove(_key);
    notifyListeners();
  }

  Future<void> _save() async {
    await _prefs?.setString(
      _key,
      jsonEncode({'start': start?.toIso8601String(), 'hour': hour, 'minute': minute, 'label': label, 'taken': taken.toList(), 'phone': phoneReminds}),
    );
    notifyListeners();
  }
}
