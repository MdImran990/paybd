import 'package:flutter/material.dart';
import '../../core/i18n/tr.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_shadows.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/utils/pin_verify.dart';
import '../../core/widgets/pin_entry.dart';
import '../../core/widgets/tx_tile.dart';
import '../auth/auth_providers.dart';
import '../notifications/notification_providers.dart';
import '../profile/profile_providers.dart';
import '../settings/settings_providers.dart';
import '../wallet/wallet_providers.dart';

void _comingSoon(BuildContext context, String title) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction_rounded,
              size: 40, color: AppColors.primary),
          const SizedBox(height: 12),
          Tr(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Tr(
            'This service is coming in a future update.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted),
          ),
        ],
      ),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // light icons on the pink header
      child: Scaffold(
        body: Consumer(
          builder: (context, ref, _) => RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: Colors.white,
            displacement: 70,
            onRefresh: () async {
              ref.invalidate(walletProvider);
              await ref.read(walletProvider.future);
            },
            child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: const [
            _Header(),
            SizedBox(height: 16),
            _ServiceGrid(),
            SizedBox(height: 16),
            _PromoBanner(),
            SizedBox(height: 20),
            _RecentSection(),
            SizedBox(height: 110),
          ],
        ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: const _PulsingQrButton(),
        bottomNavigationBar: const _BottomNav(),
      ),
    );
  }
}

// ---------------- Header + balance ----------------

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phone = ref.watch(sessionPhoneProvider) ?? '';
    final name = ref.watch(profileNameProvider);
    final unread = ref.watch(unreadCountProvider);
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, top + 14, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: const CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person_rounded, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Tr('Welcome back',
                        style: TextStyle(fontSize: 12, color: Colors.white70)),
                    Tr(name ?? phone,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              ),
              IconButton(
                tooltip: tr('Notifications'),
                onPressed: () => context.push('/inbox'),
                icon: Badge(
                  isLabelVisible: unread > 0,
                  label: Tr('$unread'),
                  child: const Icon(Icons.notifications_none_rounded,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _BalanceCard(),
        ],
      ),
    );
  }
}

const _balanceStyle = TextStyle(
    fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white);

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard();

  void _showPinSheet(BuildContext context, WidgetRef ref) {
    final h = MediaQuery.of(context).size.height;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SizedBox(
        height: h * 0.9 > 600 ? 600 : h * 0.9,
        child: PinEntry(
          title: 'Enter your PIN',
          subtitle: 'to see your balance',
          onCompleted: (pin) async {
            final error =
                await verifyPinMessage(ref.read(pinRepositoryProvider), pin);
            if (error != null) return error;
            ref.read(balanceRevealedProvider.notifier).show();
            if (ctx.mounted) Navigator.of(ctx).pop();
            return null;
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requirePin = ref.watch(requirePinProvider);
    final revealed = ref.watch(balanceRevealedProvider);
    final show = revealed || !requirePin;
    final balance = ref.watch(walletProvider).value?.balanceMinor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Tr('PayBD Balance',
                    style: TextStyle(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: show && balance != null
                      ? TweenAnimationBuilder<int>(
                          key: const ValueKey('shown'),
                          tween: IntTween(begin: 0, end: balance),
                          duration: const Duration(milliseconds: 800),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, _) =>
                              Tr(formatTaka(v), style: _balanceStyle),
                        )
                      : Tr(
                          show ? '...' : '৳ ••••••',
                          key: ValueKey(show),
                          style: _balanceStyle,
                        ),
                ),
              ],
            ),
          ),
          if (requirePin)
            GestureDetector(
              onTap: () {
                if (show) {
                  ref.read(balanceRevealedProvider.notifier).hide();
                } else {
                  _showPinSheet(context, ref);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      show
                          ? Icons.visibility_off_outlined
                          : Icons.lock_outline_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Tr(
                      show ? 'Hide' : 'Tap for balance',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------- Services ----------------

class _Service {
  final IconData icon;
  final String label;
  final String? route; // null = coming soon
  const _Service(this.icon, this.label, this.route);
}

const _services = <_Service>[
  _Service(Icons.send_rounded, 'Send Money', '/send'),
  _Service(Icons.smartphone_rounded, 'Mobile Recharge', '/recharge'),
  _Service(Icons.payments_outlined, 'Cash Out', '/cash-out'),
  _Service(Icons.qr_code_scanner_rounded, 'Payment', '/qr?tab=scan'),
  _Service(Icons.add_card_rounded, 'Add Money', '/add-money'),
  _Service(Icons.receipt_long_rounded, 'Pay Bill', '/pay-bill'),
  _Service(Icons.request_quote_rounded, 'Request Money', '/qr'),
  _Service(Icons.savings_rounded, 'Savings', '/savings'),
  _Service(Icons.volunteer_activism_rounded, 'Donation', '/donation'),
  _Service(Icons.school_rounded, 'Education Fee', '/education'),
  _Service(Icons.history_rounded, 'Statement', '/history'),
  _Service(Icons.help_outline_rounded, 'Help', '/help'),
  _Service(Icons.public_rounded, 'Remittance', null),
  _Service(Icons.account_balance_rounded, 'Loan', null),
  _Service(Icons.health_and_safety_rounded, 'Insurance', null),
  _Service(Icons.person_outline_rounded, 'My Profile', '/profile'),
];

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(24),
        boxShadow: softShadow,
      ),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 0.82,
        children: [
          for (var i = 0; i < _services.length; i++)
            FadeSlideIn(index: i, child: _ServiceTile(service: _services[i])),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final _Service service;
  const _ServiceTile({required this.service});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scale: 0.92,
      onTap: () {
        final route = service.route;
        if (route != null) {
          context.push(route);
        } else {
          _comingSoon(context, service.label);
        }
      },
      child: Opacity(
        opacity: service.route == null ? 0.55 : 1,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.09),
              ),
              child: Icon(service.icon, color: AppColors.primary, size: 26),
            ),
            const SizedBox(height: 6),
            Tr(
              service.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.card_giftcard_rounded,
              size: 36, color: AppColors.primary),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tr('Invite friends',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                SizedBox(height: 2),
                Tr('Referral offers are coming soon',
                    style:
                        TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Recent transactions ----------------

class _RecentSection extends ConsumerWidget {
  const _RecentSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallet = ref.watch(walletProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Tr('Recent transactions',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/history'),
                child: const Tr('See all'),
              ),
            ],
          ),
          wallet.when(
            loading: () => const Column(
              children: [
                TxSkeleton(),
                SizedBox(height: 10),
                TxSkeleton(),
                SizedBox(height: 10),
                TxSkeleton(),
              ],
            ),
            error: (_, _) => const Tr('Could not load transactions.',
                style: TextStyle(color: AppColors.textMuted)),
            data: (w) {
              if (w.transactions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Tr('No transactions yet',
                      style: TextStyle(color: AppColors.textMuted)),
                );
              }
              final recent = w.transactions.take(3).toList();
              return Column(
                children: [
                  for (var i = 0; i < recent.length; i++)
                    FadeSlideIn(
                      index: i + 2,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: TxTile(tx: recent[i]),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ---------------- Bottom nav ----------------

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.panel,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      height: 68,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const _NavItem(Icons.home_rounded, 'Home', active: true),
          _NavItem(Icons.receipt_long_outlined, 'History',
              onTap: () => context.push('/history')),
          const SizedBox(width: 56), // space for the QR button
          _NavItem(Icons.mail_outline_rounded, 'Inbox',
              onTap: () => context.push('/inbox')),
          _NavItem(Icons.person_outline_rounded, 'Menu',
              onTap: () => context.push('/profile')),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  const _NavItem(this.icon, this.label, {this.active = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Tr(label, style: TextStyle(fontSize: 10, color: color)),
          ],
        ),
      ),
    );
  }
}

/// QR button with a soft pulsing ring that invites a tap.
class _PulsingQrButton extends StatefulWidget {
  const _PulsingQrButton();

  @override
  State<_PulsingQrButton> createState() => _PulsingQrButtonState();
}

class _PulsingQrButtonState extends State<_PulsingQrButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) {
                final t = _c.value;
                return Container(
                  width: 64 + 28 * t,
                  height: 64 + 28 * t,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.28 * (1 - t)),
                  ),
                );
              },
            ),
          ),
          FloatingActionButton(
            onPressed: () => context.push('/qr?tab=scan'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            child: const Icon(Icons.qr_code_scanner_rounded, size: 30),
          ),
        ],
      ),
    );
  }
}
