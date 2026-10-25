import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_shadows.dart';
import '../../core/i18n/tr.dart';
import '../../core/insights/insights.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/pink_header.dart';
import '../../data/models/transaction.dart';
import '../wallet/wallet_providers.dart';

const _periodLabels = {
  InsightPeriod.thisMonth: 'This month',
  InsightPeriod.lastMonth: 'Last month',
  InsightPeriod.last3Months: 'Last 3 months',
};

const _monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

Color _colorOf(TxType t) => switch (t) {
      TxType.sent => AppColors.primary,
      TxType.cashOut => const Color(0xFFFF9A3D),
      TxType.recharge => const Color(0xFF8E5CFF),
      TxType.bill => AppColors.blue,
      TxType.donation => AppColors.green,
      TxType.education => const Color(0xFF14B8A6),
      _ => AppColors.textMuted,
    };

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  InsightPeriod _period = InsightPeriod.thisMonth;

  @override
  Widget build(BuildContext context) {
    final txs = ref.watch(walletProvider).value?.transactions ?? const <Transaction>[];
    final data = computeInsights(txs, DateTime.now(), _period);
    final change = data.changePercent;

    return PinkPage(
      header: PinkHeader(
        title: 'Spending insights',
        cardHeight: 92,
        card: HeaderCard(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Tr('Spent',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    TweenAnimationBuilder<int>(
                      key: ValueKey(data.spent),
                      tween: IntTween(begin: 0, end: data.spent),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => Tr(formatTaka(v),
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
              if (change != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    // Spending less than before is good news.
                    color: (change <= 0 ? AppColors.green : AppColors.error)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Tr('${change > 0 ? '+' : ''}$change%',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: change <= 0
                                  ? AppColors.green
                                  : AppColors.error)),
                      const Tr('vs previous period',
                          style: TextStyle(
                              fontSize: 9, color: AppColors.textMuted)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        children: staggered([
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final p in InsightPeriod.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Tr(_periodLabels[p]!),
                      selected: _period == p,
                      showCheckmark: false,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.panel,
                      side: BorderSide.none,
                      labelStyle: TextStyle(
                        color: _period == p ? Colors.white : AppColors.text,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _period = p),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _Card(
            title: 'By category',
            child: data.categories.isEmpty
                ? const _Empty()
                : _CategoryChart(categories: data.categories, total: data.spent),
          ),
          const SizedBox(height: 14),
          _Card(title: 'Last 6 months', child: _MonthBars(months: data.months)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.south_rounded,
                  color: AppColors.green,
                  label: 'Money in',
                  minor: data.moneyIn,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  icon: Icons.savings_rounded,
                  color: AppColors.primary,
                  label: 'Saved',
                  minor: data.saved,
                ),
              ),
            ],
          ),
          if (data.topRecipients.isNotEmpty) ...[
            const SizedBox(height: 14),
            _Card(
              title: 'Top recipients',
              child: Column(
                children: [
                  for (final r in data.topRecipients)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.person_rounded,
                                size: 18, color: AppColors.primary),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Tr(r.phone)),
                          Tr(formatTaka(r.minor),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
        boxShadow: softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Tr(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Tr('No spending in this period',
            style: TextStyle(color: AppColors.textMuted)),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int minor;
  const _MiniStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.minor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(18),
        boxShadow: softShadow,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tr(label,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
                Tr(formatTaka(minor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- donut chart ----------------

class _CategoryChart extends StatelessWidget {
  final List<CategoryTotal> categories;
  final int total;
  const _CategoryChart({required this.categories, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 170,
          child: TweenAnimationBuilder<double>(
            key: ValueKey(total),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, t, _) => CustomPaint(
              size: const Size.square(170),
              painter: _DonutPainter(categories, total, t),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Tr('Spent',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                    Tr(formatTaka((total * t).round()),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        for (final c in categories)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _colorOf(c.type),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Tr(c.type.label)),
                Tr('${(c.minor * 100 / total).round()}%',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(width: 12),
                SizedBox(
                  width: 96,
                  child: Tr(formatTaka(c.minor),
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<CategoryTotal> categories;
  final int total;
  final double progress;
  const _DonutPainter(this.categories, this.total, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;
    const stroke = 22.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = const Color(0xFFF0F0F5);
    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    var start = -math.pi / 2;
    const gap = 0.04;
    for (final c in categories) {
      final sweep = (c.minor / total) * math.pi * 2 * progress;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = _colorOf(c.type);
      final drawn = sweep - gap;
      if (drawn > 0) {
        canvas.drawArc(rect, start + gap / 2, drawn, false, paint);
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.total != total;
}

// ---------------- bar chart ----------------

class _MonthBars extends StatelessWidget {
  final List<MonthTotal> months;
  const _MonthBars({required this.months});

  @override
  Widget build(BuildContext context) {
    final maxValue = months.fold<int>(0, (m, e) => e.minor > m ? e.minor : m);
    return Column(
      children: [
        SizedBox(
          height: 140,
          child: TweenAnimationBuilder<double>(
            key: ValueKey(maxValue),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (_, t, _) => CustomPaint(
              size: const Size(double.infinity, 140),
              painter: _BarsPainter(months, maxValue, t),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final m in months)
              Expanded(
                child: Tr(_monthNames[m.month.month - 1],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ),
          ],
        ),
      ],
    );
  }
}

class _BarsPainter extends CustomPainter {
  final List<MonthTotal> months;
  final int maxValue;
  final double progress;
  const _BarsPainter(this.months, this.maxValue, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final slot = size.width / months.length;
    final barWidth = slot * 0.46;
    final base = Paint()..color = const Color(0xFFF0F0F5);
    for (var i = 0; i < months.length; i++) {
      final x = slot * i + (slot - barWidth) / 2;
      // grey track
      canvas.drawRRect(
        RRect.fromLTRBR(x, 0, x + barWidth, size.height, const Radius.circular(8)),
        base,
      );
      if (maxValue <= 0 || months[i].minor <= 0) continue;
      final h = size.height * (months[i].minor / maxValue) * progress;
      final isCurrent = i == months.length - 1;
      canvas.drawRRect(
        RRect.fromLTRBR(
          x,
          size.height - h,
          x + barWidth,
          size.height,
          const Radius.circular(8),
        ),
        Paint()
          ..color = isCurrent
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.35),
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) =>
      old.progress != progress || old.maxValue != maxValue;
}
