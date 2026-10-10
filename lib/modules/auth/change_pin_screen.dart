import 'package:flutter/material.dart';
import '../../core/i18n/tr.dart';
import '../../core/widgets/pay_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/pin_entry.dart';
import 'auth_providers.dart';

class ChangePinScreen extends ConsumerStatefulWidget {
  const ChangePinScreen({super.key});

  @override
  ConsumerState<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends ConsumerState<ChangePinScreen> {
  int _stage = 0; // 0 current PIN, 1 new PIN, 2 confirm new PIN
  String? _current;
  String? _new;

  static const _titles = ['Enter current PIN', 'Create new PIN', 'Confirm new PIN'];
  static const _subtitles = [
    'Verify it is you before changing your PIN.',
    'Choose a new 5-digit PIN.',
    'Enter the new PIN again.',
  ];

  Future<String?> _onPin(String pin) async {
    final repo = ref.read(activePinProvider);

    if (_stage == 0) {
      final r = await repo.verifyPin(pin);
      if (r.locked) {
        final mins = (r.lockedFor!.inSeconds / 60).ceil();
        return 'Too many wrong attempts. Try again in $mins min.';
      }
      if (!r.ok) return 'Wrong PIN. ${r.attemptsLeft} attempts left.';
      if (mounted) {
        setState(() {
          _current = pin;
          _stage = 1;
        });
      }
      return null;
    }

    if (_stage == 1) {
      if (isWeakPin(pin)) return 'Choose a less obvious PIN.';
      if (pin == _current) return 'New PIN must be different.';
      setState(() {
        _new = pin;
        _stage = 2;
      });
      return null;
    }

    if (pin != _new) {
      setState(() {
        _new = null;
        _stage = 1;
      });
      return 'PINs did not match. Try again.';
    }
    await repo.setPin(pin);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Tr('PIN changed')));
      context.pop();
    }
    return null;
  }

  Future<void> _forgotPin() async {
    final phone = ref.read(sessionPhoneProvider);
    if (phone == null) return;
    await ref.read(authRepositoryProvider).sendOtp(phone);
    if (mounted) context.push('/otp?reset=1', extra: phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PayAppBar(
        actions: [
          if (_stage == 0)
            TextButton(
              onPressed: _forgotPin,
              child: const Tr('Forgot PIN?'),
            ),
        ],
      ),
      body: SafeArea(
        child: PinEntry(
          title: _titles[_stage],
          subtitle: _subtitles[_stage],
          onCompleted: _onPin,
        ),
      ),
    );
  }
}
