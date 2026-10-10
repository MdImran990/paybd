import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../app/theme/app_colors.dart';
import '../../core/i18n/tr.dart';
import '../../core/pdf/statement_pdf.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/pay_app_bar.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/tx_tile.dart';
import '../../data/models/transaction.dart';
import '../auth/auth_providers.dart';
import '../profile/profile_providers.dart';
import '../wallet/wallet_providers.dart';

enum _Period { thisMonth, last30, last90, thisYear, all }

const _labels = {
  _Period.thisMonth: 'This month',
  _Period.last30: 'Last 30 days',
  _Period.last90: 'Last 3 months',
  _Period.thisYear: 'This year',
  _Period.all: 'All time',
};

DateTime? _startOf(_Period p) {
  final now = DateTime.now();
  switch (p) {
    case _Period.thisMonth:
      return DateTime(now.year, now.month, 1);
    case _Period.last30:
      return now.subtract(const Duration(days: 30));
    case _Period.last90:
      return now.subtract(const Duration(days: 90));
    case _Period.thisYear:
      return DateTime(now.year, 1, 1);
    case _Period.all:
      return null;
  }
}

class StatementScreen extends ConsumerStatefulWidget {
  const StatementScreen({super.key});

  @override
  ConsumerState<StatementScreen> createState() => _StatementScreenState();
}

class _StatementScreenState extends ConsumerState<StatementScreen> {
  _Period _period = _Period.thisMonth;
  bool _busy = false;

  Future<void> _download(List<Transaction> txs, int moneyIn, int moneyOut) async {
    setState(() => _busy = true);
    try {
      final phone = ref.read(sessionPhoneProvider) ?? '';
      final name = ref.read(profileNameProvider) ?? 'PayBD user';
      final bytes = await buildStatementPdf(
        name: name,
        phone: phone,
        periodLabel: _labels[_period]!,
        txs: txs,
        moneyIn: moneyIn,
        moneyOut: moneyOut,
      );
      await Printing.sharePdf(bytes: bytes, filename: 'PayBD-statement-$phone.pdf');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Tr('Could not create the statement. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    return Scaffold(
      appBar: const PayAppBar(title: Tr('Statement')),
      body: SafeArea(
        child: wallet.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(20),
            children: const [
              TxSkeleton(),
              SizedBox(height: 10),
              TxSkeleton(),
              SizedBox(height: 10),
              TxSkeleton(),
            ],
          ),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Tr('Could not load transactions.'),
                TextButton(
                  onPressed: () => ref.invalidate(walletProvider),
                  child: const Tr('Retry'),
                ),
              ],
            ),
          ),
          data: (w) {
            final start = _startOf(_period);
            final txs = [
              for (final t in w.transactions)
                if (start == null || !t.createdAt.isBefore(start)) t,
            ];
            var moneyIn = 0;
            var moneyOut = 0;
            for (final t in txs) {
              if (t.isCredit) {
                moneyIn += t.amountMinor;
              } else {
                moneyOut += t.amountMinor + t.feeMinor;
              }
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              itemCount: txs.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return _Header(
                    period: _period,
                    onPeriod: (p) => setState(() => _period = p),
                    moneyIn: moneyIn,
                    moneyOut: moneyOut,
                    count: txs.length,
                    busy: _busy,
                    onDownload: txs.isEmpty
                        ? null
                        : () => _download(txs, moneyIn, moneyOut),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: FadeSlideIn(
                    index: i < 8 ? i : 0,
                    child: TxTile(tx: txs[i - 1]),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final _Period period;
  final ValueChanged<_Period> onPeriod;
  final int moneyIn;
  final int moneyOut;
  final int count;
  final bool busy;
  final VoidCallback? onDownload;

  const _Header({
    required this.period,
    required this.onPeriod,
    required this.moneyIn,
    required this.moneyOut,
    required this.count,
    required this.busy,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final p in _Period.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Tr(_labels[p]!),
                    selected: period == p,
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.panel,
                    side: BorderSide.none,
                    labelStyle: TextStyle(
                      color: period == p ? Colors.white : AppColors.text,
                      fontSize: 12,
                    ),
                    onSelected: (_) => onPeriod(p),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _Total(label: 'Money in', minor: moneyIn)),
                  Container(width: 1, height: 40, color: Colors.white30),
                  Expanded(child: _Total(label: 'Money out', minor: moneyOut)),
                ],
              ),
              const SizedBox(height: 10),
              Tr('$count transactions',
                  style: const TextStyle(fontSize: 12, color: Colors.white70)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        PrimaryButton(
          label: 'Download PDF',
          loading: busy,
          onPressed: onDownload,
        ),
        const SizedBox(height: 16),
        if (count == 0)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Tr('No transactions in this period',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
          ),
      ],
    );
  }
}

class _Total extends StatelessWidget {
  final String label;
  final int minor;
  const _Total({required this.label, required this.minor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Tr(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        const SizedBox(height: 4),
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: minor),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (_, v, _) => Tr(
            formatTaka(v),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
