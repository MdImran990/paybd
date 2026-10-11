import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/i18n/tr.dart';
import '../../core/utils/numeric_input.dart';
import '../../core/utils/pin_verify.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/continue_bar.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/language_toggle.dart';
import '../../core/widgets/pay_keypad.dart';
import '../../core/widgets/pink_auth_page.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/repositories/pin_repository.dart';
import 'account_provider.dart';
import 'auth_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _number = TextEditingController();
  final _pin = TextEditingController();
  final _numFocus = FocusNode();
  final _pinFocus = FocusNode();
  final _pinActive = ValueNotifier<bool>(false);
  final _obscure = ValueNotifier<bool>(true);
  final _error = ValueNotifier<String?>(null);
  final _loading = ValueNotifier<bool>(false);
  final _tick = ValueNotifier<int>(0); // bumps when the text changes
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  bool get _numberValid => bdPhoneRegExp.hasMatch(_number.text);

  @override
  void initState() {
    super.initState();
    // Remember the account on this device, like the bKash app does.
    final saved = ref.read(accountProvider);
    if (saved != null) _number.text = saved;

    _numFocus.addListener(() {
      if (_numFocus.hasFocus) _pinActive.value = false;
    });
    _pinFocus.addListener(() {
      if (_pinFocus.hasFocus) _pinActive.value = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      (_numberValid ? _pinFocus : _numFocus).requestFocus();
    });
  }

  @override
  void dispose() {
    _number.dispose();
    _pin.dispose();
    _numFocus.dispose();
    _pinFocus.dispose();
    _pinActive.dispose();
    _obscure.dispose();
    _error.dispose();
    _loading.dispose();
    _tick.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _onKey(String key) {
    if (key == 'next') {
      if (!_pinActive.value && _numberValid) {
        _pinFocus.requestFocus();
      } else if (_canContinue) {
        _continue();
      }
      return;
    }
    _error.value = null;
    final pinTurn = _pinActive.value;
    final changed = applyKey(pinTurn ? _pin : _number, key,
        maxLength: pinTurn ? 5 : 11);
    if (!changed) return;
    _tick.value++;
    if (!pinTurn && _number.text.length == 11) _pinFocus.requestFocus();
  }

  bool get _canContinue {
    if (!_numberValid) return false;
    final exists = ref.read(accountsProvider).contains(_number.text);
    return !exists || _pin.text.length == 5;
  }

  Future<void> _continue() async {
    if (!_canContinue || _loading.value) return;
    final phone = _number.text;

    if (!ref.read(accountsProvider).contains(phone)) {
      _showNoAccount(phone);
      return;
    }

    final access = PinAccess(ref.read(pinRepositoryProvider), phone);
    if (!access.hasPin) {
      // Account exists but the PIN is missing: verify the number and set a new PIN.
      await _startReset(phone);
      return;
    }

    _loading.value = true;
    try {
      final error = await verifyPinMessage(access, _pin.text);
      if (error != null) {
        HapticFeedback.heavyImpact();
        _shake.forward(from: 0);
        _pin.clear();
        _error.value = error;
        _tick.value++;
        return;
      }
      await ref.read(accountProvider.notifier).save(phone);
      await ref.read(sessionPhoneProvider.notifier).setPhone(phone);
      if (mounted) context.go('/home');
    } finally {
      if (mounted) _loading.value = false;
    }
  }

  Future<void> _startReset(String phone) async {
    _loading.value = true;
    try {
      await ref.read(authRepositoryProvider).sendOtp(phone);
      if (mounted) context.push('/otp?reset=1', extra: phone);
    } finally {
      if (mounted) _loading.value = false;
    }
  }

  Future<void> _forgotPin() async {
    final phone = _number.text;
    if (!_numberValid || !ref.read(accountsProvider).contains(phone)) {
      _error.value = 'Enter your registered number first.';
      _numFocus.requestFocus();
      return;
    }
    await _startReset(phone);
  }

  void _showNoAccount(String phone) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_add_alt_1_rounded,
                size: 44, color: AppColors.primary),
            const SizedBox(height: 12),
            const Tr('No account found',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Tr(
              'There is no PayBD account for $phone on this device. Create one in a minute.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Create account',
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.push('/register', extra: phone);
              },
            ),
            TextButton(
              onPressed: () => Navigator.of(sheetContext).pop(),
              child: const Tr('Use another number'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PinkAuthPage(
      title: 'Login to PayBD',
      trailing: const LanguageToggle(),
      body: Column(
        children: [
          AnimatedBuilder(
            animation: _shake,
            builder: (_, child) => Transform.translate(
              offset: Offset(
                math.sin(_shake.value * math.pi * 6) * 10 * (1 - _shake.value),
                0,
              ),
              child: child,
            ),
            child: FadeSlideIn(
              index: 0,
              child: AuthCard(
                child: Column(
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: _tick,
                      builder: (_, _, _) => PinkField(
                        label: 'Account Number',
                        controller: _number,
                        focus: _numFocus,
                        hint: '01XXXXXXXXX',
                        prefix: const Text('+88',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ValueListenableBuilder<bool>(
                      valueListenable: _obscure,
                      builder: (_, obscure, _) => PinkField(
                        label: 'PayBD PIN',
                        controller: _pin,
                        focus: _pinFocus,
                        hint: 'Enter PayBD PIN',
                        obscure: obscure,
                        suffix: GestureDetector(
                          onTap: () => _obscure.value = !obscure,
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    ValueListenableBuilder<String?>(
                      valueListenable: _error,
                      builder: (_, e, _) => AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        alignment: Alignment.topCenter,
                        child: e == null
                            ? const SizedBox(height: 12)
                            : Padding(
                                padding: const EdgeInsets.only(top: 10, bottom: 4),
                                child: Tr(e,
                                    style: const TextStyle(
                                        color: AppColors.error, fontSize: 12)),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            index: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _forgotPin,
                  child: const Tr('Forgot PIN? Try PIN Reset',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white)),
                ),
                GestureDetector(
                  onTap: () => context.push('/terms'),
                  child: const Tr('Terms & Privacy',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FadeSlideIn(
            index: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Tr('New to PayBD?',
                    style: TextStyle(color: Colors.white70)),
                TextButton(
                  onPressed: () => context.push('/register'),
                  child: const Tr('Create account',
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
                label: 'Continue',
                loading: loading,
                onPressed: _canContinue ? _continue : null,
              ),
            ),
          ),
          PayKeypad(kind: KeypadKind.next, onKey: _onKey),
        ],
      ),
    );
  }
}
