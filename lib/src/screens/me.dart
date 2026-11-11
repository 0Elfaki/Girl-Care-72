import 'package:flutter/material.dart';

import '../format.dart';
import '../state.dart';
import '../tools/pep_reminder.dart';
import 'checkin.dart';
import 'pep.dart';
import 'period.dart';

/// Her own tools: a check-in, her period, and the 28-day reminder.
class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('ME', style: t.labelMedium?.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
      Text('Tools for you', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text('Everything here stays on this phone. No one else sees it.', style: t.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 16),
      ListenableBuilder(
        listenable: s.moods,
        builder: (context, _) {
          final today = s.moods.today;
          return _ToolCard(
            icon: Icons.spa_outlined,
            title: 'Feeling OK?',
            subtitle: today == null ? 'A quick check-in and a slow breath' : 'Today: ${today.mood.word}. Tap to check in again',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckInScreen())),
          );
        },
      ),
      ListenableBuilder(
        listenable: s.period,
        builder: (context, _) {
          final next = s.period.nextExpected;
          return _ToolCard(
            icon: Icons.calendar_month_outlined,
            title: 'My period',
            subtitle: next == null ? 'Know when the next one is coming' : 'Next one around ${shortDate(next)}',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PeriodScreen())),
          );
        },
      ),
      ListenableBuilder(
        listenable: s.pep,
        builder: (context, _) {
          final p = s.pep;
          final sub = !p.active
              ? 'A daily reminder for PEP medicine'
              : p.finished
                  ? 'Finished. Well done'
                  : 'Day ${p.today} of ${PepReminder.days}${p.takenToday ? ' · taken today' : ''}';
          return _ToolCard(
            icon: Icons.alarm_outlined,
            title: 'My 28 days',
            subtitle: sub,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PepScreen())),
          );
        },
      ),
    ]);
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(radius: 24, backgroundColor: c.primaryContainer, foregroundColor: c.onPrimaryContainer, child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
