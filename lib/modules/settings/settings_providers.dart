import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Hide the balance on the Home card (privacy in public places).
class HideBalanceNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void set(bool value) => state = value;
}

final hideBalanceProvider =
    NotifierProvider<HideBalanceNotifier, bool>(HideBalanceNotifier.new);
