import 'package:flutter_test/flutter_test.dart';
import 'package:gold_bashar/domain/enums.dart';
import 'package:gold_bashar/domain/models.dart';
import 'package:gold_bashar/features/reports/report_models.dart';

PeriodPosting pp(
  String tx,
  DateTime at,
  String acc,
  LedgerKind k,
  int amount,
  TxType t, {
  String? party,
  AccountKind? partyKind,
  String? item,
  String? karat,
  int? qty,
  int? gross,
  int? rate,
  bool reversed = false,
}) =>
    PeriodPosting(
      txId: tx,
      txType: t,
      docNumber: '2026-$tx',
      occurredAt: at,
      txReversed: reversed,
      accountId: acc,
      ledger: k,
      amount: amount,
      partyId: party,
      partyName: party == null ? null : 'محل $party',
      partyKind: partyKind,
      itemId: item,
      itemName: item,
      karatId: karat,
      karatName: karat,
      quantity: qty,
      grossWeightMg: gross,
      makingPerGramFils: rate,
    );

void main() {
  final d1 = DateTime(2026, 10, 5, 10);
  final d2 = DateTime(2026, 10, 6, 12);
  const shop = AccountKind.showroom;

  group('تقرير المبيعات', () {
    final postings = [
      // بيع: خاتمان 10 غ عيار 21 (صافي 8.850) مصنوعية 1.5/غ، ربح 11
      pp('1', d1, 'bag', LedgerKind.gold, -8850, TxType.sale,
          party: 'A', partyKind: shop, item: 'ring', karat: '21', qty: -2, gross: -10000),
      pp('1', d1, 'A', LedgerKind.gold, 8850, TxType.sale,
          party: 'A', partyKind: shop, item: 'ring', karat: '21', qty: 2, gross: 10000),
      pp('1', d1, 'A', LedgerKind.cash, 15000, TxType.sale,
          party: 'A', partyKind: shop, rate: 1500),
      pp('1', d1, 'income', LedgerKind.cash, -15000, TxType.sale,
          party: 'A', partyKind: shop, rate: 1500),
      pp('1', d1, 'income', LedgerKind.cash, 4000, TxType.sale,
          party: 'A', partyKind: shop),
      // مرتجع خاتم واحد 5 غ في اليوم التالي
      pp('2', d2, 'bag', LedgerKind.gold, 4425, TxType.goodsReturn,
          party: 'A', partyKind: shop, item: 'ring', karat: '21', qty: 1, gross: 5000),
      pp('2', d2, 'A', LedgerKind.cash, -7500, TxType.goodsReturn,
          party: 'A', partyKind: shop, rate: 1500),
      // بيع ملغى — لا يُحسب
      pp('3', d2, 'bag', LedgerKind.gold, -1000, TxType.sale,
          party: 'A', partyKind: shop, item: 'ring', karat: '21', qty: -1, gross: -1130, reversed: true),
    ];

    test('الإجماليات تطرح المرتجع وتتجاهل الملغى', () {
      final r = SalesReport.build(
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 31),
        postings: postings,
        bagId: 'bag',
        makingIncomeId: 'income',
      );
      expect(r.sold.netMg, 8850);
      expect(r.sold.pieces, 2);
      expect(r.returned.netMg, 4425);
      expect(r.netMg, 4425);
      expect(r.makingFils, 7500);
      expect(r.profitFils, 11000);
      expect(r.invoices, 1);
      expect(r.daysSorted.length, 2);
      expect(r.partiesSorted.single.netMg, 4425);
      expect(r.itemsSorted.single.$2.pieces, 1);
    });
  });

  group('كشف الشنطة', () {
    test('الافتتاحي = الآن − ما بعد البداية، والختامي = الافتتاحي + الفترة', () {
      // الآن في الشنطة: 3 خواتم صافي 20 غ، ورأس مال 100
      final stock = [
        const ItemStock(
          itemId: 'ring',
          itemName: 'ring',
          karatId: '21',
          karatName: '21',
          itemSort: 0,
          karatSort: 0,
          quantity: 3,
          grossMg: 22600,
          netMg: 20000,
        ),
      ];
      final since = [
        // في الفترة: وارد 5 خواتم صافي 30 + مصنوعية 60، ثم بيع 2 صافي 12
        pp('1', d1, 'bag', LedgerKind.gold, 30000, TxType.goodsIn,
            item: 'ring', karat: '21', qty: 5, gross: 33900),
        pp('1', d1, 'bag', LedgerKind.cash, 60000, TxType.goodsIn),
        pp('2', d2, 'bag', LedgerKind.gold, -12000, TxType.sale,
            item: 'ring', karat: '21', qty: -2, gross: -13560),
        // بعد نهاية الفترة: بيع 1 صافي 5
        pp('3', DateTime(2026, 11, 3), 'bag', LedgerKind.gold, -5000,
            TxType.sale, item: 'ring', karat: '21', qty: -1, gross: -5650),
      ];
      final s = BagStatement.build(
        from: DateTime(2026, 10, 1),
        to: DateTime(2026, 10, 31),
        sinceFrom: since,
        stockNow: stock,
        capitalNowFils: 100000,
      );
      const id = 'ring|21';
      expect(s.openingOf(id).pieces, 3 - 5 + 2 + 1);
      expect(s.openingOf(id).netMg, 20000 - 30000 + 12000 + 5000);
      expect(s.inOf(id).pieces, 5);
      expect(s.outOf(id).pieces, 2);
      expect(s.closing(id).pieces, 4);
      expect(s.closing(id).netMg, 25000);
      expect(s.openingCapitalFils, 40000);
      expect(s.closingCapitalFils, 100000);
      expect(s.moves.length, 2);
    });
  });
}
