import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../i18n/tr.dart';

/// Full-width pink "Continue →" bar that sits right above the keypad.
class ContinueBar extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  const ContinueBar({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    return Material(
      color: AppColors.primary,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: AnimatedOpacity(
          opacity: onPressed == null && !loading ? 0.55 : 1,
          duration: const Duration(milliseconds: 200),
          child: SizedBox(
            height: 58,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Tr(label,
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: loading
                        ? const SizedBox(
                            key: ValueKey('loading'),
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.2, color: Colors.white),
                          )
                        : const Icon(Icons.arrow_forward_rounded,
                            key: ValueKey('arrow'),
                            color: Colors.white,
                            size: 22),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
