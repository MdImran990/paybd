import 'package:flutter/material.dart';
import '../../core/i18n/tr.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/pin_verify.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/auth_header.dart';
import '../../core/widgets/pin_entry.dart';
import '../profile/profile_providers.dart';
import 'auth_providers.dart';

class LoginPinScreen extends ConsumerWidget {
  final String phone;
  const LoginPinScreen({super.key, required this.phone});

  String get _masked => phone.length == 11
      ? '${phone.substring(0, 3)}•••••${phone.substring(8)}'
      : phone;

  Future<void> _forgotPin(BuildContext context, WidgetRef ref) async {
    await ref.read(authRepositoryProvider).sendOtp(phone);
    if (context.mounted) context.push('/otp?reset=1', extra: phone);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(profileNameProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            AuthHeader(
              title: 'Enter PIN',
              subtitle: _masked,
              compact: true,
              showBack: true,
            ),
            Expanded(
              child: AuthSheet(
                scrollable: false,
                child: Column(
                  children: [
                    Expanded(
                      child: PinEntry(
                        title: name == null ? 'Welcome back' : 'Hi, $name',
                        subtitle: 'Enter your 5-digit PIN to log in',
                        onCompleted: (pin) async {
                          final error = await verifyPinMessage(
                              ref.read(pinRepositoryProvider), pin);
                          if (error != null) return error;
                          await ref
                              .read(sessionPhoneProvider.notifier)
                              .setPhone(phone);
                          if (context.mounted) context.go('/home');
                          return null;
                        },
                      ),
                    ),
                    TextButton(
                      onPressed: () => _forgotPin(context, ref),
                      child: const Tr('Forgot PIN?'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
