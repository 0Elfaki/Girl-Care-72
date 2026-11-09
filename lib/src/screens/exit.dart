import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// What anyone sees after Quick exit: an ordinary weather page.
/// Back closes the app instead of returning to GirlCare72.
class NeutralScreen extends StatelessWidget {
  const NeutralScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => SystemNavigator.pop(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Weather'), automaticallyImplyLeading: false, backgroundColor: Colors.transparent),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          Text('Arua', style: t.titleMedium),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.wb_cloudy_outlined, size: 56),
            const SizedBox(width: 16),
            Text('27°', style: t.displayLarge),
          ]),
          Text('Partly cloudy. Light rain after 4 pm.', style: t.bodyLarge),
          const SizedBox(height: 28),
          for (final d in const [('Tomorrow', '29°', Icons.wb_sunny_outlined), ('Wednesday', '26°', Icons.grain), ('Thursday', '27°', Icons.wb_cloudy_outlined)])
            ListTile(contentPadding: EdgeInsets.zero, leading: Icon(d.$3), title: Text(d.$1), trailing: Text(d.$2, style: t.titleMedium)),
        ]),
      ),
    );
  }
}
