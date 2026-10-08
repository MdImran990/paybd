import 'package:flutter/material.dart';
import '../../core/i18n/tr.dart';
import '../../core/widgets/pay_app_bar.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/detail_row.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/payment_request.dart';
import '../../data/models/transaction.dart';

class ConfirmPaymentScreen extends StatelessWidget {
  final PaymentRequest request;
  const ConfirmPaymentScreen({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PayAppBar(
        title: const Tr('Confirm'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.panel,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Column(
                          children: [
                            Tr(request.type.confirmHeading,
                                style: const TextStyle(
                                    color: AppColors.textMuted)),
                            const SizedBox(height: 8),
                            Tr(formatTaka(request.amountMinor),
                                style: const TextStyle(
                                    fontSize: 32, fontWeight: FontWeight.w800)),
                            const Divider(height: 32),
                            if (request.counterparty.isNotEmpty)
                              DetailRow(request.type.counterpartyLabel,
                                  request.counterparty),
                            if (request.note != null)
                              DetailRow(request.type.noteLabel, request.note!),
                            DetailRow('Amount', formatTaka(request.amountMinor)),
                            DetailRow('Fee', formatTaka(request.feeMinor)),
                            const Divider(height: 24),
                            DetailRow('Total', formatTaka(request.totalMinor),
                                bold: true),
                          ],
                        ),
                      ),
                      if (request.type.debitsWallet) ...[
                        const SizedBox(height: 16),
                        const Tr(
                          'Never share your PIN or OTP with anyone.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Confirm & enter PIN',
                onPressed: () => context.push('/pay/pin', extra: request),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
