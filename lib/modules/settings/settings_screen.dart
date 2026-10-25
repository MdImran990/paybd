import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/widgets/pink_header.dart';
import '../../core/widgets/fade_slide_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/i18n/app_language.dart';
import '../../core/i18n/tr.dart';
import '../../core/security/biometric_service.dart';
import '../../core/backup/backup_service.dart';
import '../../core/storage/prefs.dart';
import '../auth/auth_providers.dart';
import '../auth/logout.dart';
import '../nominee/nominee_provider.dart';
import '../notifications/notification_providers.dart';
import '../profile/profile_providers.dart';
import '../savings/savings_providers.dart';
import '../wallet/wallet_providers.dart';
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

  void _backupSheet(BuildContext context, WidgetRef ref) {
    final phone = ref.read(sessionPhoneProvider);
    if (phone == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheet) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Tr('Backup & restore',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Tr(
              'Copy a backup code and keep it somewhere safe. It has your transactions and settings, but not your PIN. Anyone who has this code can read your data, so do not share it.',
              style: TextStyle(color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () async {
                final prefs = ref.read(sharedPreferencesProvider);
                await Clipboard.setData(
                    ClipboardData(text: buildBackup(prefs, phone)));
                if (sheet.mounted) Navigator.of(sheet).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Tr('Backup code copied')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Tr('Copy backup code'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: AppColors.primary),
              ),
              onPressed: () {
                Navigator.of(sheet).pop();
                _restore(context, ref, phone);
              },
              icon: const Icon(Icons.restore_rounded, color: AppColors.primary),
              label: const Tr('Restore from clipboard',
                  style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _restore(BuildContext context, WidgetRef ref, String phone) async {
    final clip = await Clipboard.getData(Clipboard.kTextPlain);
    final text = clip?.text ?? '';
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Tr('Restore this backup?'),
        content: const Tr(
            'Your current data for this number will be replaced by the copied backup.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Tr('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Tr('Restore'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final error =
        await restoreBackup(ref.read(sharedPreferencesProvider), phone, text);
    // Everything reads its data again from the saved values.
    ref.invalidate(walletRepositoryProvider);
    ref.invalidate(notificationsProvider);
    ref.invalidate(savingsProvider);
    ref.invalidate(profileNameProvider);
    ref.invalidate(nomineeProvider);
    ref.invalidate(requirePinProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Tr(error ?? 'Backup restored')),
      );
    }
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
    return PinkPage(
      header: const PinkHeader(title: 'Settings'),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                leading:
                    const Icon(Icons.backup_outlined, color: AppColors.primary),
                title: const Tr('Backup & restore',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Tr(
                  'Copy your data as a backup code, or restore it.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                onTap: () => _backupSheet(context, ref),
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
