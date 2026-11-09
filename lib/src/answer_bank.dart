import 'models.dart';

/// Messages that must always show Get help first, online or offline.
final danger = RegExp(
  r'\b(rape|raped|forced|force me|defile|defiled|attack|attacked|hurt me|beat me|beats me|kill myself|suicide|end my life|bleeding a lot|touched me|abused|abuse me|threaten)',
  caseSensitive: false,
);

const _dangerReply =
    'You are not alone, and it is not your fault. Care within 72 hours can stop HIV and pregnancy. '
    'Tap Get help and a responder calls you back at a safe time. The ride is free.';

final _bank = <(RegExp, String, int)>[
  (RegExp(r'pep|hiv.*(after|stop)|72', caseSensitive: false), 'PEP is medicine that can stop HIV after forced or unprotected sex. Start it as soon as possible, within 72 hours, and take it every day for 28 days. Tap Get help and we send a free ride to a health centre that has it.', 2),
  (RegExp(r'pregnan|emergency|morning after|contracep', caseSensitive: false), 'Emergency contraception can prevent pregnancy after sex. It works best in the first 3 days, and some methods work up to 5 days. A health worker can give it to you.', 2),
  (RegExp(r'period|menstru|pad|cramp', caseSensitive: false), 'Periods are normal and healthy. They usually last 2 to 7 days. Change your pad every 4 to 6 hours and dry cloth pads in the sun. See a health worker if bleeding lasts more than 7 days or soaks a pad every hour.', 4),
  (RegExp(r'condom|family planning|implant|injection|pill', caseSensitive: false), 'Condoms used every time protect from HIV and pregnancy. Pills, injection, implant and coil prevent pregnancy but not HIV. The health centre can help you choose.', 3),
  (RegExp(r'hiv|aids|test', caseSensitive: false), 'HIV passes through sex, blood and from mother to baby, not by hugging or sharing food. An HIV test is quick and confidential. People with HIV live long, healthy lives with daily medicine.', 3),
  (RegExp(r'consent|say no|boyfriend|husband|pressure', caseSensitive: false), 'Consent means a free, clear yes, and you can change your mind any time. No one may force or pressure you into sex, not even a partner, husband or someone who gave you gifts.', 1),
  (RegExp(r'phone|photo|online|facebook|whatsapp', caseSensitive: false), 'Never send photos of your body to anyone. Lock your phone with a PIN, and save our number under a safe name. If someone threatens you online, it is not your fault. Tell a trusted adult or tap Get help.', 6),
  (RegExp(r'school|marriage|future', caseSensitive: false), 'School is your right. Girls who become pregnant or have a baby can go back to school in Uganda. No one may ask for sex in exchange for marks, money or gifts.', 7),
  (RegExp(r'safe|plan|code word|trusted', caseSensitive: false), 'A safety plan has four parts: a safe place to go, a person who will help, a code word for danger, and our number saved under a safe name.', 5),
  (RegExp(r'help|ride|number|call', caseSensitive: false), 'Flash or call the GirlCare72 number, text HELP, or tap Get help. A responder calls you back at a safe time and can send a free ride to the health centre.', 8),
];

/// Offline answer from the reviewed answer bank.
Answer bankAnswer(String q) {
  if (danger.hasMatch(q)) return Answer(text: _dangerReply, lesson: 2, help: true);
  for (final (pattern, text, lesson) in _bank) {
    if (pattern.hasMatch(q)) return Answer(text: text, lesson: lesson);
  }
  return Answer(
    text: "I don't have an approved answer for that yet. A responder can help: tap Get help and choose a safe time.",
    source: 'none',
  );
}
