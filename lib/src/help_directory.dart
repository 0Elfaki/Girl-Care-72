import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One place that helps: a helpline, the police, a health centre, legal aid.
/// A place without a phone number is reached through GirlCare72's call back.
class HelpPlace {
  HelpPlace({
    required this.id,
    required this.kind,
    required this.name,
    required this.what,
    this.phone,
    this.sms,
    this.hours,
    this.free = false,
  });

  final String id;
  final String kind; // Children, Police, Health, Counselling, Legal, Shelter
  final String name;
  final String what;
  final String? phone;
  final String? sms; // the word to text, if the place answers SMS
  final String? hours;
  final bool free;

  bool get viaGirlCare => phone == null;

  factory HelpPlace.fromJson(Map<String, dynamic> j) => HelpPlace(
        id: j['id'] as String,
        kind: j['kind'] as String? ?? 'Help',
        name: j['name'] as String,
        what: j['what'] as String? ?? '',
        phone: j['phone'] as String?,
        sms: j['sms'] as String?,
        hours: j['hours'] as String?,
        free: j['free'] == true,
      );

  Map<String, dynamic> toJson() => {'id': id, 'kind': kind, 'name': name, 'what': what, 'phone': phone, 'sms': sms, 'hours': hours, 'free': free};
}

List<HelpPlace> placesFromJson(List raw) => raw.map((e) => HelpPlace.fromJson(Map<String, dynamic>.from(e as Map))).toList();

/// The directory bundled with the app, so it works with no network.
Future<List<HelpPlace>> bundledDirectory() async => placesFromJson(jsonDecode(await rootBundle.loadString('assets/help_directory.json')) as List);
