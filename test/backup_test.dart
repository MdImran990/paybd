import 'package:flutter_test/flutter_test.dart';
import 'package:paybd/core/backup/backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const phone = '01711111111';

  test('a backup can be restored into an empty phone', () async {
    SharedPreferences.setMockInitialValues({
      'u_${phone}_wallet_balance': 1234,
      'u_${phone}_profile_name': 'Imran',
      'u_${phone}_require_pin_for_balance': false,
    });
    final prefs = await SharedPreferences.getInstance();
    final code = buildBackup(prefs, phone);

    SharedPreferences.setMockInitialValues({});
    final fresh = await SharedPreferences.getInstance();
    expect(await restoreBackup(fresh, phone, code), isNull);

    expect(fresh.getInt('u_${phone}_wallet_balance'), 1234);
    expect(fresh.getString('u_${phone}_profile_name'), 'Imran');
    expect(fresh.getBool('u_${phone}_require_pin_for_balance'), false);
  });

  test('a backup never contains the PIN', () async {
    SharedPreferences.setMockInitialValues({
      'pin_hash_$phone': 'secret',
      'u_${phone}_profile_name': 'Imran',
    });
    final prefs = await SharedPreferences.getInstance();
    expect(buildBackup(prefs, phone).contains('secret'), isFalse);
  });

  test('a backup of another number is refused', () async {
    SharedPreferences.setMockInitialValues({'u_${phone}_profile_name': 'A'});
    final prefs = await SharedPreferences.getInstance();
    final code = buildBackup(prefs, phone);
    expect(
      await restoreBackup(prefs, '01822222222', code),
      'This backup belongs to another number.',
    );
  });

  test('random text is refused', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect(await restoreBackup(prefs, phone, 'hello'),
        'This is not a PayBD backup.');
    expect(await restoreBackup(prefs, phone, '{"app":"other"}'),
        'This is not a PayBD backup.');
  });
}
