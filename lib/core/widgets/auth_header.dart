import 'package:flutter/material.dart';
import '../i18n/tr.dart';
import '../../app/theme/app_colors.dart';
import 'floating_bubbles.dart';
import 'pay_app_bar.dart';

/// Pink header used by the login / registration pages.
/// [compact] shrinks it (used while the keyboard is open).
class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool compact;
  final bool showBack;
  final Widget? trailing;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.compact = false,
    this.showBack = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      height: (compact ? 140.0 : 250.0) + top,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRect(
        child: Stack(
          children: [
            const Positioned.fill(child: FloatingBubbles()),
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.fromLTRB(24, top + 8, 24, 22),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: SingleChildScrollView(
                    reverse: true,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!compact) ...[
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Tr('PayBD',
                                  style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 18),
                        ],
                        Tr(title,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Tr(subtitle,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.white70)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (trailing != null)
              Positioned(top: top + 10, right: 16, child: trailing!),
            if (showBack)
              Positioned(
                top: top + 2,
                left: 4,
                child: BackButton(
                  color: Colors.white,
                  onPressed: () => goBackOrHome(context),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Rounded light sheet that sits under [AuthHeader]. Put it in an Expanded.
class AuthSheet extends StatelessWidget {
  final Widget child;
  final bool scrollable;

  const AuthSheet({super.key, required this.child, this.scrollable = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: scrollable
            ? SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                child: child,
              )
            : child,
      ),
    );
  }
}
