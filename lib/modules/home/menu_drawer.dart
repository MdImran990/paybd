import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/app_info.dart';
import '../../core/i18n/tr.dart';
import '../../core/widgets/coming_soon.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/pressable_scale.dart';
import '../auth/logout.dart';

/// Side menu that slides in from the right (opened from the "Menu" tab on Home).
class MenuDrawer extends ConsumerWidget {
  const MenuDrawer({super.key});

  void _go(BuildContext context, String route) {
    Scaffold.of(context).closeEndDrawer();
    context.push(route);
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.panel,
        title: const Tr('Log out?'),
        content: const Tr('You will log in again with your number and PIN.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Tr('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Tr('Log out', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (ok == true) await performLogout(ref);
  }

  void _invite(BuildContext context) {
    Scaffold.of(context).closeEndDrawer();
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
          children: [
            const Icon(Icons.card_giftcard_rounded,
                size: 44, color: AppColors.primary),
            const SizedBox(height: 12),
            const Tr('Invite your friends to PayBD.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Tr('Referral rewards will be added soon.',
                style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () async {
                await Clipboard.setData(const ClipboardData(
                  text: 'I am using PayBD, a digital wallet app. Join me! (demo build)',
                ));
                if (sheet.mounted) Navigator.of(sheet).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Tr('Invite message copied')),
                  );
                }
              },
              icon: const Icon(Icons.copy_rounded),
              label: const Tr('Copy invite message'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = math.min(MediaQuery.of(context).size.width * 0.8, 340.0);

    final items = <_Entry>[
      _Entry(Icons.home_outlined, 'Home',
          () => Scaffold.of(context).closeEndDrawer()),
      _Entry(Icons.bar_chart_rounded, 'Statement', () => _go(context, '/statement')),
      _Entry(Icons.warning_amber_rounded, 'Limits', () => _go(context, '/limits')),
      _Entry(Icons.headset_mic_outlined, 'Customer Service',
          () => _go(context, '/help')),
      _Entry(Icons.location_on_outlined, 'Agent & ATM Map', () {
        Scaffold.of(context).closeEndDrawer();
        showComingSoon(context, 'Agent & ATM Map');
      }),
      _Entry(Icons.person_outline_rounded, 'Account information',
          () => _go(context, '/profile')),
      _Entry(Icons.contact_page_outlined, 'Nominee information',
          () => _go(context, '/nominee')),
      _Entry(Icons.settings_outlined, 'Settings', () => _go(context, '/settings')),
      _Entry(Icons.explore_outlined, 'Learn about PayBD',
          () => _go(context, '/about'),
          badge: 'New!'),
      _Entry(Icons.person_add_alt_outlined, 'Refer PayBD', () => _invite(context)),
      _Entry(Icons.logout_rounded, 'Log out', () => _logout(context, ref)),
    ];

    return Drawer(
      width: width,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Tr('PayBD Menu',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
              ),
            ),
            FadeSlideIn(
              index: 0,
              offset: const Offset(0.2, 0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _HelpCard(onTap: () => _go(context, '/help')),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 4),
                children: [
                  for (var i = 0; i < items.length; i++)
                    FadeSlideIn(
                      index: i + 1,
                      offset: const Offset(0.2, 0),
                      child: _MenuItem(entry: items[i]),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
              child: Align(
                alignment: Alignment.centerRight,
                child: Tr('Version: $appVersion',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Entry {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;
  const _Entry(this.icon, this.label, this.onTap, {this.badge});
}

class _MenuItem extends StatelessWidget {
  final _Entry entry;
  const _MenuItem({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isLogout = entry.label == 'Log out';
    return PressableScale(
      scale: 0.97,
      haptic: true,
      onTap: entry.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
        child: Row(
          children: [
            Icon(entry.icon,
                size: 26, color: isLogout ? AppColors.error : AppColors.text),
            const SizedBox(width: 18),
            Expanded(
              child: Tr(entry.label,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isLogout ? AppColors.error : AppColors.text)),
            ),
            if (entry.badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Tr(entry.badge!,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
          ],
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final VoidCallback onTap;
  const _HelpCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.98,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(1.6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF9A3D), AppColors.primary, Color(0xFF8E5CFF)],
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.4),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: const Icon(Icons.support_agent_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tr('Help Center',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Tr('Quick answers about PayBD',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
