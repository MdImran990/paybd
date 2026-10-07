import 'package:flutter/material.dart';
import '../../core/widgets/pay_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/fade_slide_in.dart';
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
    return Scaffold(
      appBar: PayAppBar(title: const Text('History')),
      body: SafeArea(
        child: wallet.when(
          loading: () => ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
                const Text('Could not load transactions.'),
                TextButton(
                  onPressed: () => ref.invalidate(walletProvider),
                  child: const Text('Retry'),
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: TextField(
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Search number or transaction ID',
                      prefixIcon: const Icon(Icons.search_rounded),
                      filled: true,
                      fillColor: AppColors.panel,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                if (types.length > 1)
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                              Text('No transactions found',
                                  style: TextStyle(color: AppColors.textMuted)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
        label: Text(label),
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
