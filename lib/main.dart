import 'package:flutter/material.dart';

import 'src/api.dart';
import 'src/screens/shell.dart';
import 'src/state.dart';
import 'src/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState(Api())..load();
  runApp(GirlCareApp(state: state));
}

class GirlCareApp extends StatelessWidget {
  const GirlCareApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'GirlCare72',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        home: const Shell(),
      ),
    );
  }
}
