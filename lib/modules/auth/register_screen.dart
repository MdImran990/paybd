import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/i18n/tr.dart';
import '../../core/utils/numeric_input.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/continue_bar.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/language_toggle.dart';
import '../../core/widgets/pay_keypad.dart';
import '../../core/widgets/pink_auth_page.dart';
import 'account_provider.dart';
import 'auth_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String? initialPhone;
  const RegisterScreen({super.key, this.initialPhone});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _phone = TextEditingController();
  final _focus = FocusNode();
  final _agreed = ValueNotifier<bool>(false);
  final _loading = ValueNotifier<bool>(false);
  final _tick = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    final p = widget.initialPhone;
    if (p != null) _phone.text = p;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _phone.dispose();
    _focus.dispose();
    _agreed.dispose();
    _loading.dispose();
    _tick.dispose();
    super.dispose();
  }

  bool get _ready => bdPhoneRegExp.hasMatch(_phone.text) && _agreed.value;

  void _onKey(String key) {
    if (key == 'next') {
      if (_ready) _continue();
      return;
    }
    if (applyKey(_phone, key, maxLength: 11)) _tick.value++;
  }

  Future<void> _continue() async {
    final phone = _phone.text.trim();
    if (ref.read(accountsProvider).contains(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Tr('This number already has an account. Please log in.')),
      );
      return;
    }
    _loading.value = true;
    try {
      await ref.read(authRepositoryProvider).sendOtp(phone);
      if (mounted) context.push('/otp?mode=register', extra: phone);
    } finally {
      if (mounted) _loading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PinkAuthPage(
      title: 'Create account',
      showBack: true,
      trailing: const LanguageToggle(),
      body: Column(
        children: [
          FadeSlideIn(
            index: 0,
            child: AuthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: _tick,
                    builder: (_, _, _) => PinkField(
                      label: 'Your mobile number',
                      controller: _phone,
                      focus: _focus,
                      hint: '01XXXXXXXXX',
                      prefix: const Text('+88',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Tr('We will send a code to verify it.',
                      style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  ValueListenableBuilder<bool>(
                    valueListenable: _agreed,
                    builder: (_, agreed, _) => Row(
                      children: [
                        Checkbox(
                          value: agreed,
                          activeColor: AppColors.primary,
                          onChanged: (v) {
                            _agreed.value = v ?? false;
                            _tick.value++;
                          },
                        ),
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Tr('I agree to the ',
                                  style: TextStyle(fontSize: 13)),
                              GestureDetector(
                                onTap: () => context.push('/terms'),
                                child: const Tr(
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
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            index: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Tr('Already have an account?',
                    style: TextStyle(color: Colors.white70)),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Tr('Log in',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<int>(
            valueListenable: _tick,
            builder: (_, _, _) => ValueListenableBuilder<bool>(
              valueListenable: _loading,
              builder: (_, loading, _) => ContinueBar(
                label: 'Agree & continue',
                loading: loading,
                onPressed: _ready ? _continue : null,
              ),
            ),
          ),
          PayKeypad(kind: KeypadKind.next, onKey: _onKey),
        ],
      ),
    );
  }
}
