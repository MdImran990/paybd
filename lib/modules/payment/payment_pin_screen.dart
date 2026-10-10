import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/i18n/tr.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/pay_app_bar.dart';
import '../../core/widgets/pin_entry.dart';
import '../../core/widgets/processing_overlay.dart';
import '../../data/models/payment_request.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/wallet_repository.dart';
import '../auth/auth_providers.dart';
import '../notifications/notification_providers.dart';
import '../savings/savings_providers.dart';
import '../wallet/wallet_providers.dart';

class PaymentPinScreen extends ConsumerStatefulWidget {
  final PaymentRequest request;
  const PaymentPinScreen({super.key, required this.request});

  @override
  ConsumerState<PaymentPinScreen> createState() => _PaymentPinScreenState();
}

class _PaymentPinScreenState extends ConsumerState<PaymentPinScreen> {
  bool _processing = false;

  PaymentRequest get request => widget.request;

  Future<String?> _submit(String pin) async {
    final result = await ref.read(activePinProvider).verifyPin(pin);
    if (result.locked) {
      final mins = (result.lockedFor!.inSeconds / 60).ceil();
      return 'Too many wrong attempts. Try again in $mins min.';
    }
    if (!result.ok) {
      return 'Wrong PIN. ${result.attemptsLeft} attempts left.';
    }

    if (mounted) setState(() => _processing = true);
    final started = DateTime.now();
    try {
      final tx = await ref.read(walletProvider.notifier).pay(request);
      if (request.type == TxType.savings) {
        await ref
            .read(savingsProvider.notifier)
            .deposit(request.counterparty, request.amountMinor);
      } else if (request.type == TxType.savingsWithdraw) {
        await ref.read(savingsProvider.notifier).withdrawAll(request.counterparty);
      }
      await ref.read(notificationsProvider.notifier).add(
            title: tx.type.successTitle,
            body: '${formatTaka(tx.amountMinor)} · ${tx.counterparty}',
          );

      // Keep the animation on screen for a moment so it feels deliberate.
      const minimum = Duration(milliseconds: 900);
      final elapsed = DateTime.now().difference(started);
      if (elapsed < minimum) await Future.delayed(minimum - elapsed);

      if (mounted) context.go('/receipt', extra: tx);
      return null;
    } on WalletException catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Tr(e.message)));
        context.go('/home');
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final who = request.counterparty.isEmpty ? '' : ' (${request.counterparty})';
    return PopScope(
      canPop: !_processing,
      child: Stack(
        children: [
          Scaffold(
            appBar: PayAppBar(backgroundColor: Colors.transparent),
            body: SafeArea(
              child: PinEntry(
                title: 'Enter your PIN',
                subtitle:
                    '${request.type.label}: ${formatTaka(request.totalMinor)}$who',
                onCompleted: _submit,
              ),
            ),
          ),
          if (_processing)
            const Positioned.fill(
              child: RepaintBoundary(child: ProcessingOverlay()),
            ),
        ],
      ),
    );
  }
}
