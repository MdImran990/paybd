import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/account_keys.dart';
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
        TxType.bill => (min: 1000, max: 5000000), // ৳10 - ৳50,000
        TxType.donation => (min: 1000, max: 5000000),
        TxType.education => (min: 1000, max: 5000000),
        TxType.savings => (min: 1000, max: 5000000),
        TxType.savingsWithdraw => (min: 1, max: 100000000),
        TxType.received => (min: 0, max: 0),
      };

  /// DEMO monthly limit per service, in paisa.
  static int monthlyMax(TxType t) => switch (t) {
        TxType.sent => 30000000, // ৳300,000
        TxType.cashOut => 30000000,
        TxType.cashIn => 50000000,
        TxType.recharge => 5000000, // ৳50,000
        TxType.bill => 30000000,
        TxType.donation => 10000000,
        TxType.education => 30000000,
        TxType.savings => 50000000,
        TxType.savingsWithdraw => 999999999999,
        TxType.received => 0,
      };

  /// DEMO cash out fee: 1.5% (15 per thousand).
  static const cashOutFeePerMille = 15;
}

/// UI and providers talk only to this interface.
/// Today: MockWalletRepository (saved on this device). Later: ApiWalletRepository.
/// Money amounts are ints in paisa.
abstract class WalletRepository {
  Future<int> getBalance();
  Future<List<Transaction>> getTransactions();

  /// Fee for a payment. In the real app the server decides this.
  Future<int> quoteFee(TxType type, int amountMinor);

  /// Executes any payment (send, cash out, add money, recharge, bill, ...).
  Future<Transaction> submit(PaymentRequest request);

  /// Demo only: back to the starting demo data (used on logout).
  Future<void> reset();
}

/// DEMO ONLY. Demo balance and transactions are saved on this device so they survive
/// app restarts. Not real money. The real balance and every validation must live on the server.
class MockWalletRepository implements WalletRepository {
  static const _kBalance = 'wallet_balance';
  static const _kTxs = 'wallet_txs';
  static const startBalance = 1600300; // ৳16,003.00

  final SharedPreferences _prefs;
  final String _phone;
  int _balance;
  List<Transaction> _txs;

  MockWalletRepository(this._prefs, this._phone)
      : _balance = _prefs.getInt(acctKey(_phone, _kBalance)) ?? startBalance,
        _txs = _load(_prefs, _phone);

  static List<Transaction> _seed() {
    final now = DateTime.now();
    return [
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
    ];
  }

  static List<Transaction> _load(SharedPreferences prefs, String phone) {
    final raw = prefs.getString(acctKey(phone, _kTxs));
    if (raw == null) return _seed();
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final e in list) Transaction.fromJson(e as Map<String, dynamic>),
      ];
    } catch (_) {
      return _seed();
    }
  }

  Future<void> _save() async {
    await _prefs.setInt(acctKey(_phone, _kBalance), _balance);
    await _prefs.setString(
      acctKey(_phone, _kTxs),
      jsonEncode([for (final t in _txs) t.toJson()]),
    );
  }

  @override
  Future<int> getBalance() async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _balance;
  }

  @override
  Future<List<Transaction>> getTransactions() async {
    await Future.delayed(const Duration(milliseconds: 250));
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
    await Future.delayed(const Duration(milliseconds: 700));

    final type = request.type;
    if (type == TxType.received) {
      throw const WalletException('Not allowed.');
    }
    final limits = WalletLimits.of(type);
    final amount = request.amountMinor;
    if (amount < limits.min || amount > limits.max) {
      throw const WalletException('Amount is outside the allowed limit.');
    }
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final usedThisMonth = _txs
        .where((t) => t.type == type && !t.createdAt.isBefore(monthStart))
        .fold<int>(0, (sum, t) => sum + t.amountMinor);
    if (usedThisMonth + amount > WalletLimits.monthlyMax(type)) {
      throw const WalletException('Monthly limit exceeded.');
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
    await _save();
    return tx;
  }

  @override
  Future<void> reset() async {
    await _prefs.remove(acctKey(_phone, _kBalance));
    await _prefs.remove(acctKey(_phone, _kTxs));
    _balance = startBalance;
    _txs = _seed();
  }
}
