import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shops/shop_sale_page.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/locale.dart';
import '../../core/units.dart';
import '../../data/gold_repository.dart';
import '../../domain/enums.dart';
import '../../domain/ledger.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../bag/goods_in_page.dart';
import '../bag/goods_lines.dart';
import '../common/inputs.dart';
import '../common/ui.dart';
import '../parties/balance_widgets.dart';
import 'trader_extra_pages.dart';

/// عمليات التعامل مع التاجر — مأخوذة من ورقة "الشركة الدولية".
enum TraderOp {
  /// بيع ذهب/كسر للتاجر (بالهاتف غالباً): علينا ذهب، لنا نقد.
  sellGold,

  /// شراء ذهب/كسر من التاجر: لنا ذهب، علينا نقد.
  buyGold,

  /// تسكير: تحويل رصيد الذهب إلى نقد بسعر الحلة اليوم.
  fixPrice,

  /// تسليم كسر من الشنطة للتاجر.
  deliverScrap,

  /// استلام كسر من التاجر إلى الشنطة.
  receiveScrap,

  /// تسليم ذهب من الشنطة بأي عيار، بمعامل 1.000 افتراضياً.
  deliverGold,

  /// استلام ذهب إلى الشنطة بأي عيار، بمعامل 1.000 افتراضياً.
  receiveGold,

  /// قبض نقد أو شيك.
  receiveCash,

  /// دفع نقد أو شيك.
  payCash,
}

/// قائمة العمليات — تُفتح من دفتر التاجر أو من زر "حركة" في القائمة.
Future<void> showTraderOps(BuildContext context, Account trader) {
  final l = context.l10n;
  final ops = <(TraderOp?, IconData, String, String)>[
    (
      TraderOp.receiveGold,
      Icons.login_rounded,
      l.opReceiveGold,
      l.opReceiveGoldDesc
    ),
    (
      TraderOp.deliverGold,
      Icons.logout_rounded,
      l.opDeliverGold,
      l.opDeliverGoldDesc
    ),
    (
      TraderOp.sellGold,
      Icons.call_made_rounded,
      l.opSellGold,
      l.opSellGoldDesc
    ),
    (
      TraderOp.buyGold,
      Icons.call_received_rounded,
      l.opBuyGold,
      l.opBuyGoldDesc
    ),
    (TraderOp.fixPrice, Icons.lock_clock_rounded, l.opFix, l.opFixDesc),
    (
      TraderOp.deliverScrap,
      Icons.outbox_rounded,
      l.opDeliverScrap,
      l.opDeliverScrapDesc
    ),
    (
      TraderOp.receiveScrap,
      Icons.move_to_inbox_rounded,
      l.opReceiveScrap,
      l.opReceiveScrapDesc
    ),
    (
      TraderOp.receiveCash,
      Icons.savings_outlined,
      l.opReceiveCash,
      l.opReceiveCashDesc
    ),
    (TraderOp.payCash, Icons.payments_outlined, l.opPayCash, l.opPayCashDesc),
    (null, Icons.receipt_long_outlined, l.opGoodsInvoice, l.opGoodsInvoiceDesc),
  ];

  return _opsSheet(context, '${l.traderOps} — ${trader.name}', [
    for (final (op, icon, title, desc) in ops)
      (
        icon,
        title,
        desc,
        () => op == null
            ? GoodsInPage(workshopId: trader.id)
            : TraderTxPage(trader: trader, op: op),
      ),
    (
      Icons.monetization_on_outlined,
      l.opLira,
      l.opLiraDesc,
      () => LiraSalePage(trader: trader),
    ),
    (
      Icons.swap_horiz_rounded,
      l.opExchange,
      l.opExchangeDesc,
      () => ExchangePage(trader: trader),
    ),
  ]);
}

/// عمليات المحل: البيع، والتسكير (تحويل ذهب عليه إلى نقد بسعر اليوم)،
/// وقبض النقد أو الشيك.
Future<void> showShopOps(BuildContext context, Account shop) {
  final l = context.l10n;
  return _opsSheet(context, '${l.shopOps} — ${shop.name}', [
    (
      Icons.sell_rounded,
      l.sell,
      l.shopSellDesc,
      () => ShopSalePage(shopId: shop.id),
    ),
    (
      Icons.lock_clock_rounded,
      l.opFix,
      l.shopFixDesc,
      () => TraderTxPage(trader: shop, op: TraderOp.fixPrice),
    ),
    (
      Icons.savings_outlined,
      l.opReceiveCash,
      l.opReceiveCashDesc,
      () => TraderTxPage(trader: shop, op: TraderOp.receiveCash),
    ),
  ]);
}

Future<void> _opsSheet(BuildContext context, String title,
    List<(IconData, String, String, Widget Function())> ops) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            for (final (icon, name, desc, page) in ops) ...[
              GoldCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                      context, MaterialPageRoute(builder: (_) => page()));
                },
                child: Row(children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.goldContainer,
                    child: Icon(icon, size: 18, color: AppColors.goldDark),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                          Text(desc,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ]),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    ),
  );
}

class TraderTxPage extends ConsumerStatefulWidget {
  const TraderTxPage({super.key, required this.trader, required this.op});

  final Account trader;
  final TraderOp op;

  @override
  ConsumerState<TraderTxPage> createState() => _TraderTxPageState();
}

class _TraderTxPageState extends ConsumerState<TraderTxPage> {
  final _form = GlobalKey<FormState>();
  final _grams = TextEditingController();
  final _price = TextEditingController();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  final _chequeNo = TextEditingController();
  final _bank = TextEditingController();
  final List<GoodsLineState> _scrap = [GoodsLineState(scrap: true)];
  DateTime _date = DateTime.now();
  DateTime _due = DateTime.now().add(const Duration(days: 30));
  bool _byCheque = false;

  /// التسكير: true = الذهب لنا ويصير نقداً لنا، false = علينا ويصير نقداً علينا.
  bool? _fixOwedToUs;
  bool _busy = false;

  TraderOp get op => widget.op;
  bool get _isPrice =>
      op == TraderOp.sellGold ||
      op == TraderOp.buyGold ||
      op == TraderOp.fixPrice;
  bool get _isGold =>
      op == TraderOp.deliverGold || op == TraderOp.receiveGold;
  bool get _isScrap =>
      op == TraderOp.deliverScrap || op == TraderOp.receiveScrap || _isGold;

  /// تخرج من الشنطة، فلا تتجاوز ما فيها.
  bool get _delivers =>
      op == TraderOp.deliverScrap || op == TraderOp.deliverGold;

  /// البيع والشراء يُدخلان بالعيار والوزن كالكسر، ويُحوَّلان للحلة تلقائياً.
  bool get _usesLines =>
      _isScrap || op == TraderOp.sellGold || op == TraderOp.buyGold;

  // التسكير: دفعة اختيارية، وتاجر اختياري، وتصنيف حلة أو كسر
  final _fixCash = TextEditingController();
  final _traderGrams = TextEditingController();
  final _traderPrice = TextEditingController();
  String? _fixTraderId;
  String _fixClass = noteFixGold;

  /// استلام كسر: جزء منه يُشترى نقداً بدل إضافته كله لرصيد الذهب.
  bool _partial = false;
  final _partGrams = TextEditingController();
  final _partPrice = TextEditingController();

  int _linesNet(List<KaratOption> ks) =>
      (_scrapLines(ks) ?? const <GoodsLine>[])
          .fold<int>(0, (a, x) => a + x.netMg);

  /// الوزن الصافي (حلة) لعمليات السعر.
  int _priceNet(List<KaratOption> ks) =>
      op == TraderOp.fixPrice ? (parseGrams(_grams.text) ?? 0) : _linesNet(ks);

  /// وصف البنود للملاحظة: "عيار 21 · 100.000 غ × 0.870".
  String _describe(List<GoodsLine> lines, List<KaratOption> ks) => lines
      .map((g) =>
          '${ks.where((k) => k.id == g.karatId).firstOrNull?.name ?? ''} · '
          '${formatGrams(g.grossWeightMg)} × ${(g.karatPpm / 1000000).toStringAsFixed(3)}')
      .join(' + ');

  Future<void> _addKarat(GoodsLineState line) async {
    final l = context.l10n;
    final name = TextEditingController();
    final factor = TextEditingController();
    final result = await showDialog<(String, int)>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.newKarat),
        content: SizedBox(
          width: 380,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
                controller: name,
                autofocus: true,
                decoration: InputDecoration(labelText: l.karatNameLabel)),
            const SizedBox(height: 12),
            TextField(
              controller: factor,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: decimalInputFormatters,
              textDirection: TextDirection.ltr,
              decoration:
                  InputDecoration(labelText: l.factorLabel, hintText: '0.820'),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          FilledButton(
            onPressed: () {
              final ppm = parseKaratFactor(factor.text);
              if (name.text.trim().isEmpty ||
                  ppm == null ||
                  ppm <= 0 ||
                  ppm > karatPpmScale) {
                return;
              }
              Navigator.pop(ctx, (name.text.trim(), ppm));
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() => line.rev++);
    if (result == null || !ensureOnline(context, ref)) return;
    try {
      final id =
          await ref.read(repositoryProvider).createKarat(result.$1, result.$2);
      ref.invalidate(karatsProvider);
      ref.invalidate(karatFactorsProvider);
      ref.invalidate(karatOptionsProvider);
      if (mounted) {
        setState(() => line.karatId = id);
        showResult(context, l.karatAdded);
      }
    } catch (e) {
      if (mounted) showResult(context, readableError(e), error: true);
    }
  }

  @override
  void dispose() {
    _partGrams.dispose();
    _partPrice.dispose();
    _fixCash.dispose();
    _traderGrams.dispose();
    _traderPrice.dispose();
    for (final c in [_grams, _price, _amount, _note, _chequeNo, _bank]) {
      c.dispose();
    }
    for (final s in _scrap) {
      s.dispose();
    }
    super.dispose();
  }

  String _title(AppLocalizations l) => switch (op) {
        TraderOp.sellGold => l.opSellGold,
        TraderOp.buyGold => l.opBuyGold,
        TraderOp.fixPrice => l.opFix,
        TraderOp.deliverScrap => l.opDeliverScrap,
        TraderOp.receiveScrap => l.opReceiveScrap,
        TraderOp.deliverGold => l.opDeliverGold,
        TraderOp.receiveGold => l.opReceiveGold,
        TraderOp.receiveCash => l.opReceiveCash,
        TraderOp.payCash => l.opPayCash,
      };

  /// لصالحنا في الذهب؟ — يحدد اتجاه القيد لعمليات السعر.
  bool _owedToUs(int goldBalance) => switch (op) {
        TraderOp.sellGold => true, // علينا ذهب ولنا نقد
        TraderOp.buyGold => false,
        _ => _fixOwedToUs ?? goldBalance > 0,
      };

  List<GoodsLine>? _scrapLines(List<KaratOption> karats) {
    final out = <GoodsLine>[];
    for (final s in _scrap) {
      if (s.isBlank) continue;
      final g = s.toGoods(karats);
      if (g == null) return null;
      out.add(g);
    }
    return out;
  }

  /// الكسر المتوفر في الشنطة لكل عيار.
  Map<String, int> _bagScrap(List<ItemStock> stock) {
    final m = <String, int>{};
    for (final s in stock.where((s) => s.itemId == null && s.karatId != null)) {
      m[s.karatId!] = (m[s.karatId!] ?? 0) + s.grossMg;
    }
    return m;
  }

  List<String> _scrapProblems(AppLocalizations l, List<GoodsLine> lines,
      Map<String, int> have, List<KaratOption> karats) {
    final want = <String, int>{};
    for (final g in lines) {
      want[g.karatId] = (want[g.karatId] ?? 0) + g.grossWeightMg;
    }
    return [
      for (final e in want.entries)
        if (e.value > (have[e.key] ?? 0))
          l.bagScrapNotEnough(
            karats.where((k) => k.id == e.key).firstOrNull?.name ?? '',
            formatGrams((have[e.key] ?? 0) < 0 ? 0 : have[e.key]!),
          ),
    ];
  }

  Future<void> _submit(List<KaratOption> karats, int goldBalance) async {
    final l = context.l10n;
    if (!_form.currentState!.validate()) return;
    if (!ensureOnline(context, ref)) return;

    final sys = ref.read(systemAccountsProvider).valueOrNull ?? {};
    final bag = sys[SystemAccount.shanta];
    final cashbox = sys[SystemAccount.cashbox];
    final trading = sys[SystemAccount.tradingIncome];
    if (bag == null || cashbox == null || trading == null) {
      showResult(context, 'حسابات النظام غير مهيّأة', error: true);
      return;
    }

    final repo = ref.read(repositoryProvider);
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    List<GoodsLine>? lines;
    if (_usesLines) {
      lines = _scrapLines(karats);
      if (lines == null || lines.isEmpty) {
        showResult(context, l.fillLines, error: true);
        return;
      }
    }

    // استلام كسر مع شراء جزء منه نقداً
    PartialPricing? pricing;
    if (op == TraderOp.receiveScrap && _partial) {
      final part = parseGrams(_partGrams.text) ?? 0;
      final price = parseDinars(_partPrice.text) ?? 0;
      if (part <= 0 || price <= 0) {
        showResult(context, l.fillLines, error: true);
        return;
      }
      if (part > lines!.fold<int>(0, (a, g) => a + g.netMg)) {
        showResult(context, l.partExceeds, error: true);
        return;
      }
      pricing = PartialPricing(
          tradingIncomeId: trading, netWeightMg: part, pricePerGramFils: price);
    }

    if (_isScrap) {
      if (_delivers) {
        // لا تسليم لكسر ليس في الشنطة — المخزون من السيرفر لحظة الحفظ
        ref.invalidate(itemStockProvider(bag));
        final stock = await ref.read(itemStockProvider(bag).future);
        if (!mounted) return;
        final problems = _scrapProblems(l, lines!, _bagScrap(stock), karats);
        if (problems.isNotEmpty) {
          showResult(context, '${l.scrapExceedsBag}\n${problems.join('\n')}',
              error: true);
          return;
        }
      }
    }

    setState(() => _busy = true);
    try {
      final String doc;
      if (op == TraderOp.fixPrice) {
        final grams = _priceNet(karats);
        final price = parseDinars(_price.text)!;
        doc = await repo.fix(
          partyId: widget.trader.id,
          tradingIncomeId: trading,
          cashboxId: cashbox,
          netWeightMg: grams,
          pricePerGramFils: price,
          owedToUs: _owedToUs(goldBalance),
          cashFils: parseDinars(_fixCash.text) ?? 0,
          traderId: _fixTraderId,
          // فارغة = نفس غرامات المحل وسعره
          traderNetMg: parseGrams(_traderGrams.text) ?? grams,
          traderPriceFils: parseDinars(_traderPrice.text) ?? price,
          classNote: _fixClass,
          occurredAt: _date,
          note: note,
        );
      } else if (_isPrice) {
        final described = lines == null ? null : _describe(lines, karats);
        doc = await repo.traderPrice(
          traderId: widget.trader.id,
          tradingIncomeId: trading,
          netWeightMg: _priceNet(karats),
          pricePerGramFils: parseDinars(_price.text)!,
          owedToUs: _owedToUs(goldBalance),
          type: switch (op) {
            TraderOp.sellGold => TxType.sale,
            TraderOp.buyGold => TxType.purchase,
            _ => TxType.pricing,
          },
          occurredAt: _date,
          note: [if (described != null) described, if (note != null) note]
                  .join(' — ')
                  .isEmpty
              ? null
              : [if (described != null) described, if (note != null) note]
                  .join(' — '),
        );
      } else if (_isScrap) {
        doc = await repo.scrapMove(
          partyId: widget.trader.id,
          bagAccountId: bag,
          lines: lines!,
          toParty: _delivers,
          pricing: pricing,
          occurredAt: _date,
          note: note,
        );
      } else {
        doc = await repo.cashMove(
          partyId: widget.trader.id,
          // الشيك يُخصم من كاش الطرف كالنقد، لكنه يُحفظ في حساب الشيكات
          // لا في كاش الشنطة
          cashboxId:
              _byCheque ? (sys[SystemAccount.cheques] ?? cashbox) : cashbox,
          amountFils: parseDinars(_amount.text)!,
          incoming: op == TraderOp.receiveCash,
          cheque: _byCheque
              ? ChequeInfo(
                  dueDate: _due,
                  number: _chequeNo.text.trim().isEmpty
                      ? null
                      : _chequeNo.text.trim(),
                  bank: _bank.text.trim().isEmpty ? null : _bank.text.trim(),
                )
              : null,
          occurredAt: _date,
          note: note,
        );
        if (_byCheque) {
          ref.invalidate(allChequesProvider);
          ref.invalidate(pendingChequesProvider);
        }
      }
      invalidateAfterPosting(ref);
      navigator.pop(true);
      messenger.showSnackBar(SnackBar(
          content: Text(l.invoiceSaved(doc)),
          backgroundColor: AppColors.goldDark));
    } catch (e) {
      if (mounted) showResult(context, readableError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final karats = ref.watch(karatOptionsProvider(
        (accountId: widget.trader.id, direction: GoldDirection.incoming)));
    final balance =
        (ref.watch(balancesProvider).valueOrNull ?? const <AccountBalance>[])
            .where((b) => b.accountId == widget.trader.id)
            .firstOrNull;
    final goldBefore = balance?.goldMg ?? 0;
    final cashBefore = balance?.cashFils ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('${_title(l)} — ${widget.trader.name}')),
      body: AsyncBody<List<KaratOption>>(
        value: karats,
        data: (ks) {
          if (_isGold) ensurePure(_scrap, ks);
          ensureKarats(_scrap, ks);

          // الأثر على الرصيدين قبل الحفظ
          var dGold = 0;
          var dCash = 0;
          if (_isPrice) {
            final g = _priceNet(ks);
            final p = parseDinars(_price.text) ?? 0;
            final v = weightValue(g, p);
            final s = _owedToUs(goldBefore) ? 1 : -1;
            dGold = -s * g;
            dCash = s * v;
            if (op == TraderOp.fixPrice) {
              dCash -= s * (parseDinars(_fixCash.text) ?? 0);
            }
          } else if (_isScrap) {
            final net = _linesNet(ks);
            dGold = _delivers ? net : -net;
            // الجزء المشترى نقداً يرجع لرصيد ذهبه ويصير ثمنه علينا
            if (op == TraderOp.receiveScrap && _partial) {
              final part = parseGrams(_partGrams.text) ?? 0;
              dGold += part;
              dCash -= weightValue(part, parseDinars(_partPrice.text) ?? 0);
            }
          } else {
            final a = parseDinars(_amount.text) ?? 0;
            dCash = op == TraderOp.receiveCash ? -a : a;
          }

          final bagId = (ref.watch(systemAccountsProvider).valueOrNull ??
              {})[SystemAccount.shanta];
          final stock = bagId == null
              ? null
              : ref.watch(itemStockProvider(bagId)).valueOrNull;
          final problems = _delivers && stock != null
              ? _scrapProblems(
                  l, _scrapLines(ks) ?? const [], _bagScrap(stock), ks)
              : const <String>[];

          return Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BalanceChips(goldMg: goldBefore, cashFils: cashBefore),
                        const SizedBox(height: 16),
                        AdaptiveBox(
                          width: 240,
                          child: DateField(
                              value: _date,
                              onChanged: (d) => setState(() => _date = d)),
                        ),
                        const SizedBox(height: 16),
                        if (_isPrice) ..._priceFields(l, goldBefore, ks),
                        if (_isScrap) ..._scrapFields(l, ks, stock),
                        if (!_isPrice && !_isScrap) ..._cashFields(l),
                        for (final p in problems)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(p,
                                style: const TextStyle(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w700)),
                          ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _note,
                          decoration: InputDecoration(
                            labelText: l.noteOptional,
                            prefixIcon:
                                const Icon(Icons.notes_rounded, size: 20),
                          ),
                        ),
                        if (dGold != 0 || dCash != 0) ...[
                          const SizedBox(height: 20),
                          BalanceChange(
                            title: l.accountEffect,
                            goldBefore: goldBefore,
                            goldAfter: goldBefore + dGold,
                            cashBefore: cashBefore,
                            cashAfter: cashBefore + dCash,
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed:
                              _busy ? null : () => _submit(ks, goldBefore),
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
        },
      ),
    );
  }

  /// بنود الذهب/الكسر: عيار (أو عيار جديد) + وزن قائم + معامل يدوي اختياري.
  List<Widget> _lineCards(AppLocalizations l, List<KaratOption> ks) => [
        for (var i = 0; i < _scrap.length; i++) ...[
          GoodsLineCard(
            key: ObjectKey(_scrap[i]),
            index: i,
            title: _isScrap && !_isGold
                ? l.scrapLine(i + 1)
                : l.lineNumber(i + 1),
            line: _scrap[i],
            karats: ks,
            editableFactor: true,
            altKarats: ref
                    .watch(karatOptionsProvider((
                      accountId: widget.trader.id,
                      direction: GoldDirection.out
                    )))
                    .valueOrNull ??
                const [],
            onAddKarat: () => _addKarat(_scrap[i]),
            canRemove: _scrap.length > 1,
            onRemove: () => setState(() => _scrap.removeAt(i).dispose()),
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 12),
        ],
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: _busy
                ? null
                : () => setState(() => _scrap.add(
                    GoodsLineState(karatId: _scrap.last.karatId, scrap: true))),
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: Text(_isScrap && !_isGold ? l.addScrap : l.addLine),
            style: TextButton.styleFrom(foregroundColor: AppColors.goldDark),
          ),
        ),
      ];

  Widget _priceField(AppLocalizations l, TextEditingController c,
          {bool required = true, bool half = true}) =>
      AdaptiveBox(
        width: 220,
        half: half,
        child: TextFormField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: decimalInputFormatters,
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(
              labelText: l.pricePerGram24, suffixText: l.dinarUnit),
          onChanged: (_) => setState(() {}),
          validator: (v) {
            if (!required) return null;
            final f = parseDinars(v ?? '');
            return (f == null || f <= 0) ? l.invalidAmount : null;
          },
        ),
      );

  Widget _gramsField(AppLocalizations l, TextEditingController c, String label,
          {bool required = true}) =>
      AdaptiveBox(
        width: 220,
        half: true,
        child: TextFormField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: decimalInputFormatters,
          textDirection: TextDirection.ltr,
          decoration:
              InputDecoration(labelText: label, suffixText: l.gramsUnit),
          onChanged: (_) => setState(() {}),
          validator: (v) {
            if (!required) return null;
            final mg = parseGrams(v ?? '');
            return (mg == null || mg <= 0) ? l.invalidWeight : null;
          },
        ),
      );

  List<Widget> _priceFields(
      AppLocalizations l, int goldBalance, List<KaratOption> ks) {
    final g = _priceNet(ks);
    final p = parseDinars(_price.text) ?? 0;
    return [
      if (op == TraderOp.fixPrice) ...[
        Text(l.fixDirection,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(l.fixWeOwe)),
            ButtonSegment(value: true, label: Text(l.fixTheyOwe)),
          ],
          selected: {_fixOwedToUs ?? goldBalance > 0},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _fixOwedToUs = s.first),
        ),
        const SizedBox(height: 16),
        Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _gramsField(l, _grams, l.netGrams24),
              _priceField(l, _price),
              // تسكير الرصيد كله بضغطة — وإلا جزء منه ويبقى الباقي ذهباً
              if (goldBalance != 0)
                AdaptiveBox(
                  width: 260,
                  child: OutlinedButton(
                    onPressed: () => setState(
                        () => _grams.text = formatGrams(goldBalance.abs())),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.goldDark),
                    child: Text(
                        '${l.wholeBalance}: ${formatGrams(goldBalance.abs())} ${l.gramsUnit}'),
                  ),
                ),
            ]),
        const SizedBox(height: 16),
        Text(l.fixClass, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: noteFixGold, label: Text(l.fixClassGold)),
            ButtonSegment(value: noteFixScrap, label: Text(l.fixClassScrap)),
          ],
          selected: {_fixClass},
          showSelectedIcon: false,
          onSelectionChanged: (s) => setState(() => _fixClass = s.first),
        ),
        const SizedBox(height: 16),
        AdaptiveBox(
          width: 260,
          child: DinarsField(
            controller: _fixCash,
            label: l.fixCashNow,
            required: false,
            allowZero: true,
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(height: 4),
        Text(l.fixCashHint,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        if (widget.trader.kind == AccountKind.showroom) ...[
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            initialValue: _fixTraderId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l.fixWithTrader,
              prefixIcon: const Icon(Icons.handshake_outlined, size: 20),
            ),
            items: [
              DropdownMenuItem(value: null, child: Text(l.noTrader)),
              for (final t in ref.watch(suppliersProvider).valueOrNull ??
                  const <Account>[])
                DropdownMenuItem(value: t.id, child: Text(t.name)),
            ],
            onChanged: (v) => setState(() => _fixTraderId = v),
          ),
          if (_fixTraderId != null) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 12, runSpacing: 12, children: [
              _gramsField(l, _traderGrams, l.traderGrams, required: false),
              _priceField(l, _traderPrice, required: false),
            ]),
            const SizedBox(height: 4),
            Text(l.traderFixHint,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ],
      ] else ...[
        Text(l.goldLines, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ..._lineCards(l, ks),
        const SizedBox(height: 8),
        _priceField(l, _price, half: false),
      ],
      if (g > 0) ...[
        const SizedBox(height: 12),
        Pill(p > 0
            ? '${l.totalValue}: ${formatGrams(g)} × ${formatDinars(p)} = ${formatDinars(weightValue(g, p))} ${l.dinarUnit}'
            : '${l.netTotal}: ${formatGrams(g)} ${l.gramsUnit}'),
      ],
    ];
  }

  List<Widget> _scrapFields(
      AppLocalizations l, List<KaratOption> ks, List<ItemStock>? stock) {
    final have = stock == null ? const <String, int>{} : _bagScrap(stock);
    final net = _linesNet(ks);
    final part = parseGrams(_partGrams.text) ?? 0;
    final partPrice = parseDinars(_partPrice.text) ?? 0;
    return [
      if (_delivers && have.isNotEmpty) ...[
        Wrap(spacing: 8, runSpacing: 6, children: [
          for (final e in have.entries)
            if (e.value > 0)
              Pill(
                '${l.bagStock} · ${ks.where((k) => k.id == e.key).firstOrNull?.name ?? ''}: '
                '${formatGrams(e.value)} ${l.gramsUnit}',
                fg: AppColors.textSecondary,
                bg: AppColors.surfaceMuted,
              ),
        ]),
        const SizedBox(height: 12),
      ],
      ..._lineCards(l, ks),
      if (net > 0) ...[
        Pill('${l.netTotal}: ${formatGrams(net)} ${l.gramsUnit}'),
        const SizedBox(height: 8),
      ],
      // استلام كسر: كامله لرصيد الذهب، أو جزء منه يُحسب كاشاً علينا
      if (op == TraderOp.receiveScrap) ...[
        SwitchListTile(
          value: _partial,
          onChanged: (v) => setState(() => _partial = v),
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppColors.goldDark,
          title: Text(l.partialPricing,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle:
              Text(l.partialPricingHint, style: const TextStyle(fontSize: 12)),
        ),
        if (_partial) ...[
          Wrap(spacing: 12, runSpacing: 12, children: [
            _gramsField(l, _partGrams, l.partGrams),
            _priceField(l, _partPrice),
          ]),
          if (part > 0 && partPrice > 0) ...[
            const SizedBox(height: 10),
            Pill(
                '${l.totalValue}: ${formatGrams(part)} × ${formatDinars(partPrice)} = '
                '${formatDinars(weightValue(part, partPrice))} ${l.dinarUnit}'),
          ],
          if (part > net && net > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(l.partExceeds,
                  style: const TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w700)),
            ),
        ],
      ],
    ];
  }

  List<Widget> _cashFields(AppLocalizations l) => [
        AdaptiveBox(
          width: 260,
          child: DinarsField(
              controller: _amount,
              label: l.cashAmount,
              onChanged: (_) => setState(() {})),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          value: _byCheque,
          onChanged: (v) => setState(() => _byCheque = v),
          contentPadding: EdgeInsets.zero,
          activeThumbColor: AppColors.goldDark,
          title: Text(l.byCheque,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          subtitle: Text(l.byChequeHint, style: const TextStyle(fontSize: 12)),
        ),
        if (_byCheque)
          Wrap(spacing: 12, runSpacing: 12, children: [
            AdaptiveBox(
              width: 200,
              half: true,
              child: TextFormField(
                controller: _chequeNo,
                keyboardType: TextInputType.number,
                inputFormatters: integerInputFormatters,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(labelText: l.chequeNumber),
              ),
            ),
            AdaptiveBox(
              width: 200,
              half: true,
              child: TextFormField(
                  controller: _bank,
                  decoration: InputDecoration(labelText: l.bank)),
            ),
            AdaptiveBox(
              width: 240,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _due,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (d != null) setState(() => _due = d);
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l.dueDate,
                    prefixIcon: const Icon(Icons.event_rounded, size: 20),
                  ),
                  child: Text(
                      '${_due.year}/${_due.month.toString().padLeft(2, '0')}/${_due.day.toString().padLeft(2, '0')}'),
                ),
              ),
            ),
          ]),
      ];
}
