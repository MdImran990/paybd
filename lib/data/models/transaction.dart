enum TxType {
  sent,
  received,
  cashIn,
  cashOut,
  recharge,
  bill,
  donation,
  education,
  savings,
  savingsWithdraw,
}

extension TxTypeX on TxType {
  bool get isCredit =>
      this == TxType.received ||
      this == TxType.cashIn ||
      this == TxType.savingsWithdraw;
  bool get debitsWallet => !isCredit;

  String get label => switch (this) {
        TxType.sent => 'Send Money',
        TxType.received => 'Received',
        TxType.cashIn => 'Add Money',
        TxType.cashOut => 'Cash Out',
        TxType.recharge => 'Mobile Recharge',
        TxType.bill => 'Pay Bill',
        TxType.donation => 'Donation',
        TxType.education => 'Education Fee',
        TxType.savings => 'Savings Deposit',
        TxType.savingsWithdraw => 'Savings Withdrawal',
      };

  String get counterpartyLabel => switch (this) {
        TxType.sent => 'To',
        TxType.received => 'From',
        TxType.cashIn => 'Source',
        TxType.cashOut => 'Agent',
        TxType.recharge => 'Number',
        TxType.bill => 'Account',
        TxType.donation => 'Cause',
        TxType.education => 'Student ID',
        TxType.savings => 'Goal',
        TxType.savingsWithdraw => 'Goal',
      };

  String get confirmHeading => switch (this) {
        TxType.sent => 'You are sending',
        TxType.received => 'You are receiving',
        TxType.cashIn => 'You are adding',
        TxType.cashOut => 'You are cashing out',
        TxType.recharge => 'You are recharging',
        TxType.bill => 'You are paying a bill',
        TxType.donation => 'You are donating',
        TxType.education => 'You are paying a fee',
        TxType.savings => 'You are saving',
        TxType.savingsWithdraw => 'You are withdrawing',
      };

  String get successTitle => switch (this) {
        TxType.sent => 'Money sent',
        TxType.received => 'Money received',
        TxType.cashIn => 'Money added',
        TxType.cashOut => 'Cash out successful',
        TxType.recharge => 'Recharge successful',
        TxType.bill => 'Bill paid',
        TxType.donation => 'Donation sent',
        TxType.education => 'Fee paid',
        TxType.savings => 'Saved to goal',
        TxType.savingsWithdraw => 'Withdrawn to wallet',
      };

  /// Label for the optional note (operator, bill type, institution type).
  String get noteLabel => switch (this) {
        TxType.recharge => 'Operator',
        TxType.bill => 'Bill type',
        TxType.education => 'Institution type',
        _ => 'Note',
      };
}

class Transaction {
  final String id;
  final TxType type;
  final String counterparty; // phone, agent number, account, goal, cause...
  final String? note;
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'counterparty': counterparty,
        'note': note,
        'amountMinor': amountMinor,
        'feeMinor': feeMinor,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Transaction.fromJson(Map<String, dynamic> j) => Transaction(
        id: j['id'] as String,
        type: TxType.values.byName(j['type'] as String),
        counterparty: j['counterparty'] as String,
        note: j['note'] as String?,
        amountMinor: j['amountMinor'] as int,
        feeMinor: j['feeMinor'] as int,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
