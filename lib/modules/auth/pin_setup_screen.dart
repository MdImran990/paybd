import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/pin_entry.dart';
import 'auth_providers.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String? _first;

  bool _isWeak(String pin) =>
      pin.split('').toSet().length == 1 ||
      '0123456789'.contains(pin) ||
      '9876543210'.contains(pin);

  Future<String?> _onPin(String pin) async {
    if (_first == null) {
      if (_isWeak(pin)) return 'Choose a less obvious PIN.';
      setState(() => _first = pin);
      return null;
    }
    if (pin != _first) {
      setState(() => _first = null);
      return 'PINs did not match. Start again.';
    }
    await ref.read(activePinProvider).setPin(pin);
    if (mounted) context.go('/home');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PinEntry(
          title: _first == null ? 'Create your PIN' : 'Confirm your PIN',
          subtitle: _first == null
              ? 'Choose a 5-digit PIN. You will need it to send money.'
              : 'Enter the same PIN again.',
          onCompleted: _onPin,
        ),
      ),
    );
  }
}
