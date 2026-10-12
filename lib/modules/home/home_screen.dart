import 'package:flutter/material.dart';
import '../../core/i18n/tr.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_shadows.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/floating_bubbles.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/user_avatar.dart';
import '../../core/utils/pin_verify.dart';
import '../../core/widgets/pin_entry.dart';
import '../../core/widgets/tx_tile.dart';
import '../auth/auth_providers.dart';
import '../notifications/notification_providers.dart';
import '../profile/profile_providers.dart';
import '../settings/settings_providers.dart';
import 'menu_drawer.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _controller = ScrollController();
  int _drawerOpens = 0; // new key each time, so the menu items animate in again

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light, // light icons on the pink header
      child: Scaffold(
        endDrawer: KeyedSubtree(
          key: ValueKey(_drawerOpens),
          child: const MenuDrawer(),
        ),
        endDrawerEnableOpenDragGesture: false,
        onEndDrawerChanged: (open) {
          if (open) setState(() => _drawerOpens++);
        },
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
          controller: _controller,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            // Parallax: the header scrolls slower than the cards, which slide over it.
            AnimatedBuilder(
              animation: _controller,
              builder: (_, child) {
                final offset = _controller.hasClients ? _controller.offset : 0.0;
                return Transform.translate(
                  offset: Offset(0, offset < 0 ? 0 : offset * 0.3),
                  child: child,
                );
              },
              child: const _Header(),
            ),
            const SizedBox(height: 16),
            const _ServiceGrid(),
            const SizedBox(height: 16),
            const _PromoBanner(),
            const SizedBox(height: 20),
            const _RecentSection(),
            const SizedBox(height: 110),
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

    // The pink area has spare room at the bottom: the white balance card
    // overlaps it, the same way the card does on the login page.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            Container(
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
              ),
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: RepaintBoundary(child: FloatingBubbles()),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, top + 14, 16, 78),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const UserAvatar(
                                radius: 22, heroTag: 'profile-avatar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Tr('Welcome back',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.white70)),
                              Tr(name ?? phone,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.white24,
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: tr('Notifications'),
                            onPressed: () => context.push('/inbox'),
                            icon: Badge(
                              isLabelVisible: unread > 0,
                              label: Tr('$unread'),
                              child: const Icon(
                                  Icons.notifications_none_rounded,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 62),
          ],
        ),
        const Positioned(left: 16, right: 16, bottom: 0, child: _BalanceCard()),
      ],
    );
  }
}

const _balanceStyle = TextStyle(
    fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.text);

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
                await verifyPinMessage(ref.read(activePinProvider), pin);
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
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
              color: Color(0x26000000), blurRadius: 22, offset: Offset(0, 10)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          size: 15, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    const Tr('PayBD Balance',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 8),
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
            PressableScale(
              scale: 0.94,
              haptic: true,
              onTap: () {
                if (show) {
                  ref.read(balanceRevealedProvider.notifier).hide();
                } else {
                  _showPinSheet(context, ref);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      show
                          ? Icons.visibility_off_outlined
                          : Icons.lock_outline_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Tr(
                      show ? 'Hide' : 'Tap for balance',
                      style: const TextStyle(
                          color: Colors.white,
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
  _Service(Icons.history_rounded, 'Statement', '/statement'),
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
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(24),
        boxShadow: softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 6),
            child: Tr('Services',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.82,
            children: [
              for (var i = 0; i < _services.length; i++)
                FadeSlideIn(
                  index: i,
                  child: _ServiceTile(service: _services[i]),
                ),
            ],
          ),
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
      haptic: true,
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
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.16),
                    AppColors.primary.withValues(alpha: 0.06),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PressableScale(
        scale: 0.98,
        onTap: () => _comingSoon(context, 'Invite friends'),
        child: Container(
          padding: const EdgeInsets.all(1.6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9A3D), AppColors.primary, Color(0xFF8E5CFF)],
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.4),
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
                  child: const Icon(Icons.card_giftcard_rounded,
                      color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tr('Invite friends',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                      SizedBox(height: 2),
                      Tr('Referral offers are coming soon',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted),
              ],
            ),
          ),
        ),
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
      elevation: 16,
      shadowColor: const Color(0x40000000),
      surfaceTintColor: Colors.transparent,
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
          _NavItem(Icons.menu_rounded, 'Menu',
              onTap: () => Scaffold.of(context).openEndDrawer()),
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
    return PressableScale(
      scale: 0.86,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                height: 3,
                width: active ? 22 : 0,
                margin: const EdgeInsets.only(bottom: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 2),
              Tr(label, style: TextStyle(fontSize: 10, color: color)),
            ],
          ),
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
