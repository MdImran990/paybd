import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/account_keys.dart';
import '../../core/storage/prefs.dart';
import '../auth/auth_providers.dart';

class Nominee {
  final String name;
  final String relation;
  final String phone; // optional, may be empty

  const Nominee({required this.name, required this.relation, required this.phone});

  Map<String, dynamic> toJson() =>
      {'name': name, 'relation': relation, 'phone': phone};

  factory Nominee.fromJson(Map<String, dynamic> j) => Nominee(
        name: j['name'] as String,
        relation: j['relation'] as String,
        phone: (j['phone'] as String?) ?? '',
      );
}

/// The nominee of the logged-in account. Saved on this device, per account.
class NomineeNotifier extends Notifier<Nominee?> {
  static const _key = 'nominee';

  @override
  Nominee? build() {
    final phone = ref.watch(sessionPhoneProvider);
    final raw =
        ref.read(sharedPreferencesProvider).getString(acctKey(phone, _key));
    if (raw == null) return null;
    try {
      return Nominee.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  String get _k => acctKey(ref.read(sessionPhoneProvider), _key);

  Future<void> save(Nominee n) async {
    state = n;
    await ref.read(sharedPreferencesProvider).setString(_k, jsonEncode(n.toJson()));
  }

  Future<void> remove() async {
    state = null;
    await ref.read(sharedPreferencesProvider).remove(_k);
  }
}

final nomineeProvider =
    NotifierProvider<NomineeNotifier, Nominee?>(NomineeNotifier.new);
