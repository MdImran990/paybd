import 'package:flutter/material.dart';
import '../../core/widgets/fade_slide_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/i18n/app_language.dart';
import '../../core/i18n/tr.dart';
import '../../core/security/biometric_service.dart';
import '../../core/widgets/pay_app_bar.dart';
import '../auth/logout.dart';
import 'settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: AppColors.panel,
          title: const Tr('Delete this account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Tr(
                'All transactions, savings, messages and your PIN for this number will be deleted from this device. This cannot be undone.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                onChanged: (_) => setState(() {}),
                decoration:
                    InputDecoration(hintText: tr('Type DELETE to confirm')),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Tr('Cancel'),
            ),
            TextButton(
              onPressed: controller.text.trim() == 'DELETE'
                  ? () => Navigator.of(ctx).pop(true)
                  : null,
              child: const Tr('Delete',
                  style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
    if (ok == true) await deleteCurrentAccount(ref);
  }

  Future<void> _toggleBiometric(
      BuildContext context, WidgetRef ref, bool turnOn) async {
    final notifier = ref.read(biometricEnabledProvider.notifier);
    if (!turnOn) {
      notifier.set(false);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    if (!await BiometricService.isAvailable()) {
      messenger.showSnackBar(
        const SnackBar(content: Tr('Fingerprint is not set up on this phone.')),
      );
      return;
    }
    // Make sure it really works before relying on it.
    final ok =
        await BiometricService.authenticate(tr('Turn on fingerprint unlock'));
    if (ok) notifier.set(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requirePin = ref.watch(requirePinProvider);
    final biometric = ref.watch(biometricEnabledProvider);
    final blockShots = ref.watch(blockScreenshotsProvider);
    return Scaffold(
      appBar: const PayAppBar(title: Tr('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: staggered([
            const _LanguageTile(),
            const SizedBox(height: 12),
            _SwitchCard(
              title: 'Ask PIN to see balance',
              subtitle:
                  'Your balance stays hidden on Home until you enter your PIN.',
              value: requirePin,
              onChanged: (v) {
                ref.read(requirePinProvider.notifier).set(v);
                if (v) ref.read(balanceRevealedProvider.notifier).hide();
              },
            ),
            const SizedBox(height: 12),
            _SwitchCard(
              title: 'Unlock with fingerprint',
              subtitle:
                  'Use your fingerprint or face instead of the PIN to open PayBD. Payments still need your PIN.',
              value: biometric,
              onChanged: (v) => _toggleBiometric(context, ref, v),
            ),
            const SizedBox(height: 12),
            _SwitchCard(
              title: 'Block screenshots',
              subtitle:
                  'Hide PayBD in screenshots, screen recording and the recent apps list (Android).',
              value: blockShots,
              onChanged: (v) => ref.read(blockScreenshotsProvider.notifier).set(v),
            ),
            const SizedBox(height: 12),
            Material(
              color: AppColors.panel,
              borderRadius: BorderRadius.circular(18),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                title: const Tr('Delete this account',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.error)),
                subtitle: const Tr(
                  'Delete this account and all its data from this device.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                onTap: () => _deleteAccount(context, ref),
              ),
            ),
            const SizedBox(height: 16),
            const Tr(
              'Your data stays on this device when you log out or switch accounts.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SwitchCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        title: Tr(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Tr(
          subtitle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ),
    );
  }
}

class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.language_rounded, color: AppColors.primary),
          const SizedBox(width: 12),
          const Expanded(
            child: Tr('Language', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          for (final (code, label) in const [('en', 'English'), ('bn', 'বাংলা')])
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: lang == code,
                showCheckmark: false,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.bg,
                side: BorderSide.none,
                labelStyle: TextStyle(
                  color: lang == code ? Colors.white : AppColors.text,
                  fontSize: 12,
                ),
                onSelected: (_) =>
                    ref.read(languageProvider.notifier).set(code),
              ),
            ),
        ],
      ),
    );
  }
}
