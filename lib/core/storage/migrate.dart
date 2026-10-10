import 'package:shared_preferences/shared_preferences.dart';
import 'account_keys.dart';

/// Older builds kept ONE account in global keys. This moves that data under the
/// account's own keys, once, so nothing is lost when upgrading.
Future<void> migrateLegacyData(SharedPreferences prefs) async {
  if (prefs.getBool('migrated_per_account') == true) return;

  final phone =
      prefs.getString('account_phone') ?? prefs.getString('session_phone');
  if (phone != null) {
    if (prefs.getStringList('accounts') == null) {
      await prefs.setStringList('accounts', [phone]);
    }
    await prefs.setString('last_phone', phone);

    const bases = [
      'wallet_balance',
      'wallet_txs',
      'notifications',
      'savings_goals',
      'profile_name',
      'require_pin_for_balance',
      'biometric_unlock',
    ];
    for (final base in bases) {
      final value = prefs.get(base);
      if (value == null) continue;
      final key = acctKey(phone, base);
      if (!prefs.containsKey(key)) {
        if (value is String) {
          await prefs.setString(key, value);
        } else if (value is int) {
          await prefs.setInt(key, value);
        } else if (value is bool) {
          await prefs.setBool(key, value);
        }
      }
      await prefs.remove(base);
    }
  }
  await prefs.setBool('migrated_per_account', true);
}
