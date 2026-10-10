import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/app_info.dart';
import '../../core/i18n/tr.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/pay_app_bar.dart';
import '../../core/widgets/primary_button.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const points = <(IconData, String)>[
      (Icons.send_rounded, 'Send money and pay bills'),
      (Icons.savings_rounded, 'Save towards your goals'),
      (Icons.qr_code_scanner_rounded, 'Pay and get paid with QR'),
      (Icons.fingerprint_rounded, 'Protected by your PIN and fingerprint'),
    ];
    return Scaffold(
      appBar: const PayAppBar(title: Tr('Learn about PayBD')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            FadeSlideIn(
              index: 0,
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded,
                        size: 48, color: Colors.white),
                    SizedBox(height: 10),
                    Text('PayBD',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    SizedBox(height: 4),
                    Tr('Version: $appVersion',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    SizedBox(height: 10),
                    Tr('PayBD is a digital wallet for everyday payments.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < points.length; i++)
              FadeSlideIn(
                index: i + 1,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.1),
                        child: Icon(points[i].$1,
                            size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Tr(points[i].$2,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.yellow.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Tr(
                'This is a demo build. Balances and transactions are not real money.',
                style: TextStyle(fontSize: 12, color: AppColors.yellow),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Terms & Privacy',
              onPressed: () => context.push('/terms'),
            ),
          ],
        ),
      ),
    );
  }
}
