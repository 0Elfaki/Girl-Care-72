import 'package:flutter/material.dart';

import '../leave_page.dart';
import '../state.dart';
import 'ask.dart';
import 'exit.dart';
import 'help.dart';
import 'learn.dart';
import 'me.dart';

const tabLearn = 0;
const tabAsk = 1;
const tabMe = 2;
const tabHelp = 3;

/// From any pushed screen: closes it and shows one of the main tabs.
void showTab(BuildContext context, int tab) {
  final s = AppScope.of(context);
  Navigator.of(context).popUntil((r) => r.isFirst);
  s.openTab(tab);
}

/// Opens the neutral screen at once and removes every GirlCare72 screen from the
/// back stack, so the back button cannot return to the app.
void quickExit(BuildContext context) {
  AppScope.of(context).clearChat();
  if (leavePage()) return;
  Navigator.of(context).pushAndRemoveUntil(
    PageRouteBuilder(pageBuilder: (context, animation, secondary) => const NeutralScreen(), transitionDuration: Duration.zero),
    (_) => false,
  );
}

class QuickExitButton extends StatelessWidget {
  const QuickExitButton({super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 38),
            backgroundColor: Theme.of(context).colorScheme.inverseSurface,
            foregroundColor: Theme.of(context).colorScheme.onInverseSurface,
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          onPressed: () => quickExit(context),
          child: const Text('Quick exit'),
        ),
      );
}

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: s.tab,
      builder: (context, tab, _) => Scaffold(
        appBar: AppBar(
          title: const Text('GirlCare72', style: TextStyle(fontWeight: FontWeight.w800)),
          actions: [
            IconButton(tooltip: 'Settings', icon: const Icon(Icons.tune), onPressed: () => showSettings(context)),
            const QuickExitButton(),
          ],
        ),
        body: SafeArea(
          child: IndexedStack(index: tab, children: [
            LearnScreen(onGetHelp: () => s.openTab(tabHelp)),
            AskScreen(onGetHelp: () => s.openTab(tabHelp)),
            const MeScreen(),
            const HelpScreen(),
          ]),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: tab,
          onDestinationSelected: s.openTab,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Learn'),
            NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Ask'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Me'),
            NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Get help'),
          ],
        ),
      ),
    );
  }
}

void showSettings(BuildContext context) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final s = AppScope.of(ctx);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Settings', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: s.language,
              decoration: const InputDecoration(labelText: 'Language', border: OutlineInputBorder()),
              items: const ['English', 'Juba Arabic', 'Bari', 'Kakwa'].map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (v) => v == null ? null : s.setLanguage(v),
            ),
            const SizedBox(height: 6),
            Text('Lessons appear in a language once they are translated and approved. Until then you see English.',
                style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('Clear my progress, chat and tools'),
              onPressed: () async {
                await s.clearAll();
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cleared from this phone')));
                }
              },
            ),
            const SizedBox(height: 8),
            Text('GirlCare72 has no account and keeps no name. Your progress, reminder, periods and check-ins stay on this phone.',
                style: Theme.of(ctx).textTheme.bodySmall),
          ]),
        ),
      );
    },
  );
}
