import 'package:flutter_test/flutter_test.dart';
import 'package:gold_bashar/domain/enums.dart';
import 'package:gold_bashar/domain/models.dart';
import 'package:gold_bashar/features/statements/account_statement.dart';

StatementLine _l(String tx, DateTime at, LedgerKind k, int amount,
        {int? gross, String? karat}) =>
    StatementLine(
      postingId: '$tx-${k.wire}-$amount',
      txId: tx,
      docNumber: '2026-$tx',
      txType: TxType.sale,
      occurredAt: at,
      ledger: k,
      amount: amount,
      isReversed: false,
      grossWeightMg: gross,
      karatName: karat,
      note: 'ملاحظة',
    );

void main() {
  // الرصيد الحالي: ذهب 100 غ لنا، نقد 50 د.أ له
  const goldNow = 100000;
  const cashNow = -50000;

  final since = [
    // داخل الفترة (أكتوبر)
    _l('1', DateTime(2026, 10, 5), LedgerKind.gold, 30000,
        gross: 34000, karat: 'عيار 21'),
    _l('1', DateTime(2026, 10, 5), LedgerKind.cash, 15000),
    _l('2', DateTime(2026, 10, 31, 23, 30), LedgerKind.cash, -20000),
    // بعد نهاية الفترة — لا تظهر لكنها تدخل في حساب الرصيد السابق
    _l('3', DateTime(2026, 11, 2), LedgerKind.gold, 10000),
  ];

  test('الرصيد السابق = الحالي ناقص كل ما بعد بداية الفترة', () {
    final st = AccountStatement.build(
      from: DateTime(2026, 10, 1),
      to: DateTime(2026, 10, 31),
      since: since,
      goldNow: goldNow,
      cashNow: cashNow,
    );
    expect(st.openingGold, 100000 - 30000 - 10000);
    expect(st.openingCash, -50000 - 15000 + 20000);
    expect(st.rows.map((r) => r.docNumber), ['2026-1', '2026-2']);
    // الختامي = الحالي ناقص ما بعد الفترة
    expect(st.closingGold, 100000 - 10000);
    expect(st.closingCash, -50000);
    expect(st.rows.first.goldAfter, st.openingGold + 30000);
    expect(st.rows.first.grossByKarat, {'عيار 21': 34000});
    expect(st.cashDebit, 15000);
    expect(st.cashCredit, 20000);
  });

  test('فترة بلا حركات: الرصيد السابق = الختامي', () {
    final st = AccountStatement.build(
      from: DateTime(2026, 12, 1),
      to: DateTime(2026, 12, 31),
      since: const [],
      goldNow: goldNow,
      cashNow: cashNow,
    );
    expect(st.rows, isEmpty);
    expect(st.openingGold, goldNow);
    expect(st.closingCash, cashNow);
  });
}
