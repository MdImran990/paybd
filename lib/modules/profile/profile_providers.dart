import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/prefs.dart';

/// Display name chosen by the user (null = not set). Saved on the device.
class ProfileNameNotifier extends Notifier<String?> {
  static const _key = 'profile_name';

  @override
  String? build() => ref.read(sharedPreferencesProvider).getString(_key);

  Future<void> set(String name) async {
    final n = name.trim();
    final prefs = ref.read(sharedPreferencesProvider);
    if (n.isEmpty) {
      state = null;
      await prefs.remove(_key);
    } else {
      state = n;
      await prefs.setString(_key, n);
    }
  }

  Future<void> clear() async {
    state = null;
    await ref.read(sharedPreferencesProvider).remove(_key);
  }
}

final profileNameProvider =
    NotifierProvider<ProfileNameNotifier, String?>(ProfileNameNotifier.new);
