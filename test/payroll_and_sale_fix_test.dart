import 'package:flutter_test/flutter_test.dart';
import 'package:gold_bashar/domain/enums.dart';
import 'package:gold_bashar/domain/ledger.dart';
import 'package:gold_bashar/domain/models.dart';
import 'package:gold_bashar/domain/payroll.dart';
import 'package:gold_bashar/features/home/day_summary.dart';

int sum(List<PostingDraft> d, String account, LedgerKind ledger) => d
    .where((p) => p.accountId == account && p.ledger == ledger)
    .fold(0, (a, p) => a + p.amount);

StatementLine draw(DateTime at, int fils,
        {bool reversed = false, TxType type = TxType.cashPayment}) =>
    StatementLine(
      postingId: '$at$fils',
      txId: '$at',
      docNumber: '1',
      txType: type,
      occurredAt: at,
      ledger: LedgerKind.cash,
      amount: fils,
      isReversed: reversed,
    );

void main() {
  group('دورة الراتب', () {
    test('بلا تاريخ بداية: الشهر الميلادي', () {
      final p = salaryPeriodOf(DateTime(2026, 11, 16));
      expect(p.start, DateTime(2026, 11, 1));
      expect(p.end, DateTime(2026, 12, 1));
    });

    test('من يوم البداية لمثله في الشهر التالي', () {
      final start = DateTime(2026, 9, 10);
      expect(salaryPeriodOf(DateTime(2026, 11, 16), startDate: start).start,
          DateTime(2026, 11, 10));
      final before = salaryPeriodOf(DateTime(2026, 11, 5), startDate: start);
      expect(before.start, DateTime(2026, 10, 10));
      expect(before.end, DateTime(2026, 11, 10));
    });

    test('يوم 31 في شهر أقصر يصير آخر يوم فيه', () {
      final p = salaryPeriodOf(DateTime(2027, 2, 28),
          startDate: DateTime(2026, 1, 31));
      expect(p.start, DateTime(2027, 2, 28));
      expect(p.end, DateTime(2027, 3, 31));
    });

    test('التنقل بين الدورات يعبر السنة', () {
      final start = DateTime(2026, 1, 15);
      final dec = salaryPeriodOf(DateTime(2026, 12, 20), startDate: start);
      final next = shiftSalaryPeriod(dec, 1, startDate: start);
      expect(next.start, DateTime(2027, 1, 15));
    });
  });

  group('كشف الراتب والترحيل', () {
    final start = DateTime(2026, 9, 1);
    final lines = [
      draw(DateTime(2026, 9, 5), 100000), // أيلول: 100 من 300
      draw(DateTime(2026, 10, 3), 350000), // تشرين1: 350 من 300
      draw(DateTime(2026, 10, 9), 999000, reversed: true), // ملغاة
      draw(DateTime(2026, 11, 2), 50000), // تشرين2
    ];

    test('الباقي يُرحَّل: 200 من أيلول، ثم 150 بعد تشرين الأول', () {
      final oct = PayrollSheet.of(lines,
          period: salaryPeriodOf(DateTime(2026, 10, 1), startDate: start),
          monthlySalaryFils: 300000,
          startDate: start);
      expect(oct.carriedFils, 200000);
      expect(oct.deductedFils, 350000);
      expect(oct.remainingFils, 150000);

      final nov = PayrollSheet.of(lines,
          period: salaryPeriodOf(DateTime(2026, 11, 16), startDate: start),
          monthlySalaryFils: 300000,
          startDate: start);
      expect(nov.carriedFils, 150000);
      expect(nov.remainingFils, 150000 + 300000 - 50000);
    });

    test('صرف الباقي يُغلق الدورة على صفر', () {
      final paid = [
        ...lines,
        draw(DateTime(2026, 11, 30), 400000), // صرف راتب
      ];
      final nov = PayrollSheet.of(paid,
          period: salaryPeriodOf(DateTime(2026, 11, 16), startDate: start),
          monthlySalaryFils: 300000,
          startDate: start);
      expect(nov.remainingFils, 0);
    });

    test('بلا تاريخ بداية لا ترحيل', () {
      final nov = PayrollSheet.of(lines,
          period: salaryPeriodOf(DateTime(2026, 11, 16)),
          monthlySalaryFils: 300000);
      expect(nov.carriedFils, 0);
      expect(nov.remainingFils, 250000);
    });

    test('قبل تاريخ البداية: لا راتب', () {
      final aug = PayrollSheet.of(lines,
          period: salaryPeriodOf(DateTime(2026, 8, 10), startDate: start),
          monthlySalaryFils: 300000,
          startDate: start);
      expect(aug.started, isFalse);
      expect(aug.salaryFils, 0);
    });
  });

  test('صرف الراتب يُحسب ضمن مصاريف اليوم', () {
    DayPosting p(String account, int amount, String? note) => DayPosting(
          txId: 'x',
          accountId: account,
          ledger: LedgerKind.cash,
          amount: amount,
          txType: TxType.cashPayment,
          txReversed: false,
          lineNote: note,
        );
    final d = DaySummary.from(
      [p('box', -150000, noteSalaryPay), p('emp', 150000, null)],
      bagId: 'bag',
      cashboxId: 'box',
    );
    expect(d.expensesFils, 150000);
    expect(d.expenses, hasLength(1));
  });

  group('التسكير مع البيع', () {
    const b = LedgerBuilder();
    const ring = GoodsLine(
        grossWeightMg: 113000, karatId: 'k21', karatPpm: 885000, itemId: 'r');

    test('بيع 100 غ صافي وتسكيرها بـ70 مع تاجر بـ69.5: الفرق لنا', () {
      final d = b.shopSale(
        shopId: 'shop',
        bagAccountId: 'bag',
        cashboxId: 'box',
        makingIncomeId: 'inc',
        tradingIncomeId: 'trading',
        goods: const [ring],
        saleFix: const SaleFix(
          netMg: 100000,
          priceFils: 70000,
          traderId: 'trader',
          traderNetMg: 100000,
          traderPriceFils: 69500,
        ),
      );
      // المحل: أخذ 100.005 غ وسُكّر منها 100، فبقي عليه 0.005 غ و7000 دينار
      expect(sum(d, 'shop', LedgerKind.gold), ring.netMg - 100000);
      expect(sum(d, 'shop', LedgerKind.cash), 7000000);
      // التاجر: له علينا 6950 دينار، وعليه 100 غ
      expect(sum(d, 'trader', LedgerKind.gold), 100000);
      expect(sum(d, 'trader', LedgerKind.cash), -6950000);
      expect(sum(d, 'trading', LedgerKind.cash), -50000);
      expect(sum(d, 'box', LedgerKind.cash), 0);
    });

    test('تسكير وحده بلا بضاعة مقبول', () {
      final d = b.shopSale(
        shopId: 'shop',
        bagAccountId: 'bag',
        cashboxId: 'box',
        makingIncomeId: 'inc',
        tradingIncomeId: 'trading',
        saleFix: const SaleFix(netMg: 5000, priceFils: 70000),
      );
      expect(sum(d, 'shop', LedgerKind.gold), -5000);
      expect(sum(d, 'shop', LedgerKind.cash), 350000);
    });

    test('بلا حساب الأرباح والفروقات يُرفض', () {
      expect(
        () => b.shopSale(
          shopId: 'shop',
          bagAccountId: 'bag',
          cashboxId: 'box',
          makingIncomeId: 'inc',
          saleFix: const SaleFix(netMg: 5000, priceFils: 70000),
        ),
        throwsArgumentError,
      );
    });
  });
}
