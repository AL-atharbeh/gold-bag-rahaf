import 'package:flutter_test/flutter_test.dart';
import 'package:gold_bashar/domain/enums.dart';
import 'package:gold_bashar/domain/ledger.dart';

const trader = 'acc-trader';
const trading = 'acc-trading';
const bag = 'acc-bag';

int sumOf(List<PostingDraft> ps, String account, LedgerKind ledger) => ps
    .where((p) => p.accountId == account && p.ledger == ledger)
    .fold(0, (a, p) => a + p.amount);

List<PostingDraft> price(int netMg, int priceFils, {required bool owedToUs}) =>
    const LedgerBuilder().price(
      counterpartyId: trader,
      tradingIncomeId: trading,
      netWeightMg: netMg,
      pricePerGramFils: priceFils,
      owedToUs: owedToUs,
    );

void main() {
  group('التعامل مع التاجر — كما في ورقة الشركة الدولية', () {
    test('بيع ذهب بالهاتف: علينا ذهب ولنا نقد (500 × 106.3 = 53150)', () {
      final ps = price(500000, 106300, owedToUs: true);
      expect(sumOf(ps, trader, LedgerKind.gold), -500000);
      expect(sumOf(ps, trader, LedgerKind.cash), 53150000);
    });

    test('شراء ذهب: لنا ذهب وعلينا نقد', () {
      final ps = price(100000, 103000, owedToUs: false);
      expect(sumOf(ps, trader, LedgerKind.gold), 100000);
      expect(sumOf(ps, trader, LedgerKind.cash), -10300000);
    });

    test('تسكير ذهب علينا: 1050.42 × 108.5 = 113970.57 — يُسدَّد الذهب ويصير نقداً علينا', () {
      final ps = price(1050420, 108500, owedToUs: false);
      expect(sumOf(ps, trader, LedgerKind.gold), 1050420);
      expect(sumOf(ps, trader, LedgerKind.cash), -113970570);
    });

    test('تسليم كسر للتاجر يخرج من الشنطة ويُنقص ما علينا', () {
      final ps = const LedgerBuilder().scrapMove(
        partyId: trader,
        bagAccountId: bag,
        toParty: true,
        lines: const [GoodsLine(grossWeightMg: 100000, karatId: 'k21', karatPpm: 870000)],
      );
      expect(sumOf(ps, bag, LedgerKind.gold), -87000);
      expect(sumOf(ps, trader, LedgerKind.gold), 87000);
    });

    test('استلام كسر من التاجر يدخل الشنطة', () {
      final ps = const LedgerBuilder().scrapMove(
        partyId: trader,
        bagAccountId: bag,
        toParty: false,
        lines: const [GoodsLine(grossWeightMg: 10000, karatId: 'k18', karatPpm: 740000)],
      );
      expect(sumOf(ps, bag, LedgerKind.gold), 7400);
      expect(sumOf(ps, trader, LedgerKind.gold), -7400);
    });

    test('استلام كسر مع شراء جزء منه نقداً: الباقي فقط يُضاف لرصيد الذهب', () {
      // كسر 100 غ عيار 21 × 0.870 = 87 غ حلة، يُشترى منها 30 غ بسعر 100
      final ps = [
        ...const LedgerBuilder().scrapMove(
          partyId: trader,
          bagAccountId: bag,
          toParty: false,
          lines: const [GoodsLine(grossWeightMg: 100000, karatId: 'k21', karatPpm: 870000)],
        ),
        ...price(30000, 100000, owedToUs: false),
      ];
      expect(sumOf(ps, bag, LedgerKind.gold), 87000, reason: 'الكسر كله يدخل الشنطة');
      expect(sumOf(ps, trader, LedgerKind.gold), -57000, reason: '87 − 30 = 57 لرصيد ذهبه');
      expect(sumOf(ps, trader, LedgerKind.cash), -3000000, reason: '30 × 100 = 3000 له علينا');
    });

    test('معامل يدوي 0.820: 50 غ × 0.820 = 41 غ حلة', () {
      final ps = const LedgerBuilder().scrapMove(
        partyId: trader,
        bagAccountId: bag,
        toParty: false,
        lines: const [GoodsLine(grossWeightMg: 50000, karatId: 'k21', karatPpm: 820000)],
      );
      expect(sumOf(ps, trader, LedgerKind.gold), -41000);
    });

    test('سيناريو كامل: بيع بالهاتف ثم تسليم الكسر يصفّر الذهب ويبقى النقد لنا', () {
      final sale = price(87000, 100000, owedToUs: true); // 87 غ حلة × 100 د.أ
      final delivery = const LedgerBuilder().scrapMove(
        partyId: trader,
        bagAccountId: bag,
        toParty: true,
        lines: const [GoodsLine(grossWeightMg: 100000, karatId: 'k21', karatPpm: 870000)],
      );
      final all = [...sale, ...delivery];
      expect(sumOf(all, trader, LedgerKind.gold), 0);
      expect(sumOf(all, trader, LedgerKind.cash), 8700000);
    });
  });
}
