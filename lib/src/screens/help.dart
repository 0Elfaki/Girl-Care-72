import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config.dart';
import '../state.dart';
import 'directory.dart';
import 'help_dialogs.dart';

/// Get help: a one-step call-back request, and the directory of places that help.
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});
  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String section = 'call';

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(18), children: [
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'call', icon: Icon(Icons.phone_callback_outlined), label: Text('Call me back')),
          ButtonSegment(value: 'places', icon: Icon(Icons.map_outlined), label: Text('Places that help')),
        ],
        selected: {section},
        onSelectionChanged: (v) => setState(() => section = v.first),
      ),
      const SizedBox(height: 16),
      if (section == 'call') const _CallBackForm() else DirectoryList(onCallBack: () => setState(() => section = 'call')),
    ]);
  }
}

class _CallBackForm extends StatefulWidget {
  const _CallBackForm();
  @override
  State<_CallBackForm> createState() => _CallBackFormState();
}

class _CallBackFormState extends State<_CallBackForm> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  String language = 'English';
  String safeTime = 'Any time';
  bool forSomeone = false;
  bool sending = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit(AppState s) async {
    if (!_form.currentState!.validate()) return;
    setState(() => sending = true);
    final err = await s.api.requestHelp(phone: _phone.text.trim(), language: language, safeTime: safeTime, forSomeone: forSomeone);
    if (!mounted) return;
    setState(() {
      sending = false;
      if (err == null) _phone.clear(); // nothing about the request stays in the app
    });
    // Only say "we will call you" when the server really has the request.
    // Otherwise the girl must know to call us herself.
    err == null ? showRequestReceived(context, safeTime: safeTime) : showNotSent(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return Form(
      key: _form,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Get help', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text('One step. We call you back. We only send your number, language and a safe time.', style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
          decoration: const InputDecoration(labelText: 'Phone number to call', hintText: '07xx xxx xxx', border: OutlineInputBorder()),
          validator: (v) => (v ?? '').replaceAll(RegExp(r'\D'), '').length < 9 ? 'Enter the number we should call' : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: language,
          decoration: const InputDecoration(labelText: 'Language', border: OutlineInputBorder()),
          items: Config.languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
          onChanged: (v) => setState(() => language = v ?? language),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: safeTime,
          decoration: const InputDecoration(labelText: 'Safe time to call', border: OutlineInputBorder()),
          items: Config.safeTimes.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
          onChanged: (v) => setState(() => safeTime = v ?? safeTime),
        ),
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: forSomeone,
          onChanged: (v) => setState(() => forSomeone = v ?? false),
          title: const Text("I'm asking for someone else"),
          controlAffinity: ListTileControlAffinity.leading,
        ),
        const SizedBox(height: 8),
        FilledButton(onPressed: sending ? null : () => _submit(s), child: Text(sending ? 'Sending…' : 'Call me back')),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Or flash or call free', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              SelectableText(Config.freeNumber, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1)),
              const SizedBox(height: 4),
              Text('Flashing costs nothing. Save the number under a safe name. Text HELP for a call back, or LEARN for weekly lessons.', style: t.bodySmall),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, children: [
                FilledButton.tonalIcon(onPressed: () => callNumber(context, Config.freeNumber), icon: const Icon(Icons.call), label: const Text('Call now')),
                OutlinedButton.icon(onPressed: () => sendSms(context, Config.freeNumber, 'HELP'), icon: const Icon(Icons.sms_outlined), label: const Text('Text HELP')),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}
