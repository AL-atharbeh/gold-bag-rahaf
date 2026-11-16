import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gold_bashar/app/providers.dart';
import 'package:gold_bashar/data/gold_repository.dart';
import 'package:gold_bashar/domain/enums.dart';
import 'package:gold_bashar/domain/models.dart';
import 'package:gold_bashar/features/bag/bag_movements.dart';
import 'package:gold_bashar/features/opening/opening_balances_page.dart';
import 'package:gold_bashar/features/shops/shop_sale_page.dart';
import 'package:gold_bashar/features/traders/trader_extra_pages.dart';
import 'package:gold_bashar/features/traders/trader_tx_page.dart';
import 'package:gold_bashar/l10n/app_localizations.dart';

const _karats = [
  KaratOption(id: 'k24', name: 'عيار 24', ppm: 1000000),
  KaratOption(id: 'k21', name: 'عيار 21', ppm: 885000),
  KaratOption(id: 'k18', name: 'عيار 18', ppm: 790000),
];
const _shop = Account(id: 's', name: 'محل الأمانة', kind: AccountKind.showroom);
const _trader = Account(id: 't', name: 'أبو محمد', kind: AccountKind.trader);
const _workshop = Account(id: 'w', name: 'مشغل', kind: AccountKind.factory);

const _system = {
  SystemAccount.shanta: 'bag',
  SystemAccount.cashbox: 'box',
  SystemAccount.tradingIncome: 'trading',
  SystemAccount.makingIncome: 'making',
  SystemAccount.capital: 'cap',
};

Widget _wrap(Widget child) => ProviderScope(
      overrides: [
        karatOptionsProvider.overrideWith((ref, q) => _karats),
        itemsProvider.overrideWith(
            (ref) => const [Item(id: 'ring', name: 'خاتم'), Item(id: 'l', name: 'ليرة')]),
        itemStockProvider.overrideWith((ref, id) => const [
              ItemStock(
                  itemId: 'ring',
                  itemName: 'خاتم',
                  karatId: 'k21',
                  karatName: 'عيار 21',
                  quantity: 5,
                  grossMg: 50000,
                  netMg: 44250),
            ]),
        recentMakingsProvider.overrideWith((ref, k) =>
            k.itemId == 'ring' && k.karatId == 'k21'
                ? [
                    LastMaking(1500, false, DateTime(2026, 11, 10)),
                    LastMaking(2500, false, DateTime(2026, 11, 3)),
                    LastMaking(3000, true, DateTime(2026, 10, 20)),
                  ]
                : const <LastMaking>[]),
        employeesProvider.overrideWith((ref) => const <Account>[]),
        accountsProvider.overrideWith((ref) => [_shop, _trader, _workshop]),
        counterpartiesProvider
            .overrideWith((ref) => [_shop, _trader, _workshop]),
        showroomsProvider.overrideWith((ref) => [_shop]),
        suppliersProvider.overrideWith((ref) => [_trader, _workshop]),
        systemAccountsProvider.overrideWith((ref) => _system),
        balancesProvider.overrideWith((ref) => Stream.value(const [])),
      ],
      child: MaterialApp(
        locale: const Locale('ar', 'JO'),
        supportedLocales: const [Locale('ar', 'JO'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    );

Future<void> _pump(WidgetTester t, Widget page) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1.0;
  addTearDown(t.view.resetPhysicalSize);
  await t.pumpWidget(_wrap(page));
  await t.pumpAndSettle();
}

void main() {
  testWidgets('البيع يعبّئ آخر مصنوعية ويعرض المسترد والخصم', (t) async {
    await _pump(t, const ShopSalePage(shopId: 's'));
    await t.tap(find.text('خاتم').first);
    await t.pumpAndSettle();
    expect(find.textContaining('آخر مصنوعية لهذا المحل'), findsOneWidget);
    expect(find.text('1.500'), findsOneWidget);
    expect(find.text('المسترد من المحل'), findsOneWidget);
    // خصم المصنوعية يظهر حين تكون هناك مصنوعية محسوبة
    await t.enterText(
        find.widgetWithText(TextFormField, 'الوزن القائم').first, '10');
    await t.pumpAndSettle();
    expect(find.text('خصم المصنوعية'), findsOneWidget);
    await t.ensureVisible(find.text('إضافة مسترد'));
    await t.pumpAndSettle();
    await t.tap(find.text('إضافة مسترد'));
    await t.pumpAndSettle();
    expect(find.text('مسترد 1'), findsOneWidget);
    expect(find.text('مصنوعية المسترد'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('آخر 3 مصنوعيات للصنف عند المحل، واختيار إحداها', (t) async {
    await _pump(t, const ShopSalePage(shopId: 's'));
    await t.tap(find.text('خاتم').first);
    await t.pumpAndSettle();
    expect(find.text('1.500 / على الغرام · 10/11'), findsOneWidget);
    expect(find.text('3.000 / على القطعة · 20/10'), findsOneWidget);
    await t.ensureVisible(find.text('2.500 / على الغرام · 3/11'));
    await t.pumpAndSettle();
    await t.tap(find.text('2.500 / على الغرام · 3/11'));
    await t.pumpAndSettle();
    expect(find.text('2.500'), findsOneWidget);
  });

  testWidgets('التسكير مع البيع: غرامات وسعر وتاجر أو مشغل', (t) async {
    await _pump(t, const ShopSalePage(shopId: 's'));
    await t.ensureVisible(find.text('تسكير مع البيع (اختياري)'));
    await t.pumpAndSettle();
    await t.tap(find.text('تسكير مع البيع (اختياري)'));
    await t.pumpAndSettle();
    expect(find.text('غرامات التسكير (صافي)'), findsOneWidget);
    expect(find.text('تسكير مع تاجر أو مشغل (اختياري)'), findsOneWidget);
    await t.enterText(
        find.widgetWithText(TextFormField, 'غرامات التسكير (صافي)'), '100');
    await t.enterText(
        find.widgetWithText(TextFormField, 'سعر غرام الحلة').last, '70');
    await t.pumpAndSettle();
    expect(find.textContaining('7000.000'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets('تسكير المحل يعرض النقد والتاجر والتصنيف', (t) async {
    await _pump(t, const TraderTxPage(trader: _shop, op: TraderOp.fixPrice));
    expect(find.text('حلة'), findsOneWidget);
    expect(find.text('كسر'), findsOneWidget);
    expect(find.text('نقد الآن (اختياري)'), findsOneWidget);
    expect(find.text('تسكير مع تاجر أو مشغل (اختياري)'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('تسكير التاجر بلا اختيار تاجر', (t) async {
    await _pump(t, const TraderTxPage(trader: _trader, op: TraderOp.fixPrice));
    expect(find.text('تسكير مع تاجر أو مشغل (اختياري)'), findsNothing);
  });

  testWidgets('استلام ذهب يبدأ بمعامل 1.000', (t) async {
    await _pump(t, const TraderTxPage(trader: _trader, op: TraderOp.receiveGold));
    expect(find.textContaining('1.000'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets('الليرة: أجور القطعة، والشنطة مغلقة افتراضياً', (t) async {
    await _pump(t, const LiraSalePage(trader: _trader));
    expect(find.text('الأجور / قطعة'), findsOneWidget);
    final sw = t.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(sw.value, isFalse);
    expect(t.takeException(), isNull);
  });

  testWidgets('البدل: الأجور لنا أو علينا', (t) async {
    await _pump(t, const ExchangePage(trader: _workshop));
    expect(find.text('لنا'), findsOneWidget);
    expect(find.text('علينا'), findsOneWidget);
    expect(find.textContaining('1.000'), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets('الأرصدة الافتتاحية تعرض الأطراف والشنطة', (t) async {
    await _pump(t, const OpeningBalancesPage());
    expect(find.text('محتوى الشنطة عند البدء'), findsOneWidget);
    expect(find.text('مشغل'), findsOneWidget);
    await t.tap(find.text('محتوى الشنطة عند البدء'));
    await t.pumpAndSettle();
    expect(find.text('إضافة كسر'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  test('حركات الشنطة تُجمع بالحركة وتُستثنى الملغاة', () {
    PeriodPosting p(String tx, int amount, {bool reversed = false}) =>
        PeriodPosting(
          txId: tx,
          txType: TxType.goodsIn,
          docNumber: tx,
          occurredAt: DateTime(2026, 10, 1),
          txReversed: reversed,
          accountId: 'bag',
          ledger: LedgerKind.gold,
          amount: amount,
          quantity: 2,
        );
    final list = bagMovements(
        [p('a', 1000), p('a', 500), p('b', -300), p('c', 9, reversed: true)]);
    expect(list.length, 2);
    expect(list.firstWhere((m) => m.first.txId == 'a').netMg, 1500);
    expect(list.firstWhere((m) => m.first.txId == 'a').pieces, 4);
  });
}
