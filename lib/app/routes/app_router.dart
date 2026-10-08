import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/transaction.dart';
import '../../modules/auth/change_pin_screen.dart';
import '../../modules/auth/login_pin_screen.dart';
import '../../modules/auth/login_screen.dart';
import '../../modules/auth/register_details_screen.dart';
import '../../modules/auth/register_screen.dart';
import '../../modules/auth/otp_screen.dart';
import '../../modules/auth/pin_setup_screen.dart';
import '../../modules/auth/auth_providers.dart';
import '../../modules/home/home_screen.dart';
import '../../modules/notifications/inbox_screen.dart';
import '../../modules/onboarding/onboarding_screen.dart';
import '../../modules/savings/savings_screen.dart';
import '../../modules/support/help_screen.dart';
import '../../modules/support/terms_screen.dart';
import '../../modules/profile/profile_screen.dart';
import '../../modules/qr/qr_payload.dart';
import '../../modules/qr/qr_screen.dart';
import '../../modules/payment/confirm_payment_screen.dart';
import '../../modules/payment/payment_entry_screens.dart';
import '../../modules/payment/payment_pin_screen.dart';
import '../../modules/payment/receipt_screen.dart';
import '../../data/models/payment_request.dart';
import '../../modules/settings/settings_screen.dart';
import '../../modules/splash/splash_screen.dart';
import '../../modules/transactions/history_screen.dart';

/// The page underneath slides left a little while a new page comes in.
Widget _parallaxExit(Animation<double> secondary, Widget child) {
  return SlideTransition(
    position: Tween<Offset>(begin: Offset.zero, end: const Offset(-0.18, 0))
        .animate(secondary.drive(CurveTween(curve: Curves.easeOutCubic))),
    child: child,
  );
}

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, secondary, child) => _parallaxExit(
      secondary,
      FadeTransition(
        opacity: animation.drive(CurveTween(curve: Curves.easeOut)),
        child: child,
      ),
    ),
  );
}

CustomTransitionPage<void> _slide(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, secondary, child) {
      final enter = animation.drive(CurveTween(curve: Curves.easeOutCubic));
      return _parallaxExit(
        secondary,
        SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.25, 0), end: Offset.zero)
              .animate(enter),
          child: FadeTransition(opacity: enter, child: child),
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run the redirect whenever the session changes (login / logout).
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen<String?>(sessionPhoneProvider, (_, _) => refresh.value++);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = ref.read(sessionPhoneProvider) != null;
      final path = state.matchedLocation;
      const publicPaths = {
        '/',
        '/onboarding',
        '/login',
        '/login/pin',
        '/register',
        '/register/details',
        '/otp',
        '/terms',
      };
      final hasPin = ref.read(pinRepositoryProvider).hasPin;
      if (!loggedIn && !publicPaths.contains(path)) return '/login';
      // Logged in but the PIN was never created (app closed during setup).
      if (loggedIn && !hasPin && path != '/pin-setup' && path != '/otp') {
        return '/pin-setup';
      }
      if (loggedIn &&
          (path == '/login' ||
              path == '/login/pin' ||
              path == '/register' ||
              path == '/onboarding')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (_, s) => _fade(s, const SplashScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (_, s) => _fade(s, const OnboardingScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (_, s) => _fade(s, const LoginScreen()),
      ),
      GoRoute(
        path: '/login/pin',
        pageBuilder: (_, s) {
          final p = s.extra;
          return _slide(
            s,
            p is String ? LoginPinScreen(phone: p) : const LoginScreen(),
          );
        },
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (_, s) => _slide(
          s,
          RegisterScreen(initialPhone: s.extra is String ? s.extra as String : null),
        ),
      ),
      GoRoute(
        path: '/register/details',
        pageBuilder: (_, s) {
          final p = s.extra;
          return _fade(
            s,
            p is String ? RegisterDetailsScreen(phone: p) : const RegisterScreen(),
          );
        },
      ),
      GoRoute(
        path: '/otp',
        pageBuilder: (_, s) =>
            _slide(
          s,
          OtpScreen(
            phone: (s.extra as String?) ?? '',
            resetPin: s.uri.queryParameters['reset'] == '1',
            register: s.uri.queryParameters['mode'] == 'register',
          ),
        ),
      ),
      GoRoute(
        path: '/pin-setup',
        pageBuilder: (_, s) => _fade(s, const PinSetupScreen()),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (_, s) => _fade(s, const HomeScreen()),
      ),
      GoRoute(
        path: '/send',
        pageBuilder: (_, s) {
          final e = s.extra;
          return _slide(
            s,
            SendMoneyScreen(prefill: e is QrPayload ? e : null),
          );
        },
      ),
      GoRoute(
        path: '/qr',
        pageBuilder: (_, s) => _slide(
          s,
          QrScreen(
            initialTab: s.uri.queryParameters['tab'] == 'scan' ? 1 : 0,
          ),
        ),
      ),
      GoRoute(
        path: '/cash-out',
        pageBuilder: (_, s) => _slide(s, const CashOutScreen()),
      ),
      GoRoute(
        path: '/add-money',
        pageBuilder: (_, s) => _slide(s, const AddMoneyScreen()),
      ),
      GoRoute(
        path: '/recharge',
        pageBuilder: (_, s) => _slide(s, const RechargeScreen()),
      ),
      GoRoute(
        path: '/pay-bill',
        pageBuilder: (_, s) => _slide(s, const PayBillScreen()),
      ),
      GoRoute(
        path: '/donation',
        pageBuilder: (_, s) => _slide(s, const DonationScreen()),
      ),
      GoRoute(
        path: '/education',
        pageBuilder: (_, s) => _slide(s, const EducationFeeScreen()),
      ),
      GoRoute(
        path: '/savings',
        pageBuilder: (_, s) => _slide(s, const SavingsScreen()),
      ),
      GoRoute(
        path: '/savings/add',
        pageBuilder: (_, s) => _slide(
          s,
          SavingsDepositScreen(goalName: s.extra is String ? s.extra as String : null),
        ),
      ),
      GoRoute(
        path: '/inbox',
        pageBuilder: (_, s) => _slide(s, const InboxScreen()),
      ),
      GoRoute(
        path: '/help',
        pageBuilder: (_, s) => _slide(s, const HelpScreen()),
      ),
      GoRoute(
        path: '/terms',
        pageBuilder: (_, s) => _slide(s, const TermsScreen()),
      ),
      GoRoute(
        path: '/pay/confirm',
        pageBuilder: (_, s) {
          final p = s.extra;
          return _slide(
            s,
            p is PaymentRequest
                ? ConfirmPaymentScreen(request: p)
                : const HomeScreen(),
          );
        },
      ),
      GoRoute(
        path: '/pay/pin',
        pageBuilder: (_, s) {
          final p = s.extra;
          return _slide(
            s,
            p is PaymentRequest
                ? PaymentPinScreen(request: p)
                : const HomeScreen(),
          );
        },
      ),
      GoRoute(
        path: '/receipt',
        pageBuilder: (_, s) {
          final t = s.extra;
          return _fade(
            s,
            t is Transaction ? ReceiptScreen(tx: t) : const HomeScreen(),
          );
        },
      ),
      GoRoute(
        path: '/history',
        pageBuilder: (_, s) => _slide(s, const HistoryScreen()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (_, s) => _slide(s, const ProfileScreen()),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (_, s) => _slide(s, const SettingsScreen()),
      ),
      GoRoute(
        path: '/change-pin',
        pageBuilder: (_, s) => _slide(s, const ChangePinScreen()),
      ),
    ],
  );
});
