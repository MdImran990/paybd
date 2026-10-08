import 'package:flutter/material.dart';
import '../../core/i18n/tr.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/pay_app_bar.dart';
import '../../core/i18n/app_language.dart';
import '../auth/logout.dart';
import 'settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _erase(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Tr('Erase all data?'),
        content: const Tr(
          'This deletes your account, PIN, demo balance and transactions from this device, then logs you out.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Tr('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Tr('Erase',
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
      appBar: PayAppBar(title: const Tr('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const _LanguageTile(),
            const SizedBox(height: 12),
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
                title: const Tr('Ask PIN to see balance',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Tr(
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
                title: const Tr('Erase all data',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.error)),
                subtitle: const Tr(
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
