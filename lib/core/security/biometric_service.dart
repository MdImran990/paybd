import 'package:local_auth/local_auth.dart';

/// Fingerprint / face unlock. Only used to open the app; payments still need the PIN.
class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// True when this phone has a fingerprint or face enrolled.
  static Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Shows the system fingerprint prompt. Returns false if cancelled or failed.
  static Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }
}
