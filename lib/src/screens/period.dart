import 'package:flutter/material.dart';

import '../format.dart';
import '../state.dart';
import 'learn.dart';
import 'nurse.dart';
import 'shell.dart';

/// Logs the first day of each period and says when the next one is likely.
class PeriodScreen extends StatelessWidget {
  const PeriodScreen({super.key});

  Future<void> _pickDay(BuildContext context, AppState s) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      helpText: 'First day of that period',
    );
    if (d != null) await s.period.add(d);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('My period'), actions: const [QuickExitButton()]),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: s.period,
          builder: (context, _) {
            final p = s.period;
            final next = p.nextExpected;
            final until = p.daysUntilNext();
            final loggedToday = p.starts.contains(dateOnly(DateTime.now()));
            return ListView(padding: const EdgeInsets.all(18), children: [
              Card(
                color: c.primaryContainer.withValues(alpha: .5),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: next == null
                      ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Know when your next period is coming.', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          Text('Tap the button on the first day of your period. After two periods the app learns your own rhythm.', style: t.bodyLarge),
                        ])
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('NEXT PERIOD', style: t.labelMedium?.copyWith(letterSpacing: 1.2)),
                          Text('Around ${shortDate(next)}', style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 4),
                          Text(_untilText(until!), style: t.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                            p.estimated ? 'Guessed from the usual 28-day cycle. Log your next period to make it yours.' : 'Your cycle: about ${p.cycleLength} days.',
                            style: t.bodySmall,
                          ),
                        ]),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: loggedToday ? null : () => s.period.add(DateTime.now()),
                icon: const Icon(Icons.water_drop_outlined),
                label: Text(loggedToday ? 'Logged for today' : 'My period started today'),
              ),
              TextButton(onPressed: () => _pickDay(context, s), child: const Text('It started on another day')),
              if (until != null && until <= -7)
                Card(
                  color: c.tertiaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('More than a week late?', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: c.onTertiaryContainer)),
                      const SizedBox(height: 4),
                      Text('Stress, illness or growing up can delay a period. If you had sex, a nurse can help you check, in private.',
                          style: TextStyle(color: c.onTertiaryContainer)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => showNurseSheet(context, question: 'My period is more than a week late.'),
                        icon: const Icon(Icons.support_agent),
                        label: const Text('Talk to a nurse'),
                      ),
                    ]),
                  ),
                ),
              const SizedBox(height: 14),
              if (p.starts.isNotEmpty) ...[
                Text('Past periods', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                for (final d in p.starts.reversed.take(12))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.water_drop, color: c.primary),
                    title: Text('${shortDate(d)} ${d.year}'),
                    trailing: IconButton(tooltip: 'Remove', icon: const Icon(Icons.close), onPressed: () => s.period.remove(d)),
                  ),
                const SizedBox(height: 10),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Good to know', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text('• Periods usually come every 21 to 35 days and last 2 to 7 days.'),
                    const Text('• In the first years they are often irregular. That is normal.'),
                    const Text('• Bleeding more than 7 days, or soaking a pad every hour: see a health worker.'),
                    const SizedBox(height: 8),
                    if (s.lesson(4) case final l?)
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LessonScreen(lesson: l))),
                        icon: const Icon(Icons.menu_book_outlined),
                        label: Text('Read: ${l.title}'),
                      ),
                  ]),
                ),
              ),
              const SizedBox(height: 8),
              Text('Your dates stay on this phone only.', style: t.bodySmall),
            ]);
          },
        ),
      ),
    );
  }

  String _untilText(int d) => switch (d) {
        0 => 'Expected today',
        1 => 'Tomorrow',
        > 1 => 'In $d days',
        -1 => '1 day late',
        _ => '${-d} days late',
      };
}
