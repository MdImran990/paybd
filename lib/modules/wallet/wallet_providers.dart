import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/prefs.dart';
import '../../data/models/payment_request.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => MockWalletRepository(ref.watch(sharedPreferencesProvider)),
);

class WalletState {
  final int balanceMinor;
  final List<Transaction> transactions;
  const WalletState({required this.balanceMinor, required this.transactions});
}

class WalletNotifier extends AsyncNotifier<WalletState> {
  @override
  Future<WalletState> build() => _load();

  Future<WalletState> _load() async {
    final repo = ref.read(walletRepositoryProvider);
    return WalletState(
      balanceMinor: await repo.getBalance(),
      transactions: await repo.getTransactions(),
    );
  }

  /// Runs any payment and refreshes the wallet.
  Future<Transaction> pay(PaymentRequest request) async {
    final repo = ref.read(walletRepositoryProvider);
    final tx = await repo.submit(request);
    state = AsyncData(await _load());
    return tx;
  }
}

final walletProvider =
    AsyncNotifierProvider<WalletNotifier, WalletState>(WalletNotifier.new);
