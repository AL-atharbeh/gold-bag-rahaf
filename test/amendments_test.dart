import 'package:flutter_test/flutter_test.dart';
import 'package:gold_bashar/domain/enums.dart';
import 'package:gold_bashar/domain/ledger.dart';
import 'package:gold_bashar/domain/models.dart';
import 'package:gold_bashar/features/home/day_summary.dart';

int sum(List<PostingDraft> d, String account, LedgerKind ledger) => d
    .where((p) => p.accountId == account && p.ledger == ledger)
    .fold(0, (a, p) => a + p.amount);

GoodsLine line(int grams,
        {int ppm = 885000, int qty = 0, int rate = 0, bool piece = false}) =>
    GoodsLine(
      grossWeightMg: grams * 1000,
      karatId: 'k21',
      karatPpm: ppm,
      itemId: 'ring',
      quantity: qty == 0 ? null : qty,
      makingPerGramFils: rate,
      makingPerPiece: piece,
    );

void main() {
  const b = LedgerBuilder();

  group('المصنوعية', () {
    test('على القطعة = العدد × السعر، لا علاقة للوزن', () {
      expect(line(40, qty: 3, rate: 5000, piece: true).makingFils, 15000);
      expect(line(40, qty: 3, rate: 5000).makingFils, 200000);
    });

    test('خصم الكسر وخصم إضافي', () {
      expect(makingDiscountFor(150500), 500);
      expect(makingDiscountFor(150500, extraFils: 10000), 10500);
      expect(makingDiscountFor(150000), 0);
      // لا يتجاوز المجموع
      expect(makingDiscountFor(5000, extraFils: 9000), 5000);
      expect(makingDiscountFor(0, extraFils: 9000), 0);
    });

    test('الخصم ينقص ما على المحل ولا يدخل الصندوق', () {
      final d = b.shopSale(
        shopId: 'shop',
        bagAccountId: 'bag',
        cashboxId: 'box',
        makingIncomeId: 'inc',
        goods: [line(100, rate: 1505)],
        makingDiscountFils: 10500,
      );
      expect(sum(d, 'shop', LedgerKind.cash), 150500 - 10500);
      expect(sum(d, 'box', LedgerKind.cash), 0);
    });
  });

  group('المسترد داخل الفاتورة', () {
    test('200 غ مبيعة و50 مستردة: يُخصم عن المحل ويعود للشنطة', () {
      final d = b.shopSale(
        shopId: 'shop',
        bagAccountId: 'bag',
        cashboxId: 'box',
        makingIncomeId: 'inc',
        goods: [line(200)],
        recovered: [line(50)],
      );
      expect(sum(d, 'shop', LedgerKind.gold), 177000 - 44250);
      expect(sum(d, 'bag', LedgerKind.gold), -177000 + 44250);
      expect(sum(d, 'shop', LedgerKind.cash), 0);
    });

    test('مصنوعية المسترد تُخصم إن أُدخلت', () {
      final d = b.shopSale(
        shopId: 'shop',
        bagAccountId: 'bag',
        cashboxId: 'box',
        makingIncomeId: 'inc',
        recovered: [line(50, rate: 1000)],
      );
      expect(sum(d, 'shop', LedgerKind.cash), -50000);
      expect(sum(d, 'inc', LedgerKind.cash), 50000);
    });
  });

  group('التسكير', () {
    test('مثال المحل والتاجر: 100 غ، 7000 مقابل 6950، والفرق 50', () {
      final d = b.fix(
        counterpartyId: 'shop',
        tradingIncomeId: 'trading',
        cashboxId: 'box',
        netWeightMg: 100000,
        pricePerGramFils: 70000,
        owedToUs: true,
        traderId: 'trader',
        traderNetMg: 100000,
        traderPriceFils: 69500,
        classNote: noteFixGold,
      );
      expect(sum(d, 'shop', LedgerKind.gold), -100000);
      expect(sum(d, 'shop', LedgerKind.cash), 7000000);
      expect(sum(d, 'trader', LedgerKind.gold), 100000);
      expect(sum(d, 'trader', LedgerKind.cash), -6950000);
      expect(sum(d, 'trading', LedgerKind.gold), 0);
      expect(sum(d, 'trading', LedgerKind.cash), -50000);
    });

    test('النقد اختياري: الجزء يدخل الصندوق والباقي ذمة', () {
      final d = b.fix(
        counterpartyId: 'shop',
        tradingIncomeId: 'trading',
        cashboxId: 'box',
        netWeightMg: 100000,
        pricePerGramFils: 70000,
        owedToUs: true,
        cashFils: 2000000,
      );
      expect(sum(d, 'box', LedgerKind.cash), 2000000);
      expect(sum(d, 'shop', LedgerKind.cash), 5000000);
    });

    test('التصنيف لا يغيّر الأرقام', () {
      List<PostingDraft> run(String note) => b.fix(
            counterpartyId: 'shop',
            tradingIncomeId: 'trading',
            cashboxId: 'box',
            netWeightMg: 1000,
            pricePerGramFils: 70000,
            owedToUs: true,
            classNote: note,
          );
      expect(sum(run(noteFixGold), 'shop', LedgerKind.cash),
          sum(run(noteFixScrap), 'shop', LedgerKind.cash));
    });
  });

  group('البدل', () {
    GoodsLine pure(int grams) => GoodsLine(
        grossWeightMg: grams * 1000, karatId: 'k24', karatPpm: 1000000);

    test('استلام بلا تسليم يبقى في الرصيد، والأجور علينا', () {
      final d = b.exchange(
        partyId: 't',
        bagAccountId: 'bag',
        makingIncomeId: 'inc',
        received: [pure(100)],
        feePerGramFils: 500,
      );
      expect(sum(d, 't', LedgerKind.gold), -100000);
      expect(sum(d, 'bag', LedgerKind.gold), 100000);
      expect(sum(d, 't', LedgerKind.cash), -50000);
    });

    test('استلام وتسليم، والأجور لنا', () {
      final d = b.exchange(
        partyId: 't',
        bagAccountId: 'bag',
        makingIncomeId: 'inc',
        received: [pure(100)],
        delivered: [pure(100)],
        feePerGramFils: 500,
        feeForUs: true,
      );
      expect(sum(d, 't', LedgerKind.gold), 0);
      expect(sum(d, 't', LedgerKind.cash), 50000);
    });
  });

  group('الأرصدة الافتتاحية', () {
    test('طرف له ذهب وعليه نقد', () {
      final d = b.openingParty(
          partyId: 'p', capitalId: 'cap', goldMg: -5000, cashFils: 7000);
      expect(sum(d, 'p', LedgerKind.gold), -5000);
      expect(sum(d, 'p', LedgerKind.cash), 7000);
    });

    test('الشنطة: بضاعة وكسر وكاش', () {
      final d = b.openingBag(
        bagAccountId: 'bag',
        cashboxId: 'box',
        capitalId: 'cap',
        goods: [line(10, rate: 1000)],
        scrap: [
          const GoodsLine(
              grossWeightMg: 10000, karatId: 'k18', karatPpm: 740000)
        ],
        cashFils: 300000,
      );
      expect(sum(d, 'bag', LedgerKind.gold), 8850 + 7400);
      expect(sum(d, 'bag', LedgerKind.cash), 10000);
      expect(sum(d, 'box', LedgerKind.cash), 300000);
    });
  });

  test('سحب الموظف يُحسب ضمن المصاريف', () {
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
      [p('box', -20000, noteEmployeeDraw), p('emp', 20000, noteEmployeeDraw)],
      bagId: 'bag',
      cashboxId: 'box',
    );
    expect(d.expensesFils, 20000);
    expect(d.cashOutFils, 20000);
    expect(d.expenses, hasLength(1));
  });
}
