import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../state.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});
  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
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
    err == null ? _showReceived() : _showNotSent();
  }

  Future<void> _callFreeNumber() async {
    final ok = await launchUrl(Uri(scheme: 'tel', path: Config.freeNumber.replaceAll(' ', '')));
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Call ${Config.freeNumber}')));
    }
  }

  void _showReceived() => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(Icons.check_circle, size: 48, color: Theme.of(ctx).colorScheme.primary),
          title: const Text('Request received'),
          content: Text(
            'We will call you back shortly, at the safe time you chose (${safeTime.toLowerCase()}). '
            'The call comes from a neutral number.\n\nNothing about this request is kept in the app.',
          ),
          actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );

  void _showNotSent() => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(Icons.phone_in_talk, size: 48, color: Theme.of(ctx).colorScheme.primary),
          title: const Text('Please call us now'),
          content: Text(
            'Your request did not reach us, so we cannot call you back yet. '
            'Flash or call ${Config.freeNumber}, or text HELP to it, and a responder will help you.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Try again later')),
            FilledButton.icon(
              icon: const Icon(Icons.call),
              label: const Text('Call now'),
              onPressed: () {
                Navigator.pop(ctx);
                _callFreeNumber();
              },
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;

    return Form(
      key: _form,
      child: ListView(padding: const EdgeInsets.all(18), children: [
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
            ]),
          ),
        ),
      ]),
    );
  }
}
