import 'transaction.dart';

/// What the user is about to pay. Used by every flow (send, cash out, add money, recharge).
class PaymentRequest {
  final TxType type;
  final String counterparty;
  final String? note;
  final int amountMinor; // paisa
  final int feeMinor; // paisa, quoted by the repository (server in real app)

  const PaymentRequest({
    required this.type,
    required this.counterparty,
    this.note,
    required this.amountMinor,
    required this.feeMinor,
  });

  int get totalMinor =>
      type.debitsWallet ? amountMinor + feeMinor : amountMinor;
}
