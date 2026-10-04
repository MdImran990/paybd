import '../models/transaction.dart';

class WalletException implements Exception {
  final String message;
  const WalletException(this.message);
  @override
  String toString() => message;
}

/// DEMO limits. Real limits must come from the server / regulations.
class WalletLimits {
  static const minSendMinor = 1000; // ৳10
  static const maxSendMinor = 2500000; // ৳25,000
}

/// UI and providers talk only to this interface.
/// Today: MockWalletRepository. Later: ApiWalletRepository.
/// Money amounts are ints in paisa.
abstract class WalletRepository {
  Future<int> getBalance();
  Future<List<Transaction>> getTransactions();
  Future<Transaction> sendMoney({
    required String toPhone,
    required int amountMinor,
  });
}

/// DEMO ONLY. In-memory data, reset when the app restarts. Not real money.
/// The real balance and every validation must live on the server.
class MockWalletRepository implements WalletRepository {
  int _balance = 1600300; // ৳16,003.00
  final List<Transaction> _txs = [];

  MockWalletRepository() {
    final now = DateTime.now();
    _txs.addAll([
      Transaction(
        id: 'TX1001',
        type: TxType.received,
        counterparty: '01712345678',
        amountMinor: 50000,
        feeMinor: 0,
        createdAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      Transaction(
        id: 'TX1000',
        type: TxType.sent,
        counterparty: '01898765432',
        amountMinor: 20000,
        feeMinor: 0,
        createdAt: now.subtract(const Duration(days: 3, hours: 5)),
      ),
    ]);
  }

  @override
  Future<int> getBalance() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _balance;
  }

  @override
  Future<List<Transaction>> getTransactions() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final list = [..._txs]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  @override
  Future<Transaction> sendMoney({
    required String toPhone,
    required int amountMinor,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (amountMinor < WalletLimits.minSendMinor ||
        amountMinor > WalletLimits.maxSendMinor) {
      throw const WalletException('Amount is outside the allowed limit.');
    }
    if (amountMinor > _balance) {
      throw const WalletException('Insufficient balance.');
    }
    _balance -= amountMinor;
    final tx = Transaction(
      id: 'TX${DateTime.now().millisecondsSinceEpoch}',
      type: TxType.sent,
      counterparty: toPhone,
      amountMinor: amountMinor,
      feeMinor: 0,
      createdAt: DateTime.now(),
    );
    _txs.add(tx);
    return tx;
  }
}
