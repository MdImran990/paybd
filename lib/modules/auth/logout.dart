import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_lock/app_lock_provider.dart';
import '../notifications/notification_providers.dart';
import '../profile/profile_providers.dart';
import '../savings/savings_providers.dart';
import '../settings/settings_providers.dart';
import '../wallet/wallet_providers.dart';
import 'account_provider.dart';
import 'auth_providers.dart';

/// Ends the session only. The account, PIN and data stay on the device (like a
/// server would keep them). The router guard sends the user to /login.
Future<void> performLogout(WidgetRef ref) async {
  ref.read(balanceRevealedProvider.notifier).hide();
  ref.read(appLockProvider.notifier).unlock();
  await ref.read(sessionPhoneProvider.notifier).logout();
}

/// Deletes the PIN and every demo record (used when a different number registers).
Future<void> wipeUserData(WidgetRef ref) async {
  await ref.read(pinRepositoryProvider).clear();
  await ref.read(walletRepositoryProvider).reset();
  await ref.read(notificationsProvider.notifier).clear();
  await ref.read(savingsProvider.notifier).clear();
  await ref.read(profileNameProvider.notifier).clear();
  ref.invalidate(walletProvider);
  ref.invalidate(walletRepositoryProvider);
  ref.read(biometricEnabledProvider.notifier).set(false);
}

/// Erases the account and all data from this device, then logs out.
Future<void> performEraseAll(WidgetRef ref) async {
  await wipeUserData(ref);
  await ref.read(accountProvider.notifier).clear();
  await performLogout(ref);
}
