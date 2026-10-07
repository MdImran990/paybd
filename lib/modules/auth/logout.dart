import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_lock/app_lock_provider.dart';
import '../notifications/notification_providers.dart';
import '../profile/profile_providers.dart';
import '../savings/savings_providers.dart';
import '../settings/settings_providers.dart';
import '../wallet/wallet_providers.dart';
import 'auth_providers.dart';

/// Clears everything saved for the current user. The router guard then sends the
/// user to /login because the session becomes null.
Future<void> performLogout(WidgetRef ref) async {
  await ref.read(pinRepositoryProvider).clear();
  await ref.read(walletRepositoryProvider).reset();
  await ref.read(notificationsProvider.notifier).clear();
  await ref.read(savingsProvider.notifier).clear();
  await ref.read(profileNameProvider.notifier).clear();
  ref.invalidate(walletProvider);
  ref.invalidate(walletRepositoryProvider);
  ref.read(balanceRevealedProvider.notifier).hide();
  ref.read(appLockProvider.notifier).unlock();
  await ref.read(sessionPhoneProvider.notifier).logout();
}
