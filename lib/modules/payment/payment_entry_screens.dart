import 'package:flutter/material.dart';
import '../../core/widgets/pay_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/billers.dart';
import '../../core/utils/operators.dart';
import '../../data/models/transaction.dart';
import '../qr/qr_payload.dart';
import '../savings/savings_providers.dart';
import 'payment_form_screen.dart';

class SendMoneyScreen extends StatelessWidget {
  /// Set when the user arrives from scanning a QR code.
  final QrPayload? prefill;
  const SendMoneyScreen({super.key, this.prefill});

  @override
  Widget build(BuildContext context) => PaymentFormScreen(
        type: TxType.sent,
        title: 'Send Money',
        recipientLabel: 'Recipient',
        blockSelf: true,
        initialPhone: prefill?.phone,
        initialAmountMinor: prefill?.amountMinor,
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

class PayBillScreen extends StatelessWidget {
  const PayBillScreen({super.key});

  @override
  Widget build(BuildContext context) => const PaymentFormScreen(
        type: TxType.bill,
        title: 'Pay Bill',
        recipientLabel: 'Account / meter number',
        recipientIsPhone: false,
        noteLabel: 'Bill type',
        noteOptions: billTypes,
        quickAmounts: [500, 1000, 2000, 5000],
      );
}

class DonationScreen extends StatelessWidget {
  const DonationScreen({super.key});

  @override
  Widget build(BuildContext context) => const PaymentFormScreen(
        type: TxType.donation,
        title: 'Donation',
        noteLabel: 'Cause',
        noteOptions: donationCauses,
        quickAmounts: [100, 500, 1000, 2000],
      );
}

class EducationFeeScreen extends StatelessWidget {
  const EducationFeeScreen({super.key});

  @override
  Widget build(BuildContext context) => const PaymentFormScreen(
        type: TxType.education,
        title: 'Education Fee',
        recipientLabel: 'Student ID',
        recipientIsPhone: false,
        noteLabel: 'Institution type',
        noteOptions: institutionTypes,
        quickAmounts: [500, 1000, 2000, 5000],
      );
}

class SavingsDepositScreen extends ConsumerWidget {
  /// Goal preselected when opened from a goal card.
  final String? goalName;
  const SavingsDepositScreen({super.key, this.goalName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final names = [for (final g in ref.watch(savingsProvider)) g.name];
    if (names.isEmpty) {
      return Scaffold(
        appBar: PayAppBar(title: const Text('Add to savings')),
        body: const Center(child: Text('Create a savings goal first.')),
      );
    }
    return PaymentFormScreen(
      type: TxType.savings,
      title: 'Add to savings',
      noteLabel: 'Goal',
      noteOptions: names,
      initialNote: names.contains(goalName) ? goalName : null,
      quickAmounts: const [500, 1000, 2000, 5000],
    );
  }
}
