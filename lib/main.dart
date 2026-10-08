import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/routes/app_router.dart';
import 'app/theme/app_theme.dart';
import 'core/i18n/app_language.dart';
import 'core/storage/prefs.dart';
import 'data/repositories/pin_repository.dart';
import 'modules/app_lock/app_lock_provider.dart';
import 'modules/app_lock/lock_overlay.dart';
import 'modules/auth/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  initLanguage(prefs);
  final pinRepo = await SecurePinRepository.create(prefs);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        pinRepositoryProvider.overrideWithValue(pinRepo),
      ],
      child: const PayBdApp(),
    ),
  );
}

class PayBdApp extends ConsumerStatefulWidget {
  const PayBdApp({super.key});

  @override
  ConsumerState<PayBdApp> createState() => _PayBdAppState();
}

class _PayBdAppState extends ConsumerState<PayBdApp>
    with WidgetsBindingObserver {
  static const _lockAfter = Duration(seconds: 30);
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final t = _pausedAt;
      _pausedAt = null;
      if (t != null && DateTime.now().difference(t) >= _lockAfter) {
        ref.read(appLockProvider.notifier).lock();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'PayBD',
      theme: AppTheme.light,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => Stack(
        children: [
          child ?? const SizedBox.shrink(),
          Consumer(
            builder: (_, ref, _) => ref.watch(appLockProvider)
                ? const Positioned.fill(child: LockOverlay())
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
