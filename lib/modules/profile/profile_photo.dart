import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/storage/account_keys.dart';
import '../../core/storage/prefs.dart';
import '../auth/auth_providers.dart';

/// Path of the profile photo of the logged-in account (null = none).
/// The picture is copied into the app's private storage, so it stays even if the
/// original is deleted from the gallery.
class ProfilePhotoNotifier extends Notifier<String?> {
  static const _key = 'photo_path';

  @override
  String? build() {
    final phone = ref.watch(sessionPhoneProvider);
    final path =
        ref.read(sharedPreferencesProvider).getString(acctKey(phone, _key));
    if (path == null) return null;
    return File(path).existsSync() ? path : null;
  }

  String get _k => acctKey(ref.read(sessionPhoneProvider), _key);

  /// Returns true when a new photo was saved.
  Future<bool> pick(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return false;

      final dir = await getApplicationDocumentsDirectory();
      final phone = ref.read(sessionPhoneProvider) ?? 'guest';
      final dest = File(
        '${dir.path}/profile_${phone}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await File(picked.path).copy(dest.path);

      final old = state;
      state = dest.path;
      await ref.read(sharedPreferencesProvider).setString(_k, dest.path);
      if (old != null) {
        try {
          await File(old).delete();
        } catch (_) {}
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> remove() async {
    final old = state;
    state = null;
    await ref.read(sharedPreferencesProvider).remove(_k);
    if (old != null) {
      try {
        await File(old).delete();
      } catch (_) {}
    }
  }
}

final profilePhotoProvider =
    NotifierProvider<ProfilePhotoNotifier, String?>(ProfilePhotoNotifier.new);
