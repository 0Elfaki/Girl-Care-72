import 'package:web/web.dart' as web;

/// Replaces this page in the browser history with a weather search,
/// so the Back button cannot bring GirlCare72 back.
bool leavePage() {
  try {
    web.window.sessionStorage.clear();
    web.window.location.replace('https://www.google.com/search?q=weather');
    return true;
  } catch (_) {
    return false;
  }
}
