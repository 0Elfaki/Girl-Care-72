// Dev only: opens one screen with sample data, for screenshots and design checks.
// Not part of the app that girls get (that is lib/main.dart).
//
//   flutter build web -t lib/preview_main.dart -o build/preview --base-href /
//   then open  /?screen=me | checkin | relationship | pep | pep-active | period | places | ask | nurse
import 'package:flutter/material.dart';

import 'src/api.dart';
import 'src/screens/checkin.dart';
import 'src/screens/directory.dart';
import 'src/screens/nurse.dart';
import 'src/screens/pep.dart';
import 'src/screens/period.dart';
import 'src/screens/shell.dart';
import 'src/state.dart';
import 'src/theme.dart';
import 'src/tools/checkin.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final screen = Uri.base.queryParameters['screen'] ?? 'me';
  final state = AppState(Api());
  state.load().then((_) async {
    final now = DateTime.now();
    switch (screen) {
      case 'me':
        state.openTab(tabMe);
        await state.period.add(now.subtract(const Duration(days: 19)));
      case 'checkin':
        await state.moods.add(Mood.low);
      case 'pep-active':
        await state.pep.begin(firstDay: now.subtract(const Duration(days: 11)), hour: 21, minute: 0, label: 'Take your vitamins');
        for (var d = 1; d <= 10; d++) {
          if (d != 4) state.pep.taken.add(d);
        }
        await state.pep.setTakenToday(false);
      case 'period':
        for (final back in [19, 48, 78]) {
          await state.period.add(now.subtract(Duration(days: back)));
        }
      case 'ask':
        state.openTab(tabAsk);
    }
  });

  final home = switch (screen) {
    'checkin' => const CheckInScreen(),
    'relationship' => const RelationshipCheckScreen(),
    'pep' || 'pep-active' => const PepScreen(),
    'period' => const PeriodScreen(),
    'places' => Scaffold(
        appBar: AppBar(title: const Text('GirlCare72')),
        body: SafeArea(child: ListView(padding: const EdgeInsets.all(18), children: [DirectoryList(onCallBack: () {})])),
      ),
    'nurse' => const _OpenSheet(),
    _ => const Shell(),
  };

  runApp(AppScope(
    state: state,
    child: MaterialApp(debugShowCheckedModeBanner: false, theme: buildTheme(Brightness.light), darkTheme: buildTheme(Brightness.dark), home: home),
  ));
}

class _OpenSheet extends StatefulWidget {
  const _OpenSheet();
  @override
  State<_OpenSheet> createState() => _OpenSheetState();
}

class _OpenSheetState extends State<_OpenSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => showNurseSheet(context, question: 'Is it normal to have pain during my period?'));
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Ask')));
}
