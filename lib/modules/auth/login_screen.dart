import 'package:flutter/material.dart';
import '../../core/i18n/tr.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/auth_header.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/language_toggle.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/repositories/pin_repository.dart';
import 'account_provider.dart';
import 'auth_providers.dart';

/// Shared phone field used by the login and registration pages.
class PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool autofocus;

  const PhoneField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(11),
      ],
      onChanged: onChanged,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      style: const TextStyle(
          fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1),
      decoration: InputDecoration(
        hintText: '01XXXXXXXXX',
        filled: true,
        fillColor: AppColors.panel,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16, right: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tr('+88',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: AppColors.primary)),
              SizedBox(width: 10),
              SizedBox(
                height: 22,
                child: VerticalDivider(width: 1, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

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
  void initState() {
    super.initState();
    // Remember the account on this device, like the bKash app does.
    final saved = ref.read(accountProvider);
    if (saved != null) {
      _phone.text = saved;
      _valid.value = bdPhoneRegExp.hasMatch(saved);
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _valid.dispose();
    _loading.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final phone = _phone.text.trim();
    final hasAccount = ref.read(accountsProvider).contains(phone);
    FocusManager.instance.primaryFocus?.unfocus();

    if (hasAccount) {
      if (PinAccess(ref.read(pinRepositoryProvider), phone).hasPin) {
        context.push('/login/pin', extra: phone);
      } else {
        // Account exists but the PIN is missing: verify the number and set a new PIN.
        _loading.value = true;
        try {
          await ref.read(authRepositoryProvider).sendOtp(phone);
          if (mounted) context.push('/otp?reset=1', extra: phone);
        } finally {
          _loading.value = false;
        }
      }
      return;
    }

    if (!mounted) return;
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
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Column(
          children: [
            AuthHeader(
              title: 'Login',
              subtitle: 'Log in to your PayBD account',
              compact: keyboardOpen,
              trailing: const LanguageToggle(),
            ),
            Expanded(
              child: AuthSheet(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeSlideIn(
                      index: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Tr('Enter your mobile number',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800)),
                          SizedBox(height: 4),
                          Tr('We will ask for your PIN next.',
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
                            _valid.value = bdPhoneRegExp.hasMatch(v),
                      ),
                    ),
                    const SizedBox(height: 22),
                    FadeSlideIn(
                      index: 2,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _loading,
                        builder: (_, loading, _) =>
                            ValueListenableBuilder<bool>(
                          valueListenable: _valid,
                          builder: (_, valid, _) => PrimaryButton(
                            label: 'Next',
                            loading: loading,
                            onPressed: valid ? _next : null,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FadeSlideIn(
                      index: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Tr('New to PayBD?',
                              style: TextStyle(color: AppColors.textMuted)),
                          TextButton(
                            onPressed: () => context.push('/register'),
                            child: const Tr('Create account',
                                style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: () => context.push('/terms'),
                        child: const Tr(
                          'Terms & Privacy',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
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
