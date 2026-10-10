import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_providers.dart';

/// True while the app is locked and the PIN is needed.
/// Locked on a cold start when the user is logged in, and after 30+ seconds in the background.
class AppLockNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(sessionPhoneProvider) != null &&
      ref.read(activePinProvider).hasPin;

  void lock() {
    if (ref.read(sessionPhoneProvider) != null &&
        ref.read(activePinProvider).hasPin) {
      state = true;
    }
  }

  void unlock() => state = false;
}

final appLockProvider =
    NotifierProvider<AppLockNotifier, bool>(AppLockNotifier.new);
