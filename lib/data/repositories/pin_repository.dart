import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

/// Stores only a salted hash of the PIN in the device's secure storage
/// (Android Keystore / iOS Keychain). The attempt counter and lock survive restarts.
///
/// IMPORTANT: a 5-digit PIN is easy to brute-force offline. The real protection is
/// verifying the PIN on the server (rate limited). This class is the local, demo version.
class SecurePinRepository implements PinRepository {
  static const _kSalt = 'pin_salt';
  static const _kHash = 'pin_hash';
  static const _kFailed = 'pin_failed';
  static const _kLockedUntil = 'pin_locked_until';
  static const maxAttempts = 5;
  static const lockDuration = Duration(minutes: 5);

  final FlutterSecureStorage _secure;
  final SharedPreferences _prefs;
  String? _salt;
  String? _hash;

  SecurePinRepository._(this._secure, this._prefs);

  /// Loads the saved PIN hash. Call once in main() before runApp.
  static Future<SecurePinRepository> create(SharedPreferences prefs) async {
    final repo = SecurePinRepository._(const FlutterSecureStorage(), prefs);
    try {
      repo._salt = await repo._secure.read(key: _kSalt);
      repo._hash = await repo._secure.read(key: _kHash);
    } catch (_) {
      // Secure storage unavailable: behave as "no PIN set".
    }
    return repo;
  }

  String _hashOf(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  String _newSalt() {
    final r = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => r.nextInt(256)));
  }

  @override
  bool get hasPin => _hash != null && _salt != null;

  @override
  Future<void> setPin(String pin) async {
    final salt = _newSalt();
    final hash = _hashOf(salt, pin);
    await _secure.write(key: _kSalt, value: salt);
    await _secure.write(key: _kHash, value: hash);
    _salt = salt;
    _hash = hash;
    await _prefs.remove(_kFailed);
    await _prefs.remove(_kLockedUntil);
  }

  @override
  Future<PinResult> verifyPin(String pin) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();

    final lockedMillis = _prefs.getInt(_kLockedUntil);
    if (lockedMillis != null) {
      final until = DateTime.fromMillisecondsSinceEpoch(lockedMillis);
      if (now.isBefore(until)) {
        return PinResult(ok: false, lockedFor: until.difference(now));
      }
      await _prefs.remove(_kLockedUntil);
      await _prefs.remove(_kFailed);
    }

    if (!hasPin) return const PinResult(ok: false);

    if (_hashOf(_salt!, pin) == _hash) {
      await _prefs.remove(_kFailed);
      return const PinResult(ok: true);
    }

    final failed = (_prefs.getInt(_kFailed) ?? 0) + 1;
    if (failed >= maxAttempts) {
      await _prefs.setInt(
          _kLockedUntil, now.add(lockDuration).millisecondsSinceEpoch);
      await _prefs.remove(_kFailed);
      return const PinResult(ok: false, lockedFor: lockDuration);
    }
    await _prefs.setInt(_kFailed, failed);
    return PinResult(ok: false, attemptsLeft: maxAttempts - failed);
  }

  @override
  Future<void> clear() async {
    try {
      await _secure.delete(key: _kSalt);
      await _secure.delete(key: _kHash);
    } catch (_) {}
    _salt = null;
    _hash = null;
    await _prefs.remove(_kFailed);
    await _prefs.remove(_kLockedUntil);
  }
}
