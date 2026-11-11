import 'package:flutter/material.dart';

import '../config.dart';
import '../state.dart';
import '../theme.dart';
import '../tools/checkin.dart';
import 'help_dialogs.dart';
import 'learn.dart';
import 'nurse.dart';
import 'shell.dart';

/// "Feeling OK?": a one-tap check-in, a breathing minute, and who to talk to.
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});
  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  Mood? picked;
  bool? safe; // answer to "are you safe right now?"

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final mood = picked ?? s.moods.today?.mood;
    return Scaffold(
      appBar: AppBar(title: const Text('Feeling OK?'), actions: const [QuickExitButton()]),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(18), children: [
          Text('How are you today?', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Tap one. Nobody else sees it.', style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final m in Mood.values)
                Expanded(
                  child: _MoodButton(
                    mood: m,
                    selected: mood == m,
                    onTap: () {
                      setState(() {
                        picked = m;
                        safe = null;
                      });
                      s.moods.add(m);
                    },
                  ),
                ),
            ],
          ),
          if (mood != null) ...[
            const SizedBox(height: 16),
            _Reply(mood: mood, safe: safe, onSafe: (v) => setState(() => safe = v)),
          ],
          const SizedBox(height: 20),
          ListenableBuilder(
            listenable: s.moods,
            builder: (context, _) {
              final week = s.moods.week;
              if (week.every((m) => m == null)) return const SizedBox.shrink();
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('This week', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final m in week)
                      Expanded(
                        child: Icon(m?.icon ?? Icons.circle_outlined, size: 30, color: m == null ? c.outlineVariant : (m.heavy ? c.error : c.primary)),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ]);
            },
          ),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: CircleAvatar(backgroundColor: c.primaryContainer, foregroundColor: c.onPrimaryContainer, child: const Icon(Icons.favorite_border)),
              title: const Text('Is my relationship safe?', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('7 quick questions. Nothing is saved.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RelationshipCheckScreen())),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: CircleAvatar(backgroundColor: c.primaryContainer, foregroundColor: c.onPrimaryContainer, child: const Icon(Icons.air)),
              title: const Text('Breathe for a minute', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Slows a racing heart. Any time.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showBreathing(context),
            ),
          ),
          const SizedBox(height: 20),
          Text('If you think about hurting yourself, call Sauti 116. It is free, day and night, and they listen.', style: t.bodyMedium),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(onPressed: () => callNumber(context, '116'), icon: const Icon(Icons.call), label: const Text('Call 116')),
          ),
        ]),
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  const _MoodButton({required this.mood, required this.selected, required this.onTap});
  final Mood mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: selected ? c.primaryContainer : c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: selected ? c.primary : c.outlineVariant, width: selected ? 2 : 1)),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(children: [
              Icon(mood.icon, size: 34, color: selected ? c.primary : c.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(mood.word, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w700 : FontWeight.w500), textAlign: TextAlign.center),
            ]),
          ),
        ),
      ),
    );
  }
}

/// What the app says back, with the next steps that fit the mood.
class _Reply extends StatelessWidget {
  const _Reply({required this.mood, required this.safe, required this.onSafe});
  final Mood mood;
  final bool? safe;
  final ValueChanged<bool> onSafe;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final r = replyFor(mood);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: c.primaryContainer.withValues(alpha: .5), borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.title, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(r.text, style: t.bodyLarge),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (r.breathe) FilledButton.icon(onPressed: () => showBreathing(context), icon: const Icon(Icons.air), label: const Text('Breathe with me')),
            if (r.talk)
              FilledButton.tonalIcon(
                onPressed: () => showNurseSheet(context, question: 'I feel ${mood.word.toLowerCase()} and want to talk to someone.'),
                icon: const Icon(Icons.support_agent),
                label: const Text('Talk to someone'),
              ),
            if (mood == Mood.great && s.lessons.isNotEmpty)
              FilledButton.tonalIcon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonScreen(lesson: s.lessons.first))),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Learn something'),
              ),
          ]),
        ]),
      ),
      if (mood.heavy) ...[
        const SizedBox(height: 12),
        Text('Are you safe right now?', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        SegmentedButton<bool>(
          segments: const [ButtonSegment(value: true, label: Text('Yes')), ButtonSegment(value: false, label: Text('No'))],
          selected: {?safe},
          emptySelectionAllowed: true,
          onSelectionChanged: (v) => onSafe(v.first),
        ),
        if (safe == false) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: c.primaryContainer, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.primary, width: 2)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text('You are not alone.', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              const SizedBox(height: 4),
              const Text('A responder can call you back at a safe time, or you can call now. If someone hurt you, care within 72 hours can stop HIV and pregnancy.'),
              const SizedBox(height: 10),
              FilledButton(onPressed: () => showTab(context, tabHelp), child: const Text('Get help now')),
              const SizedBox(height: 6),
              OutlinedButton.icon(onPressed: () => callNumber(context, Config.freeNumber), icon: const Icon(Icons.call), label: Text('Call ${Config.freeNumber}')),
            ]),
          ),
        ],
        if (safe == true) ...[
          const SizedBox(height: 8),
          Text('Good. Keep this app and the free number close, and tell one person you trust how you feel.', style: t.bodyMedium),
        ],
      ],
    ]);
  }
}

/// A one-minute breathing circle: in 4, hold 4, out 6.
Future<void> showBreathing(BuildContext context) => showDialog<void>(
      context: context,
      builder: (_) => const Dialog(child: Padding(padding: EdgeInsets.all(20), child: _Breathing())),
    );

class _Breathing extends StatefulWidget {
  const _Breathing();
  @override
  State<_Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<_Breathing> with SingleTickerProviderStateMixin {
  static const cycle = 14; // seconds: 4 in, 4 hold, 6 out
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: cycle))..repeat();
  late final Animation<double> _size = TweenSequence<double>([
    TweenSequenceItem(tween: Tween<double>(begin: .55, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 4),
    TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 4),
    TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: .55).chain(CurveTween(curve: Curves.easeInOut)), weight: 6),
  ]).animate(_ctrl);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _phase(double v) => v < 4 / cycle ? 'Breathe in' : v < 8 / cycle ? 'Hold' : 'Breathe out';

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_phase(_ctrl.value), style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('Follow the circle. Five rounds is about a minute.', style: t.bodySmall, textAlign: TextAlign.center),
        const SizedBox(height: 20),
        SizedBox(
          width: 200,
          height: 200,
          child: Center(
            child: Container(
              width: 200 * _size.value,
              height: 200 * _size.value,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.primary.withValues(alpha: .25), border: Border.all(color: c.primary, width: 4)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
      ]),
    );
  }
}

/// Seven yes/no questions about a partner. Nothing is saved.
class RelationshipCheckScreen extends StatefulWidget {
  const RelationshipCheckScreen({super.key});
  @override
  State<RelationshipCheckScreen> createState() => _RelationshipCheckScreenState();
}

class _RelationshipCheckScreenState extends State<RelationshipCheckScreen> {
  final answers = List<bool?>.filled(relationshipQuestions.length, null);
  bool get complete => answers.every((a) => a != null);

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final level = complete ? relationshipLevel(answers.map((a) => a!).toList()) : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Is my relationship safe?'), actions: const [QuickExitButton()]),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(18), children: [
          Text('Think of your boyfriend, husband or the person you are close to. Answer yes or no. Nothing is saved.',
              style: t.bodyLarge),
          const SizedBox(height: 16),
          for (var i = 0; i < relationshipQuestions.length; i++) ...[
            Text('${i + 1}. ${relationshipQuestions[i]}', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            SegmentedButton<bool>(
              segments: const [ButtonSegment(value: false, label: Text('No')), ButtonSegment(value: true, label: Text('Yes'))],
              selected: {?answers[i]},
              emptySelectionAllowed: true,
              onSelectionChanged: (v) => setState(() => answers[i] = v.first),
            ),
            const SizedBox(height: 14),
          ],
          if (level != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: level == RelationshipLevel.fine ? okGreen.withValues(alpha: .15) : c.primaryContainer,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: level == RelationshipLevel.unsafe ? c.primary : Colors.transparent, width: 2),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(
                  switch (level) {
                    RelationshipLevel.fine => 'This sounds respectful.',
                    RelationshipLevel.watch => 'Some of this is a warning sign.',
                    RelationshipLevel.unsafe => 'You deserve to be safe.',
                  },
                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  switch (level) {
                    RelationshipLevel.fine => 'Everyone deserves that. If anything changes, come back and check again.',
                    RelationshipLevel.watch =>
                      'Checking your phone, fear or control often grow over time. Talk to a trusted adult, and make a safety plan just in case.',
                    RelationshipLevel.unsafe =>
                      'None of this is your fault. Hurting you, forcing you or trading gifts for sex is never OK, even from a husband. A responder can talk it through with you, in private.',
                  },
                  style: t.bodyLarge,
                ),
                const SizedBox(height: 12),
                if (level == RelationshipLevel.unsafe) FilledButton(onPressed: () => showTab(context, tabHelp), child: const Text('Get help')),
                if (level != RelationshipLevel.fine) ...[
                  const SizedBox(height: 6),
                  if (AppScope.of(context).lesson(5) case final l?)
                    OutlinedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonScreen(lesson: l))),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: Text('Read: ${l.title}'),
                    ),
                ],
              ]),
            ),
        ]),
      ),
    );
  }
}
