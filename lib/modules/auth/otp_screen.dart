import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/i18n/tr.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/utils/numeric_input.dart';
import '../../core/widgets/continue_bar.dart';
import '../../core/widgets/pay_keypad.dart';
import '../../core/widgets/pink_auth_page.dart';
import '../notifications/notification_providers.dart';
import 'auth_providers.dart';

const _otpLength = 6;
const _resendSeconds = 30;

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;

  /// true = the user forgot the PIN: after the OTP they create a new PIN.
  final bool resetPin;

  /// true = new account: after the OTP the user fills in their details.
  final bool register;
  const OtpScreen({
    super.key,
    required this.phone,
    this.resetPin = false,
    this.register = false,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();
  Timer? _timer;
  int _seconds = _resendSeconds;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _seconds = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 1) {
        t.cancel();
      }
      if (mounted) setState(() => _seconds--);
    });
  }

  Future<void> _resend() async {
    await ref.read(authRepositoryProvider).sendOtp(widget.phone);
    _controller.clear();
    setState(() => _error = null);
    _startTimer();
  }

  Future<void> _verify() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ok = await ref
          .read(authRepositoryProvider)
          .verifyOtp(widget.phone, _controller.text);
      if (!mounted) return;
      if (ok) {
        if (widget.register) {
          context.go('/register/details', extra: widget.phone);
          return;
        }
        if (widget.resetPin) {
          // The OTP proves the user owns this number, so this also logs them in.
          ref.read(sessionPhoneProvider.notifier).setPhone(widget.phone);
          context.go('/pin-setup');
          return;
        }
        ref.read(sessionPhoneProvider.notifier).setPhone(widget.phone);
        ref.read(notificationsProvider.notifier).addWelcomeIfEmpty();
        final hasPin = ref.read(activePinProvider).hasPin;
        context.go(hasPin ? '/home' : '/pin-setup');
      } else {
        HapticFeedback.heavyImpact();
        _controller.clear();
        setState(() => _error = 'Wrong OTP. Please try again.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onKey(String key) {
    if (key == 'next') return;
    if (applyKey(_controller, key, maxLength: _otpLength)) {
      setState(() => _error = null);
      if (_controller.text.length == _otpLength) _verify();
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _controller.text;
    return PinkAuthPage(
      title: 'Verify your number',
      showBack: true,
      body: Column(
        children: [
          FadeSlideIn(
            index: 0,
            child: AuthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tr('Enter the 6-digit code sent to ${widget.phone}',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textMuted)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < _otpLength; i++)
                        _OtpBox(
                          char: i < code.length ? code[i] : '',
                          active: i == code.length,
                          error: _error != null,
                        ),
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    alignment: Alignment.topCenter,
                    child: _error == null
                        ? const SizedBox(height: 14)
                        : Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Tr(_error!,
                                style: const TextStyle(color: AppColors.error)),
                          ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _seconds > 0
                          ? Tr('Resend code in ${_seconds}s',
                              key: const ValueKey('timer'),
                              style:
                                  const TextStyle(color: AppColors.textMuted))
                          : TextButton(
                              key: const ValueKey('resend'),
                              onPressed: _resend,
                              child: const Tr('Resend code'),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            index: 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Tr(
                'DEMO MODE: use code 123456. No real SMS is sent.',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ContinueBar(
            label: 'Verify',
            loading: _loading,
            onPressed: code.length == _otpLength ? _verify : null,
          ),
          PayKeypad(kind: KeypadKind.pin, onKey: _onKey),
        ],
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final String char;
  final bool active;
  final bool error;
  const _OtpBox({
    required this.char,
    required this.active,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: char.isNotEmpty ? 1.08 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 40,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: error
                ? AppColors.error
                : active
                    ? AppColors.primary
                    : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Tr(char,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
