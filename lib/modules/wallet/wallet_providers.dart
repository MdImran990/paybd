import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => MockWalletRepository(),
);

final balanceProvider = FutureProvider<double>(
  (ref) => ref.watch(walletRepositoryProvider).getBalance(),
);
