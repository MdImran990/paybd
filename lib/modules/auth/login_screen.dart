import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/primary_button.dart';
import 'auth_providers.dart';

final _bdPhone = RegExp(r'^01[3-9]\d{8}$');

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _valid = ValueNotifier<bool>(false);
  final _loading = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _phone.dispose();
    _valid.dispose();
    _loading.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final phone = _phone.text.trim();
    _loading.value = true;
    try {
      await ref.read(authRepositoryProvider).sendOtp(phone);
      if (mounted) context.push('/otp', extra: phone);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send OTP. Try again.')),
        );
      }
    } finally {
      _loading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const Text('Welcome to PayBD',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Enter your mobile number to continue.',
                  style: TextStyle(color: AppColors.textMuted)),
              const SizedBox(height: 36),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                autofocus: true,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                onChanged: (v) => _valid.value = _bdPhone.hasMatch(v),
                style: const TextStyle(fontSize: 18, letterSpacing: 1),
                decoration: InputDecoration(
                  hintText: '01XXXXXXXXX',
                  prefixIcon: const Icon(Icons.phone_android_rounded),
                  filled: true,
                  fillColor: AppColors.panel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const Spacer(),
              ValueListenableBuilder<bool>(
                valueListenable: _loading,
                builder: (_, loading, _) => ValueListenableBuilder<bool>(
                  valueListenable: _valid,
                  builder: (_, valid, _) => PrimaryButton(
                    label: 'Continue',
                    loading: loading,
                    onPressed: valid ? _submit : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
