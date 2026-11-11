import 'package:flutter/material.dart';

import '../format.dart';
import '../notifications.dart';
import '../state.dart';
import '../theme.dart';
import '../tools/pep_reminder.dart';
import 'shell.dart';

/// The 28 days of PEP: a neutral daily reminder and a place to tick each day.
class PepScreen extends StatelessWidget {
  const PepScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('My 28 days'), actions: const [QuickExitButton()]),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: s.pep,
          builder: (context, _) => s.pep.active ? _Progress(pep: s.pep) : _Setup(pep: s.pep),
        ),
      ),
    );
  }
}

/// Before she starts: what PEP is, and the three choices for the reminder.
class _Setup extends StatefulWidget {
  const _Setup({required this.pep, this.editing = false});
  final PepReminder pep;
  final bool editing;
  @override
  State<_Setup> createState() => _SetupState();
}

class _SetupState extends State<_Setup> {
  late DateTime firstDay = widget.pep.start ?? dateOnly(DateTime.now());
  late TimeOfDay time = TimeOfDay(hour: widget.pep.hour, minute: widget.pep.minute);
  late String label = widget.pep.label;
  bool saving = false;

  String get _whichDay {
    final d = dateOnly(DateTime.now()).difference(firstDay).inDays;
    return d == 0 ? 'today' : d == 1 ? 'yesterday' : 'other';
  }

  Future<void> _pickDay() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: firstDay,
      firstDate: now.subtract(const Duration(days: PepReminder.days - 1)),
      lastDate: now,
      helpText: 'Day you took the first pill',
    );
    if (d != null) setState(() => firstDay = dateOnly(d));
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: time, helpText: 'Reminder time each day');
    if (t != null) setState(() => time = t);
  }

  Future<void> _start() async {
    setState(() => saving = true);
    await widget.pep.begin(firstDay: firstDay, hour: time.hour, minute: time.minute, label: label);
    if (!mounted) return;
    if (widget.editing) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.all(18), children: [
      if (!widget.editing) ...[
        Card(
          color: c.primaryContainer.withValues(alpha: .5),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('PEP is medicine that can stop HIV after forced or unprotected sex.', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('It works when you take one pill every day for 28 days. This reminder helps you finish.', style: t.bodyLarge),
              const SizedBox(height: 6),
              Text('The reminder shows only the words you choose below. It never says PEP, HIV or GirlCare72.', style: t.bodySmall),
            ]),
          ),
        ),
        const SizedBox(height: 18),
      ],
      Text('1. When did you take the first pill?', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'today', label: Text('Today')),
          ButtonSegment(value: 'yesterday', label: Text('Yesterday')),
          ButtonSegment(value: 'other', label: Text('Other day')),
        ],
        selected: {_whichDay},
        onSelectionChanged: (v) {
          final now = dateOnly(DateTime.now());
          switch (v.first) {
            case 'today':
              setState(() => firstDay = now);
            case 'yesterday':
              setState(() => firstDay = now.subtract(const Duration(days: 1)));
            default:
              _pickDay();
          }
        },
      ),
      if (_whichDay == 'other') Padding(padding: const EdgeInsets.only(top: 6), child: Text('First pill on ${shortDate(firstDay)}', style: t.bodyMedium)),
      const SizedBox(height: 18),
      Text('2. What time each day?', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text('Pick a time you are usually alone, like bedtime.', style: t.bodySmall),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: _pickTime, icon: const Icon(Icons.schedule), label: Text(clockTime(time.hour, time.minute))),
      const SizedBox(height: 18),
      Text('3. Words on the reminder', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text('This is all anyone sees on your screen.', style: t.bodySmall),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [for (final l in PepReminder.labels) ChoiceChip(label: Text(l), selected: label == l, onSelected: (_) => setState(() => label = l))],
      ),
      const SizedBox(height: 22),
      FilledButton(onPressed: saving ? null : _start, child: Text(saving ? 'Setting up…' : widget.editing ? 'Save' : 'Start my 28 days')),
      if (widget.editing) TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
    ]);
  }
}

/// After she starts: which day she is on, a tick for today, and the full 28.
class _Progress extends StatelessWidget {
  const _Progress({required this.pep});
  final PepReminder pep;

  Future<void> _stop(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop the reminders?'),
        content: const Text('Your 28 days and ticks will be removed from this phone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Stop')),
        ],
      ),
    );
    if (ok == true) await pep.stop();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final day = pep.today;
    if (pep.finished) {
      return ListView(padding: const EdgeInsets.all(18), children: [
        Icon(Icons.celebration, size: 56, color: c.primary),
        const SizedBox(height: 10),
        Text('You finished your 28 days.', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        Text('Well done. You took ${pep.taken.length} of ${PepReminder.days} ticks here.', style: t.bodyLarge),
        const SizedBox(height: 6),
        Text('Next step: an HIV test. A health worker will tell you when to test, and again a few months later. A responder can book it with you.', style: t.bodyLarge),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => showTab(context, tabHelp), child: const Text('Book my test')),
        const SizedBox(height: 8),
        TextButton(onPressed: () => pep.stop(), child: const Text('Clear this from my phone')),
      ]);
    }
    final pct = ((day - 1) / PepReminder.days).clamp(0.0, 1.0);
    return ListView(padding: const EdgeInsets.all(18), children: [
      Card(
        color: c.primaryContainer.withValues(alpha: .5),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Day $day of ${PepReminder.days}', style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: pct, minHeight: 10)),
            const SizedBox(height: 8),
            Text('Started ${shortDate(pep.start!)} · last pill ${shortDate(pep.lastDay!)}', style: t.bodyMedium),
          ]),
        ),
      ),
      const SizedBox(height: 14),
      FilledButton.icon(
        style: pep.takenToday ? FilledButton.styleFrom(backgroundColor: okGreen) : null,
        onPressed: () => pep.setTakenToday(!pep.takenToday),
        icon: Icon(pep.takenToday ? Icons.check_circle : Icons.circle_outlined),
        label: Text(pep.takenToday ? 'Taken today' : 'I took it today'),
      ),
      const SizedBox(height: 18),
      Text('All 28 days', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [for (var d = 1; d <= PepReminder.days; d++) _DayDot(day: d, today: day, taken: pep.taken.contains(d))]),
      const SizedBox(height: 18),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tips', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('• Same time every day, with food if it upsets your stomach.'),
            const Text('• Forgot one? Take it as soon as you remember, then carry on. Never take two together.'),
            const Text('• Vomiting, rash or feeling very unwell: tell a health worker. Do not stop on your own.'),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: () => showTab(context, tabHelp), icon: const Icon(Icons.favorite_border), label: const Text('Talk to a health worker')),
          ]),
        ),
      ),
      const SizedBox(height: 14),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.alarm),
        title: Text('Reminder at ${clockTime(pep.hour, pep.minute)}'),
        subtitle: Text('Says "${pep.label}"'),
        trailing: TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Change reminder'), actions: const [QuickExitButton()]),
                body: SafeArea(child: _Setup(pep: pep, editing: true)),
              ),
            ),
          ),
          child: const Text('Change'),
        ),
      ),
      if (!pep.phoneReminds)
        Card(
          color: c.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              Reminders.instance.available
                  ? 'This phone is not showing reminders. Allow notifications for GirlCare72 in the phone settings, or open this page each day.'
                  : 'A browser cannot remind you when the page is closed. Open this page each day, or install the Android app.',
              style: TextStyle(color: c.onErrorContainer),
            ),
          ),
        ),
      const SizedBox(height: 8),
      TextButton(onPressed: () => _stop(context), child: const Text('Stop reminders')),
    ]);
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.day, required this.today, required this.taken});
  final int day;
  final int today;
  final bool taken;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final past = day < today;
    final isToday = day == today;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: taken ? okGreen : (past ? c.surfaceContainerHighest : c.surface),
        border: Border.all(color: isToday ? c.primary : (taken ? okGreen : c.outlineVariant), width: isToday ? 3 : 1),
      ),
      child: taken
          ? const Icon(Icons.check, color: Colors.white, size: 20)
          : Text('$day', style: TextStyle(fontWeight: FontWeight.w700, color: past ? c.onSurfaceVariant : c.onSurface)),
    );
  }
}
