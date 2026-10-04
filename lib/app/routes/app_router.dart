import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../modules/auth/login_screen.dart';
import '../../modules/auth/otp_screen.dart';
import '../../modules/home/home_screen.dart';
import '../../modules/onboarding/onboarding_screen.dart';
import '../../modules/splash/splash_screen.dart';

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
        path: '/home',
        pageBuilder: (_, s) => _fade(s, const HomeScreen()),
      ),
    ],
  );
});
