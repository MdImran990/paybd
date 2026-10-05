import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ask for the PIN before showing the balance on Home.
class RequirePinNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) => state = value;
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
