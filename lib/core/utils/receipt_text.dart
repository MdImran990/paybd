import '../../data/models/transaction.dart';
import 'format.dart';

/// Plain-text receipt (for copying / sharing).
String receiptText(Transaction tx) {
  final b = StringBuffer();
  b.writeln('PayBD receipt (DEMO, not real money)');
  b.writeln('Type: ${tx.type.label}');
  if (tx.counterparty.isNotEmpty) {
    b.writeln('${tx.type.counterpartyLabel}: ${tx.counterparty}');
  }
  if (tx.note != null) b.writeln('${tx.type.noteLabel}: ${tx.note}');
  b.writeln('Amount: ${formatTaka(tx.amountMinor)}');
  b.writeln('Fee: ${formatTaka(tx.feeMinor)}');
  b.writeln('Transaction ID: ${tx.id}');
  b.write('Date: ${formatDateTime(tx.createdAt)}');
  return b.toString();
}
