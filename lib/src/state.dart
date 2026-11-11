import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';
import 'help_directory.dart';
import 'models.dart';
import 'tools/checkin.dart';
import 'tools/pep_reminder.dart';
import 'tools/period_tracker.dart';

/// Everything the app remembers lives on this phone only, and "Clear my data" removes it.
class AppState extends ChangeNotifier {
  AppState(this.api);
  final Api api;
  SharedPreferences? _prefs;

  String track = '15-24';
  String language = 'English';
  bool draftLessons = false;
  final Map<String, List<Lesson>> _lessons = {};
  Set<String> done = {};
  Map<String, int> scores = {};
  final List<ChatLine> chat = [];
  List<Map<String, dynamic>> _pendingEvents = [];
  List<HelpPlace> places = [];

  /// Her own tools. Each keeps its data on this phone and clears with the rest.
  final pep = PepReminder();
  final period = PeriodTracker();
  final moods = MoodLog();

  /// Which main tab is showing. Any screen can switch it, see [openTab].
  final tab = ValueNotifier<int>(0);
  void openTab(int i) => tab.value = i;

  List<Lesson> get lessons => _lessons[track] ?? const [];
  Lesson? lesson(int n) => lessons.where((l) => l.n == n).firstOrNull;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    track = p.getString('track') ?? track;
    language = p.getString('language') ?? language;
    done = (p.getStringList('done') ?? []).toSet();
    scores = Map<String, int>.from(jsonDecode(p.getString('scores') ?? '{}') as Map);
    _pendingEvents = (jsonDecode(p.getString('events') ?? '[]') as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
    pep.attach(p);
    period.attach(p);
    moods.attach(p);

    // Bundled lessons and places first, so the app works with no network.
    final raw = jsonDecode(await rootBundle.loadString('assets/lessons.json')) as List;
    for (final l in raw.map((e) => Lesson.fromJson(Map<String, dynamic>.from(e as Map)))) {
      _lessons.putIfAbsent(l.track, () => []).add(l);
    }
    places = await bundledDirectory();
    // Then anything downloaded earlier.
    for (final t in ['10-14', '15-24']) {
      final cached = p.getString('lessons_${t}_$language');
      if (cached != null) {
        _lessons[t] = (jsonDecode(cached) as List).map((e) => Lesson.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      }
    }
    final cachedPlaces = p.getString('directory');
    if (cachedPlaces != null) places = placesFromJson(jsonDecode(cachedPlaces) as List);
    notifyListeners();
    refresh();
  }

  /// Downloads the latest approved lessons and directory, and sends waiting learning counts.
  Future<void> refresh() async {
    for (final t in ['10-14', '15-24']) {
      final res = await api.lessons(t, language);
      if (res != null && res.lessons.isNotEmpty) {
        _lessons[t] = res.lessons;
        draftLessons = res.draft;
        await _prefs?.setString('lessons_${t}_$language', jsonEncode(res.lessons.map(_lessonJson).toList()));
      }
    }
    final dir = await api.directory();
    if (dir != null && dir.isNotEmpty) {
      places = dir;
      await _prefs?.setString('directory', jsonEncode(dir.map((p) => p.toJson()).toList()));
    }
    if (await api.sendEvents(_pendingEvents)) {
      _pendingEvents = [];
      await _prefs?.setString('events', '[]');
    }
    notifyListeners();
  }

  Map<String, dynamic> _lessonJson(Lesson l) => {
        'n': l.n,
        'track': l.track,
        'title': l.title,
        'key': l.keyMessages,
        'story': l.story,
        'quiz': l.quiz.map((q) => {'q': q.question, 'options': q.options, 'answer': q.answer}).toList(),
        'sms': l.sms,
      };

  String doneKey(Lesson l) => '${l.track}:${l.n}';

  Future<void> setTrack(String t) async {
    track = t;
    await _prefs?.setString('track', t);
    notifyListeners();
  }

  Future<void> setLanguage(String lang) async {
    language = lang;
    await _prefs?.setString('language', lang);
    notifyListeners();
    refresh();
  }

  void logEvent(Lesson l, String kind, {double? score}) {
    _pendingEvents.add({'lesson_n': l.n, 'track': l.track, 'kind': kind, 'score': score, 'language': language});
    _prefs?.setString('events', jsonEncode(_pendingEvents));
  }

  Future<void> finishQuiz(Lesson l, int right) async {
    done.add(doneKey(l));
    scores[doneKey(l)] = right;
    await _prefs?.setStringList('done', done.toList());
    await _prefs?.setString('scores', jsonEncode(scores));
    logEvent(l, 'finished');
    logEvent(l, 'quiz', score: l.quiz.isEmpty ? null : right / l.quiz.length);
    notifyListeners();
    refresh();
  }

  /// Clears progress, scores, the chat and her tools (reminder, periods, check-ins) from this phone.
  Future<void> clearAll() async {
    done.clear();
    scores.clear();
    chat.clear();
    await _prefs?.remove('done');
    await _prefs?.remove('scores');
    await pep.stop();
    await period.clear();
    await moods.clear();
    notifyListeners();
  }

  void clearChat() {
    chat.clear();
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);

  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
