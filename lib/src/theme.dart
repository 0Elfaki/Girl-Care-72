import 'package:flutter/material.dart';

const plum = Color(0xFF7A3E8E);
const marigold = Color(0xFFD99210);
const okGreen = Color(0xFF2C8549);

ThemeData buildTheme(Brightness b) {
  final scheme = ColorScheme.fromSeed(seedColor: plum, brightness: b, primary: b == Brightness.light ? plum : const Color(0xFFD49BE6));
  final base = ThemeData(colorScheme: scheme, useMaterial3: true, brightness: b);
  return base.copyWith(
    textTheme: base.textTheme.apply(fontSizeFactor: 1.05),
    appBarTheme: AppBarTheme(backgroundColor: scheme.primaryContainer, foregroundColor: scheme.onPrimaryContainer, elevation: 0),
    cardTheme: CardThemeData(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: scheme.outlineVariant))),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(64, 52), textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
  );
}
