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
  bool hasPin(String phone);
  Future<void> setPin(String phone, String pin);
  Future<PinResult> verifyPin(String phone, String pin);
  Future<void> clear(String phone);
}

/// A [PinRepository] bound to one account, so screens do not repeat the phone number.
class PinAccess {
  final PinRepository _repo;
  final String phone;
  const PinAccess(this._repo, this.phone);

  bool get hasPin => phone.isNotEmpty && _repo.hasPin(phone);
  Future<void> setPin(String pin) => _repo.setPin(phone, pin);
  Future<PinResult> verifyPin(String pin) => _repo.verifyPin(phone, pin);
  Future<void> clear() => _repo.clear(phone);
}

/// Stores only a salted hash of each account's PIN in the device's secure storage
/// (Android Keystore / iOS Keychain). The attempt counter and lock survive restarts.
///
/// IMPORTANT: a 5-digit PIN is easy to brute-force offline. The real protection is
/// verifying the PIN on the server (rate limited). This class is the local, demo version.
class SecurePinRepository implements PinRepository {
  static String _saltKey(String p) => 'pin_salt_$p';
  static String _hashKey(String p) => 'pin_hash_$p';
  static String _failedKey(String p) => 'pin_failed_$p';
  static String _lockedKey(String p) => 'pin_locked_until_$p';
  static const maxAttempts = 5;
  static const lockDuration = Duration(minutes: 5);

  final FlutterSecureStorage _secure;
  final SharedPreferences _prefs;
  final Map<String, ({String salt, String hash})> _creds = {};

  SecurePinRepository._(this._secure, this._prefs);

  /// Loads the saved PIN hashes of every account on this device. Call once in main().
  static Future<SecurePinRepository> create(SharedPreferences prefs) async {
    final repo = SecurePinRepository._(const FlutterSecureStorage(), prefs);
    try {
      // Older builds kept a single PIN. Move it under its account so it is not lost.
      final legacyPhone =
          prefs.getString('account_phone') ?? prefs.getString('session_phone');
      final legacySalt = await repo._secure.read(key: 'pin_salt');
      final legacyHash = await repo._secure.read(key: 'pin_hash');
      if (legacyPhone != null && legacySalt != null && legacyHash != null) {
        await repo._secure.write(key: _saltKey(legacyPhone), value: legacySalt);
        await repo._secure.write(key: _hashKey(legacyPhone), value: legacyHash);
        await repo._secure.delete(key: 'pin_salt');
        await repo._secure.delete(key: 'pin_hash');
      }
      for (final phone in prefs.getStringList('accounts') ?? const <String>[]) {
        final salt = await repo._secure.read(key: _saltKey(phone));
        final hash = await repo._secure.read(key: _hashKey(phone));
        if (salt != null && hash != null) {
          repo._creds[phone] = (salt: salt, hash: hash);
        }
      }
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
  bool hasPin(String phone) => _creds.containsKey(phone);

  @override
  Future<void> setPin(String phone, String pin) async {
    final salt = _newSalt();
    final hash = _hashOf(salt, pin);
    await _secure.write(key: _saltKey(phone), value: salt);
    await _secure.write(key: _hashKey(phone), value: hash);
    _creds[phone] = (salt: salt, hash: hash);
    await _prefs.remove(_failedKey(phone));
    await _prefs.remove(_lockedKey(phone));
  }

  @override
  Future<PinResult> verifyPin(String phone, String pin) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final now = DateTime.now();

    final lockedMillis = _prefs.getInt(_lockedKey(phone));
    if (lockedMillis != null) {
      final until = DateTime.fromMillisecondsSinceEpoch(lockedMillis);
      if (now.isBefore(until)) {
        return PinResult(ok: false, lockedFor: until.difference(now));
      }
      await _prefs.remove(_lockedKey(phone));
      await _prefs.remove(_failedKey(phone));
    }

    final cred = _creds[phone];
    if (cred == null) return const PinResult(ok: false);

    if (_hashOf(cred.salt, pin) == cred.hash) {
      await _prefs.remove(_failedKey(phone));
      return const PinResult(ok: true);
    }

    final failed = (_prefs.getInt(_failedKey(phone)) ?? 0) + 1;
    if (failed >= maxAttempts) {
      await _prefs.setInt(
          _lockedKey(phone), now.add(lockDuration).millisecondsSinceEpoch);
      await _prefs.remove(_failedKey(phone));
      return const PinResult(ok: false, lockedFor: lockDuration);
    }
    await _prefs.setInt(_failedKey(phone), failed);
    return PinResult(ok: false, attemptsLeft: maxAttempts - failed);
  }

  @override
  Future<void> clear(String phone) async {
    try {
      await _secure.delete(key: _saltKey(phone));
      await _secure.delete(key: _hashKey(phone));
    } catch (_) {}
    _creds.remove(phone);
    await _prefs.remove(_failedKey(phone));
    await _prefs.remove(_lockedKey(phone));
  }
}
