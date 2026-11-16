import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/locale.dart';
import '../../core/units.dart';
import '../../domain/enums.dart';
import '../../domain/ledger.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../bag/goods_lines.dart';
import '../common/inputs.dart';
import '../common/ui.dart';
import '../parties/balance_widgets.dart';

/// خصم المصنوعية: بلا خصم، أو حذف الكسر، أو حذف الكسر مع خصم إضافي.
enum _Discount { none, fraction, extra }

/// تكلفة المصنوعية التي تتبع وزناً يخرج من الشنطة أو يعود إليها — بمتوسط
/// رأس المال لكل غرام صافٍ فيها.
int capitalCost(int net, AccountBalance? bag) {
  if (bag == null || net <= 0 || bag.goldMg <= 0 || bag.cashFils <= 0) {
    return 0;
  }
  final cost = (bag.cashFils * net + bag.goldMg ~/ 2) ~/ bag.goldMg;
  return cost > bag.cashFils ? bag.cashFils : cost;
}

/// بيع للمحل من الشنطة، مع استلام كسر و/أو نقد في نفس الحركة.
///
/// أربعة أقسام كلها اختيارية — يكفي واحد منها:
///   • البضاعة المباعة: بمعامل البضاعة للمحل (0.885 لعيار 21) ومصنوعية
///     على القائم تصير ديناً نقدياً عليه.
///   • المسترد: بضاعة تعود من المحل بمعامل البضاعة، ويُخصم عنه ذهبها
///     ومصنوعيتها إن أُدخلت.
///   • الكسر المستلم: بمعامل الكسر (0.870 لعيار 21) وينقص ذهب المحل.
///   • النقد المستلم: يدخل الصندوق وينقص دين المحل النقدي.
class ShopSalePage extends ConsumerStatefulWidget {
  const ShopSalePage({super.key, this.shopId});

  /// المحل إن فُتحت الشاشة من دفتره.
  final String? shopId;

  @override
  ConsumerState<ShopSalePage> createState() => _ShopSalePageState();
}

class _ShopSalePageState extends ConsumerState<ShopSalePage> {
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController();
  final _cash = TextEditingController();
  final List<GoodsLineState> _goods = [GoodsLineState()];
  final List<GoodsLineState> _recovered = [];
  final List<GoodsLineState> _scrap = [];
  final _discount = TextEditingController();
  _Discount _discountMode = _Discount.none;

  // التسكير مع البيع: غرامات وسعر، وتاجر أو مشغل اختياري بغراماته وسعره
  bool _fixOn = false;
  final _fixGrams = TextEditingController();
  final _fixPrice = TextEditingController();
  final _traderGrams = TextEditingController();
  final _traderPrice = TextEditingController();
  String? _fixTraderId;
  String _fixClass = noteFixGold;
  late String? _shopId = widget.shopId;
  DateTime _date = DateTime.now();
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    _cash.dispose();
    _discount.dispose();
    for (final c in [_fixGrams, _fixPrice, _traderGrams, _traderPrice]) {
      c.dispose();
    }
    for (final l in [..._goods, ..._recovered, ..._scrap]) {
      l.dispose();
    }
    super.dispose();
  }

  void _addGoods() {
    final last = _goods.lastOrNull;
    setState(() => _goods.add(GoodsLineState(
        karatId: last?.karatId, making: last?.making.text ?? '')));
  }

  /// اختيار منتج من البطاقات: يملأ أول بند فارغ أو يضيف بنداً جديداً.
  void _pick(ProductOption p) {
    setState(() {
      var line = _goods
          .where((g) => g.itemId == null && g.gross.text.trim().isEmpty)
          .firstOrNull;
      if (line == null) {
        line = GoodsLineState(making: _goods.lastOrNull?.making.text ?? '');
        _goods.add(line);
      }
      line
        ..itemId = p.itemId
        ..karatId = p.karatId;
    });
  }

  /// ما يُخصم من مجموع المصنوعية النهائي.
  int _discountFils(int total) => switch (_discountMode) {
        _Discount.none => 0,
        _Discount.fraction => makingDiscountFor(total),
        _Discount.extra => makingDiscountFor(total,
            extraFils: parseDinars(_discount.text) ?? 0),
      };

  /// يعبّئ آخر مصنوعية بيع بها هذا الصنف لهذا المحل، ويبقى قابلاً للتعديل،
  /// ويعرض آخر 3 للاختيار منها.
  void _applyRemembered(AppLocalizations l) {
    final shop = _shopId;
    for (final line in _goods) {
      final item = line.itemId, karat = line.karatId;
      if (shop == null || item == null || karat == null) {
        line.recent = const [];
        continue;
      }
      final recent = ref
          .watch(recentMakingsProvider(
              (partyId: shop, itemId: item, karatId: karat)))
          .valueOrNull;
      // لم تصل بعد: يُعبّأ حين تصل
      if (recent == null) continue;
      line.recent = recent;
      final key = '$shop|$item|$karat';
      if (line.makingKey == key) continue;
      line.makingKey = key;
      line.makingHint = null;
      final m = recent.firstOrNull;
      if (m == null) continue;
      line.making.text = formatDinars(m.rateFils);
      line.perPiece = m.perPiece;
      line.makingHint = l.lastMakingHint(
          formatDinars(m.rateFils), m.perPiece ? l.perPiece : l.perGram);
    }
  }

  /// التسكير المُدخل، أو null إن لم يُفعَّل أو لم يكتمل.
  /// [goldAfterSale] رصيد ذهب المحل بعد البيع: موجب = الذهب عليه.
  SaleFix? _saleFix(int goldAfterSale) {
    if (!_fixOn) return null;
    final grams = parseGrams(_fixGrams.text) ?? 0;
    final price = parseDinars(_fixPrice.text) ?? 0;
    if (grams <= 0 || price <= 0) return null;
    return SaleFix(
      netMg: grams,
      priceFils: price,
      owedToUs: goldAfterSale >= 0,
      traderId: _fixTraderId,
      // فارغة = نفس غرامات المحل وسعره
      traderNetMg: parseGrams(_traderGrams.text) ?? grams,
      traderPriceFils: parseDinars(_traderPrice.text) ?? price,
      classNote: _fixClass,
    );
  }

  void _addScrap() {
    final last = _scrap.lastOrNull;
    setState(
        () => _scrap.add(GoodsLineState(karatId: last?.karatId, scrap: true)));
  }

  Future<void> _newShop() async {
    final l = context.l10n;
    final name = await askName(context, title: l.newShop, label: l.shop);
    if (name == null || !mounted || !ensureOnline(context, ref)) return;
    try {
      final id = await ref.read(repositoryProvider).createShowroom(name);
      ref.invalidate(accountsProvider);
      setState(() => _shopId = id);
    } catch (e) {
      if (mounted) showResult(context, readableError(e), error: true);
    }
  }

  /// البنود غير الفارغة — والبند الناقص يُرجع null.
  List<GoodsLine>? _collect(
      List<GoodsLineState> lines, List<KaratOption> karats) {
    final out = <GoodsLine>[];
    for (final s in lines) {
      if (s.isBlank) continue;
      final g = s.toGoods(karats);
      if (g == null) return null;
      out.add(g);
    }
    return out;
  }

  /// كل صنف وعيار يتجاوز البيعُ فيه الموجودَ في الشنطة وزناً أو عدداً.
  List<String> _stockProblems(
    AppLocalizations l,
    List<GoodsLine> goods,
    List<ItemStock> stock,
    List<Item> items,
    List<KaratOption> karats,
  ) {
    final soldMg = <String, int>{};
    final soldQty = <String, int>{};
    for (final g in goods) {
      final key = '${g.itemId}|${g.karatId}';
      soldMg[key] = (soldMg[key] ?? 0) + g.grossWeightMg;
      soldQty[key] = (soldQty[key] ?? 0) + (g.quantity ?? 0);
    }
    final problems = <String>[];
    for (final key in soldMg.keys) {
      final parts = key.split('|');
      final rows =
          stock.where((s) => s.itemId == parts[0] && s.karatId == parts[1]);
      final haveMg = rows.fold<int>(0, (a, s) => a + s.grossMg);
      final haveQty = rows.fold<int>(0, (a, s) => a + s.quantity);
      final item = items.where((i) => i.id == parts[0]).firstOrNull?.name ?? '';
      final karat =
          karats.where((k) => k.id == parts[1]).firstOrNull?.name ?? '';
      if (soldMg[key]! > haveMg) {
        problems.add(
            l.bagNotEnough(item, karat, formatGrams(haveMg < 0 ? 0 : haveMg)));
      } else if (soldQty[key]! > haveQty) {
        problems
            .add(l.bagNotEnoughCount(item, karat, haveQty < 0 ? 0 : haveQty));
      }
    }
    return problems;
  }

  Future<void> _submit(
    List<KaratOption> goodsKarats,
    List<KaratOption> scrapKarats,
    AccountBalance? bagBalance,
  ) async {
    final l = context.l10n;
    if (!_form.currentState!.validate()) return;
    final goods = _collect(_goods, goodsKarats);
    final scrap = _collect(_scrap, scrapKarats);
    final recovered = _collect(_recovered, goodsKarats);
    if (goods == null || scrap == null || recovered == null) {
      showResult(context, l.fillLines, error: true);
      return;
    }
    final cash =
        _cash.text.trim().isEmpty ? 0 : (parseDinars(_cash.text) ?? -1);
    if (cash < 0) {
      showResult(context, l.invalidAmount, error: true);
      return;
    }
    final shopGold = (ref.read(balancesProvider).valueOrNull ??
                const <AccountBalance>[])
            .where((b) => b.accountId == _shopId)
            .firstOrNull
            ?.goldMg ??
        0;
    final saleFix = _saleFix(shopGold +
        goods.fold<int>(0, (a, g) => a + g.netMg) -
        recovered.fold<int>(0, (a, g) => a + g.netMg) -
        scrap.fold<int>(0, (a, g) => a + g.netMg));
    if (_fixOn && saleFix == null) {
      showResult(context, l.fixNeedsGramsPrice, error: true);
      return;
    }
    if (goods.isEmpty &&
        scrap.isEmpty &&
        recovered.isEmpty &&
        cash == 0 &&
        saleFix == null) {
      showResult(context, l.emptyTx, error: true);
      return;
    }

    // لا بيع لما ليس في الشنطة — يُقرأ المخزون من السيرفر لحظة الحفظ
    final bagForStock = (ref.read(systemAccountsProvider).valueOrNull ??
        {})[SystemAccount.shanta];
    if (goods.isNotEmpty && bagForStock != null) {
      final items = ref.read(itemsProvider).valueOrNull ?? const <Item>[];
      ref.invalidate(itemStockProvider(bagForStock));
      final List<ItemStock> stock;
      try {
        stock = await ref.read(itemStockProvider(bagForStock).future);
      } catch (e) {
        if (mounted) showResult(context, readableError(e), error: true);
        return;
      }
      if (!mounted) return;
      final problems = _stockProblems(l, goods, stock, items, goodsKarats);
      if (problems.isNotEmpty) {
        showResult(context, '${l.saleExceedsBag}\n${problems.join('\n')}',
            error: true);
        return;
      }
    }
    if (!ensureOnline(context, ref)) return;

    final sys = ref.read(systemAccountsProvider).valueOrNull ?? {};
    final bag = sys[SystemAccount.shanta];
    final cashbox = sys[SystemAccount.cashbox];
    final makingIncome = sys[SystemAccount.makingIncome];
    if (bag == null || cashbox == null || makingIncome == null) {
      showResult(context, 'حسابات النظام غير مهيّأة', error: true);
      return;
    }

    final goodsNet = goods.fold<int>(0, (a, g) => a + g.netMg);
    final recoveredNet = recovered.fold<int>(0, (a, g) => a + g.netMg);
    final makingTotal = goods.fold<int>(0, (a, g) => a + g.makingFils) -
        recovered.fold<int>(0, (a, g) => a + g.makingFils);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final doc = await ref.read(repositoryProvider).shopSale(
            shopId: _shopId!,
            bagAccountId: bag,
            cashboxId: cashbox,
            makingIncomeId: makingIncome,
            goods: goods,
            scrap: scrap,
            recovered: recovered,
            cashReceivedFils: cash,
            costOutFils: capitalCost(goodsNet, bagBalance),
            costBackFils: capitalCost(recoveredNet, bagBalance),
            makingDiscountFils: _discountFils(makingTotal),
            saleFix: saleFix,
            tradingIncomeId: sys[SystemAccount.tradingIncome],
            occurredAt: _date,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      invalidateAfterPosting(ref);
      navigator.pop(true);
      messenger.showSnackBar(SnackBar(
        content: Text(l.invoiceSaved(doc)),
        backgroundColor: AppColors.goldDark,
      ));
    } catch (e) {
      if (mounted) showResult(context, readableError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final shops = ref.watch(showroomsProvider);
    final items = ref.watch(itemsProvider);
    final goodsKarats = ref.watch(karatOptionsProvider(
        (accountId: _shopId, direction: GoldDirection.out)));
    final scrapKarats = ref.watch(karatOptionsProvider(
        (accountId: _shopId, direction: GoldDirection.incoming)));

    final all = [shops, items, goodsKarats, scrapKarats];
    final loading = all.any((a) => a.isLoading);
    final error = all.map((a) => a.error).whereType<Object>().firstOrNull;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(l.shopSaleTitle)),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.goldPrimary))
          : error != null
              ? CenteredMessage(
                  icon: Icons.error_outline_rounded,
                  title: readableError(error))
              : _body(l, shops.value!, items.value!, goodsKarats.value!,
                  scrapKarats.value!),
    );
  }

  Widget _body(
    AppLocalizations l,
    List<Account> shops,
    List<Item> items,
    List<KaratOption> goodsKarats,
    List<KaratOption> scrapKarats,
  ) {
    ensureKarats(_scrap, scrapKarats);
    ensureKarats(_recovered, goodsKarats);

    final sys = ref.watch(systemAccountsProvider).valueOrNull ?? {};
    final bagId = sys[SystemAccount.shanta];
    final balances =
        ref.watch(balancesProvider).valueOrNull ?? const <AccountBalance>[];
    final bagBalance = balances.where((b) => b.accountId == bagId).firstOrNull;
    final shopBalance =
        balances.where((b) => b.accountId == _shopId).firstOrNull;
    final stock =
        bagId == null ? null : ref.watch(itemStockProvider(bagId)).valueOrNull;

    // البيع مما في الشنطة فقط: الأصناف المتوفرة، ولكل صنف عياراته المتوفرة
    final inBag = (stock ?? const <ItemStock>[])
        .where((s) => s.itemId != null && s.grossMg > 0)
        .toList();
    ItemStock? stockOf(String? itemId, String karatId) => inBag
        .where((s) => s.itemId == itemId && s.karatId == karatId)
        .firstOrNull;
    final saleItems =
        items.where((i) => inBag.any((s) => s.itemId == i.id)).toList();
    List<KaratOption> karatsFor(GoodsLineState line) => goodsKarats
        .where((k) => line.itemId == null
            ? inBag.any((s) => s.karatId == k.id)
            : stockOf(line.itemId, k.id) != null)
        .toList();
    final products = [
      for (final s in inBag)
        if (items.where((i) => i.id == s.itemId).firstOrNull case final item?)
          ProductOption(
            itemId: item.id,
            karatId: s.karatId!,
            itemName: item.name,
            karatName: s.karatName ?? '',
            quantity: s.quantity,
            grossMg: s.grossMg,
          ),
    ];
    for (final line in _goods) {
      if (line.itemId != null && !saleItems.any((i) => i.id == line.itemId)) {
        line.itemId = null;
      }
      ensureKarats([line], karatsFor(line));
    }
    _applyRemembered(l);
    final goods = _collect(_goods, goodsKarats) ?? const <GoodsLine>[];
    final recovered = _collect(_recovered, goodsKarats) ?? const <GoodsLine>[];
    final scrap = _collect(_scrap, scrapKarats) ?? const <GoodsLine>[];
    final cash = parseDinars(_cash.text) ?? 0;

    final goodsNet = goods.fold<int>(0, (a, g) => a + g.netMg);
    final soldMaking = goods.fold<int>(0, (a, g) => a + g.makingFils);
    final recoveredNet = recovered.fold<int>(0, (a, g) => a + g.netMg);
    final recoveredMaking = recovered.fold<int>(0, (a, g) => a + g.makingFils);
    final making = soldMaking - recoveredMaking;
    final discount = _discountFils(making);
    final scrapNet = scrap.fold<int>(0, (a, g) => a + g.netMg);

    final goldBefore = shopBalance?.goldMg ?? 0;
    final cashBefore = shopBalance?.cashFils ?? 0;
    final goldAfterSale = goldBefore + goodsNet - recoveredNet - scrapNet;
    final fix = _saleFix(goldAfterSale);
    final fixSign = (fix?.owedToUs ?? true) ? 1 : -1;
    final fixValue = fix == null ? 0 : weightValue(fix.netMg, fix.priceFils);
    final goldAfter = goldAfterSale - fixSign * (fix?.netMg ?? 0);
    final cashAfter =
        cashBefore + making - discount - cash + fixSign * fixValue;
    final touched = goodsNet != 0 ||
        recoveredNet != 0 ||
        scrapNet != 0 ||
        cash != 0 ||
        fix != null;
    final traders =
        ref.watch(suppliersProvider).valueOrNull ?? const <Account>[];

    Widget gramsField(TextEditingController c, String label, {String? hint}) =>
        AdaptiveBox(
          width: 220,
          half: true,
          child: TextFormField(
            controller: c,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: decimalInputFormatters,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
                labelText: label, hintText: hint, suffixText: l.gramsUnit),
            onChanged: (_) => setState(() {}),
          ),
        );
    Widget priceField(TextEditingController c, {String? hint}) => AdaptiveBox(
          width: 220,
          half: true,
          child: TextFormField(
            controller: c,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: decimalInputFormatters,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
                labelText: l.pricePerGram24,
                hintText: hint,
                suffixText: l.dinarUnit),
            onChanged: (_) => setState(() {}),
          ),
        );

    // ما يتجاوز الموجود في الشنطة — يظهر هنا ويمنع الحفظ
    final warnings = stock == null
        ? const <String>[]
        : _stockProblems(l, goods, stock, items, goodsKarats);

    Widget section(String title, IconData icon) => Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Row(children: [
            Icon(icon, size: 20, color: AppColors.goldDark),
            const SizedBox(width: 8),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ]),
        );

    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // المحل + التاريخ
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AdaptiveBox(
                        width: 360,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey('shop|$_shopId|${shops.length}'),
                          initialValue: shops.any((s) => s.id == _shopId)
                              ? _shopId
                              : null,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: l.shop,
                            prefixIcon:
                                const Icon(Icons.storefront_outlined, size: 20),
                            helperText: shops.isEmpty ? l.noShops : null,
                          ),
                          items: [
                            for (final s in shops)
                              DropdownMenuItem(
                                  value: s.id, child: Text(s.name)),
                          ],
                          onChanged: widget.shopId != null
                              ? null
                              : (v) => setState(() {
                                    _shopId = v;
                                    for (final g in _goods) {
                                      g.makingKey = null;
                                    }
                                  }),
                          validator: (v) => v == null ? l.requiredField : null,
                        ),
                      ),
                      if (widget.shopId == null)
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _newShop,
                          icon:
                              const Icon(Icons.add_business_outlined, size: 18),
                          label: Text(l.newShop),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.goldDark),
                        ),
                      AdaptiveBox(
                        width: 240,
                        child: DateField(
                            value: _date,
                            onChanged: (d) => setState(() => _date = d)),
                      ),
                    ],
                  ),
                  if (shopBalance != null) ...[
                    const SizedBox(height: 12),
                    BalanceChips(goldMg: goldBefore, cashFils: cashBefore),
                  ],
                  const SizedBox(height: 16),

                  // ١) البضاعة المباعة
                  section(l.soldGoods, Icons.sell_outlined),
                  if (stock != null && saleItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text('${l.bagEmpty} — ${l.bagEmptyHint}',
                          style:
                              const TextStyle(color: AppColors.textSecondary)),
                    ),
                  // بطاقات المنتجات المتوفرة — ضغطة تضيف بنداً بالصنف والعيار الصحيحين
                  if (products.isNotEmpty) ...[
                    Text(l.pickFromBag,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final p in products)
                          AdaptiveBox(
                            width: 190,
                            half: true,
                            spacing: 10,
                            child: _ProductCard(
                              product: p,
                              selected: _goods.any((g) =>
                                  g.itemId == p.itemId &&
                                  g.karatId == p.karatId),
                              onTap: () => _pick(p),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    for (var i = 0; i < _goods.length; i++) ...[
                      GoodsLineCard(
                        key: ObjectKey(_goods[i]),
                        index: i,
                        line: _goods[i],
                        items: saleItems,
                        karats: goodsKarats,
                        products: products,
                        perPieceOption: true,
                        canRemove: true,
                        onRemove: () =>
                            setState(() => _goods.removeAt(i).dispose()),
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: _busy ? null : _addGoods,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: Text(l.addLine),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.goldDark),
                    ),
                  ),
                  for (final w in warnings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(w,
                          style: const TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),

                  // خصم المصنوعية على المجموع النهائي
                  if (making > 0) ...[
                    section(l.makingDiscount, Icons.percent_rounded),
                    SegmentedButton<_Discount>(
                      segments: [
                        ButtonSegment(
                            value: _Discount.none, label: Text(l.noDiscount)),
                        ButtonSegment(
                            value: _Discount.fraction,
                            label: Text(l.dropFraction)),
                        ButtonSegment(
                            value: _Discount.extra,
                            label: Text(l.extraDiscount)),
                      ],
                      selected: {_discountMode},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) =>
                          setState(() => _discountMode = s.first),
                    ),
                    if (_discountMode == _Discount.extra) ...[
                      const SizedBox(height: 12),
                      AdaptiveBox(
                        width: 260,
                        child: DinarsField(
                          controller: _discount,
                          label: l.extraDiscount,
                          required: false,
                          allowZero: true,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                    if (discount > 0) ...[
                      const SizedBox(height: 10),
                      Pill(
                          '${l.finalMaking}: ${formatDinars(making - discount)} ${l.dinarUnit}'),
                    ],
                    const SizedBox(height: 8),
                  ],

                  // ٢) المسترد من المحل — داخل نفس الحركة
                  section(l.recoveredGoods, Icons.assignment_return_outlined),
                  for (var i = 0; i < _recovered.length; i++) ...[
                    GoodsLineCard(
                      key: ObjectKey(_recovered[i]),
                      index: i,
                      title: l.recoveredLine(i + 1),
                      line: _recovered[i],
                      items: items,
                      karats: goodsKarats,
                      editableFactor: true,
                      perPieceOption: true,
                      makingLabel: l.recoveredMaking,
                      canRemove: true,
                      onRemove: () =>
                          setState(() => _recovered.removeAt(i).dispose()),
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: _busy
                          ? null
                          : () => setState(() => _recovered.add(GoodsLineState(
                              karatId: _recovered.lastOrNull?.karatId))),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: Text(l.addRecovered),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.goldDark),
                    ),
                  ),

                  // ٣) الكسر المستلم
                  section(l.receivedScrap, Icons.recycling_rounded),
                  for (var i = 0; i < _scrap.length; i++) ...[
                    GoodsLineCard(
                      key: ObjectKey(_scrap[i]),
                      index: i,
                      title: l.scrapLine(i + 1),
                      line: _scrap[i],
                      karats: scrapKarats,
                      editableFactor: true,
                      altKarats: goodsKarats,
                      canRemove: true,
                      onRemove: () =>
                          setState(() => _scrap.removeAt(i).dispose()),
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: _busy ? null : _addScrap,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: Text(l.addScrap),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.goldDark),
                    ),
                  ),

                  // ٤) النقد المستلم
                  section(l.receivedCash, Icons.payments_outlined),
                  AdaptiveBox(
                    width: 260,
                    child: DinarsField(
                      controller: _cash,
                      label: l.cashAmount,
                      required: false,
                      allowZero: true,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  // ٥) التسكير مع البيع — اختياري، ومعه تاجر أو مشغل
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _fixOn,
                    onChanged: (v) => setState(() => _fixOn = v),
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.goldDark,
                    secondary: const Icon(Icons.lock_clock_outlined,
                        color: AppColors.goldDark),
                    title: Text(l.fixInSale,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(l.fixInSaleHint,
                        style: const TextStyle(fontSize: 12)),
                  ),
                  if (_fixOn) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 12, runSpacing: 12, children: [
                      gramsField(_fixGrams, l.fixGrams),
                      priceField(_fixPrice),
                    ]),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                            value: noteFixGold, label: Text(l.fixClassGold)),
                        ButtonSegment(
                            value: noteFixScrap, label: Text(l.fixClassScrap)),
                      ],
                      selected: {_fixClass},
                      showSelectedIcon: false,
                      onSelectionChanged: (v) =>
                          setState(() => _fixClass = v.first),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: _fixTraderId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: l.fixWithTrader,
                        prefixIcon:
                            const Icon(Icons.handshake_outlined, size: 20),
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(l.noTrader)),
                        for (final t in traders)
                          DropdownMenuItem(value: t.id, child: Text(t.name)),
                      ],
                      onChanged: (v) => setState(() => _fixTraderId = v),
                    ),
                    if (_fixTraderId != null) ...[
                      const SizedBox(height: 12),
                      Wrap(spacing: 12, runSpacing: 12, children: [
                        gramsField(_traderGrams, l.traderGrams,
                            hint: _fixGrams.text),
                        priceField(_traderPrice, hint: _fixPrice.text),
                      ]),
                      const SizedBox(height: 4),
                      Text(l.traderFixHint,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                    if (fix != null) ...[
                      const SizedBox(height: 10),
                      Pill(
                          '${l.opFix}: ${formatGrams(fix.netMg)} ${l.gramsUnit} × ${formatDinars(fix.priceFils)} = ${formatDinars(fixValue)} ${l.dinarUnit}'),
                      if (fix.traderId != null &&
                          (fix.traderNetMg != fix.netMg ||
                              fix.traderPriceFils != fix.priceFils)) ...[
                        const SizedBox(height: 6),
                        Pill(
                            '${l.fixSpread}: ${formatDinars(fixValue - weightValue(fix.traderNetMg, fix.traderPriceFils))} ${l.dinarUnit}'),
                      ],
                    ],
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _note,
                    decoration: InputDecoration(
                      labelText: l.noteOptional,
                      prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // الملخص والأثر على حساب المحل
                  if (touched) ...[
                    SummaryBar(title: l.summary, items: [
                      if (goodsNet != 0)
                        (
                          l.soldGoods,
                          '${formatGrams(goodsNet)} ${l.gramsUnit}'
                        ),
                      if (recoveredNet != 0)
                        (
                          l.recoveredGoods,
                          '${formatGrams(recoveredNet)} ${l.gramsUnit}'
                        ),
                      if (making != 0)
                        (
                          l.totalMaking,
                          '${formatDinars(making - discount)} ${l.dinarUnit}'
                        ),
                      if (scrapNet != 0)
                        (
                          l.receivedScrap,
                          '${formatGrams(scrapNet)} ${l.gramsUnit}'
                        ),
                      if (cash != 0)
                        (
                          l.receivedCash,
                          '${formatDinars(cash)} ${l.dinarUnit}'
                        ),
                      if (fix != null)
                        (
                          l.opFix,
                          '${formatGrams(fix.netMg)} ${l.gramsUnit} = ${formatDinars(fixValue)} ${l.dinarUnit}'
                        ),
                    ]),
                    const SizedBox(height: 12),
                    BalanceChange(
                      title: l.accountEffect,
                      goldBefore: goldBefore,
                      goldAfter: goldAfter,
                      cashBefore: cashBefore,
                      cashAfter: cashAfter,
                    ),
                    const SizedBox(height: 20),
                  ],
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _submit(goodsKarats, scrapKarats, bagBalance),
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(l.saveTx),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard(
      {required this.product, required this.selected, required this.onTap});

  final ProductOption product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final p = product;
    return Material(
      color: selected ? AppColors.goldContainer : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.goldPrimary : AppColors.border,
              width: selected ? 2 : 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(p.itemName,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w800)),
                  ),
                  // العيار بارز — هو ما يُخلط بين الحلق 18 والحلق 21
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.goldPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(p.karatName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                [
                  if (p.quantity > 0) l.piecesCount(p.quantity),
                  '${formatGrams(p.grossMg)} ${l.gramsUnit}',
                ].join('  ·  '),
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
