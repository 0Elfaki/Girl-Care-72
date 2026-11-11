# GirlCare72 app (Flutter)

The girls' app: short lessons in two age tracks, quizzes, audio, Ask GirlCare, Talk to a nurse, a help directory, her own tools (Feeling OK?, My period, My 28 days PEP reminder), Get help and Quick exit. No account, no name. It works offline with the bundled lessons and the reviewed answer bank, and connects to the GirlCare72 server for approved lessons, AI answers and call-back requests.

## What is inside

| Screen | What it does |
| --- | --- |
| Learn | 8 lessons for ages 10 to 14 and 15 to 24: key messages, a story, a 3-question quiz and Listen (text-to-speech). Progress stays on the phone. |
| Ask | Ask GirlCare. Answers come from the server's AI, using approved lessons only, or from the reviewed answer bank when offline. Danger words show Get help first, online or offline. The chat is never saved. **Talk to a nurse** sends her question to a real person: a call back (`kind: nurse` on `/api/public/help`) or an SMS `ASK …` to the free number. |
| Me | Her own tools, all on the phone only. **Feeling OK?**: a one-tap mood check-in, a breathing minute, who to talk to, Sauti 116, and a 7-question relationship safety check (never saved). **My period**: logs first days and predicts the next one. **My 28 days**: a daily PEP reminder for 28 days; the notification shows only the neutral words she picks (`Daily reminder`, `Take your vitamins` …), never PEP or GirlCare72. |
| Get help | Two parts. **Call me back**: the number to call, language, a safe time, and "for someone else". The success popup shows only when the server confirmed the request; otherwise a "Please call us now" popup with a Call now button. **Places that help**: a directory (Sauti 116, police 999/112, Child and Family Protection Unit, health centre, GBV agency, counselling, legal aid, shelter) with tap-to-call and tap-to-text. Bundled in `assets/help_directory.json`; the server can replace it from `/api/public/directory` (`{"places": [...]}`). Places without a number are reached through the call back. |
| Quick exit | On every screen. Opens a plain weather page and removes the app's screens from the back stack. Back then closes the app. |
| Settings | Language, and Clear my progress and chat. |

Privacy on Android: the app blocks screenshots and hides its content in the recent-apps screen (`FLAG_SECURE` in `MainActivity.kt`), and turns off Android backup.

## Build

You need Flutter 3.35 or newer and the Android SDK.

```bash
flutter pub get
flutter test
flutter build apk --release \
  --dart-define=API_BASE=https://your-server-address \
  --dart-define=FREE_NUMBER="0788907052"
```

The file is `build/app/outputs/flutter-apk/app-release.apk`. Upload it in the dashboard under **Website & app** and the website's Download button gives it to girls.

`API_BASE` is the GirlCare72 server's address. Without it the app runs offline only.

Before you share the app widely, sign it with your own key instead of the debug key: create a keystore and follow https://docs.flutter.dev/deployment/android#sign-the-app. Keep the keystore safe; every update must be signed with the same key.

## Change the name, icon or colours

- Name on the phone: `android:label` in `android/app/src/main/AndroidManifest.xml`.
- Icon: replace the files in `android/app/src/main/res/mipmap-*` (keep it neutral, like a learning app).
- Colours: `lib/src/theme.dart`.

## Lessons

`assets/lessons.json` holds the bundled draft lessons so the app works on first open without data. The app replaces them with the lessons published from the dashboard whenever it reaches the server. Lessons say "draft" until a health worker and the GBV agency approve them in the dashboard.

## Code map

```
lib/main.dart                app start
lib/src/config.dart          API_BASE, FREE_NUMBER, languages
lib/src/state.dart           lessons, progress, anonymous lesson counts (on this phone only)
lib/src/api.dart             calls to the server
lib/src/answer_bank.dart     offline answers and danger words
lib/src/notifications.dart   neutral daily reminders (flutter_local_notifications)
lib/src/help_directory.dart  places that help, bundled + from the server
lib/src/tools/               her own data: PEP reminder, period tracker, mood log + relationship check
lib/src/screens/             learn, ask, nurse, me, pep, period, checkin, help, directory, quick-exit screens
lib/preview_main.dart        dev only: opens one screen with sample data for screenshots
```

## Licence

MIT. See LICENSE.
