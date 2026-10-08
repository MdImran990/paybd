import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/pay_app_bar.dart';
import '../auth/logout.dart';
import 'settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _erase(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Erase all data?'),
        content: const Text(
          'This deletes your account, PIN, demo balance and transactions from this device, then logs you out.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Erase',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) await performEraseAll(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requirePin = ref.watch(requirePinProvider);
    return Scaffold(
      appBar: PayAppBar(title: const Text('Settings')),
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
            const SizedBox(height: 12),
            Material(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(18),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                leading:
                    const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                title: const Text('Erase all data',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.error)),
                subtitle: const Text(
                  'Delete the account and demo data from this device.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                onTap: () => _erase(context, ref),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
