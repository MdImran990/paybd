import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../storage/account_keys.dart';

/// What a backup contains for one account (never the PIN).
const backupKeys = [
  'wallet_balance',
  'wallet_txs',
  'notifications',
  'savings_goals',
  'profile_name',
  'nominee',
  'require_pin_for_balance',
];

/// Text the user can copy and keep safe.
String buildBackup(SharedPreferences prefs, String phone) {
  final data = <String, Object?>{};
  for (final key in backupKeys) {
    final value = prefs.get(acctKey(phone, key));
    if (value != null) data[key] = value;
  }
  return jsonEncode({
    'app': 'paybd',
    'version': 1,
    'phone': phone,
    'createdAt': DateTime.now().toIso8601String(),
    'data': data,
  });
}

/// Puts a backup back. Returns null on success, or an error message.
Future<String?> restoreBackup(
  SharedPreferences prefs,
  String phone,
  String text,
) async {
  final Map<String, dynamic> json;
  try {
    json = jsonDecode(text) as Map<String, dynamic>;
  } catch (_) {
    return 'This is not a PayBD backup.';
  }
  if (json['app'] != 'paybd' || json['version'] != 1) {
    return 'This is not a PayBD backup.';
  }
  if (json['phone'] != phone) {
    return 'This backup belongs to another number.';
  }
  final data = json['data'];
  if (data is! Map<String, dynamic>) return 'This is not a PayBD backup.';

  for (final entry in data.entries) {
    if (!backupKeys.contains(entry.key)) continue;
    final key = acctKey(phone, entry.key);
    final value = entry.value;
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    }
  }
  return null;
}
