import 'package:flutter/material.dart';
import '../../core/i18n/tr.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../core/widgets/fade_slide_in.dart';
import '../../core/widgets/continue_bar.dart';
import '../../core/widgets/language_toggle.dart';
import '../../core/widgets/pink_auth_page.dart';
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
    return PinkAuthPage(
      title: 'Your details',
      trailing: const LanguageToggle(),
      body: Column(
        children: [
          FadeSlideIn(
            index: 0,
            child: AuthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Tr('Number verified: ${widget.phone}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 14),
                  const Tr('What should we call you?',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _name,
                    maxLength: 40,
                    textCapitalization: TextCapitalization.words,
                    onChanged: (v) => _valid.value = _isValidName(v),
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: tr('Full name'),
                      counterText: '',
                      filled: false,
                      prefixIcon: const Icon(Icons.person_outline_rounded,
                          color: AppColors.primary),
                      enabledBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFE5E5EC)),
                      ),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            index: 1,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.verified_user_outlined,
                      color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Tr(
                      'This is a basic account. Identity verification (eKYC) will be added later to raise your limits.',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottom: ColoredBox(
        color: AppColors.primary,
        child: SafeArea(
          top: false,
          child: ValueListenableBuilder<bool>(
            valueListenable: _loading,
            builder: (_, loading, _) => ValueListenableBuilder<bool>(
              valueListenable: _valid,
              builder: (_, valid, _) => ContinueBar(
                label: 'Continue',
                loading: loading,
                onPressed: valid ? _create : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
