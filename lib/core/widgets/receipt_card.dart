import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../data/models/transaction.dart';
import '../utils/format.dart';
import 'detail_row.dart';

class ReceiptCard extends StatelessWidget {
  final Transaction tx;
  const ReceiptCard({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    final sent = tx.type == TxType.sent;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          DetailRow('Type', sent ? 'Send Money' : 'Received'),
          DetailRow(sent ? 'To' : 'From', tx.counterparty),
          DetailRow('Amount', formatTaka(tx.amountMinor)),
          DetailRow('Fee', formatTaka(tx.feeMinor)),
          DetailRow('Transaction ID', tx.id),
          DetailRow('Date & time', formatDateTime(tx.createdAt)),
          const DetailRow('Status', 'Successful'),
          const SizedBox(height: 8),
          const Text(
            'DEMO transaction. Not real money.',
            style: TextStyle(fontSize: 12, color: AppColors.yellow),
          ),
        ],
      ),
    );
  }
}
