import 'package:flutter/material.dart';
import '../../core/widgets/pay_app_bar.dart';
import '../../app/theme/app_colors.dart';

/// PLACEHOLDER. Replace with the real Terms of Use and Privacy Policy
/// written or reviewed by a lawyer before any public launch.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PayAppBar(title: const Text('Terms & Privacy')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: const [
            Text('Terms of Use',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            Text(
              'PayBD is currently a demo application. It does not hold or move real money. '
              'The final Terms of Use will be published before launch.',
              style: TextStyle(color: AppColors.textMuted, height: 1.5),
            ),
            SizedBox(height: 24),
            Text('Privacy Policy',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            Text(
              'In this demo, your data (phone number, PIN hash, demo transactions) is stored only on '
              'this device. The final Privacy Policy, explaining what is collected and why, '
              'will be published before launch.',
              style: TextStyle(color: AppColors.textMuted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
