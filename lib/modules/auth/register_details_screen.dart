import 'package:flutter/material.dart';
import '../../core/i18n/tr.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/auth_header.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/primary_button.dart';
import '../notifications/notification_providers.dart';
import '../profile/profile_providers.dart';
import 'account_provider.dart';
import 'auth_providers.dart';

class RegisterDetailsScreen extends ConsumerStatefulWidget {
  final String phone;
  const RegisterDetailsScreen({super.key, required this.phone});

  @override
  ConsumerState<RegisterDetailsScreen> createState() =>
      _RegisterDetailsScreenState();
}

class _RegisterDetailsScreenState extends ConsumerState<RegisterDetailsScreen> {
  final _name = TextEditingController();
  final _valid = ValueNotifier<bool>(false);
  final _loading = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _name.dispose();
    _valid.dispose();
    _loading.dispose();
    super.dispose();
  }

  bool _isValidName(String v) {
    final t = v.trim();
    return t.length >= 3 && t.length <= 40 && !RegExp(r'\d').hasMatch(t);
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    final phone = widget.phone;
    FocusManager.instance.primaryFocus?.unfocus();
    _loading.value = true;

    // Grab everything first: the screen is replaced as soon as the session is set.
    final accounts = ref.read(accountsProvider.notifier);
    final lastAccount = ref.read(accountProvider.notifier);
    final session = ref.read(sessionPhoneProvider.notifier);
    final profileName = ref.read(profileNameProvider.notifier);
    final notifications = ref.read(notificationsProvider.notifier);
    try {
      // Other accounts on this device are never touched.
      await accounts.add(phone);
      await lastAccount.save(phone);
      // Log in first, so the name and welcome message are saved under THIS account.
      await session.setPhone(phone);
      await profileName.set(name);
      await notifications.addWelcomeIfEmpty();
      if (mounted) context.go('/pin-setup');
    } finally {
      if (mounted) _loading.value = false;
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
              title: 'Your details',
              subtitle: 'Number verified: ${widget.phone}',
              compact: keyboardOpen,
            ),
            Expanded(
              child: AuthSheet(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const FadeSlideIn(
                      index: 0,
                      child: Tr('What should we call you?',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      index: 1,
                      child: TextField(
                        controller: _name,
                        maxLength: 40,
                        textCapitalization: TextCapitalization.words,
                        onChanged: (v) => _valid.value = _isValidName(v),
                        onTapOutside: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        decoration: InputDecoration(
                          hintText: tr('Full name'),
                          counterText: '',
                          filled: true,
                          fillColor: AppColors.panel,
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FadeSlideIn(
                      index: 2,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.verified_user_outlined,
                                color: AppColors.primary, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Tr(
                                'This is a basic account. Identity verification (eKYC) will be added later to raise your limits.',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.textMuted),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    FadeSlideIn(
                      index: 3,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _loading,
                        builder: (_, loading, _) =>
                            ValueListenableBuilder<bool>(
                          valueListenable: _valid,
                          builder: (_, valid, _) => PrimaryButton(
                            label: 'Continue',
                            loading: loading,
                            onPressed: valid ? _create : null,
                          ),
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
