import '../../domain/enums.dart';
import '../../domain/ledger.dart';
import '../../domain/models.dart';

/// ملخص يوم الموزّع من قيود اليوم.
///
/// الحركات الملغاة وقيودها العكسية لا تدخل في الملخص — كأنها لم تكن.
class DaySummary {
  const DaySummary({
    required this.txCount,
    required this.soldNetMg,
    required this.soldPieces,
    required this.returnedNetMg,
    required this.goodsInNetMg,
    required this.scrapInMg,
    required this.cashInFils,
    required this.cashOutFils,
    this.expensesFils = 0,
    this.chequesInFils = 0,
    this.expenses = const [],
  });

  factory DaySummary.from(
    List<DayPosting> postings, {
    required String? bagId,
    required String? cashboxId,
    String? expensesId,
    String? chequesId,
  }) {
    var expenses = 0, chequesIn = 0;
    final expenseList = <(ExpenseCategory?, String?, int)>[];
    final txs = <String>{};
    var sold = 0, pieces = 0, returned = 0, goodsIn = 0, scrap = 0;
    var cashIn = 0, cashOut = 0;

    for (final p in postings) {
      if (p.txReversed || p.txType == TxType.reversal) continue;
      txs.add(p.txId);
      // الرصيد الافتتاحي موجود قبل اليوم، لا مقبوض ولا كسر مستلم فيه
      if (p.txType == TxType.openingBalance) continue;

      if (p.accountId == bagId && p.ledger == LedgerKind.gold) {
        if (p.itemId == null) {
          if (p.amount > 0) scrap += p.amount;
        } else if (p.txType == TxType.sale && p.amount < 0) {
          sold -= p.amount;
          pieces -= p.quantity ?? 0;
        } else if ((p.txType == TxType.goodsReturn ||
                p.lineNote == noteRecovered) &&
            p.amount > 0) {
          returned += p.amount;
        } else if (p.txType == TxType.goodsIn && p.amount > 0) {
          goodsIn += p.amount;
        }
      } else if (p.accountId == cashboxId && p.ledger == LedgerKind.cash) {
        if (p.amount > 0) {
          cashIn += p.amount;
        } else {
          cashOut -= p.amount;
          // سحب الموظف يخرج من الكاش ويُعرض مع المصاريف
          if (p.lineNote == noteEmployeeDraw || p.lineNote == noteSalaryPay) {
            expenses -= p.amount;
            expenseList.add((null, p.txNote ?? p.lineNote, -p.amount));
          }
        }
      } else if (p.accountId == expensesId && p.ledger == LedgerKind.cash) {
        expenses += p.amount;
        expenseList
            .add((ExpenseCategory.fromKey(p.lineNote), p.txNote, p.amount));
      } else if (p.accountId == chequesId &&
          p.ledger == LedgerKind.cash &&
          p.amount > 0) {
        chequesIn += p.amount;
      }
    }

    return DaySummary(
      txCount: txs.length,
      soldNetMg: sold,
      soldPieces: pieces,
      returnedNetMg: returned,
      goodsInNetMg: goodsIn,
      scrapInMg: scrap,
      cashInFils: cashIn,
      cashOutFils: cashOut,
      expensesFils: expenses,
      chequesInFils: chequesIn,
      expenses: expenseList,
    );
  }

  final int txCount;
  final int soldNetMg;
  final int soldPieces;
  final int returnedNetMg;
  final int goodsInNetMg;
  final int scrapInMg;
  final int cashInFils;
  final int cashOutFils;

  /// مصاريف اليوم من كاش الشنطة.
  final int expensesFils;

  /// شيكات استُلمت اليوم (تُحسب على الطرف كالنقد، وتُحفظ منفصلة).
  final int chequesInFils;

  /// كل مصروف: البند، والوصف، والمبلغ.
  final List<(ExpenseCategory?, String?, int)> expenses;
}
