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
import '../common/inputs.dart';
import '../common/ui.dart';
import '../parties/balance_widgets.dart';

/// بند من الفاتورة الأصلية يمكن إرجاع جزء منه.
class ReturnableLine {
  ReturnableLine({
    required this.line,
    required this.makingPerGramFils,
    required this.maxCount,
    required this.maxGrossMg,
  });

  final TxLine line;
  final int makingPerGramFils;

  /// الحد الأعلى للإرجاع: الأقل من بند الفاتورة ومما بقي فعلاً عند الطرف
  /// (أو في الشنطة عند الإرجاع للمشغل).
  final int? maxCount;
  final int maxGrossMg;

  final count = TextEditingController();
  final gross = TextEditingController();

  int get grossMg => parseGrams(gross.text) ?? 0;
  int? get qty => int.tryParse(count.text);

  GoodsLine? toGoodsLine() {
    if (grossMg <= 0) return null;
    return GoodsLine(
      grossWeightMg: grossMg,
      karatId: line.karatId!,
      karatPpm: line.karatPpm!,
      itemId: line.itemId,
      quantity: line.quantity == null ? null : (qty ?? 0),
      makingPerGramFils: makingPerGramFils,
    );
  }

  bool get exceeds =>
      grossMg > maxGrossMg ||
      (maxCount != null && qty != null && qty! > maxCount!);

  void dispose() {
    count.dispose();
    gross.dispose();
  }
}

/// يستخرج بنود البضاعة للطرف من الفاتورة، ويربط كل بند بسعر مصنوعيته.
///
/// سطور المصنوعية منفصلة في القيد؛ يُعرف سطر كل بند لأن مبلغه
/// = القائم × سعر الغرام بالضبط.
List<(TxLine, int)> goodsWithMaking(TxDetail tx, String partyId,
    {required bool fromShop}) {
  final mine = tx.lines.where((x) => x.accountId == partyId);
  final goods = mine
      .where((x) =>
          x.ledger == LedgerKind.gold &&
          x.itemId != null &&
          (fromShop ? x.amount > 0 : x.amount < 0))
      .toList();
  final making =
      mine.where((x) => x.makingPerGramFils != null).toList(growable: true);
  final used = <int>{};
  return [
    for (final g in goods)
      (
        g,
        () {
          final gross = (g.grossWeightMg ?? 0).abs();
          for (var i = 0; i < making.length; i++) {
            if (used.contains(i)) continue;
            final m = making[i];
            if (weightValue(gross, m.makingPerGramFils!) == m.amount.abs()) {
              used.add(i);
              return m.makingPerGramFils!;
            }
          }
          return 0;
        }(),
      ),
  ];
}

/// مرتجع جزئي من فاتورة بيع لمحل، أو من وارد مشغل.
class PartialReturnPage extends ConsumerStatefulWidget {
  const PartialReturnPage({super.key, required this.tx, required this.party});

  final TxDetail tx;
  final Account party;

  /// فاتورة بيع: المحل يعيد إلينا. وارد بضاعة: نعيد نحن للمشغل أو التاجر.
  bool get fromShop => tx.type != TxType.goodsIn;

  @override
  ConsumerState<PartialReturnPage> createState() => _PartialReturnPageState();
}

class _PartialReturnPageState extends ConsumerState<PartialReturnPage> {
  List<ReturnableLine>? _lines;
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final r in _lines ?? const <ReturnableLine>[]) {
      r.dispose();
    }
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final sys = await ref.read(systemAccountsProvider.future);
      final bagId = sys[SystemAccount.shanta];
      // الحد: ما بقي عند المحل من الصنف، أو ما بقي في الشنطة عند الإرجاع للمشغل
      final holderId = widget.fromShop ? widget.party.id : bagId;
      final stock = holderId == null
          ? const <ItemStock>[]
          : await ref.read(repositoryProvider).itemStock(holderId);

      final lines = <ReturnableLine>[];
      for (final (l, rate) in goodsWithMaking(widget.tx, widget.party.id,
          fromShop: widget.fromShop)) {
        final s = stock
            .where((x) => x.itemId == l.itemId && x.karatId == l.karatId)
            .firstOrNull;
        final origGross = (l.grossWeightMg ?? 0).abs();
        final origQty = l.quantity?.abs();
        final haveGross = (s?.grossMg ?? 0).clamp(0, 1 << 62);
        final haveQty = (s?.quantity ?? 0).clamp(0, 1 << 30);
        lines.add(ReturnableLine(
          line: l,
          makingPerGramFils: rate,
          maxGrossMg: origGross < haveGross ? origGross : haveGross,
          maxCount:
              origQty == null ? null : (origQty < haveQty ? origQty : haveQty),
        ));
      }
      if (!mounted) return;
      setState(() => _lines = lines);
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  /// حصة القطع المرتجعة من تكلفة المصنوعية التي خرجت من الشنطة عند البيع.
  int _costBack(String? bagId, List<GoodsLine> goods) {
    if (!widget.fromShop || bagId == null) return 0;
    final costOut = widget.tx.lines
        .where((x) =>
            x.accountId == bagId &&
            x.ledger == LedgerKind.cash &&
            x.makingPerGramFils == null &&
            x.amount < 0)
        .fold<int>(0, (a, x) => a - x.amount);
    if (costOut == 0) return 0;
    final totalNet = (_lines ?? const <ReturnableLine>[])
        .fold<int>(0, (a, r) => a + r.line.amount.abs());
    final retNet = goods.fold<int>(0, (a, g) => a + g.netMg);
    if (totalNet == 0) return 0;
    return (costOut * retNet + totalNet ~/ 2) ~/ totalNet;
  }

  Future<void> _save(AppLocalizations l) async {
    final lines = _lines ?? const <ReturnableLine>[];
    final goods = [
      for (final r in lines)
        if (r.toGoodsLine() != null) r.toGoodsLine()!
    ];
    if (goods.isEmpty) {
      _snack(l.nothingToReturn, error: true);
      return;
    }
    if (lines.any((r) => r.exceeds)) {
      _snack(l.returnExceeds, error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final sys = await ref.read(systemAccountsProvider.future);
      final bag = sys[SystemAccount.shanta];
      final income = sys[SystemAccount.makingIncome];
      if (bag == null || income == null) throw Exception('الحسابات غير مهيّأة');
      final doc = await ref.read(repositoryProvider).goodsReturn(
            partyId: widget.party.id,
            bagAccountId: bag,
            makingIncomeId: income,
            lines: goods,
            fromShop: widget.fromShop,
            costBackFils: _costBack(bag, goods),
            occurredAt: _date,
            note: [
              '${l.partialReturn} — ${widget.tx.docNumber}',
              if (_note.text.trim().isNotEmpty) _note.text.trim(),
            ].join(' · '),
          );
      invalidateAfterPosting(ref);
      if (!mounted) return;
      _snack(l.returnSaved(doc));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _snack(readableError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String s, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(s),
        backgroundColor: error ? AppColors.error : AppColors.goldDark,
      ));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lines = _lines;
    final balance =
        (ref.watch(balancesProvider).valueOrNull ?? const <AccountBalance>[])
            .where((b) => b.accountId == widget.party.id)
            .firstOrNull;

    final goods = [
      for (final r in lines ?? const <ReturnableLine>[])
        if (r.toGoodsLine() != null) r.toGoodsLine()!
    ];
    final net = goods.fold<int>(0, (a, g) => a + g.netMg);
    final making = goods.fold<int>(0, (a, g) => a + g.makingFils);
    final sign = widget.fromShop ? -1 : 1;
    final goldBefore = balance?.goldMg ?? 0;
    final cashBefore = balance?.cashFils ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
            '${l.partialReturn} — ${ltrIsolate('#${widget.tx.docNumber}')}'),
      ),
      body: _loadError != null
          ? CenteredMessage(
              icon: Icons.error_outline_rounded,
              title: readableError(_loadError!))
          : lines == null
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.goldPrimary))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 820),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            BalanceChips(
                                goldMg: goldBefore, cashFils: cashBefore),
                            const SizedBox(height: 14),
                            Text(
                              widget.fromShop
                                  ? l.returnFromShopHint
                                  : l.returnToWorkshopHint,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 14),
                            DateField(
                                value: _date,
                                onChanged: (d) => setState(() => _date = d)),
                            const SizedBox(height: 8),
                            SectionTitle(l.invoiceLines),
                            for (final r in lines) ...[
                              _LineCard(
                                  r: r, l: l, onChanged: () => setState(() {})),
                              const SizedBox(height: 10),
                            ],
                            const SizedBox(height: 6),
                            TextField(
                              controller: _note,
                              decoration: InputDecoration(
                                labelText: l.noteOptional,
                                prefixIcon:
                                    const Icon(Icons.notes_rounded, size: 20),
                              ),
                            ),
                            if (goods.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              BalanceChange(
                                title: l.partialReturn,
                                goldBefore: goldBefore,
                                goldAfter: goldBefore + sign * net,
                                cashBefore: cashBefore,
                                cashAfter: cashBefore + sign * making,
                              ),
                            ],
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: _saving ? null : () => _save(l),
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.assignment_return_rounded),
                              label: Text(l.saveReturn),
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

class _LineCard extends StatelessWidget {
  const _LineCard({required this.r, required this.l, required this.onChanged});

  final ReturnableLine r;
  final AppLocalizations l;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final x = r.line;
    final karat = [
      if (x.karatName != null) x.karatName!,
      if (x.karatPpm != null) (x.karatPpm! / 1000000).toStringAsFixed(3),
    ].join(' · ');
    final available = r.maxGrossMg > 0;

    return GoldCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(
              child: Text('${x.itemName ?? l.unknownItem}  ·  $karat',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            TextButton(
              onPressed: !available
                  ? null
                  : () {
                      r.gross.text = formatGrams(r.maxGrossMg);
                      if (r.maxCount != null) {
                        r.count.text = '${r.maxCount}';
                      }
                      onChanged();
                    },
              child: Text(l.returnAll),
            ),
          ]),
          Text(
            [
              if (x.quantity != null) '${l.count}: ${x.quantity!.abs()}',
              '${l.grossWeight}: ${formatGrams((x.grossWeightMg ?? 0).abs())}',
              if (r.makingPerGramFils > 0)
                '${l.making}: ${formatDinars(r.makingPerGramFils)} ${l.dinarUnit}/${l.gramsUnit}',
            ].join('  ·  '),
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            l.maxReturn(
                r.maxCount?.toString() ?? '—', formatGrams(r.maxGrossMg)),
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: available ? AppColors.goldDark : AppColors.textMuted),
          ),
          if (available) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 12, runSpacing: 12, children: [
              if (x.quantity != null)
                AdaptiveBox(
                  width: 150,
                  half: true,
                  child: TextField(
                    controller: r.count,
                    keyboardType: TextInputType.number,
                    inputFormatters: integerInputFormatters,
                    textDirection: TextDirection.ltr,
                    onChanged: (_) => onChanged(),
                    decoration: InputDecoration(labelText: l.returnedCount),
                  ),
                ),
              AdaptiveBox(
                width: 190,
                half: true,
                child: TextField(
                  controller: r.gross,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: decimalInputFormatters,
                  textDirection: TextDirection.ltr,
                  onChanged: (_) => onChanged(),
                  decoration: InputDecoration(
                      labelText: l.returnedGross, suffixText: l.gramsUnit),
                ),
              ),
            ]),
            if (r.exceeds)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(l.returnExceeds,
                    style: const TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.w700)),
              ),
          ],
        ],
      ),
    );
  }
}
