import 'package:flutter/material.dart';
import '../../core/i18n/tr.dart';
import '../../core/widgets/pay_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../auth/auth_providers.dart';
import '../auth/logout.dart';
import 'profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _editName(BuildContext context, WidgetRef ref) async {
    final controller =
        TextEditingController(text: ref.read(profileNameProvider) ?? '');
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Tr('Your name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 30,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: tr('Enter your name')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Tr('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Tr('Save'),
          ),
        ],
      ),
    );
    if (name != null) await ref.read(profileNameProvider.notifier).set(name);
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Tr('Log out?'),
        content: const Tr(
            'You will log in again with your number and PIN.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Tr('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Tr('Log out',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await performLogout(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = ref.watch(sessionPhoneProvider) ?? '';
    final name = ref.watch(profileNameProvider);
    return Scaffold(
      appBar: PayAppBar(title: const Tr('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child:
                        Icon(Icons.person_rounded, size: 34, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Tr(name ?? 'PayBD Account',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Tr(phone,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.white70)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: tr('Edit name'),
                    onPressed: () => _editName(context, ref),
                    icon: const Icon(Icons.edit_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _MenuTile(
              icon: Icons.lock_outline_rounded,
              label: 'Change PIN',
              onTap: () => context.push('/change-pin'),
            ),
            _MenuTile(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () => context.push('/settings'),
            ),
            _MenuTile(
              icon: Icons.help_outline_rounded,
              label: 'Help & Support',
              onTap: () => context.push('/help'),
            ),
            _MenuTile(
              icon: Icons.description_outlined,
              label: 'Terms & Privacy',
              onTap: () => context.push('/terms'),
            ),
            _MenuTile(
              icon: Icons.info_outline_rounded,
              label: 'About PayBD',
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'PayBD',
                applicationVersion: '0.2.0 (demo)',
                children: const [
                  Tr('Demo build. Balances and transactions are not real money.'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _MenuTile(
              icon: Icons.logout_rounded,
              label: 'Log out',
              color: AppColors.error,
              onTap: () => _logout(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.panel,
        elevation: 1.5,
        shadowColor: const Color(0x22000000),
        surfaceTintColor: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(icon, color: color ?? AppColors.primary),
                const SizedBox(width: 14),
                Expanded(
                  child: Tr(label,
                      style: TextStyle(fontWeight: FontWeight.w600, color: c)),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted.withValues(alpha: 0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
