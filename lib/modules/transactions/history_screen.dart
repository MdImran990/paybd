import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/i18n/tr.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/pink_header.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/tx_tile.dart';
import '../../data/models/transaction.dart';
import '../wallet/wallet_providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  TxType? _filter; // null = all
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider);
    return PinkPage(
      header: PinkHeader(
        title: 'History',
        cardHeight: 56,
        card: HeaderCard(
          child: TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: tr('Search number or transaction ID'),
              hintStyle: const TextStyle(
                  color: AppColors.textMuted, fontWeight: FontWeight.w400),
              prefixIcon:
                  const Icon(Icons.search_rounded, color: AppColors.primary),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 17),
            ),
          ),
        ),
      ),
      body: wallet.when(
        loading: () => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: const [
            TxSkeleton(),
            SizedBox(height: 10),
            TxSkeleton(),
            SizedBox(height: 10),
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
          final types = {for (final t in w.transactions) t.type}.toList();
          final q = _query.trim().toLowerCase();
          final shown = [
            for (final t in w.transactions)
              if ((_filter == null || t.type == _filter) &&
                  (q.isEmpty ||
                      t.counterparty.toLowerCase().contains(q) ||
                      t.id.toLowerCase().contains(q) ||
                      (t.note ?? '').toLowerCase().contains(q)))
                t,
          ];
          return Column(
            children: [
              if (types.length > 1)
                SizedBox(
                  height: 58,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    children: [
                      _FilterChip(
                        label: 'All',
                        selected: _filter == null,
                        onTap: () => setState(() => _filter = null),
                      ),
                      for (final t in types)
                        _FilterChip(
                          label: t.label,
                          selected: _filter == t,
                          onTap: () => setState(() => _filter = t),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: shown.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_rounded,
                                size: 56, color: AppColors.textMuted),
                            SizedBox(height: 12),
                            Tr('No transactions found',
                                style: TextStyle(color: AppColors.textMuted)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                        itemCount: shown.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => FadeSlideIn(
                          index: i < 8 ? i : 0,
                          child: TxTile(tx: shown[i]),
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Tr(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.panel,
        side: BorderSide.none,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppColors.text,
          fontSize: 12,
        ),
        onSelected: (_) => onTap(),
      ),
    );
  }
}
