import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';

/// Opens the phone dialler with [number] filled in.
Future<void> callNumber(BuildContext context, String number) async {
  var ok = false;
  try {
    ok = await launchUrl(Uri(scheme: 'tel', path: number.replaceAll(' ', '')));
  } catch (_) {}
  if (!ok && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Call $number')));
}

/// Opens the SMS app with [text] ready to send to [number].
Future<void> sendSms(BuildContext context, String number, String text) async {
  var ok = false;
  try {
    ok = await launchUrl(Uri(scheme: 'sms', path: number.replaceAll(' ', ''), query: 'body=${Uri.encodeComponent(text)}'));
  } catch (_) {}
  if (!ok && context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Text "$text" to $number')));
}

/// Shown only when the server confirmed it has the request.
void showRequestReceived(BuildContext context, {required String safeTime, String who = 'A responder'}) => showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.check_circle, size: 48, color: Theme.of(ctx).colorScheme.primary),
        title: const Text('Request received'),
        content: Text(
          '$who will call you back shortly, at the safe time you chose (${safeTime.toLowerCase()}). '
          'The call comes from a neutral number.\n\nNothing about this request is kept in the app.',
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );

/// The request did not reach the server, so she must reach a person herself.
void showNotSent(BuildContext context) => showDialog<void>(
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
              callNumber(context, Config.freeNumber);
            },
          ),
        ],
      ),
    );
