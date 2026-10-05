import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import 'settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requirePin = ref.watch(requirePinProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.panel,
                borderRadius: BorderRadius.circular(18),
              ),
              child: SwitchListTile(
                value: requirePin,
                onChanged: (v) {
                  ref.read(requirePinProvider.notifier).set(v);
                  if (v) ref.read(balanceRevealedProvider.notifier).hide();
                },
                activeThumbColor: AppColors.primary,
                title: const Text('Ask PIN to see balance',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text(
                  'Your balance stays hidden on Home until you enter your PIN.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Settings are not saved after you close the app yet.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
