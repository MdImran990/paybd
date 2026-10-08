import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/prefs.dart';

/// The phone number that has an account on this device (demo "server" record).
/// A real backend will answer "does this number have an account?" instead.
class AccountNotifier extends Notifier<String?> {
  static const _key = 'account_phone';

  @override
  String? build() {
    final prefs = ref.read(sharedPreferencesProvider);
    // Older builds only saved the session; treat that number as the account.
    return prefs.getString(_key) ?? prefs.getString('session_phone');
  }

  Future<void> save(String phone) async {
    state = phone;
    await ref.read(sharedPreferencesProvider).setString(_key, phone);
  }

  Future<void> clear() async {
    state = null;
    await ref.read(sharedPreferencesProvider).remove(_key);
  }
}

final accountProvider =
    NotifierProvider<AccountNotifier, String?>(AccountNotifier.new);
