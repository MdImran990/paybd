import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/prefs.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/pin_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => MockAuthRepository(),
);

/// Overridden in main() with the loaded SecurePinRepository.
final pinRepositoryProvider = Provider<PinRepository>(
  (ref) => throw UnimplementedError(
    'pinRepositoryProvider must be overridden in main()',
  ),
);

/// Phone number of the logged-in user (null when logged out). Saved on the device.
class SessionNotifier extends Notifier<String?> {
  static const _key = 'session_phone';

  @override
  String? build() => ref.read(sharedPreferencesProvider).getString(_key);

  // State is set first (synchronously) so the router guard sees the login at once.
  Future<void> setPhone(String phone) async {
    state = phone;
    await ref.read(sharedPreferencesProvider).setString(_key, phone);
  }

  Future<void> logout() async {
    state = null;
    await ref.read(sharedPreferencesProvider).remove(_key);
  }
}

final sessionPhoneProvider =
    NotifierProvider<SessionNotifier, String?>(SessionNotifier.new);

/// The PIN of the logged-in account.
final activePinProvider = Provider<PinAccess>(
  (ref) => PinAccess(
    ref.watch(pinRepositoryProvider),
    ref.watch(sessionPhoneProvider) ?? '',
  ),
);
