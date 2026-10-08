import 'package:flutter/material.dart';
import '../../core/i18n/tr.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_colors.dart';
import '../../core/utils/pin_verify.dart';
import '../../core/widgets/pin_entry.dart';
import '../auth/auth_providers.dart';
import '../auth/logout.dart';
import 'app_lock_provider.dart';

/// Full-screen PIN lock drawn above the whole app (so the page behind keeps its state).
class LockOverlay extends ConsumerStatefulWidget {
  const LockOverlay({super.key});

  @override
  ConsumerState<LockOverlay> createState() => _LockOverlayState();
}

class _LockOverlayState extends ConsumerState<LockOverlay> {
  bool _confirmLogout = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PinEntry(
                title: 'Welcome back',
                subtitle: 'Enter your PIN to unlock PayBD',
                onCompleted: (pin) async {
                  final error = await verifyPinMessage(
                      ref.read(pinRepositoryProvider), pin);
                  if (error != null) return error;
                  ref.read(appLockProvider.notifier).unlock();
                  return null;
                },
              ),
            ),
            if (!_confirmLogout)
              TextButton(
                onPressed: () => setState(() => _confirmLogout = true),
                child: const Tr('Forgot PIN? Log out'),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Column(
                  children: [
                    const Tr(
                      'Log out? Then tap "Forgot PIN?" on the login page to set a new PIN.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () =>
                              setState(() => _confirmLogout = false),
                          child: const Tr('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => performLogout(ref),
                          child: const Tr('Log out',
                              style: TextStyle(color: AppColors.error)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
