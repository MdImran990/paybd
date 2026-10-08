import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
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
  final _focus = FocusNode();
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
    _focus.dispose();
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
        final hasPin = ref.read(pinRepositoryProvider).hasPin;
        context.go(hasPin ? '/home' : '/pin-setup');
      } else {
        _controller.clear();
        setState(() => _error = 'Wrong OTP. Please try again.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _controller.text;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Verify your number',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('Enter the 6-digit code sent to ${widget.phone}',
                  style: const TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => _focus.requestFocus(),
                child: Stack(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 0; i < _otpLength; i++)
                          _OtpBox(
                            char: i < code.length ? code[i] : '',
                            active: i == code.length && _focus.hasFocus,
                            error: _error != null,
                          ),
                      ],
                    ),
                    // Hidden field that receives the typing
                    SizedBox(
                      width: 1,
                      height: 1,
                      child: Opacity(
                        opacity: 0,
                        child: TextField(
                          controller: _controller,
                          focusNode: _focus,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(_otpLength),
                          ],
                          onChanged: (v) {
                            setState(() => _error = null);
                            if (v.length == _otpLength) _verify();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 20),
              Center(
                child: _seconds > 0
                    ? Text('Resend code in ${_seconds}s',
                        style: const TextStyle(color: AppColors.textMuted))
                    : TextButton(
                        onPressed: _resend,
                        child: const Text('Resend code'),
                      ),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'DEMO MODE: use code 123456. No real SMS is sent.',
                  style: TextStyle(fontSize: 12, color: AppColors.yellow),
                ),
              ),
              PrimaryButton(
                label: 'Verify',
                loading: _loading,
                onPressed: code.length == _otpLength ? _verify : null,
              ),
            ],
          ),
        ),
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
      width: 48,
      height: 58,
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
      child: Text(char,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
    ),
    );
  }
}
