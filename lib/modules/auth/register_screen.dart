import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/auth_header.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/primary_button.dart';
import 'account_provider.dart';
import 'auth_providers.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String? initialPhone;
  const RegisterScreen({super.key, this.initialPhone});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _phone = TextEditingController();
  final _phoneOk = ValueNotifier<bool>(false);
  final _agreed = ValueNotifier<bool>(false);
  final _loading = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    final p = widget.initialPhone;
    if (p != null) {
      _phone.text = p;
      _phoneOk.value = bdPhoneRegExp.hasMatch(p);
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _phoneOk.dispose();
    _agreed.dispose();
    _loading.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final phone = _phone.text.trim();
    FocusManager.instance.primaryFocus?.unfocus();

    if (ref.read(accountProvider) == phone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('This number already has an account. Please log in.')),
      );
      return;
    }

    _loading.value = true;
    try {
      await ref.read(authRepositoryProvider).sendOtp(phone);
      if (mounted) context.push('/otp?mode=register', extra: phone);
    } finally {
      _loading.value = false;
    }
  }
  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            AuthHeader(
              title: 'Create account',
              subtitle: 'Open your PayBD wallet in a minute',
              compact: keyboardOpen,
              showBack: true,
            ),
            Expanded(
              child: AuthSheet(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FadeSlideIn(
                      index: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your mobile number',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800)),
                          SizedBox(height: 4),
                          Text('We will send a code to verify it.',
                              style: TextStyle(color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    FadeSlideIn(
                      index: 1,
                      child: PhoneField(
                        controller: _phone,
                        onChanged: (v) =>
                            _phoneOk.value = bdPhoneRegExp.hasMatch(v),
                      ),
                    ),
                    const SizedBox(height: 14),
                    FadeSlideIn(
                      index: 2,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _agreed,
                        builder: (_, agreed, _) => Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Checkbox(
                              value: agreed,
                              activeColor: AppColors.primary,
                              onChanged: (v) => _agreed.value = v ?? false,
                            ),
                            Expanded(
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text('I agree to the ',
                                      style: TextStyle(fontSize: 13)),
                                  GestureDetector(
                                    onTap: () => context.push('/terms'),
                                    child: const Text(
                                      'Terms & Privacy',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      index: 3,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _loading,
                        builder: (_, loading, _) =>
                            ValueListenableBuilder<bool>(
                          valueListenable: _phoneOk,
                          builder: (_, phoneOk, _) =>
                              ValueListenableBuilder<bool>(
                            valueListenable: _agreed,
                            builder: (_, agreed, _) => PrimaryButton(
                              label: 'Agree & continue',
                              loading: loading,
                              onPressed:
                                  (phoneOk && agreed) ? _continue : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account?',
                            style: TextStyle(color: AppColors.textMuted)),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Log in',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
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
