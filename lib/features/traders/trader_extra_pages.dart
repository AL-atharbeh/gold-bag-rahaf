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
import '../shops/shop_sale_page.dart';

const _liraName = 'ليرة';

Widget _saveButton(AppLocalizations l, bool busy, VoidCallback onPressed) =>
    FilledButton.icon(
      onPressed: busy ? null : onPressed,
      icon: busy
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
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    );

/// بيع ليرة للتاجر: وزن قائم وعدد، والأجور على القطعة لنا.
///
/// تصير عليه ذهباً بصافيها ونقداً بأجورها. تخرج من الشنطة افتراضياً —
/// فلا تُباع ليرة غير موجودة؛ يُطفأ الزر لليرة من خارج المخزون.
class LiraSalePage extends ConsumerStatefulWidget {
  const LiraSalePage({super.key, required this.trader});

  final Account trader;

  @override
  ConsumerState<LiraSalePage> createState() => _LiraSalePageState();
}

class _LiraSalePageState extends ConsumerState<LiraSalePage> {
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController();
  final _line = GoodsLineState()..perPiece = true;
  DateTime _date = DateTime.now();
  bool _fromBag = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _ensureItem();
  }

  /// صنف "ليرة" يُنشأ مرة واحدة إن لم يكن موجوداً.
  Future<void> _ensureItem() async {
    try {
      final items = await ref.read(itemsProvider.future);
      // الاسم المطابق أولاً، لا "نص ليرة" أو "ربع ليرة"
      final found =
          items.where((i) => i.name.trim() == _liraName).firstOrNull ??
              items.where((i) => i.name.contains(_liraName)).firstOrNull;
      if (found != null) {
        if (mounted) setState(() => _line.itemId = found.id);
        return;
      }
      final item = await ref.read(repositoryProvider).createItem(_liraName);
      ref.invalidate(itemsProvider);
      if (mounted) setState(() => _line.itemId = item.id);
    } catch (e) {
      // بلا اتصال مثلاً: يبقى الصنف قابلاً للاختيار يدوياً
      if (mounted) showResult(context, readableError(e), error: true);
    }
  }

  @override
  void dispose() {
    _note.dispose();
    _line.dispose();
    super.dispose();
  }

  Future<void> _submit(List<KaratOption> karats, AccountBalance? bag) async {
    final l = context.l10n;
    if (!_form.currentState!.validate()) return;
    final g = _line.toGoods(karats);
    if (g == null) {
      showResult(context, l.fillLines, error: true);
      return;
    }
    if ((g.quantity ?? 0) <= 0) {
      showResult(context, l.liraCountNeeded, error: true);
      return;
    }
    if (!ensureOnline(context, ref)) return;

    final sys = ref.read(systemAccountsProvider).valueOrNull ?? {};
    final bagId = sys[SystemAccount.shanta];
    final cashbox = sys[SystemAccount.cashbox];
    final making = sys[SystemAccount.makingIncome];
    final trading = sys[SystemAccount.tradingIncome];
    if (bagId == null ||
        cashbox == null ||
        making == null ||
        trading == null) {
      showResult(context, 'حسابات النظام غير مهيّأة', error: true);
      return;
    }

    if (_fromBag) {
      ref.invalidate(itemStockProvider(bagId));
      final stock = await ref.read(itemStockProvider(bagId).future);
      if (!mounted) return;
      final have = stock
          .where((s) => s.itemId == g.itemId && s.karatId == g.karatId)
          .fold<int>(0, (a, s) => a + s.grossMg);
      if (g.grossWeightMg > have) {
        showResult(context, l.saleExceedsBag, error: true);
        return;
      }
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final doc = await ref.read(repositoryProvider).shopSale(
            shopId: widget.trader.id,
            // خارج الشنطة: يقابلها حساب إيراد التجارة بدل مخزون الشنطة
            bagAccountId: _fromBag ? bagId : trading,
            cashboxId: cashbox,
            makingIncomeId: making,
            goods: [g],
            costOutFils: _fromBag
                ? capitalCost(g.netMg, bag,
                    scrapMg: bagScrapMg(
                        ref.read(itemStockProvider(bagId)).valueOrNull))
                : 0,
            occurredAt: _date,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
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
        (accountId: widget.trader.id, direction: GoldDirection.out)));
    final items = ref.watch(itemsProvider).valueOrNull ?? const <Item>[];
    final balances =
        ref.watch(balancesProvider).valueOrNull ?? const <AccountBalance>[];
    final bagId =
        ref.watch(systemAccountsProvider).valueOrNull?[SystemAccount.shanta];
    final bag = balances.where((b) => b.accountId == bagId).firstOrNull;
    final mine =
        balances.where((b) => b.accountId == widget.trader.id).firstOrNull;
    final goldBefore = mine?.goldMg ?? 0;
    final cashBefore = mine?.cashFils ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('${l.opLira} — ${widget.trader.name}')),
      body: AsyncBody<List<KaratOption>>(
        value: karats,
        data: (ks) {
          ensureKarats([_line], ks);
          final g = _line.toGoods(ks);
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
                        GoodsLineCard(
                          index: 0,
                          title: l.opLira,
                          line: _line,
                          items: items,
                          karats: ks,
                          editableFactor: true,
                          makingLabel: l.liraFee,
                          canRemove: false,
                          onRemove: () {},
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          value: _fromBag,
                          onChanged: (v) => setState(() => _fromBag = v),
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppColors.goldDark,
                          title: Text(l.liraFromBag,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(l.liraFromBagHint,
                              style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _note,
                          decoration: InputDecoration(
                            labelText: l.noteOptional,
                            prefixIcon:
                                const Icon(Icons.notes_rounded, size: 20),
                          ),
                        ),
                        if (g != null) ...[
                          const SizedBox(height: 20),
                          BalanceChange(
                            title: l.accountEffect,
                            goldBefore: goldBefore,
                            goldAfter: goldBefore + g.netMg,
                            cashBefore: cashBefore,
                            cashAfter: cashBefore + g.makingFils,
                          ),
                        ],
                        const SizedBox(height: 20),
                        _saveButton(l, _busy, () => _submit(ks, bag)),
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
}

/// بدل ذهب: استلام ذهب من الطرف بمعامل 1.000 (قابل للتعديل)، وتسليمه
/// الآن أو تركه في الرصيد، بأجور على الغرام لنا أو علينا.
class ExchangePage extends ConsumerStatefulWidget {
  const ExchangePage({super.key, required this.trader});

  final Account trader;

  @override
  ConsumerState<ExchangePage> createState() => _ExchangePageState();
}

class _ExchangePageState extends ConsumerState<ExchangePage> {
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController();
  final _fee = TextEditingController();
  final List<GoodsLineState> _received = [GoodsLineState(scrap: true)];
  final List<GoodsLineState> _delivered = [];
  DateTime _date = DateTime.now();
  bool _feeForUs = false;
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    _fee.dispose();
    for (final s in [..._received, ..._delivered]) {
      s.dispose();
    }
    super.dispose();
  }

  List<GoodsLine>? _collect(List<GoodsLineState> lines, List<KaratOption> ks) {
    final out = <GoodsLine>[];
    for (final s in lines) {
      if (s.isBlank) continue;
      final g = s.toGoods(ks);
      if (g == null) return null;
      out.add(g);
    }
    return out;
  }

  Future<void> _submit(List<KaratOption> ks) async {
    final l = context.l10n;
    if (!_form.currentState!.validate()) return;
    final received = _collect(_received, ks);
    final delivered = _collect(_delivered, ks);
    if (received == null || delivered == null) {
      showResult(context, l.fillLines, error: true);
      return;
    }
    if (received.isEmpty && delivered.isEmpty) {
      showResult(context, l.emptyTx, error: true);
      return;
    }
    if (!ensureOnline(context, ref)) return;
    final sys = ref.read(systemAccountsProvider).valueOrNull ?? {};
    final bag = sys[SystemAccount.shanta];
    final making = sys[SystemAccount.makingIncome];
    if (bag == null || making == null) {
      showResult(context, 'حسابات النظام غير مهيّأة', error: true);
      return;
    }

    if (delivered.isNotEmpty) {
      // لا تسليم لذهب ليس في الشنطة
      ref.invalidate(itemStockProvider(bag));
      final stock = await ref.read(itemStockProvider(bag).future);
      if (!mounted) return;
      final want = <String, int>{};
      for (final g in delivered) {
        want[g.karatId] = (want[g.karatId] ?? 0) + g.grossWeightMg;
      }
      // الوارد في نفس الحركة يُحسب ضمن المتوفر
      for (final g in received) {
        want[g.karatId] = (want[g.karatId] ?? 0) - g.grossWeightMg;
      }
      final short = want.entries.where((e) {
        final have = stock
            .where((s) => s.itemId == null && s.karatId == e.key)
            .fold<int>(0, (a, s) => a + s.grossMg);
        return e.value > have;
      });
      if (short.isNotEmpty) {
        showResult(context, l.scrapExceedsBag, error: true);
        return;
      }
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final doc = await ref.read(repositoryProvider).exchange(
            partyId: widget.trader.id,
            bagAccountId: bag,
            makingIncomeId: making,
            received: received,
            delivered: delivered,
            feePerGramFils: parseDinars(_fee.text) ?? 0,
            feeForUs: _feeForUs,
            occurredAt: _date,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
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

  List<Widget> _lines(
    AppLocalizations l,
    List<GoodsLineState> lines,
    List<KaratOption> ks,
    List<KaratOption> alt,
  ) =>
      [
        for (var i = 0; i < lines.length; i++) ...[
          GoodsLineCard(
            key: ObjectKey(lines[i]),
            index: i,
            line: lines[i],
            karats: ks,
            altKarats: alt,
            editableFactor: true,
            canRemove: true,
            onRemove: () => setState(() => lines.removeAt(i).dispose()),
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 12),
        ],
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            onPressed: _busy
                ? null
                : () => setState(() => lines.add(GoodsLineState(scrap: true))),
            icon: const Icon(Icons.add_circle_outline_rounded),
            label: Text(l.addLine),
            style: TextButton.styleFrom(foregroundColor: AppColors.goldDark),
          ),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final karats = ref.watch(karatOptionsProvider(
        (accountId: widget.trader.id, direction: GoldDirection.incoming)));
    final alt = ref
            .watch(karatOptionsProvider(
                (accountId: widget.trader.id, direction: GoldDirection.out)))
            .valueOrNull ??
        const <KaratOption>[];
    final mine = (ref.watch(balancesProvider).valueOrNull ??
            const <AccountBalance>[])
        .where((b) => b.accountId == widget.trader.id)
        .firstOrNull;
    final goldBefore = mine?.goldMg ?? 0;
    final cashBefore = mine?.cashFils ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('${l.opExchange} — ${widget.trader.name}')),
      body: AsyncBody<List<KaratOption>>(
        value: karats,
        data: (ks) {
          ensurePure([..._received, ..._delivered], ks);
          ensureKarats([..._received, ..._delivered], ks);
          final received = _collect(_received, ks) ?? const <GoodsLine>[];
          final delivered = _collect(_delivered, ks) ?? const <GoodsLine>[];
          final net = delivered.fold<int>(0, (a, g) => a + g.netMg) -
              received.fold<int>(0, (a, g) => a + g.netMg);
          final base = received.isNotEmpty ? received : delivered;
          final fee = weightValue(
              base.fold<int>(0, (a, g) => a + g.grossWeightMg),
              parseDinars(_fee.text) ?? 0);

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
                        SectionTitle(l.exchangeReceived),
                        ..._lines(l, _received, ks, alt),
                        const SizedBox(height: 8),
                        SectionTitle(l.exchangeDelivered),
                        Text(l.exchangeDeliveredHint,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        ..._lines(l, _delivered, ks, alt),
                        const SizedBox(height: 8),
                        SectionTitle(l.exchangeFee),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            AdaptiveBox(
                              width: 240,
                              child: DinarsField(
                                controller: _fee,
                                label: l.exchangeFeePerGram,
                                required: false,
                                allowZero: true,
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            SegmentedButton<bool>(
                              segments: [
                                ButtonSegment(
                                    value: false, label: Text(l.feeOnUs)),
                                ButtonSegment(
                                    value: true, label: Text(l.feeForUs)),
                              ],
                              selected: {_feeForUs},
                              showSelectedIcon: false,
                              onSelectionChanged: (s) =>
                                  setState(() => _feeForUs = s.first),
                            ),
                          ],
                        ),
                        if (fee > 0) ...[
                          const SizedBox(height: 10),
                          Pill(
                              '${l.exchangeFee}: ${formatDinars(fee)} ${l.dinarUnit}'),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _note,
                          decoration: InputDecoration(
                            labelText: l.noteOptional,
                            prefixIcon:
                                const Icon(Icons.notes_rounded, size: 20),
                          ),
                        ),
                        if (net != 0 || fee != 0) ...[
                          const SizedBox(height: 20),
                          BalanceChange(
                            title: l.accountEffect,
                            goldBefore: goldBefore,
                            goldAfter: goldBefore + net,
                            cashBefore: cashBefore,
                            cashAfter: cashBefore + (_feeForUs ? fee : -fee),
                          ),
                        ],
                        const SizedBox(height: 20),
                        _saveButton(l, _busy, () => _submit(ks)),
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
}
