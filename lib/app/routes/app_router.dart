import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/transaction.dart';
import '../../modules/auth/login_screen.dart';
import '../../modules/auth/otp_screen.dart';
import '../../modules/auth/pin_setup_screen.dart';
import '../../modules/home/home_screen.dart';
import '../../modules/onboarding/onboarding_screen.dart';
import '../../modules/send_money/confirm_send_screen.dart';
import '../../modules/send_money/receipt_screen.dart';
import '../../modules/send_money/send_money_screen.dart';
import '../../modules/send_money/send_payload.dart';
import '../../modules/send_money/send_pin_screen.dart';
import '../../modules/splash/splash_screen.dart';
import '../../modules/transactions/history_screen.dart';

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

CustomTransitionPage<void> _slide(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, _, child) => SlideTransition(
      position: Tween(begin: const Offset(1, 0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic))
          .animate(animation),
      child: child,
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
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
        path: '/otp',
        pageBuilder: (_, s) =>
            _slide(s, OtpScreen(phone: (s.extra as String?) ?? '')),
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
        pageBuilder: (_, s) => _slide(s, const SendMoneyScreen()),
      ),
      GoRoute(
        path: '/send/confirm',
        pageBuilder: (_, s) {
          final p = s.extra;
          return _slide(
            s,
            p is SendPayload ? ConfirmSendScreen(payload: p) : const SendMoneyScreen(),
          );
        },
      ),
      GoRoute(
        path: '/send/pin',
        pageBuilder: (_, s) {
          final p = s.extra;
          return _slide(
            s,
            p is SendPayload ? SendPinScreen(payload: p) : const SendMoneyScreen(),
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
    ],
  );
});
