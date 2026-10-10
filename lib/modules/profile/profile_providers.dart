import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/account_keys.dart';
import '../../core/storage/prefs.dart';
import '../auth/auth_providers.dart';

/// Display name chosen by the user (null = not set). Saved per account.
class ProfileNameNotifier extends Notifier<String?> {
  static const _key = 'profile_name';

  @override
  String? build() {
    final phone = ref.watch(sessionPhoneProvider);
    return ref.read(sharedPreferencesProvider).getString(acctKey(phone, _key));
  }

  String get _k => acctKey(ref.read(sessionPhoneProvider), _key);

  Future<void> set(String name) async {
    final n = name.trim();
    final prefs = ref.read(sharedPreferencesProvider);
    if (n.isEmpty) {
      state = null;
      await prefs.remove(_k);
    } else {
      state = n;
      await prefs.setString(_k, n);
    }
  }

  Future<void> clear() async {
    state = null;
    await ref.read(sharedPreferencesProvider).remove(_k);
  }
}

final profileNameProvider =
    NotifierProvider<ProfileNameNotifier, String?>(ProfileNameNotifier.new);
