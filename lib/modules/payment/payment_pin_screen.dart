import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/pin_entry.dart';
import '../../data/models/payment_request.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/wallet_repository.dart';
import '../auth/auth_providers.dart';
import '../wallet/wallet_providers.dart';

class PaymentPinScreen extends ConsumerWidget {
  final PaymentRequest request;
  const PaymentPinScreen({super.key, required this.request});

  Future<String?> _submit(BuildContext context, WidgetRef ref, String pin) async {
    final result = await ref.read(pinRepositoryProvider).verifyPin(pin);
    if (result.locked) {
      final mins = (result.lockedFor!.inSeconds / 60).ceil();
      return 'Too many wrong attempts. Try again in $mins min.';
    }
    if (!result.ok) {
      return 'Wrong PIN. ${result.attemptsLeft} attempts left.';
    }
    try {
      final tx = await ref.read(walletProvider.notifier).pay(request);
      if (context.mounted) context.go('/receipt', extra: tx);
      return null;
    } on WalletException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
        context.go('/home');
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final who = request.counterparty.isEmpty ? '' : ' (${request.counterparty})';
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: PinEntry(
          title: 'Enter your PIN',
          subtitle:
              '${request.type.label}: ${formatTaka(request.totalMinor)}$who',
          onCompleted: (pin) => _submit(context, ref, pin),
        ),
      ),
    );
  }
}
