import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../format.dart';

enum Mood {
  great('Great', Icons.sentiment_very_satisfied),
  ok('OK', Icons.sentiment_satisfied),
  low('Low', Icons.sentiment_neutral),
  sad('Sad', Icons.sentiment_dissatisfied),
  bad('Very bad', Icons.sentiment_very_dissatisfied);

  const Mood(this.word, this.icon);
  final String word;
  final IconData icon;

  /// Sad and very bad days get the extra "are you safe?" question and the helpline.
  bool get heavy => this == sad || this == bad;
}

class MoodEntry {
  MoodEntry(this.day, this.mood);
  final DateTime day;
  final Mood mood;
}

/// The last 30 check-ins, on this phone only.
class MoodLog extends ChangeNotifier {
  static const _key = 'moods';
  static const keep = 30;
  SharedPreferences? _prefs;
  List<MoodEntry> entries = [];

  MoodEntry? get today {
    final d = dateOnly(DateTime.now());
    for (final e in entries) {
      if (e.day == d) return e;
    }
    return null;
  }

  /// The last seven days, oldest first, with null for days she did not check in.
  List<Mood?> get week {
    final today = dateOnly(DateTime.now());
    return [
      for (var i = 6; i >= 0; i--)
        entries.where((e) => e.day == today.subtract(Duration(days: i))).map((e) => e.mood).firstOrNull,
    ];
  }

  void attach(SharedPreferences prefs) {
    _prefs = prefs;
    entries = ((jsonDecode(prefs.getString(_key) ?? '[]') as List))
        .map((e) => MoodEntry(DateTime.parse(e['d'] as String), Mood.values[(e['m'] as num).toInt()]))
        .toList();
    notifyListeners();
  }

  Future<void> add(Mood mood) async {
    final d = dateOnly(DateTime.now());
    entries = [...entries.where((e) => e.day != d), MoodEntry(d, mood)];
    if (entries.length > keep) entries = entries.sublist(entries.length - keep);
    await _prefs?.setString(_key, jsonEncode([for (final e in entries) {'d': e.day.toIso8601String(), 'm': e.mood.index}]));
    notifyListeners();
  }

  Future<void> clear() async {
    entries = [];
    await _prefs?.remove(_key);
    notifyListeners();
  }
}

/// What the app says back after a check-in.
class MoodReply {
  const MoodReply(this.title, this.text, {this.breathe = false, this.talk = false});
  final String title;
  final String text;
  final bool breathe;
  final bool talk;
}

MoodReply replyFor(Mood m) => switch (m) {
      Mood.great => const MoodReply('Lovely.', 'Keep doing what makes you feel this way. A lesson or a chat with a friend can keep it going.'),
      Mood.ok => const MoodReply('OK is fine.', 'Not every day has to be big. Do one small kind thing for yourself today.', breathe: true),
      Mood.low => const MoodReply('Low days happen.', 'A slow breath can help right now. So can telling one person you trust.', breathe: true, talk: true),
      Mood.sad => const MoodReply('Sorry you feel sad.', 'You are not alone. Breathe with me for a minute, or talk to someone who listens.', breathe: true, talk: true),
      Mood.bad => const MoodReply('This sounds heavy.', 'You deserve support today, not later. Someone can listen right now.', breathe: true, talk: true),
    };

/// Short yes/no questions about a boyfriend, husband or partner.
const relationshipQuestions = [
  'Does he check your phone or messages, or say who you can talk to?',
  'Are you afraid of making him angry?',
  'Has he pushed, slapped or hurt you, or threatened to?',
  'Does he pressure you into sex or touching you do not want?',
  'Does he give you money, gifts or school fees and expect sex back?',
  'Does he stop you seeing friends or family, or going to school?',
  'Does he say it is your fault when he is angry or hurts you?',
];

/// Questions 3 and 4 are about violence and forced sex: one yes is enough.
const _urgent = {2, 3};

enum RelationshipLevel { fine, watch, unsafe }

RelationshipLevel relationshipLevel(List<bool> yes) {
  for (final i in _urgent) {
    if (i < yes.length && yes[i]) return RelationshipLevel.unsafe;
  }
  final count = yes.where((y) => y).length;
  if (count >= 3) return RelationshipLevel.unsafe;
  if (count >= 1) return RelationshipLevel.watch;
  return RelationshipLevel.fine;
}
