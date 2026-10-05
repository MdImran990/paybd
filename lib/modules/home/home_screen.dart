import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../settings/settings_providers.dart';
import '../wallet/wallet_providers.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
          children: const [
            _Header(),
            SizedBox(height: 20),
            _BalanceCard(),
            SizedBox(height: 24),
            _QuickActions(),
            SizedBox(height: 20),
            _OfferBanner(),
            SizedBox(height: 24),
            _ServicesPanel(),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: SizedBox(
        width: 64,
        height: 64,
        child: FloatingActionButton(
          onPressed: () => context.push('/qr?tab=scan'),
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          child: const Icon(Icons.qr_code_scanner_rounded, size: 30),
        ),
      ),
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('PayBD',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
        const Spacer(),
        IconButton(
          tooltip: 'Profile',
          onPressed: () => context.push('/profile'),
          icon: const Icon(Icons.account_circle_outlined),
        ),
        IconButton(
          tooltip: 'Notifications',
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coming soon')),
          ),
          icon: const Icon(Icons.notifications_none_rounded),
        ),
      ],
    );
  }
}

class _BalanceCard extends ConsumerWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(balanceProvider).value ?? 0.0;
    final hidden = ref.watch(hideBalanceProvider);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Icon(Icons.account_balance_wallet_outlined, size: 16),
                  const SizedBox(width: 6),
                  const Text('PayBD Balance', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        ref.read(hideBalanceProvider.notifier).toggle(),
                    child: Icon(
                      hidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 16,
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                // Animated count-up, only this widget rebuilds
                hidden
                    ? const Text(
                        '৳ ••••••',
                        style: TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w800),
                      )
                    : TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: balance),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, _) => Text(
                    '৳ ${v.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => context.push('/add-money'),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add_circle_outline, size: 16),
                      SizedBox(width: 6),
                      Text('Add Money', style: TextStyle(fontSize: 12)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          const CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.green,
            child: Icon(Icons.check_rounded, size: 40, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionItem(Icons.north_rounded, 'Send', AppColors.yellow, '/send'),
        _ActionItem(Icons.south_rounded, 'Receive', AppColors.pink, '/qr'),
        _ActionItem(Icons.history_rounded, 'History', AppColors.green, '/history'),
        _ActionItem(Icons.help_outline_rounded, 'A/c Balance', AppColors.blue),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? route;
  const _ActionItem(this.icon, this.label, this.color, [this.route]);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              if (route != null) {
                context.push(route!);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon')),
                );
              }
            },
            child: SizedBox(
              width: 58,
              height: 58,
              child: Icon(icon, color: color, size: 26),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}

class _OfferBanner extends StatelessWidget {
  const _OfferBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Icon(Icons.campaign_rounded, size: 54, color: AppColors.yellow),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cashback 100%',
                    style: TextStyle(
                        color: AppColors.green,
                        fontWeight: FontWeight.w800,
                        fontSize: 16)),
                SizedBox(height: 4),
                Text('Invite your friends and get Cashback',
                    style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicesPanel extends StatelessWidget {
  const _ServicesPanel();

  static const _items = <(IconData, String, String?)>[
    (Icons.smartphone_rounded, 'Recharge', '/recharge'),
    (Icons.flight_takeoff_rounded, 'Travelling', null),
    (Icons.apartment_rounded, 'Hotel', null),
    (Icons.wifi_rounded, 'WiFi', null),
    (Icons.lightbulb_outline_rounded, 'Electricity', null),
    (Icons.movie_outlined, 'Movie', null),
    (Icons.storefront_rounded, 'Store', null),
    (Icons.payments_outlined, 'Cash Out', '/cash-out'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          const Text('PayBD Services',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 18,
            children: [
              for (final it in _items)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    final route = it.$3;
                    if (route != null) {
                      context.push(route);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coming soon')),
                      );
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(it.$1, color: AppColors.green, size: 28),
                      const SizedBox(height: 8),
                      Text(it.$2,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.panel,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            tooltip: 'Home',
            onPressed: () {},
            icon: const Icon(Icons.home_rounded, color: AppColors.green),
          ),
          IconButton(
            tooltip: 'Wallet',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Coming soon')),
            ),
            icon: const Icon(Icons.account_balance_wallet_outlined,
                color: AppColors.textMuted),
          ),
          const SizedBox(width: 48), // space for the QR button
          IconButton(
            tooltip: 'Activity',
            onPressed: () => context.push('/history'),
            icon: const Icon(Icons.swap_horiz_rounded,
                color: AppColors.textMuted),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.push('/profile'),
            icon: const Icon(Icons.person_outline_rounded,
                color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
