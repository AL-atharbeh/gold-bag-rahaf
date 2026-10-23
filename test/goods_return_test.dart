import 'package:flutter_test/flutter_test.dart';
import 'package:gold_bashar/domain/enums.dart';
import 'package:gold_bashar/domain/ledger.dart';
import 'package:gold_bashar/domain/models.dart';
import 'package:gold_bashar/features/returns/partial_return_page.dart';

const b = LedgerBuilder();

int sumOf(List<PostingDraft> d, String acc, LedgerKind k) => d
    .where((x) => x.accountId == acc && x.ledger == k)
    .fold(0, (a, x) => a + x.amount);

void main() {
  // خاتمان عيار 21 (0.885) وزنهما 10 غ، مصنوعية 1.500 د.أ/غ
  const line = GoodsLine(
    grossWeightMg: 10000,
    karatId: 'k21',
    karatPpm: 885000,
    itemId: 'ring',
    quantity: 2,
    makingPerGramFils: 1500,
  );

  test('مرتجع من المحل: يعود للشنطة وينقص عن المحل ذهباً ومصنوعية', () {
    final d = b.goodsReturn(
      partyId: 'shop',
      bagAccountId: 'bag',
      makingIncomeId: 'income',
      lines: [line],
      fromShop: true,
      costBackFils: 4000,
    );
    expect(sumOf(d, 'bag', LedgerKind.gold), 8850);
    expect(sumOf(d, 'shop', LedgerKind.gold), -8850);
    expect(sumOf(d, 'shop', LedgerKind.cash), -15000);
    // تعود تكلفة القطع لرأس مال الشنطة، ويُعكس صافي الإيراد
    expect(sumOf(d, 'bag', LedgerKind.cash), 4000);
    expect(sumOf(d, 'income', LedgerKind.cash), 15000 - 4000);
    final bagGold = d.firstWhere(
        (x) => x.accountId == 'bag' && x.ledger == LedgerKind.gold);
    expect(bagGold.quantity, 2);
    expect(bagGold.itemId, 'ring');
  });

  test('مرتجع للمشغل: يخرج من الشنطة وينقص ما له علينا', () {
    final d = b.goodsReturn(
      partyId: 'ws',
      bagAccountId: 'bag',
      makingIncomeId: 'income',
      lines: [line],
      fromShop: false,
    );
    expect(sumOf(d, 'bag', LedgerKind.gold), -8850);
    expect(sumOf(d, 'ws', LedgerKind.gold), 8850);
    expect(sumOf(d, 'ws', LedgerKind.cash), 15000);
    expect(sumOf(d, 'bag', LedgerKind.cash), -15000);
    expect(sumOf(d, 'income', LedgerKind.cash), 0);
  });

  test('ربط كل بند بسعر مصنوعيته من سطور الفاتورة', () {
    final tx = TxDetail(
      id: 't',
      type: TxType.sale,
      docNumber: '2026-00001',
      occurredAt: DateTime(2026, 10, 1),
      isReversed: false,
      lines: const [
        TxLine(
            accountId: 'shop',
            ledger: LedgerKind.gold,
            amount: 8850,
            grossWeightMg: 10000,
            itemId: 'ring',
            karatId: 'k21'),
        TxLine(
            accountId: 'shop',
            ledger: LedgerKind.gold,
            amount: 3950,
            grossWeightMg: 5000,
            itemId: 'chain',
            karatId: 'k18'),
        // سلسلة بلا مصنوعية، والخاتم 1.500
        TxLine(
            accountId: 'shop',
            ledger: LedgerKind.cash,
            amount: 15000,
            makingPerGramFils: 1500),
      ],
    );
    final r = goodsWithMaking(tx, 'shop', fromShop: true);
    expect(r.map((e) => e.$2), [1500, 0]);
  });

  test('المرتجع الفارغ مرفوض', () {
    expect(
      () => b.goodsReturn(
          partyId: 'shop',
          bagAccountId: 'bag',
          makingIncomeId: 'income',
          lines: const [],
          fromShop: true),
      throwsArgumentError,
    );
  });
}
