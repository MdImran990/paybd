import '../../data/repositories/pin_repository.dart';

/// Returns an error message to show, or null when the PIN is correct.
Future<String?> verifyPinMessage(PinRepository repo, String pin) async {
  final r = await repo.verifyPin(pin);
  if (r.locked) {
    final mins = (r.lockedFor!.inSeconds / 60).ceil();
    return 'Too many wrong attempts. Try again in $mins min.';
  }
  if (!r.ok) return 'Wrong PIN. ${r.attemptsLeft} attempts left.';
  return null;
}
