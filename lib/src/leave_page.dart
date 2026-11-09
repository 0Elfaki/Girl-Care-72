// On the web, Quick exit replaces the page so Back cannot return to it.
// On phones this does nothing; the app shows its own neutral screen.
export 'leave_page_stub.dart' if (dart.library.js_interop) 'leave_page_web.dart';
