import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/prefs.dart';
import '../../data/models/payment_request.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/wallet_repository.dart';
import '../auth/auth_providers.dart';

/// One wallet per account: it changes automatically when another number logs in.
final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final phone = ref.watch(sessionPhoneProvider);
  return MockWalletRepository(
    ref.watch(sharedPreferencesProvider),
    phone ?? 'guest',
  );
});

class WalletState {
  final int balanceMinor;
  final List<Transaction> transactions;
  const WalletState({required this.balanceMinor, required this.transactions});
}

class WalletNotifier extends AsyncNotifier<WalletState> {
  @override
  Future<WalletState> build() => _load(ref.watch(walletRepositoryProvider));

  Future<WalletState> _load(WalletRepository repo) async {
    return WalletState(
      balanceMinor: await repo.getBalance(),
      transactions: await repo.getTransactions(),
    );
  }

  /// Runs any payment and refreshes the wallet.
  Future<Transaction> pay(PaymentRequest request) async {
    final repo = ref.read(walletRepositoryProvider);
    final tx = await repo.submit(request);
    state = AsyncData(await _load(repo));
    return tx;
  }
}

final walletProvider =
    AsyncNotifierProvider<WalletNotifier, WalletState>(WalletNotifier.new);
