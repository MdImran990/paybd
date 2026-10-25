import '../../data/models/transaction.dart';

enum InsightPeriod { thisMonth, lastMonth, last3Months }

/// Money that leaves the wallet for everyday spending (savings are shown separately).
const spendingTypes = {
  TxType.sent,
  TxType.cashOut,
  TxType.recharge,
  TxType.bill,
  TxType.donation,
  TxType.education,
};

class CategoryTotal {
  final TxType type;
  final int minor;
  const CategoryTotal(this.type, this.minor);
}

class MonthTotal {
  final DateTime month;
  final int minor;
  const MonthTotal(this.month, this.minor);
}

class RecipientTotal {
  final String phone;
  final int minor;
  const RecipientTotal(this.phone, this.minor);
}

class Insights {
  final int spent;
  final int previousSpent;
  final int moneyIn;
  final int saved;
  final int count;
  final List<CategoryTotal> categories; // biggest first
  final List<MonthTotal> months; // last 6 months, oldest first
  final List<RecipientTotal> topRecipients;

  const Insights({
    required this.spent,
    required this.previousSpent,
    required this.moneyIn,
    required this.saved,
    required this.count,
    required this.categories,
    required this.months,
    required this.topRecipients,
  });

  /// Change against the previous period in percent (null when there is nothing to compare).
  int? get changePercent => previousSpent == 0
      ? null
      : ((spent - previousSpent) * 100 / previousSpent).round();
}

int _spendOf(Transaction t) => t.amountMinor + t.feeMinor;

bool _inRange(DateTime t, DateTime start, DateTime end) =>
    !t.isBefore(start) && t.isBefore(end);

/// Works out all numbers for the Insights screen. [now] is a parameter so it can be tested.
Insights computeInsights(
  List<Transaction> txs,
  DateTime now,
  InsightPeriod period,
) {
  final thisMonth = DateTime(now.year, now.month, 1);
  final nextMonth = DateTime(now.year, now.month + 1, 1);

  late DateTime start;
  late DateTime end;
  late DateTime prevStart;
  late DateTime prevEnd;
  switch (period) {
    case InsightPeriod.thisMonth:
      start = thisMonth;
      end = nextMonth;
      prevStart = DateTime(now.year, now.month - 1, 1);
      prevEnd = thisMonth;
    case InsightPeriod.lastMonth:
      start = DateTime(now.year, now.month - 1, 1);
      end = thisMonth;
      prevStart = DateTime(now.year, now.month - 2, 1);
      prevEnd = start;
    case InsightPeriod.last3Months:
      start = DateTime(now.year, now.month - 2, 1);
      end = nextMonth;
      prevStart = DateTime(now.year, now.month - 5, 1);
      prevEnd = start;
  }

  var spent = 0;
  var previous = 0;
  var moneyIn = 0;
  var saved = 0;
  var count = 0;
  final byType = <TxType, int>{};
  final byRecipient = <String, int>{};

  for (final t in txs) {
    final inPeriod = _inRange(t.createdAt, start, end);
    if (spendingTypes.contains(t.type)) {
      if (inPeriod) {
        final v = _spendOf(t);
        spent += v;
        count++;
        byType[t.type] = (byType[t.type] ?? 0) + v;
        if (t.type == TxType.sent) {
          byRecipient[t.counterparty] = (byRecipient[t.counterparty] ?? 0) + v;
        }
      } else if (_inRange(t.createdAt, prevStart, prevEnd)) {
        previous += _spendOf(t);
      }
    }
    if (inPeriod) {
      if (t.type == TxType.received || t.type == TxType.cashIn) {
        moneyIn += t.amountMinor;
      } else if (t.type == TxType.savings) {
        saved += t.amountMinor;
      }
    }
  }

  final categories = [
    for (final e in byType.entries) CategoryTotal(e.key, e.value),
  ]..sort((a, b) => b.minor.compareTo(a.minor));

  final recipients = [
    for (final e in byRecipient.entries) RecipientTotal(e.key, e.value),
  ]..sort((a, b) => b.minor.compareTo(a.minor));

  final months = <MonthTotal>[];
  for (var i = 5; i >= 0; i--) {
    final m = DateTime(now.year, now.month - i, 1);
    final next = DateTime(m.year, m.month + 1, 1);
    var sum = 0;
    for (final t in txs) {
      if (spendingTypes.contains(t.type) && _inRange(t.createdAt, m, next)) {
        sum += _spendOf(t);
      }
    }
    months.add(MonthTotal(m, sum));
  }

  return Insights(
    spent: spent,
    previousSpent: previous,
    moneyIn: moneyIn,
    saved: saved,
    count: count,
    categories: categories,
    months: months,
    topRecipients: recipients.take(3).toList(),
  );
}
