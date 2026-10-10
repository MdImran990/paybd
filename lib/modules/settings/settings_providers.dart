import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/security/secure_screen.dart';
import '../../core/storage/account_keys.dart';
import '../../core/storage/prefs.dart';
import '../auth/auth_providers.dart';

/// Ask for the PIN before showing the balance on Home. Saved on the device.
class RequirePinNotifier extends Notifier<bool> {
  static const _key = 'require_pin_for_balance';

  @override
  bool build() {
    final phone = ref.watch(sessionPhoneProvider);
    return ref.read(sharedPreferencesProvider).getBool(acctKey(phone, _key)) ??
        true;
  }

  void set(bool value) {
    state = value;
    ref
        .read(sharedPreferencesProvider)
        .setBool(acctKey(ref.read(sessionPhoneProvider), _key), value);
  }
}

final requirePinProvider =
    NotifierProvider<RequirePinNotifier, bool>(RequirePinNotifier.new);

/// True while the balance is visible. It hides itself after 10 seconds.
class BalanceRevealNotifier extends Notifier<bool> {
  Timer? _timer;

  @override
  bool build() {
    ref.onDispose(() => _timer?.cancel());
    return false;
  }

  void show() {
    state = true;
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 10), hide);
  }

  void hide() {
    _timer?.cancel();
    state = false;
  }
}

final balanceRevealedProvider =
    NotifierProvider<BalanceRevealNotifier, bool>(BalanceRevealNotifier.new);

/// Unlock the app with a fingerprint / face instead of typing the PIN.
class BiometricEnabledNotifier extends Notifier<bool> {
  static const _key = 'biometric_unlock';

  @override
  bool build() {
    final phone = ref.watch(sessionPhoneProvider);
    return ref.read(sharedPreferencesProvider).getBool(acctKey(phone, _key)) ??
        false;
  }

  void set(bool value) {
    state = value;
    ref
        .read(sharedPreferencesProvider)
        .setBool(acctKey(ref.read(sessionPhoneProvider), _key), value);
  }
}

final biometricEnabledProvider =
    NotifierProvider<BiometricEnabledNotifier, bool>(BiometricEnabledNotifier.new);

/// Block screenshots and screen recording (on by default).
class BlockScreenshotsNotifier extends Notifier<bool> {
  static const key = 'block_screenshots';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(key) ?? true;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(key, value);
    SecureScreen.setEnabled(value);
  }
}

final blockScreenshotsProvider =
    NotifierProvider<BlockScreenshotsNotifier, bool>(BlockScreenshotsNotifier.new);
