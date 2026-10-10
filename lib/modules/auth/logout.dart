import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app_lock/app_lock_provider.dart';
import '../nominee/nominee_provider.dart';
import '../notifications/notification_providers.dart';
import '../profile/profile_photo.dart';
import '../profile/profile_providers.dart';
import '../savings/savings_providers.dart';
import '../settings/settings_providers.dart';
import '../wallet/wallet_providers.dart';
import 'account_provider.dart';
import 'auth_providers.dart';

/// Ends the session only. The account, PIN, transactions and documents stay on the
/// device (like a server would keep them). The router guard sends the user to /login.
Future<void> performLogout(WidgetRef ref) async {
  ref.read(balanceRevealedProvider.notifier).hide();
  ref.read(appLockProvider.notifier).unlock();
  await ref.read(sessionPhoneProvider.notifier).logout();
}

/// Permanently deletes the logged-in account from this device. Only called after the
/// user typed DELETE. Other accounts on the device are not touched.
Future<void> deleteCurrentAccount(WidgetRef ref) async {
  final phone = ref.read(sessionPhoneProvider);
  if (phone == null) return;

  await ref.read(activePinProvider).clear();
  await ref.read(walletRepositoryProvider).reset();
  await ref.read(notificationsProvider.notifier).clear();
  await ref.read(savingsProvider.notifier).clear();
  await ref.read(profileNameProvider.notifier).clear();
  await ref.read(profilePhotoProvider.notifier).remove();
  await ref.read(nomineeProvider.notifier).remove();
  ref.read(biometricEnabledProvider.notifier).set(false);
  ref.invalidate(walletProvider);
  ref.invalidate(walletRepositoryProvider);

  await ref.read(accountsProvider.notifier).remove(phone);
  if (ref.read(accountProvider) == phone) {
    await ref.read(accountProvider.notifier).clear();
  }
  await performLogout(ref);
}
