import 'package:flutter_test/flutter_test.dart';
import 'package:gold_bashar/core/units.dart';
import 'package:gold_bashar/domain/enums.dart';
import 'package:gold_bashar/domain/ledger.dart';
import 'package:gold_bashar/domain/models.dart';

/// معرّفات وهمية — المنطق لا يعرف شيئاً عن قاعدة البيانات.
const shanta = 'acc-shanta';
const showroom = 'acc-showroom';
const consignment = 'acc-consignment';
const trading = 'acc-trading';
const making = 'acc-making';
const cashbox = 'acc-cashbox';
const k21 = 'karat-21';

// من دفتر العميل: البضاعة تخرج بمعامل أعلى من الذي يعود به الذهب.
const ppm21Out = 885000; // بضاعة 885
const ppm21In = 870000;  // تسليم ذهب 21
const ppm18Out = 790000; // بضاعة 790
const ppm18In = 740000;  // تسليم كسر 18
const ppm21 = ppm21Out;

/// بند بضاعة تخرج — معامل ٠٫٨٨٥.
GoodsLine line(int grams, {int makingPerGram = 0}) => GoodsLine(
      grossWeightMg: grams * 1000,
      karatId: k21,
      karatPpm: ppm21Out,
      makingPerGramFils: makingPerGram,
    );

/// بند ذهب يعود إلينا — معامل ٠٫٨٧٠. الشراء ودفعة الكسر دخول لا خروج.
GoodsLine lineIn(int grams) => GoodsLine(
      grossWeightMg: grams * 1000,
      karatId: k21,
      karatPpm: ppm21In,
    );

int sumOf(List<PostingDraft> ps, LedgerKind ledger) =>
    ps.where((p) => p.ledger == ledger).fold(0, (a, p) => a + p.amount);

void main() {
  const b = LedgerBuilder();

  group('الوحدات', () {
    test('الوزن الصافي يُحسب من العيار', () {
      // 100 غرام تخرج بضاعة عيار 21 = 88.5 غرام صافي
      expect(netWeight(100000, ppm21Out), 88500);
    });

    test('لا تراكم خطأ في الكسور العشرية', () {
      // ثلاث قطع 33.33 غرام لا تُنتج 99.98999...
      final total = List.filled(3, 33330).fold<int>(0, (a, w) => a + w);
      expect(total, 99990);
    });
  });

  group('السداد', () {
    test('الدفعة النقدية تُنقص دين الطرف وتزيد الصندوق', () {
      final ps = b.receiveCash(
        counterpartyId: showroom,
        cashboxId: cashbox,
        amountFils: 1000000,
      );
      expect(ps.firstWhere((p) => p.accountId == cashbox).amount, 1000000);
      expect(ps.firstWhere((p) => p.accountId == showroom).amount, -1000000);
      expect(sumOf(ps, LedgerKind.cash), 0);
    });

  });

  group('معاملا العيار', () {
    test('العيار يعطي معاملاً مختلفاً لكل اتجاه', () {
      const k = Karat(
        id: 'k21',
        name: 'عيار 21',
        outFactorPpm: ppm21Out,
        inFactorPpm: ppm21In,
        sortOrder: 1,
      );
      expect(k.factorFor(GoldDirection.out), 885000);
      expect(k.factorFor(GoldDirection.incoming), 870000);
    });

    test('الهامش يظهر كفرق وزن حقيقي', () {
      // 100 غرام تخرج ثم تعود بنفس الوزن القائم
      final out = netWeight(100000, ppm21Out);
      final back = netWeight(100000, ppm21In);
      expect(out, 88500);
      expect(back, 87000);
      // الفارق 1.5 غرام صافي لصالح التاجر
      expect(out - back, 1500);
    });

    test('عيار 18 يخرج بـ 0.790 ويعود بـ 0.740', () {
      expect(netWeight(100000, ppm18Out), 79000);
      expect(netWeight(100000, ppm18In), 74000);
    });

    test('المعامل الخاص بطرف يتجاوز العام، والفارغ يرثه', () {
      const general = KaratFactor(
        karatId: 'k21',
        karatName: 'عيار 21',
        outFactorPpm: 885000,
        inFactorPpm: 870000,
        sortOrder: 1,
      );
      const custom = KaratFactor(
        karatId: 'k21',
        karatName: 'عيار 21',
        outFactorPpm: 890000,
        inFactorPpm: 870000,
        sortOrder: 1,
        outIsCustom: true,
      );

      expect(general.optionFor(GoldDirection.out).ppm, 885000);
      expect(custom.optionFor(GoldDirection.out).ppm, 890000);
      // الدخول لم يُتجاوز فبقي عاماً
      expect(custom.isCustomFor(GoldDirection.incoming), isFalse);
      expect(custom.optionFor(GoldDirection.incoming).ppm, 870000);
    });
  });

  group('التسكير', () {
    const b = LedgerBuilder();

    test('يحوّل دين الذهب إلى دين نقدي ولا يسدّد شيئاً', () {
      final ps = b.price(
        counterpartyId: showroom,
        tradingIncomeId: trading,
        netWeightMg: 100000,     // 100 غرام صافي عليه
        pricePerGramFils: 92600, // 92.6 دينار للغرام
        owedToUs: true,
      );

      final gold = ps.firstWhere(
          (p) => p.accountId == showroom && p.ledger == LedgerKind.gold);
      final cash = ps.firstWhere(
          (p) => p.accountId == showroom && p.ledger == LedgerKind.cash);

      expect(gold.amount, -100000);   // دين الذهب نزل
      expect(cash.amount, 9260000);   // وقام مكانه 9260 ديناراً
      expect(sumOf(ps, LedgerKind.gold), 0);
      expect(sumOf(ps, LedgerKind.cash), 0);
    });

    test('ينعكس حين يكون الذهب علينا لا لنا', () {
      final ps = b.price(
        counterpartyId: showroom,
        tradingIncomeId: trading,
        netWeightMg: 100000,
        pricePerGramFils: 92600,
        owedToUs: false,
      );

      final gold = ps.firstWhere(
          (p) => p.accountId == showroom && p.ledger == LedgerKind.gold);
      final cash = ps.firstWhere(
          (p) => p.accountId == showroom && p.ledger == LedgerKind.cash);

      expect(gold.amount, 100000);    // ديننا بالذهب نزل نحو الصفر
      expect(cash.amount, -9260000);  // وصرنا مدينين نقداً
    });

    test('التسكير الجزئي يترك الباقي ذهباً', () {
      final ps = b.price(
        counterpartyId: showroom,
        tradingIncomeId: trading,
        netWeightMg: 40000,
        pricePerGramFils: 92600,
        owedToUs: true,
      );
      // 100 غرام في الذمة، سُكّر منها 40 فقط
      final gold = ps.firstWhere(
          (p) => p.accountId == showroom && p.ledger == LedgerKind.gold);
      expect(gold.amount, -40000);
      expect(100000 + gold.amount, 60000); // الباقي غير مسكَّر
    });

    test('يرفض وزناً أو سعراً غير موجب', () {
      expect(
        () => b.price(
            counterpartyId: showroom,
            tradingIncomeId: trading,
            netWeightMg: 0,
            pricePerGramFils: 92600,
            owedToUs: true),
        throwsArgumentError,
      );
      expect(
        () => b.price(
            counterpartyId: showroom,
            tradingIncomeId: trading,
            netWeightMg: 100000,
            pricePerGramFils: 0,
            owedToUs: true),
        throwsArgumentError,
      );
    });
  });

  group('الدفعات الصادرة', () {
    const b = LedgerBuilder();

    test('الدفع النقدي يُخرج المال ويُنقص ما علينا', () {
      final ps = b.payCash(
        counterpartyId: showroom,
        cashboxId: cashbox,
        amountFils: 1000000,
      );
      expect(ps.firstWhere((p) => p.accountId == cashbox).amount, -1000000);
      expect(ps.firstWhere((p) => p.accountId == showroom).amount, 1000000);
      expect(sumOf(ps, LedgerKind.cash), 0);
    });

    test('القبض والدفع متعاكسان تماماً', () {
      final inn = b.receiveCash(
          counterpartyId: showroom, cashboxId: cashbox, amountFils: 500000);
      final out = b.payCash(
          counterpartyId: showroom, cashboxId: cashbox, amountFils: 500000);

      // قبض ثم دفع بنفس المبلغ يعيد كل حساب إلى ما كان
      final net = [...inn, ...out]
          .where((p) => p.accountId == showroom)
          .fold<int>(0, (a, p) => a + p.amount);
      expect(net, 0);
    });

  });

}
