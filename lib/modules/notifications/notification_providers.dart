import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/prefs.dart';
import '../../data/models/app_notification.dart';

/// In-app notification center (saved on the device).
/// Real push notifications (Firebase) need the backend and are added later.
class NotificationsNotifier extends Notifier<List<AppNotification>> {
  static const _key = 'notifications';
  static const _max = 50;

  @override
  List<AppNotification> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list)
          AppNotification.fromJson(e as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _save() => ref.read(sharedPreferencesProvider).setString(
        _key,
        jsonEncode([for (final n in state) n.toJson()]),
      );

  Future<void> add({required String title, required String body}) async {
    final n = AppNotification(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      body: body,
      createdAt: DateTime.now(),
    );
    state = [n, ...state].take(_max).toList();
    await _save();
  }

  Future<void> addWelcomeIfEmpty() async {
    if (state.isNotEmpty) return;
    await add(
      title: 'Welcome to PayBD',
      body: 'This is a demo build. Balances and transactions are not real money.',
    );
  }

  Future<void> markAllRead() async {
    if (state.every((n) => n.read)) return;
    state = [for (final n in state) n.copyWith(read: true)];
    await _save();
  }

  Future<void> clear() async {
    state = const [];
    await ref.read(sharedPreferencesProvider).remove(_key);
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, List<AppNotification>>(
        NotificationsNotifier.new);

final unreadCountProvider = Provider<int>(
  (ref) => ref.watch(notificationsProvider).where((n) => !n.read).length,
);
