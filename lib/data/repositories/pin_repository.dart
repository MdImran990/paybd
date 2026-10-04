class PinResult {
  final bool ok;
  final int attemptsLeft;
  final Duration? lockedFor;
  const PinResult({required this.ok, this.attemptsLeft = 0, this.lockedFor});
  bool get locked => lockedFor != null;
}

abstract class PinRepository {
  bool get hasPin;
  Future<void> setPin(String pin);
  Future<PinResult> verifyPin(String pin);
  Future<void> clear();
}

/// DEMO ONLY. The PIN is kept in memory (lost when the app closes).
/// Production: verify the PIN on the server and never store it in plain text on the device.
class MockPinRepository implements PinRepository {
  static const maxAttempts = 5;
  static const lockDuration = Duration(minutes: 5);

  String? _pin;
  int _failed = 0;
  DateTime? _lockedUntil;

  @override
  bool get hasPin => _pin != null;

  @override
  Future<void> setPin(String pin) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _pin = pin;
    _failed = 0;
    _lockedUntil = null;
  }

  @override
  Future<void> clear() async {
    _pin = null;
    _failed = 0;
    _lockedUntil = null;
  }

  @override
  Future<PinResult> verifyPin(String pin) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    if (_lockedUntil != null) {
      if (now.isBefore(_lockedUntil!)) {
        return PinResult(ok: false, lockedFor: _lockedUntil!.difference(now));
      }
      _lockedUntil = null;
      _failed = 0;
    }
    if (pin == _pin) {
      _failed = 0;
      return const PinResult(ok: true);
    }
    _failed++;
    if (_failed >= maxAttempts) {
      _lockedUntil = now.add(lockDuration);
      return const PinResult(ok: false, lockedFor: lockDuration);
    }
    return PinResult(ok: false, attemptsLeft: maxAttempts - _failed);
  }
}
