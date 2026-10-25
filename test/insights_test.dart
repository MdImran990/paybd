import 'package:flutter_test/flutter_test.dart';
import 'package:paybd/core/insights/insights.dart';
import 'package:paybd/data/models/transaction.dart';

Transaction _tx(
  String id,
  TxType type,
  int amount,
  DateTime when, {
  int fee = 0,
  String who = '01711111111',
}) =>
    Transaction(
      id: id,
      type: type,
      counterparty: who,
      amountMinor: amount,
      feeMinor: fee,
      createdAt: when,
    );

void main() {
  final now = DateTime(2026, 10, 15);
  final txs = [
    _tx('1', TxType.sent, 10000, DateTime(2026, 10, 5)),
    _tx('2', TxType.cashOut, 100000, DateTime(2026, 10, 10), fee: 1500),
    _tx('3', TxType.recharge, 5000, DateTime(2026, 9, 20)),
    _tx('4', TxType.received, 20000, DateTime(2026, 10, 2)),
    _tx('5', TxType.savings, 30000, DateTime(2026, 10, 3)),
    _tx('6', TxType.bill, 7000, DateTime(2026, 8, 15)),
  ];

  test('this month: spending includes fees, savings are separate', () {
    final r = computeInsights(txs, now, InsightPeriod.thisMonth);
    expect(r.spent, 111500);
    expect(r.previousSpent, 5000);
    expect(r.moneyIn, 20000);
    expect(r.saved, 30000);
    expect(r.count, 2);
    expect(r.changePercent, 2130);
  });

  test('categories are sorted, biggest first', () {
    final r = computeInsights(txs, now, InsightPeriod.thisMonth);
    expect(r.categories.first.type, TxType.cashOut);
    expect(r.categories.first.minor, 101500);
    expect(r.categories.last.type, TxType.sent);
  });

  test('last 6 months for the bar chart', () {
    final r = computeInsights(txs, now, InsightPeriod.thisMonth);
    expect(r.months.length, 6);
    expect(r.months.last.minor, 111500); // October
    expect(r.months[4].minor, 5000); // September
    expect(r.months[3].minor, 7000); // August
  });

  test('last month compares with the month before', () {
    final r = computeInsights(txs, now, InsightPeriod.lastMonth);
    expect(r.spent, 5000);
    expect(r.previousSpent, 7000);
    expect(r.changePercent, -29);
  });

  test('top recipients only count money sent', () {
    final r = computeInsights(txs, now, InsightPeriod.thisMonth);
    expect(r.topRecipients.length, 1);
    expect(r.topRecipients.first.phone, '01711111111');
    expect(r.topRecipients.first.minor, 10000);
  });

  test('no previous spending means no percentage', () {
    final r = computeInsights(
      [_tx('1', TxType.sent, 100, DateTime(2026, 10, 1))],
      now,
      InsightPeriod.thisMonth,
    );
    expect(r.changePercent, isNull);
  });
}
