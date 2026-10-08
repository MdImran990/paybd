import 'package:flutter/material.dart';
import '../i18n/tr.dart';
import '../../app/theme/app_colors.dart';
import '../../data/models/transaction.dart';
import '../utils/format.dart';
import '../utils/tx_ui.dart';
import 'copy_receipt_button.dart';
import 'receipt_card.dart';

class TxTile extends StatelessWidget {
  final Transaction tx;
  const TxTile({super.key, required this.tx});

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Tr('Transaction details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            ReceiptCard(tx: tx),
            CopyReceiptButton(tx: tx),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final credit = tx.isCredit;
    final color = credit ? AppColors.green : AppColors.error;
    return Material(
      color: AppColors.panel,
      elevation: 1.5,
      shadowColor: const Color(0x22000000),
      surfaceTintColor: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _showDetails(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(txIcon(tx.type), color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tr(
                      txTitle(tx),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Tr(formatDateTime(tx.createdAt),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Tr(
                '${credit ? '+' : '-'}${formatTaka(tx.amountMinor)}',
                style: TextStyle(fontWeight: FontWeight.w800, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
