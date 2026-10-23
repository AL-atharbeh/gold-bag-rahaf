import 'package:flutter_test/flutter_test.dart';
import 'package:gold_bashar/core/units.dart';
import 'package:gold_bashar/domain/enums.dart';
import 'package:gold_bashar/domain/ledger.dart';
import 'package:gold_bashar/features/common/inputs.dart';

const bag = 'acc-bag';
const workshop = 'acc-workshop';

int sumOf(List<PostingDraft> ps, String account, LedgerKind ledger) => ps
    .where((p) => p.accountId == account && p.ledger == ledger)
    .fold(0, (a, p) => a + p.amount);

GoodsLine goods({
  required int grossMg,
  required int ppm,
  int qty = 1,
  int makingPerGramFils = 0,
  String item = 'ring',
}) =>
    GoodsLine(
      grossWeightMg: grossMg,
      karatId: 'k$ppm',
      karatPpm: ppm,
      itemId: item,
      quantity: qty,
      makingPerGramFils: makingPerGramFils,
    );

void main() {
  const b = LedgerBuilder();

  group('قراءة الوزن المكتوب', () {
    test('كل أشكال الفاصلة العشرية تُقرأ كنقطة', () {
      for (final s in ['115.15', '115,15', '115٫15', '115،15', '١١٥٫١٥', ' 115.15 ']) {
        expect(parseGrams(s), 115150, reason: s);
      }
    });

    test('بلا فاصلة يُقرأ غرامات كاملة', () {
      expect(parseGrams('115'), 115000);
    });

    test('لوحة المفاتيح العربية تكتب أرقاماً إنجليزية ونقطة', () {
      // "ز" هو زر النقطة في التخطيط العربي، و"و" زر الفاصلة
      expect(LatinNumberFormatter.normalize('١١٥٫١٥'), '115.15');
      expect(LatinNumberFormatter.normalize('115ز15'), '115.15');
      expect(LatinNumberFormatter.normalize('115و15'), '115.15');
      expect(LatinNumberFormatter.normalize('۱۲۳'), '123');
      expect(LatinNumberFormatter.normalize('١٢', decimal: false), '12');
    });

    test('فاصلتان وزن غير صالح', () {
      expect(parseGrams('1.15.5'), isNull);
    });
  });

  group('وارد بضاعة من المشغل', () {
    test('عيار 21: الصافي = القائم × 0.885 والمصنوعية على القائم', () {
      // 45.300 غ عيار 21، مصنوعية 1.500 د.أ للغرام
      final ps = b.goodsIn(
        workshopId: workshop,
        bagAccountId: bag,
        lines: [goods(grossMg: 45300, ppm: 885000, qty: 12, makingPerGramFils: 1500)],
      );

      // 45.300 × 0.885 = 40.0905 → 40.091 غ (تقريب لأقرب مليغرام)
      expect(sumOf(ps, bag, LedgerKind.gold), 40091);
      expect(sumOf(ps, workshop, LedgerKind.gold), -40091, reason: 'للمشغل علينا ذهب');

      // 45.300 × 1.500 = 67.950 د.أ
      expect(sumOf(ps, bag, LedgerKind.cash), 67950, reason: 'رأس مال في الشنطة');
      expect(sumOf(ps, workshop, LedgerKind.cash), -67950, reason: 'للمشغل علينا نقداً');
    });

    test('عيار 14 بمعامل 14/24 وعيار 18 بـ 0.790', () {
      final ps = b.goodsIn(
        workshopId: workshop,
        bagAccountId: bag,
        lines: [
          goods(grossMg: 24000, ppm: 583333), // 24 × 14/24 = 14.000
          goods(grossMg: 10000, ppm: 790000), // 10 × 0.790 = 7.900
        ],
      );
      expect(sumOf(ps, bag, LedgerKind.gold), 14000 + 7900);
    });

    test('العدد والوزن يدخلان الشنطة بإشارة موجبة ويخرجان من المشغل بسالبة', () {
      final ps = b.goodsIn(
        workshopId: workshop,
        bagAccountId: bag,
        lines: [goods(grossMg: 5000, ppm: 885000, qty: 3)],
      );
      final bagLine = ps.firstWhere((p) => p.accountId == bag && p.ledger == LedgerKind.gold);
      final wsLine = ps.firstWhere((p) => p.accountId == workshop && p.ledger == LedgerKind.gold);
      expect(bagLine.quantity, 3);
      expect(bagLine.grossWeightMg, 5000);
      expect(bagLine.itemId, 'ring');
      expect(wsLine.quantity, -3);
      expect(wsLine.grossWeightMg, -5000);
    });

    test('بلا مصنوعية لا يمسّ دفتر النقد', () {
      final ps = b.goodsIn(
        workshopId: workshop,
        bagAccountId: bag,
        lines: [goods(grossMg: 5000, ppm: 885000)],
      );
      expect(ps.where((p) => p.ledger == LedgerKind.cash), isEmpty);
    });

    test('القيد متوازن في الدفترين مهما تعددت البنود', () {
      final ps = b.goodsIn(
        workshopId: workshop,
        bagAccountId: bag,
        lines: [
          goods(grossMg: 12345, ppm: 885000, qty: 4, makingPerGramFils: 1250, item: 'ring'),
          goods(grossMg: 7777, ppm: 790000, qty: 2, makingPerGramFils: 2000, item: 'chain'),
          goods(grossMg: 3333, ppm: 583333, qty: 1, makingPerGramFils: 900, item: 'earring'),
        ],
      );
      for (final ledger in LedgerKind.values) {
        expect(ps.where((p) => p.ledger == ledger).fold<int>(0, (a, p) => a + p.amount), 0);
      }
    });

    test('يرفض فاتورة فارغة أو وزناً صفرياً', () {
      expect(
        () => b.goodsIn(workshopId: workshop, bagAccountId: bag, lines: const []),
        throwsArgumentError,
      );
      expect(
        () => b.goodsIn(
          workshopId: workshop,
          bagAccountId: bag,
          lines: [goods(grossMg: 0, ppm: 885000)],
        ),
        throwsArgumentError,
      );
    });
  });
}
