import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:girlcare72/src/help_directory.dart';
import 'package:girlcare72/src/tools/checkin.dart';
import 'package:girlcare72/src/tools/pep_reminder.dart';
import 'package:girlcare72/src/tools/period_tracker.dart';

void main() {
  group('PEP reminder', () {
    test('day 1 is the start day, day 28 is the last', () {
      final start = DateTime(2026, 11, 1);
      expect(PepReminder.dayNumber(start, DateTime(2026, 11, 1, 23, 59)), 1);
      expect(PepReminder.dayNumber(start, DateTime(2026, 11, 28)), 28);
      expect(PepReminder.dayNumber(start, DateTime(2026, 11, 29)), 29); // finished
    });

    test('reminder words never mention PEP, HIV or the app', () {
      for (final l in PepReminder.labels) {
        expect(l.toLowerCase(), isNot(contains('pep')));
        expect(l.toLowerCase(), isNot(contains('hiv')));
        expect(l.toLowerCase(), isNot(contains('girlcare')));
      }
    });
  });

  group('Period tracker', () {
    test('uses 28 days until there are two periods', () {
      expect(PeriodTracker.averageCycle([]), 28);
      expect(PeriodTracker.averageCycle([DateTime(2026, 1, 1)]), 28);
    });

    test('learns her own cycle and ignores a second tap in the same period', () {
      // gaps: 2 (ignored), 28, 30 -> 29
      final starts = [DateTime(2026, 1, 1), DateTime(2026, 1, 3), DateTime(2026, 1, 31), DateTime(2026, 3, 2)];
      expect(PeriodTracker.averageCycle(starts), 29);
    });

    test('keeps the guess within 21 to 35 days', () {
      expect(PeriodTracker.averageCycle([DateTime(2026, 1, 1), DateTime(2026, 1, 17)]), 21);
      expect(PeriodTracker.averageCycle([DateTime(2026, 1, 1), DateTime(2026, 2, 25)]), 35);
    });
  });

  group('Relationship check', () {
    test('no yes answers is fine', () {
      expect(relationshipLevel(List.filled(7, false)), RelationshipLevel.fine);
    });

    test('one or two yes answers is a warning', () {
      expect(relationshipLevel([true, false, false, false, false, false, false]), RelationshipLevel.watch);
      expect(relationshipLevel([true, true, false, false, false, false, false]), RelationshipLevel.watch);
    });

    test('violence or forced sex is unsafe on its own', () {
      expect(relationshipLevel([false, false, true, false, false, false, false]), RelationshipLevel.unsafe);
      expect(relationshipLevel([false, false, false, true, false, false, false]), RelationshipLevel.unsafe);
    });

    test('three other yes answers is unsafe', () {
      expect(relationshipLevel([true, true, false, false, true, false, false]), RelationshipLevel.unsafe);
    });
  });

  group('Help directory', () {
    test('bundled directory loads and the two free numbers are there', () {
      final places = placesFromJson(jsonDecode(File('assets/help_directory.json').readAsStringSync()) as List);
      expect(places.length, greaterThanOrEqualTo(6));
      expect(places.firstWhere((p) => p.id == 'sauti').phone, '116');
      expect(places.firstWhere((p) => p.id == 'police').phone, '999');
      // Places without a number are reached through GirlCare72's call back.
      expect(places.where((p) => p.viaGirlCare), isNotEmpty);
      expect(places.map((p) => p.id).toSet().length, places.length, reason: 'ids must be unique');
    });
  });
}
