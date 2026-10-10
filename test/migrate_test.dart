import 'package:flutter_test/flutter_test.dart';
import 'package:paybd/core/storage/account_keys.dart';
import 'package:paybd/core/storage/migrate.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('old single-account data moves under the account and nothing is lost', () async {
    SharedPreferences.setMockInitialValues({
      'session_phone': '01711111111',
      'wallet_balance': 123400,
      'wallet_txs': '[]',
      'profile_name': 'Imran',
      'require_pin_for_balance': false,
    });
    final prefs = await SharedPreferences.getInstance();

    await migrateLegacyData(prefs);

    expect(prefs.getInt(acctKey('01711111111', 'wallet_balance')), 123400);
    expect(prefs.getString(acctKey('01711111111', 'profile_name')), 'Imran');
    expect(prefs.getBool(acctKey('01711111111', 'require_pin_for_balance')), false);
    expect(prefs.getStringList('accounts'), ['01711111111']);
    expect(prefs.containsKey('wallet_balance'), isFalse);
  });

  test('runs only once', () async {
    SharedPreferences.setMockInitialValues({'session_phone': '01711111111'});
    final prefs = await SharedPreferences.getInstance();
    await migrateLegacyData(prefs);
    await prefs.setInt('wallet_balance', 5); // new global key must be left alone
    await migrateLegacyData(prefs);
    expect(prefs.getInt('wallet_balance'), 5);
  });
}
