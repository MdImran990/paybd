import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/models/transaction.dart';
import '../utils/receipt_text.dart';

class CopyReceiptButton extends StatelessWidget {
  final Transaction tx;
  const CopyReceiptButton({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () async {
        await Clipboard.setData(ClipboardData(text: receiptText(tx)));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Receipt copied')),
          );
        }
      },
      icon: const Icon(Icons.copy_rounded, size: 18),
      label: const Text('Copy receipt'),
    );
  }
}
