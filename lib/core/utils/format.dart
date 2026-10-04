/// Money is always stored as an int in paisa (minor units). Never use double for money.
String formatTaka(int minor) {
  final negative = minor < 0;
  final abs = minor.abs();
  final taka = (abs ~/ 100).toString();
  final paisa = (abs % 100).toString().padLeft(2, '0');

  // Bangladeshi grouping: 1,60,000
  String grouped;
  if (taka.length <= 3) {
    grouped = taka;
  } else {
    final last3 = taka.substring(taka.length - 3);
    var rest = taka.substring(0, taka.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped = '${parts.join(',')},$last3';
  }
  return '${negative ? '-' : ''}৳ $grouped.$paisa';
}

/// "125.5" -> 12550. Returns null if the text is not a valid amount.
int? parseTakaToMinor(String input) {
  final m = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(input.trim());
  if (m == null) return null;
  final taka = int.parse(m.group(1)!);
  final frac = (m.group(2) ?? '').padRight(2, '0');
  return taka * 100 + int.parse(frac);
}

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String formatDateTime(DateTime d) {
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final m = d.minute.toString().padLeft(2, '0');
  final ampm = d.hour >= 12 ? 'PM' : 'AM';
  final day = d.day.toString().padLeft(2, '0');
  return '$day ${_months[d.month - 1]} ${d.year}, ${h.toString().padLeft(2, '0')}:$m $ampm';
}
