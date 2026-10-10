import 'package:flutter_test/flutter_test.dart';
import 'package:paybd/data/models/payment_request.dart';
import 'package:paybd/data/models/transaction.dart';
import 'package:paybd/data/repositories/wallet_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

PaymentRequest _req(TxType type, int amount, {String who = '01712345678'}) =>
    PaymentRequest(
      type: type,
      counterparty: who,
      amountMinor: amount,
      feeMinor: 0,
    );

void main() {
  late SharedPreferences prefs;
  late MockWalletRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = MockWalletRepository(prefs, '01711111111');
  });

  test('starts with the demo balance', () async {
    expect(await repo.getBalance(), MockWalletRepository.startBalance);
  });

  test('sending reduces the balance and adds a transaction', () async {
    final before = await repo.getBalance();
    final tx = await repo.submit(_req(TxType.sent, 10000));
    expect(await repo.getBalance(), before - 10000);
    expect(tx.type, TxType.sent);
    expect((await repo.getTransactions()).first.id, tx.id);
  });

  test('cash out charges the demo fee', () async {
    expect(await repo.quoteFee(TxType.cashOut, 100000), 1500);
    final before = await repo.getBalance();
    await repo.submit(_req(TxType.cashOut, 100000));
    expect(await repo.getBalance(), before - 100000 - 1500);
  });

  test('add money increases the balance', () async {
    final before = await repo.getBalance();
    await repo.submit(_req(TxType.cashIn, 50000, who: 'Bank account'));
    expect(await repo.getBalance(), before + 50000);
  });

  test('insufficient balance is rejected', () async {
    expect(
      () => repo.submit(_req(TxType.sent, 2500000)),
      throwsA(isA<WalletException>()),
    );
  });

  test('amount outside the limit is rejected', () async {
    expect(
      () => repo.submit(_req(TxType.sent, 500)),
      throwsA(isA<WalletException>()),
    );
  });

  test('data survives a restart (new repository, same storage)', () async {
    await repo.submit(_req(TxType.sent, 10000));
    final again = MockWalletRepository(prefs, '01711111111');
    expect(await again.getBalance(), MockWalletRepository.startBalance - 10000);
    expect((await again.getTransactions()).length, 3);
  });

  test('reset restores the demo data', () async {
    await repo.submit(_req(TxType.sent, 10000));
    await repo.reset();
    expect(await repo.getBalance(), MockWalletRepository.startBalance);
    expect((await repo.getTransactions()).length, 2);
  });

  test('accounts on the same phone keep separate data', () async {
    await repo.submit(_req(TxType.sent, 10000));
    final other = MockWalletRepository(prefs, '01822222222');
    expect(await other.getBalance(), MockWalletRepository.startBalance);
    expect((await other.getTransactions()).length, 2);
    // the first account is untouched
    final first = MockWalletRepository(prefs, '01711111111');
    expect(await first.getBalance(), MockWalletRepository.startBalance - 10000);
  });
}
