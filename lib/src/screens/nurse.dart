import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../state.dart';
import 'help_dialogs.dart';

/// What the sheet was closed with: a call-back request that was sent (or not), or an SMS to open.
typedef _Outcome = ({String kind, String? error, String safeTime, String question});

/// Talk to a nurse: a real person answers her health question, by call back or SMS.
/// The result dialogs open from the caller's screen, after the sheet (and what she typed) is gone.
Future<void> showNurseSheet(BuildContext context, {String question = ''}) async {
  final r = await showModalBottomSheet<_Outcome>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _NurseSheet(question: question),
  );
  if (r == null || !context.mounted) return;
  switch (r.kind) {
    case 'sms':
      await sendSms(context, Config.freeNumber, 'ASK ${r.question}'.trim());
    case 'call' when r.error == null:
      showRequestReceived(context, safeTime: r.safeTime, who: 'A nurse');
    default:
      showNotSent(context);
  }
}

class _NurseSheet extends StatefulWidget {
  const _NurseSheet({required this.question});
  final String question;
  @override
  State<_NurseSheet> createState() => _NurseSheetState();
}

class _NurseSheetState extends State<_NurseSheet> {
  final _form = GlobalKey<FormState>();
  late final _question = TextEditingController(text: widget.question);
  final _phone = TextEditingController();
  String safeTime = Config.safeTimes.first;
  bool sending = false;

  @override
  void dispose() {
    _question.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _callMeBack(AppState s) async {
    if (!_form.currentState!.validate()) return;
    setState(() => sending = true);
    final err = await s.api.requestHelp(
      phone: _phone.text.trim(),
      language: s.language,
      safeTime: safeTime,
      forSomeone: false,
      kind: 'nurse',
      question: _question.text.trim(),
    );
    if (!mounted) return;
    // Closing the sheet also drops everything she typed.
    Navigator.pop(context, (kind: 'call', error: err, safeTime: safeTime, question: ''));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Form(
          key: _form,
          child: ListView(shrinkWrap: true, padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), children: [
            Row(children: [
              Icon(Icons.support_agent, color: c.primary),
              const SizedBox(width: 8),
              Text('Talk to a nurse', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 4),
            Text('A nurse from the GirlCare72 team answers you in person. Nothing you write is kept in the app.', style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
            const SizedBox(height: 14),
            TextFormField(
              controller: _question,
              maxLength: 300,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Your question', border: OutlineInputBorder()),
              validator: (v) => (v ?? '').trim().length < 3 ? 'Write your question' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
              decoration: const InputDecoration(labelText: 'Phone number to call', hintText: '07xx xxx xxx', border: OutlineInputBorder()),
              validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length < 9 ? 'Enter the number we should call' : null,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: safeTime,
              decoration: const InputDecoration(labelText: 'Safe time to call', border: OutlineInputBorder()),
              items: Config.safeTimes.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (v) => setState(() => safeTime = v ?? safeTime),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: sending ? null : () => _callMeBack(s),
              icon: const Icon(Icons.call),
              label: Text(sending ? 'Sending…' : 'A nurse calls me back'),
            ),
            const SizedBox(height: 14),
            Row(children: [
              const Expanded(child: Divider()),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('or', style: t.bodySmall)),
              const Expanded(child: Divider()),
            ]),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, (kind: 'sms', error: null, safeTime: safeTime, question: _question.text.trim())),
              icon: const Icon(Icons.sms_outlined),
              label: Text('Text ASK to ${Config.freeNumber}'),
            ),
            const SizedBox(height: 4),
            Text('Works with no internet. The nurse replies by SMS or calls.', style: t.bodySmall, textAlign: TextAlign.center),
          ]),
        ),
      ),
    );
  }
}
