import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../auth/auth_providers.dart';
import '../wallet/wallet_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Text('Log out?'),
        content: const Text('You will need to verify your number again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log out',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;

    // Demo: every login starts a fresh demo account.
    await ref.read(pinRepositoryProvider).clear();
    ref.invalidate(walletProvider);
    ref.invalidate(walletRepositoryProvider);
    // The router guard sends the user to /login once the session is cleared.
    ref.read(sessionPhoneProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = ref.watch(sessionPhoneProvider) ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
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
                    child: Icon(Icons.person_rounded, size: 34, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PayBD Account',
                            style: TextStyle(fontSize: 12, color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(phone,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ],
                    ),
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
              icon: Icons.info_outline_rounded,
              label: 'About PayBD',
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'PayBD',
                applicationVersion: '0.1.0 (demo)',
                children: const [
                  Text('Demo build. Balances and transactions are not real money.'),
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
                  child: Text(label,
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
