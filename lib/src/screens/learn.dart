import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../models.dart';
import '../state.dart';
import '../theme.dart';
import 'shell.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key, required this.onGetHelp});
  final VoidCallback onGetHelp;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    return RefreshIndicator(
      onRefresh: s.refresh,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Text('LEARN', style: t.labelMedium?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
        Text('Short lessons for every girl', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        SegmentedButton<String>(
          segments: const [ButtonSegment(value: '10-14', label: Text('Ages 10–14')), ButtonSegment(value: '15-24', label: Text('Ages 15–24'))],
          selected: {s.track},
          onSelectionChanged: (v) => s.setTrack(v.first),
        ),
        if (s.draftLessons) ...[
          const SizedBox(height: 12),
          Card(child: Padding(padding: const EdgeInsets.all(12), child: Text('These lessons are drafts waiting for review by a health worker.', style: t.bodySmall))),
        ],
        const SizedBox(height: 12),
        for (final l in s.lessons) _LessonTile(lesson: l, done: s.done.contains(s.doneKey(l))),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: onGetHelp, icon: const Icon(Icons.favorite_border), label: const Text('Need help now?')),
      ]),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson, required this.done});
  final Lesson lesson;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: done ? okGreen.withValues(alpha: .15) : c.primaryContainer,
          foregroundColor: done ? okGreen : c.onPrimaryContainer,
          child: done ? const Icon(Icons.check) : Text('${lesson.n}', style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        title: Text(lesson.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: const Text('3 min · quiz'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          AppScope.of(context).logEvent(lesson, 'opened');
          Navigator.push(context, MaterialPageRoute(builder: (_) => LessonScreen(lesson: lesson)));
        },
      ),
    );
  }
}

class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key, required this.lesson});
  final Lesson lesson;
  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  final _tts = FlutterTts();
  bool speaking = false;

  @override
  void initState() {
    super.initState();
    _tts.setCompletionHandler(() => mounted ? setState(() => speaking = false) : null);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    if (speaking) {
      await _tts.stop();
      setState(() => speaking = false);
      return;
    }
    final l = widget.lesson;
    await _tts.setSpeechRate(0.45);
    setState(() => speaking = true);
    await _tts.speak('${l.title}. ${l.keyMessages.join(' ')} Story. ${l.story}');
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.lesson;
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('Lesson ${l.n}'), actions: const [QuickExitButton()]),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(18), children: [
          Text(l.track == '10-14' ? 'AGES 10 TO 14' : 'AGES 15 TO 24', style: t.labelMedium?.copyWith(letterSpacing: 1.2)),
          Text(l.title, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(onPressed: _toggleAudio, icon: Icon(speaking ? Icons.stop : Icons.play_arrow), label: Text(speaking ? 'Stop' : 'Listen')),
          ),
          const SizedBox(height: 12),
          for (final k in l.keyMessages)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(padding: const EdgeInsets.only(top: 6, right: 10), child: Icon(Icons.circle, size: 8, color: c.primary)),
                Expanded(child: Text(k, style: t.bodyLarge)),
              ]),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: c.primaryContainer.withValues(alpha: .6), borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('STORY', style: t.labelMedium?.copyWith(letterSpacing: 1.2)),
              const SizedBox(height: 4),
              Text(l.story, style: t.bodyLarge),
            ]),
          ),
          const SizedBox(height: 20),
          if (l.quiz.isNotEmpty)
            FilledButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizScreen(lesson: l))),
              child: Text('Take the ${l.quiz.length}-question quiz'),
            ),
        ]),
      ),
    );
  }
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.lesson});
  final Lesson lesson;
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final Map<int, int> answers = {};
  bool saved = false;

  @override
  Widget build(BuildContext context) {
    final qs = widget.lesson.quiz;
    final t = Theme.of(context).textTheme;
    final right = [for (var i = 0; i < qs.length; i++) if (answers[i] == qs[i].answer) i].length;
    final finished = answers.length == qs.length;
    if (finished && !saved) {
      saved = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => AppScope.of(context).finishQuiz(widget.lesson, right));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz'), actions: const [QuickExitButton()]),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(18), children: [
          Text(widget.lesson.title, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          for (var i = 0; i < qs.length; i++) ...[
            Text('${i + 1}. ${qs[i].question}', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            for (var j = 0; j < qs[i].options.length; j++) _option(context, i, j, qs[i]),
            const SizedBox(height: 14),
          ],
          if (finished)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('You got $right of ${qs.length}.', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(right == qs.length ? 'Well done.' : 'You can read the lesson again any time.'),
                  const SizedBox(height: 4),
                  Text('Your score stays on this phone.', style: t.bodySmall),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst), child: const Text('Back to lessons')),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _option(BuildContext context, int i, int j, QuizQuestion q) {
    final chosen = answers[i];
    Color? bg;
    if (chosen != null) {
      if (j == q.answer) {
        bg = okGreen.withValues(alpha: .18);
      } else if (j == chosen) {
        bg = Theme.of(context).colorScheme.errorContainer;
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: bg ?? Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: chosen == null ? () => setState(() => answers[i] = j) : null,
          child: Padding(padding: const EdgeInsets.all(14), child: Text(q.options[j])),
        ),
      ),
    );
  }
}
