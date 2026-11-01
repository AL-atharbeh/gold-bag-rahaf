import 'package:flutter_test/flutter_test.dart';
import 'package:gold_bashar/domain/enums.dart';
import 'package:gold_bashar/domain/models.dart';
import 'package:gold_bashar/features/home/day_summary.dart';

DayPosting p(String tx, String acc, LedgerKind k, int amount, TxType t,
        {String? item, int? qty, bool reversed = false, String? note, String? txNote}) =>
    DayPosting(
      txId: tx,
      accountId: acc,
      ledger: k,
      amount: amount,
      txType: t,
      txReversed: reversed,
      itemId: item,
      quantity: qty,
      lineNote: note,
      txNote: txNote,
    );

void main() {
  test('ملخص اليوم: مبيعات وكسر ونقد ومصنوعية، بلا الحركات الملغاة', () {
    final d = DaySummary.from(
      [
        // بيع خاتمين 8.850 صافي، مصنوعية 15، تكلفة 4، كسر 2 غ، نقد 50
        p('1', 'bag', LedgerKind.gold, -8850, TxType.sale, item: 'r', qty: -2),
        p('1', 'shop', LedgerKind.gold, 8850, TxType.sale, item: 'r', qty: 2),
        p('1', 'income', LedgerKind.cash, -15000, TxType.sale),
        p('1', 'income', LedgerKind.cash, 4000, TxType.sale),
        p('1', 'bag', LedgerKind.gold, 2000, TxType.sale),
        p('1', 'cashbox', LedgerKind.cash, 50000, TxType.sale),
        // حركة ملغاة وقيدها العكسي — لا تُحسب
        p('2', 'bag', LedgerKind.gold, -1000, TxType.sale,
            item: 'r', qty: -1, reversed: true),
        p('3', 'bag', LedgerKind.gold, 1000, TxType.reversal, item: 'r', qty: 1),
        // دفع نقد لتاجر
        p('4', 'cashbox', LedgerKind.cash, -20000, TxType.cashPayment),
      ],
      bagId: 'bag',
      cashboxId: 'cashbox',
    );
    expect(d.txCount, 2);
    expect(d.soldNetMg, 8850);
    expect(d.soldPieces, 2);
    expect(d.scrapInMg, 2000);
    expect(d.cashInFils, 50000);
    expect(d.cashOutFils, 20000);
  });

  test('المصاريف تُخصم من الكاش ومن الربح، والشيك لا يُعدّ كاشاً', () {
    final d = DaySummary.from(
      [
        p('1', 'income', LedgerKind.cash, -15000, TxType.sale),
        // بنزين 5 د.أ
        p('2', 'expenses', LedgerKind.cash, 5000, TxType.expense,
            note: 'fuel', txNote: 'بنزين'),
        p('2', 'cashbox', LedgerKind.cash, -5000, TxType.expense),
        // شيك 100 من محل: في حساب الشيكات لا في الكاش
        p('3', 'cheques', LedgerKind.cash, 100000, TxType.cashPayment),
        p('3', 'shop', LedgerKind.cash, -100000, TxType.cashPayment),
      ],
      bagId: 'bag',
      cashboxId: 'cashbox',
      expensesId: 'expenses',
      chequesId: 'cheques',
    );
    expect(d.expensesFils, 5000);
    expect(d.expenses.single.$1, ExpenseCategory.fuel);
    expect(d.cashInFils, 0);
    expect(d.cashOutFils, 5000);
    expect(d.chequesInFils, 100000);
  });
}
