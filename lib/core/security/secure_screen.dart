import 'package:flutter/services.dart';

/// Blocks screenshots, screen recording and the recent-apps preview (Android FLAG_SECURE).
/// iOS cannot block screenshots, so there this does nothing.
class SecureScreen {
  static const _channel = MethodChannel('paybd/secure');

  static Future<void> setEnabled(bool enabled) async {
    try {
      await _channel.invokeMethod<void>(enabled ? 'enable' : 'disable');
    } on MissingPluginException {
      // iOS or a test run: nothing to do.
    } on PlatformException {
      // Ignore: screen protection is best-effort.
    }
  }
}
