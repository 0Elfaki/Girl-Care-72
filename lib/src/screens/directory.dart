import 'package:flutter/material.dart';

import '../config.dart';
import '../help_directory.dart';
import '../state.dart';
import 'help_dialogs.dart';

/// Places that help: helplines, police, health, counselling, legal aid, shelter.
class DirectoryList extends StatefulWidget {
  const DirectoryList({super.key, required this.onCallBack});

  /// Opens the call-back form, for places reached through GirlCare72.
  final VoidCallback onCallBack;
  @override
  State<DirectoryList> createState() => _DirectoryListState();
}

class _DirectoryListState extends State<DirectoryList> {
  String kind = 'All';

  static const _icons = {
    'Children': Icons.child_care,
    'Police': Icons.local_police_outlined,
    'Health': Icons.local_hospital_outlined,
    'Counselling': Icons.forum_outlined,
    'Legal': Icons.gavel,
    'Shelter': Icons.night_shelter_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    final girlcare = HelpPlace(
      id: 'girlcare72',
      kind: 'GirlCare72',
      name: 'GirlCare72',
      what: 'Flash or call, or text HELP. A responder calls you back at a safe time and can send a free ride to care.',
      phone: Config.freeNumber,
      sms: 'HELP',
      hours: '24 hours',
      free: true,
    );
    final kinds = ['All', ...{for (final p in s.places) p.kind}];
    final shown = [girlcare, ...s.places.where((p) => kind == 'All' || p.kind == kind)];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Places that help', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text('Calls to free numbers cost nothing. Where there is no number, GirlCare72 connects you.', style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
      const SizedBox(height: 10),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final k in kinds)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(label: Text(k), selected: kind == k, onSelected: (_) => setState(() => kind = k)),
            ),
        ]),
      ),
      const SizedBox(height: 10),
      for (final p in shown)
        Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(p.id == 'girlcare72' ? Icons.favorite : (_icons[p.kind] ?? Icons.place_outlined), color: c.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(p.name, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    Text([p.kind, if (p.hours != null) p.hours!, if (p.free) 'free'].join(' · '), style: t.bodySmall?.copyWith(color: c.onSurfaceVariant)),
                  ]),
                ),
              ]),
              const SizedBox(height: 8),
              Text(p.what, style: t.bodyMedium),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, children: [
                if (p.phone != null)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                    onPressed: () => callNumber(context, p.phone!),
                    icon: const Icon(Icons.call),
                    label: Text('Call ${p.phone}'),
                  ),
                if (p.phone != null && p.sms != null)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
                    onPressed: () => sendSms(context, p.phone!, p.sms!),
                    icon: const Icon(Icons.sms_outlined),
                    label: Text('Text ${p.sms}'),
                  ),
                if (p.viaGirlCare)
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                    onPressed: widget.onCallBack,
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('Ask GirlCare72 to connect me'),
                  ),
              ]),
            ]),
          ),
        ),
      const SizedBox(height: 6),
      Text('In danger right now? Call 999 or 112, or go to the nearest police post or health centre.', style: t.bodySmall),
    ]);
  }
}
