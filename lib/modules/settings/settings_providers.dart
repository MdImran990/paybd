import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/prefs.dart';

/// Ask for the PIN before showing the balance on Home. Saved on the device.
class RequirePinNotifier extends Notifier<bool> {
  static const _key = 'require_pin_for_balance';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(_key) ?? true;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
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
