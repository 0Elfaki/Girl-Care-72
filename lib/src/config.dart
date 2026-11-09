/// Build-time settings. Set them when you build the app, for example:
///
///   flutter build apk --release \
///     --dart-define=API_BASE=https://api.girlcare72.com \
///     --dart-define=FREE_NUMBER="0788907052"
class Config {
  /// Address of the GirlCare72 server. Empty means the app works offline only:
  /// bundled lessons, the reviewed answer bank, and the free number for help.
  static const apiBase = String.fromEnvironment('API_BASE', defaultValue: '');

  /// The free number girls flash or call.
  static const freeNumber = String.fromEnvironment('FREE_NUMBER', defaultValue: '0788907052');

  static const languages = ['English', 'Juba Arabic', 'Bari', 'Kakwa'];
  static const safeTimes = ['Any time', 'Morning', 'Afternoon', 'After 6 pm'];
}
