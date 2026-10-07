import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

const _faqs = <(String, String)>[
  (
    'Is the money in PayBD real?',
    'No. This is a demo build. Balances and transactions are for testing only. '
        'Real money services will be added after the required approvals.',
  ),
  (
    'How do I send money?',
    'Open Send Money, enter the number and amount, confirm, then enter your PIN. '
        'You can also scan a PayBD QR code.',
  ),
  (
    'I forgot my PIN. What can I do?',
    'Go to Menu, Change PIN, then tap "Forgot PIN?" and verify your number with an OTP.',
  ),
  (
    'Why is my balance hidden?',
    'For your privacy the balance stays hidden until you tap "Tap for balance" and enter your PIN. '
        'You can change this in Settings.',
  ),
  (
    'How many wrong PIN attempts are allowed?',
    'After 5 wrong attempts your PIN is locked for 5 minutes.',
  ),
  (
    'Should I share my PIN or OTP?',
    'Never. PayBD will never ask for your PIN or OTP.',
  ),
];

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            for (final (q, a) in _faqs)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Theme(
                    data: Theme.of(context)
                        .copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      title: Text(q,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      childrenPadding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a,
                            style: const TextStyle(
                                color: AppColors.textMuted, height: 1.5)),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'Support contact details will be added before launch.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
