import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../format.dart';

/// The first day of each period, on this phone only. From those it guesses
/// when the next one will come.
class PeriodTracker extends ChangeNotifier {
  static const defaultCycle = 28;
  static const _key = 'periods';

  SharedPreferences? _prefs;
  List<DateTime> starts = [];

  DateTime? get last => starts.isEmpty ? null : starts.last;
  int get cycleLength => averageCycle(starts);

  /// True until she has logged two periods, so the guess is the usual 28 days.
  bool get estimated => starts.length < 2;
  DateTime? get nextExpected => last?.add(Duration(days: cycleLength));

  /// Days from [now] to the next expected period: negative when it is late.
  int? daysUntilNext([DateTime? now]) => nextExpected?.difference(dateOnly(now ?? DateTime.now())).inDays;

  /// Average gap between her last few periods, kept within 21 to 35 days.
  /// Gaps under 15 days (a second tap in the same period) or over 60 are ignored.
  static int averageCycle(List<DateTime> starts) {
    final gaps = <int>[];
    for (var i = 1; i < starts.length; i++) {
      final g = dateOnly(starts[i]).difference(dateOnly(starts[i - 1])).inDays;
      if (g >= 15 && g <= 60) gaps.add(g);
    }
    final recent = gaps.length > 6 ? gaps.sublist(gaps.length - 6) : gaps;
    if (recent.isEmpty) return defaultCycle;
    return (recent.reduce((a, b) => a + b) / recent.length).round().clamp(21, 35);
  }

  void attach(SharedPreferences prefs) {
    _prefs = prefs;
    starts = (prefs.getStringList(_key) ?? []).map(DateTime.parse).toList()..sort();
    notifyListeners();
  }

  Future<void> add(DateTime day) async {
    final d = dateOnly(day);
    if (starts.contains(d)) return;
    starts = [...starts, d]..sort();
    await _save();
  }

  Future<void> remove(DateTime day) async {
    starts = starts.where((s) => s != dateOnly(day)).toList();
    await _save();
  }

  Future<void> clear() async {
    starts = [];
    await _prefs?.remove(_key);
    notifyListeners();
  }

  Future<void> _save() async {
    await _prefs?.setStringList(_key, starts.map((d) => d.toIso8601String()).toList());
    notifyListeners();
  }
}
