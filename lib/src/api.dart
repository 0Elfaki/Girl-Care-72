import 'dart:convert';

import 'package:http/http.dart' as http;

import 'answer_bank.dart';
import 'config.dart';
import 'help_directory.dart';
import 'models.dart';

/// Talks to the GirlCare72 server. Nothing sent here contains a name.
/// Only Get help sends a phone number, so a responder can call back.
class Api {
  Api({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  static const _timeout = Duration(seconds: 20);

  bool get online => Config.apiBase.isNotEmpty;
  Uri _u(String path, [Map<String, String>? q]) => Uri.parse(Config.apiBase.replaceAll(RegExp(r'/$'), '') + path).replace(queryParameters: q);

  /// Published lessons for one age track, or null if the server can't be reached.
  Future<({List<Lesson> lessons, bool draft})?> lessons(String track, String language) async {
    if (!online) return null;
    try {
      final r = await _client.get(_u('/api/public/lessons', {'track': track, 'language': language})).timeout(_timeout);
      if (r.statusCode != 200) return null;
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      final list = (j['lessons'] as List).map((e) => Lesson.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      return (lessons: list, draft: j['draft'] == true);
    } catch (_) {
      return null;
    }
  }

  /// Ask GirlCare. Falls back to the reviewed answer bank when offline.
  Future<Answer> ask(String question, String track, String language) async {
    final offline = bankAnswer(question);
    if (!online) return offline;
    try {
      final r = await _client
          .post(_u('/api/public/ask'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'question': question, 'track': track, 'language': language}))
          .timeout(const Duration(seconds: 45));
      if (r.statusCode != 200) return offline;
      final a = Answer.fromJson(jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>);
      // Danger words always bring up Get help, whatever the server says.
      return Answer(text: a.text, lesson: a.lesson, help: a.help || offline.help, source: a.source);
    } catch (_) {
      return offline;
    }
  }

  /// Sends a call-back request. Returns an error message, or null on success.
  /// [kind] is "help" (a responder) or "nurse" (a health question, with [question]).
  Future<String?> requestHelp({
    required String phone,
    required String language,
    required String safeTime,
    required bool forSomeone,
    String kind = 'help',
    String? question,
  }) async {
    if (!online) return 'offline';
    try {
      final r = await _client
          .post(_u('/api/public/help'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'phone': phone,
                'language': language,
                'safe_time': safeTime,
                'for_someone': forSomeone,
                'kind': kind,
                if (question != null && question.isNotEmpty) 'question': question,
                'check': 'gc72',
              }))
          .timeout(_timeout);
      if (r.statusCode == 200) return null;
      return 'server';
    } catch (_) {
      return 'offline';
    }
  }

  /// The help directory the team keeps in the dashboard, or null if the server can't be reached.
  Future<List<HelpPlace>?> directory() async {
    if (!online) return null;
    try {
      final r = await _client.get(_u('/api/public/directory')).timeout(_timeout);
      if (r.statusCode != 200) return null;
      final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      return placesFromJson(j['places'] as List? ?? []);
    } catch (_) {
      return null;
    }
  }

  /// Anonymous learning counts: lesson, track and score only.
  Future<bool> sendEvents(List<Map<String, dynamic>> events) async {
    if (!online || events.isEmpty) return false;
    try {
      final r = await _client
          .post(_u('/api/public/events'), headers: {'Content-Type': 'application/json'}, body: jsonEncode({'events': events.take(50).toList()}))
          .timeout(_timeout);
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
