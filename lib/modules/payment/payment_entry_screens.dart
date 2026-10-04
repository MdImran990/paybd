import 'package:flutter/material.dart';
import '../../core/utils/operators.dart';
import '../../data/models/transaction.dart';
import 'payment_form_screen.dart';

class SendMoneyScreen extends StatelessWidget {
  const SendMoneyScreen({super.key});

  @override
  Widget build(BuildContext context) => const PaymentFormScreen(
        type: TxType.sent,
        title: 'Send Money',
        recipientLabel: 'Recipient',
        blockSelf: true,
      );
}

class CashOutScreen extends StatelessWidget {
  const CashOutScreen({super.key});

  @override
  Widget build(BuildContext context) => const PaymentFormScreen(
        type: TxType.cashOut,
        title: 'Cash Out',
        recipientLabel: 'Agent number',
        quickAmounts: [500, 1000, 2000, 5000],
      );
}

class AddMoneyScreen extends StatelessWidget {
  const AddMoneyScreen({super.key});

  @override
  Widget build(BuildContext context) => const PaymentFormScreen(
        type: TxType.cashIn,
        title: 'Add Money',
        noteLabel: 'Add from',
        noteOptions: ['Bank account', 'Card', 'Agent'],
        quickAmounts: [500, 1000, 5000, 10000],
      );
}

class RechargeScreen extends StatelessWidget {
  const RechargeScreen({super.key});

  @override
  Widget build(BuildContext context) => PaymentFormScreen(
        type: TxType.recharge,
        title: 'Mobile Recharge',
        recipientLabel: 'Mobile number',
        noteLabel: 'Operator',
        noteOptions: mobileOperators,
        suggestNote: operatorForPhone,
        quickAmounts: const [20, 50, 100, 200],
      );
}
