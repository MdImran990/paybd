enum TxType { sent, received }

class Transaction {
  final String id;
  final TxType type;
  final String counterparty; // phone number
  final int amountMinor; // paisa
  final int feeMinor; // paisa
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.counterparty,
    required this.amountMinor,
    required this.feeMinor,
    required this.createdAt,
  });

  bool get isCredit => type == TxType.received;
}
