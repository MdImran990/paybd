import '../models/payment_request.dart';
import '../models/transaction.dart';

class WalletException implements Exception {
  final String message;
  const WalletException(this.message);
  @override
  String toString() => message;
}

/// DEMO limits and fee. Real limits and fees come from the server / regulations.
class WalletLimits {
  static ({int min, int max}) of(TxType t) => switch (t) {
        TxType.sent => (min: 1000, max: 2500000), // ৳10 - ৳25,000
        TxType.cashOut => (min: 5000, max: 2500000), // ৳50 - ৳25,000
        TxType.cashIn => (min: 5000, max: 5000000), // ৳50 - ৳50,000
        TxType.recharge => (min: 1000, max: 100000), // ৳10 - ৳1,000
        TxType.received => (min: 0, max: 0),
      };

  /// DEMO cash out fee: 1.5% (15 per thousand).
  static const cashOutFeePerMille = 15;
}

/// UI and providers talk only to this interface.
/// Today: MockWalletRepository. Later: ApiWalletRepository.
/// Money amounts are ints in paisa.
abstract class WalletRepository {
  Future<int> getBalance();
  Future<List<Transaction>> getTransactions();

  /// Fee for a payment. In the real app the server decides this.
  Future<int> quoteFee(TxType type, int amountMinor);

  /// Executes send, cash out, add money or recharge.
  Future<Transaction> submit(PaymentRequest request);
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
  Future<int> quoteFee(TxType type, int amountMinor) async {
    if (type == TxType.cashOut) {
      return (amountMinor * WalletLimits.cashOutFeePerMille + 500) ~/ 1000;
    }
    return 0;
  }

  @override
  Future<Transaction> submit(PaymentRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final type = request.type;
    if (type == TxType.received) {
      throw const WalletException('Not allowed.');
    }
    final limits = WalletLimits.of(type);
    final amount = request.amountMinor;
    if (amount < limits.min || amount > limits.max) {
      throw const WalletException('Amount is outside the allowed limit.');
    }

    // Never trust the fee sent by the app: recompute it here (the server's job).
    final fee = await quoteFee(type, amount);

    if (type.debitsWallet) {
      if (amount + fee > _balance) {
        throw const WalletException('Insufficient balance.');
      }
      _balance -= amount + fee;
    } else {
      _balance += amount;
    }

    final tx = Transaction(
      id: 'TX${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      counterparty: request.counterparty,
      note: request.note,
      amountMinor: amount,
      feeMinor: fee,
      createdAt: DateTime.now(),
    );
    _txs.add(tx);
    return tx;
  }
}
