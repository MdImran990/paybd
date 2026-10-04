import 'package:flutter/material.dart';
import '../../data/models/transaction.dart';

IconData txIcon(TxType type) => switch (type) {
      TxType.sent => Icons.north_rounded,
      TxType.received => Icons.south_rounded,
      TxType.cashIn => Icons.add_card_rounded,
      TxType.cashOut => Icons.payments_outlined,
      TxType.recharge => Icons.smartphone_rounded,
    };

String txTitle(Transaction tx) {
  final c = tx.counterparty;
  switch (tx.type) {
    case TxType.sent:
      return 'Sent to $c';
    case TxType.received:
      return 'Received from $c';
    case TxType.cashIn:
      return 'Added from $c';
    case TxType.cashOut:
      return 'Cash out to agent $c';
    case TxType.recharge:
      final op = tx.note;
      return op == null ? 'Recharge $c' : 'Recharge $c ($op)';
  }
}
