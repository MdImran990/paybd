import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/prefs.dart';

/// Every number that has an account on this device (demo "server" record).
/// A real backend will answer "does this number have an account?" instead.
class AccountsNotifier extends Notifier<List<String>> {
  static const _key = 'accounts';

  @override
  List<String> build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final saved = prefs.getStringList(_key);
    if (saved != null) return saved;
    // Older builds only saved one account.
    final legacy =
        prefs.getString('account_phone') ?? prefs.getString('session_phone');
    return legacy == null ? const [] : [legacy];
  }

  Future<void> add(String phone) async {
    if (state.contains(phone)) return;
    state = [...state, phone];
    await ref.read(sharedPreferencesProvider).setStringList(_key, state);
  }

  Future<void> remove(String phone) async {
    state = state.where((p) => p != phone).toList();
    await ref.read(sharedPreferencesProvider).setStringList(_key, state);
  }
}

final accountsProvider =
    NotifierProvider<AccountsNotifier, List<String>>(AccountsNotifier.new);

/// The number used last (pre-filled on the login page).
class AccountNotifier extends Notifier<String?> {
  static const _key = 'last_phone';

  @override
  String? build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getString(_key) ??
        prefs.getString('account_phone') ??
        prefs.getString('session_phone');
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
