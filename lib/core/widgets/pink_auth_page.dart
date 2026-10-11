import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/app_colors.dart';
import '../i18n/tr.dart';
import 'floating_bubbles.dart';
import 'pay_app_bar.dart';

/// Login / registration / OTP layout: pink page, white card in the middle,
/// "Continue" bar and number keypad at the bottom.
class PinkAuthPage extends StatelessWidget {
  final String title;
  final bool showBack;
  final Widget? trailing;
  final Widget body;
  final Widget bottom;

  const PinkAuthPage({
    super.key,
    required this.title,
    required this.body,
    required this.bottom,
    this.showBack = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              const Positioned.fill(
                child: RepaintBoundary(child: FloatingBubbles()),
              ),
              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(showBack ? 4 : 20, top + 8, 16, 0),
                    child: Row(
                      children: [
                        if (showBack)
                          BackButton(
                            color: Colors.white,
                            onPressed: () => goBackOrHome(context),
                          )
                        else
                          const _Logo(),
                        const Spacer(),
                        ?trailing,
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 14),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Tr(title,
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: body,
                    ),
                  ),
                  bottom,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.account_balance_wallet_rounded,
              color: AppColors.primary, size: 22),
        ),
        const SizedBox(width: 10),
        const Text('PayBD',
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
      ],
    );
  }
}

/// White card used on the pink pages.
class AuthCard extends StatelessWidget {
  final Widget child;
  const AuthCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
              color: Color(0x22000000), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );
  }
}

/// Underlined field that is typed with the on-screen keypad (no system keyboard).
class PinkField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final FocusNode focus;
  final String hint;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscure;
  final VoidCallback? onTap;

  const PinkField({
    super.key,
    required this.label,
    required this.controller,
    required this.focus,
    required this.hint,
    this.prefix,
    this.suffix,
    this.obscure = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: focus,
      builder: (_, _) {
        final active = focus.hasFocus;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Tr(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.primary : AppColors.textMuted)),
            Row(
              children: [
                if (prefix != null) ...[prefix!, const SizedBox(width: 8)],
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focus,
                    keyboardType: TextInputType.none,
                    obscureText: obscure,
                    obscuringCharacter: '•',
                    enableInteractiveSelection: false,
                    cursorColor: AppColors.primary,
                    onTap: onTap,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: 1),
                    decoration: InputDecoration(
                      hintText: tr(hint),
                      hintStyle: const TextStyle(
                          fontWeight: FontWeight.w400,
                          color: AppColors.textMuted,
                          letterSpacing: 0),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                ?suffix,
              ],
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: active ? 2 : 1,
              color: active ? AppColors.primary : const Color(0xFFE5E5EC),
            ),
          ],
        );
      },
    );
  }
}
