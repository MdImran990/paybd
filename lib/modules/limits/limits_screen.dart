import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_shadows.dart';
import '../../core/i18n/tr.dart';
import '../../core/utils/format.dart';
import '../../core/utils/tx_ui.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/pay_app_bar.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/wallet_repository.dart';
import '../wallet/wallet_providers.dart';

const _types = [
  TxType.sent,
  TxType.cashOut,
  TxType.cashIn,
  TxType.recharge,
  TxType.bill,
  TxType.donation,
  TxType.education,
  TxType.savings,
];

class LimitsScreen extends ConsumerWidget {
  const LimitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = ref.watch(walletProvider).value?.transactions ?? const <Transaction>[];
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    int usedOf(TxType t) => txs
        .where((x) => x.type == t && !x.createdAt.isBefore(monthStart))
        .fold<int>(0, (sum, x) => sum + x.amountMinor);

    return Scaffold(
      appBar: const PayAppBar(title: Tr('Limits')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            for (var i = 0; i < _types.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FadeSlideIn(
                  index: i,
                  child: _LimitCard(type: _types[i], used: usedOf(_types[i])),
                ),
              ),
            const SizedBox(height: 4),
            const Tr(
              'Limits shown here are for the demo. Real limits are set by the server and regulations.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _LimitCard extends StatelessWidget {
  final TxType type;
  final int used;
  const _LimitCard({required this.type, required this.used});

  @override
  Widget build(BuildContext context) {
    final per = WalletLimits.of(type);
    final monthly = WalletLimits.monthlyMax(type);
    final progress = monthly <= 0 ? 0.0 : (used / monthly > 1 ? 1.0 : used / monthly);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
        boxShadow: softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Icon(txIcon(type), size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Tr(type.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              Tr('${(progress * 100).round()}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                color: AppColors.primary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Tr('Used this month',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              Tr('${formatTaka(used)} / ${formatTaka(monthly)}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Tr('Per transaction',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              Tr('${formatTaka(per.min)} - ${formatTaka(per.max)}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}
