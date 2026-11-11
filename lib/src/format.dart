const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "24 Nov"
String shortDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// "8:00 pm"
String clockTime(int hour, int minute) {
  final h = hour % 12 == 0 ? 12 : hour % 12;
  return '$h:${minute.toString().padLeft(2, '0')} ${hour < 12 ? 'am' : 'pm'}';
}

/// The same day at midnight, so two dates compare by day only.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
