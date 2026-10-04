import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/transaction.dart';
import '../../data/repositories/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => MockWalletRepository(),
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

  Future<Transaction> send(String phone, int amountMinor) async {
    final repo = ref.read(walletRepositoryProvider);
    final tx = await repo.sendMoney(toPhone: phone, amountMinor: amountMinor);
    state = AsyncData(await _load());
    return tx;
  }
}

final walletProvider =
    AsyncNotifierProvider<WalletNotifier, WalletState>(WalletNotifier.new);

/// Balance in taka for display (Home balance card uses this).
final balanceProvider = Provider<AsyncValue<double>>(
  (ref) => ref.watch(walletProvider).whenData((w) => w.balanceMinor / 100),
);
