import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/prefs.dart';
import '../../data/models/savings_goal.dart';

/// Savings goals (demo, saved on the device).
class SavingsNotifier extends Notifier<List<SavingsGoal>> {
  static const _key = 'savings_goals';

  @override
  List<SavingsGoal> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list) SavingsGoal.fromJson(e as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<void> _save() => ref.read(sharedPreferencesProvider).setString(
        _key,
        jsonEncode([for (final g in state) g.toJson()]),
      );

  /// Returns an error message, or null when the goal was created.
  Future<String?> create(String name, int targetMinor) async {
    final n = name.trim();
    if (n.isEmpty) return 'Enter a goal name.';
    if (targetMinor <= 0) return 'Enter a target amount.';
    if (state.any((g) => g.name.toLowerCase() == n.toLowerCase())) {
      return 'A goal with this name already exists.';
    }
    state = [
      ...state,
      SavingsGoal(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: n,
        targetMinor: targetMinor,
        savedMinor: 0,
      ),
    ];
    await _save();
    return null;
  }

  Future<void> deposit(String name, int amountMinor) async {
    state = [
      for (final g in state)
        g.name == name ? g.copyWith(savedMinor: g.savedMinor + amountMinor) : g,
    ];
    await _save();
  }

  Future<void> withdrawAll(String name) async {
    state = [
      for (final g in state) g.name == name ? g.copyWith(savedMinor: 0) : g,
    ];
    await _save();
  }

  Future<void> delete(String id) async {
    state = state.where((g) => g.id != id).toList();
    await _save();
  }

  Future<void> clear() async {
    state = const [];
    await ref.read(sharedPreferencesProvider).remove(_key);
  }
}

final savingsProvider =
    NotifierProvider<SavingsNotifier, List<SavingsGoal>>(SavingsNotifier.new);
