import 'package:flutter/material.dart';

import '../answer_bank.dart';
import '../models.dart';
import '../state.dart';

class AskScreen extends StatefulWidget {
  const AskScreen({super.key, required this.onGetHelp});
  final VoidCallback onGetHelp;
  @override
  State<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends State<AskScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  bool busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(AppState s) async {
    final q = _ctrl.text.trim();
    if (q.length < 2 || busy) return;
    _ctrl.clear();
    setState(() {
      busy = true;
      s.chat.add(ChatLine(fromGirl: true, text: q));
      // Danger words show Get help straight away, before any answer arrives.
      if (danger.hasMatch(q)) s.chat.add(ChatLine(fromGirl: false, text: '', answer: Answer(text: '', help: true)));
    });
    _toEnd();
    final a = await s.api.ask(q, s.track, s.language);
    if (!mounted) return;
    setState(() {
      s.chat.removeWhere((c) => !c.fromGirl && c.text.isEmpty);
      s.chat.add(ChatLine(fromGirl: false, text: a.text, answer: a));
      busy = false;
    });
    _toEnd();
  }

  void _toEnd() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      });

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final c = Theme.of(context).colorScheme;
    return Column(children: [
      Expanded(
        child: ListView(controller: _scroll, padding: const EdgeInsets.all(16), children: [
          Text('Ask GirlCare', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Ask anything about your body, health or safety. Answers come only from approved lessons. No name needed, and the chat is not saved.',
              style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant)),
          const SizedBox(height: 14),
          if (s.chat.isEmpty) _bubble(context, false, 'Hi. What would you like to know? For example: "What is PEP?" or "Is my period normal?"'),
          for (final line in s.chat) ...[
            if (!line.fromGirl && (line.answer?.help ?? false)) _helpCard(context),
            if (line.text.isNotEmpty) _bubble(context, line.fromGirl, line.text, answer: line.answer),
          ],
          if (busy) Padding(padding: const EdgeInsets.all(8), child: Text('Thinking…', style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant))),
        ]),
      ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                maxLength: 300,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(s),
                decoration: const InputDecoration(hintText: 'Type your question', border: OutlineInputBorder(), counterText: ''),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: busy ? null : () => _send(s), child: const Text('Ask')),
          ]),
        ),
      ),
    ]);
  }

  Widget _bubble(BuildContext context, bool mine, String text, {Answer? answer}) {
    final c = Theme.of(context).colorScheme;
    final src = answer == null
        ? null
        : answer.source == 'ai'
            ? 'AI, from approved lessons'
            : answer.source == 'bank'
                ? 'Reviewed answer bank'
                : null;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .8),
        decoration: BoxDecoration(
          color: mine ? c.primary : c.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(text, style: TextStyle(color: mine ? c.onPrimary : c.onSurface, fontSize: 16)),
          if (src != null || answer?.lesson != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text([?src, if (answer?.lesson != null) 'see lesson ${answer!.lesson}'].join(' · '),
                  style: TextStyle(fontSize: 12, color: c.onSurfaceVariant)),
            ),
        ]),
      ),
    );
  }

  Widget _helpCard(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: c.primaryContainer, borderRadius: BorderRadius.circular(14), border: Border.all(color: c.primary, width: 2)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('You are not alone.', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        const SizedBox(height: 4),
        const Text('If someone hurt you, care within 72 hours can stop HIV and pregnancy. The ride is free.'),
        const SizedBox(height: 10),
        FilledButton(onPressed: widget.onGetHelp, child: const Text('Get help now')),
      ]),
    );
  }
}
