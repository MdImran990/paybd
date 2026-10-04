import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/detail_row.dart';
import '../../core/widgets/primary_button.dart';
import 'send_payload.dart';

class ConfirmSendScreen extends StatelessWidget {
  final SendPayload payload;
  const ConfirmSendScreen({super.key, required this.payload});

  @override
  Widget build(BuildContext context) {
    const fee = 0; // DEMO: fee comes from the server in the real app
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.panel,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      children: [
                        const Text('You are sending',
                            style: TextStyle(color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        Text(formatTaka(payload.amountMinor),
                            style: const TextStyle(
                                fontSize: 32, fontWeight: FontWeight.w800)),
                        const Divider(height: 32),
                        DetailRow('To', payload.phone),
                        DetailRow('Amount', formatTaka(payload.amountMinor)),
                        DetailRow('Fee', formatTaka(fee)),
                        const Divider(height: 24),
                        DetailRow('Total', formatTaka(payload.amountMinor + fee),
                            bold: true),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Confirm & enter PIN',
                onPressed: () => context.push('/send/pin', extra: payload),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
