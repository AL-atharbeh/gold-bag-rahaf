import 'package:flutter_test/flutter_test.dart';
import 'package:gold_bashar/domain/enums.dart';
import 'package:gold_bashar/domain/ledger.dart';

const bag = 'acc-bag';
const shop = 'acc-shop';
const cashbox = 'acc-cashbox';
const makingIncome = 'acc-making';

int sumOf(List<PostingDraft> ps, String account, LedgerKind ledger) => ps
    .where((p) => p.accountId == account && p.ledger == ledger)
    .fold(0, (a, p) => a + p.amount);

GoodsLine goods(int grossMg, int ppm, {int qty = 1, int making = 0}) => GoodsLine(
      grossWeightMg: grossMg,
      karatId: 'k$ppm',
      karatPpm: ppm,
      itemId: 'ring',
      quantity: qty,
      makingPerGramFils: making,
    );

GoodsLine scrap(int grossMg, int ppm) =>
    GoodsLine(grossWeightMg: grossMg, karatId: 'k$ppm', karatPpm: ppm);

List<PostingDraft> sale({
  List<GoodsLine> g = const [],
  List<GoodsLine> s = const [],
  int cash = 0,
  int cost = 0,
}) =>
    const LedgerBuilder().shopSale(
      shopId: shop,
      bagAccountId: bag,
      cashboxId: cashbox,
      makingIncomeId: makingIncome,
      goods: g,
      scrap: s,
      cashReceivedFils: cash,
      costOutFils: cost,
    );

void main() {
  group('بيع للمحل', () {
    test('البضاعة تخرج من الشنطة بمعامل البضاعة وتصير ذهباً على المحل', () {
      // 50 غ عيار 21 × 0.885 = 44.250
      final ps = sale(g: [goods(50000, 885000, qty: 10)]);
      expect(sumOf(ps, bag, LedgerKind.gold), -44250);
      expect(sumOf(ps, shop, LedgerKind.gold), 44250);
    });

    test('المصنوعية على القائم دين نقدي على المحل وإيراد لنا', () {
      // 50 غ × 1.000 د.أ = 50.000
      final ps = sale(g: [goods(50000, 885000, making: 1000)]);
      expect(sumOf(ps, shop, LedgerKind.cash), 50000);
      expect(sumOf(ps, makingIncome, LedgerKind.cash), -50000);
    });

    test('الكسر يُحسب بمعامل الكسر وينقص ذهب المحل ويدخل الشنطة', () {
      // كسر 10 غ عيار 21 × 0.870 = 8.700، و10 غ عيار 18 × 0.740 = 7.400
      final ps = sale(s: [scrap(10000, 870000), scrap(10000, 740000)]);
      expect(sumOf(ps, shop, LedgerKind.gold), -16100);
      expect(sumOf(ps, bag, LedgerKind.gold), 16100);
      final scrapLine = ps.firstWhere((p) => p.accountId == bag);
      expect(scrapLine.itemId, isNull, reason: 'الكسر بلا صنف');
      expect(scrapLine.quantity, isNull);
    });

    test('مثال كامل: يبقى لنا 20.2 غ وعليه 50 دينار', () {
      // بيع 50 غ عيار 21 (44.250 صافي) بمصنوعية 2.000 للغرام = 100 د.أ
      // استلام كسر 27.586 غ عيار 21 × 0.870 = 24.000 (تقريباً)
      // استلام 50 د.أ نقداً
      final ps = sale(
        g: [goods(50000, 885000, making: 2000)],
        s: [scrap(27586, 870000)],
        cash: 50000,
      );
      expect(sumOf(ps, shop, LedgerKind.gold), 44250 - 24000);
      expect(sumOf(ps, shop, LedgerKind.cash), 100000 - 50000);
      expect(sumOf(ps, cashbox, LedgerKind.cash), 50000);
    });

    test('تكلفة المصنوعية تخرج من رأس مال الشنطة وتُخصم من الإيراد', () {
      final ps = sale(g: [goods(50000, 885000, making: 2000)], cost: 60000);
      expect(sumOf(ps, bag, LedgerKind.cash), -60000);
      // الإيراد 100 والتكلفة 60 → الربح 40 (الإيراد دائن بالسالب)
      expect(sumOf(ps, makingIncome, LedgerKind.cash), -100000 + 60000);
    });

    test('دفعة نقدية وحدها تكفي لحركة', () {
      final ps = sale(cash: 25000);
      expect(sumOf(ps, shop, LedgerKind.cash), -25000);
      expect(ps.where((p) => p.ledger == LedgerKind.gold), isEmpty);
    });

    test('القيد متوازن في الدفترين دائماً', () {
      final ps = sale(
        g: [goods(12345, 885000, qty: 3, making: 1500), goods(7777, 790000, making: 2500)],
        s: [scrap(4321, 870000)],
        cash: 33333,
        cost: 12000,
      );
      for (final ledger in LedgerKind.values) {
        expect(ps.where((p) => p.ledger == ledger).fold<int>(0, (a, p) => a + p.amount), 0);
      }
    });

    test('يرفض حركة فارغة', () {
      expect(() => sale(), throwsArgumentError);
    });
  });
}
