import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/receipt_card.dart';
import '../../data/models/transaction.dart';

class ReceiptScreen extends StatelessWidget {
  final Transaction tx;
  const ReceiptScreen({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    // The money has already moved, so going "back" must not repeat the payment.
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 700),
                          curve: Curves.elasticOut,
                          builder: (_, v, child) =>
                              Transform.scale(scale: v, child: child),
                          child: const CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.green,
                            child: Icon(Icons.check_rounded,
                                size: 48, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(tx.type.successTitle,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        Text(formatTaka(tx.amountMinor),
                            style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: AppColors.green)),
                        const SizedBox(height: 24),
                        ReceiptCard(tx: tx),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryButton(label: 'Done', onPressed: () => context.go('/home')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
