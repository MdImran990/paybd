enum TxType { sent, received, cashIn, cashOut, recharge }

extension TxTypeX on TxType {
  bool get isCredit => this == TxType.received || this == TxType.cashIn;
  bool get debitsWallet => !isCredit;

  String get label => switch (this) {
        TxType.sent => 'Send Money',
        TxType.received => 'Received',
        TxType.cashIn => 'Add Money',
        TxType.cashOut => 'Cash Out',
        TxType.recharge => 'Mobile Recharge',
      };

  String get counterpartyLabel => switch (this) {
        TxType.sent => 'To',
        TxType.received => 'From',
        TxType.cashIn => 'Source',
        TxType.cashOut => 'Agent',
        TxType.recharge => 'Number',
      };

  String get confirmHeading => switch (this) {
        TxType.sent => 'You are sending',
        TxType.received => 'You are receiving',
        TxType.cashIn => 'You are adding',
        TxType.cashOut => 'You are cashing out',
        TxType.recharge => 'You are recharging',
      };

  String get successTitle => switch (this) {
        TxType.sent => 'Money sent',
        TxType.received => 'Money received',
        TxType.cashIn => 'Money added',
        TxType.cashOut => 'Cash out successful',
        TxType.recharge => 'Recharge successful',
      };
}

class Transaction {
  final String id;
  final TxType type;
  final String counterparty; // phone number, agent number or source
  final String? note; // e.g. mobile operator for a recharge
  final int amountMinor; // paisa
  final int feeMinor; // paisa
  final DateTime createdAt;

  const Transaction({
    required this.id,
    required this.type,
    required this.counterparty,
    this.note,
    required this.amountMinor,
    required this.feeMinor,
    required this.createdAt,
  });

  bool get isCredit => type.isCredit;
}
