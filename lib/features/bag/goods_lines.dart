import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/locale.dart';
import '../../core/units.dart';
import '../../domain/ledger.dart';
import '../../domain/models.dart';
import '../common/inputs.dart';
import '../common/ui.dart';

/// حالة بند واحد في فاتورة: بضاعة (صنف وعدد ومصنوعية) أو كسر (عيار ووزن فقط).
class GoodsLineState {
  GoodsLineState({this.karatId, String making = '', this.scrap = false})
      : making = TextEditingController(text: making);

  /// الكسر لا صنف له ولا عدد ولا مصنوعية — وزن وعيار فقط.
  final bool scrap;

  String? itemId;
  String? karatId;

  /// يتغيّر بعد نافذة الصنف الجديد ليُعاد بناء القائمة المنسدلة.
  int rev = 0;
  final count = TextEditingController();
  final gross = TextEditingController();
  final TextEditingController making;

  /// المصنوعية للقطعة بدل الغرام — في البيع.
  bool perPiece = false;

  /// الصنف والعيار اللذان عُبئت لهما آخر مصنوعية، ونص التذكير بها.
  String? makingKey;
  String? makingHint;

  /// معامل يدوي يتجاوز معامل العيار لهذا البند وحده (مثلاً 0.820).
  /// فارغ = معامل العيار المختار.
  final factor = TextEditingController();

  /// المعامل اليدوي إن كان صالحاً، وإلا null.
  int? get factorPpm {
    final t = factor.text.trim();
    if (t.isEmpty) return null;
    final ppm = parseKaratFactor(t);
    return (ppm == null || ppm <= 0 || ppm > karatPpmScale) ? null : ppm;
  }

  /// null = البند غير مكتمل بعد.
  GoodsLine? toGoods(List<KaratOption> karats) {
    final base = karats.where((k) => k.id == karatId).firstOrNull;
    final grossMg = parseGrams(gross.text);
    if (base == null || grossMg == null || grossMg <= 0) return null;
    if (factor.text.trim().isNotEmpty && factorPpm == null) return null;
    final karat = factorPpm == null
        ? base
        : KaratOption(id: base.id, name: base.name, ppm: factorPpm!);
    if (scrap) return GoodsLine.of(karat, grossWeightMg: grossMg);

    if (itemId == null) return null;
    final makingFils =
        making.text.trim().isEmpty ? 0 : parseDinars(making.text);
    if (makingFils == null || makingFils < 0) return null;
    final qty = int.tryParse(count.text.trim());
    // المصنوعية للقطعة لا تُحسب بلا عدد
    if (perPiece && makingFils > 0 && (qty == null || qty <= 0)) return null;
    return GoodsLine.of(
      karat,
      grossWeightMg: grossMg,
      itemId: itemId,
      quantity: (qty == null || qty <= 0) ? null : qty,
      makingPerGramFils: makingFils,
      makingPerPiece: perPiece,
    );
  }

  /// البند فارغ تماماً — يُتجاهل بدل أن يُعدّ ناقصاً.
  bool get isBlank =>
      gross.text.trim().isEmpty &&
      count.text.trim().isEmpty &&
      (scrap || itemId == null);

  void dispose() {
    count.dispose();
    gross.dispose();
    making.dispose();
    factor.dispose();
  }
}

/// منتج متوفر للبيع: صنف بعيار معيّن — "حلق عيار 21" غير "حلق عيار 18".
class ProductOption {
  const ProductOption({
    required this.itemId,
    required this.karatId,
    required this.itemName,
    required this.karatName,
    required this.quantity,
    required this.grossMg,
  });

  final String itemId;
  final String karatId;
  final String itemName;
  final String karatName;
  final int quantity;
  final int grossMg;

  String get key => '$itemId|$karatId';
}

/// العيار الافتراضي لبند جديد: 21 إن وُجد.
String? defaultKaratId(List<KaratOption> karats) =>
    karats.where((k) => k.name.contains('21')).firstOrNull?.id ??
    karats.firstOrNull?.id;

/// يضمن أن لكل بند عياراً صالحاً من القائمة الحالية.
void ensureKarats(List<GoodsLineState> lines, List<KaratOption> karats) {
  final def = defaultKaratId(karats);
  for (final line in lines) {
    if (line.karatId == null || !karats.any((k) => k.id == line.karatId)) {
      line.karatId = def;
    }
  }
}

/// بنود الذهب: معامل 1.000 افتراضياً، قابل للتعديل.
void ensurePure(List<GoodsLineState> lines, List<KaratOption> karats) {
  final pure = karats.where((k) => k.ppm == karatPpmScale).firstOrNull;
  for (final line in lines) {
    if (line.karatId != null) continue;
    if (pure != null) {
      line.karatId = pure.id;
    } else {
      line.karatId = defaultKaratId(karats);
      line.factor.text = '1.000';
    }
  }
}

class GoodsLineCard extends StatelessWidget {
  const GoodsLineCard({
    super.key,
    required this.index,
    required this.line,
    required this.karats,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
    this.items = const [],
    this.onNewItem,
    this.title,
    this.itemLabel,
    this.karatLabel,
    this.products,
    this.editableFactor = false,
    this.altKarats = const [],
    this.onAddKarat,
    this.perPieceOption = false,
    this.makingLabel,
  });

  /// اختيار المصنوعية للقطعة أو للغرام.
  final bool perPieceOption;

  /// عنوان خانة المصنوعية إن اختلف عن الافتراضي.
  final String? makingLabel;

  /// في البيع: خانة واحدة "المنتج" (صنف + عيار) بدل خانتي الصنف والعيار.
  final List<ProductOption>? products;

  /// خانة معامل يدوي بجانب العيار — في التعامل مع التجار.
  final bool editableFactor;

  /// إضافة عيار جديد للمنشأة من قائمة العيارات.
  final VoidCallback? onAddKarat;

  static const _newKaratValue = '__new_karat__';
  static const _customFactorValue = '__custom_factor__';

  /// المعاملات البديلة لنفس العيارات — في التجار: معامل البضاعة بجانب معامل الكسر.
  final List<KaratOption> altKarats;

  /// 870000 → "0.870"، و583333 → "0.583333": ثلاث خانات على الأقل بلا أصفار زائدة.
  static String _fmt(int ppm) {
    var s = (ppm / karatPpmScale).toStringAsFixed(6);
    while (s.endsWith('0') && s.split('.').last.length > 3) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  /// قائمة واحدة: كل عيار بمعامليه، ومعامل يدوي، وعيار جديد.
  Widget _karatFactorDropdown(BuildContext context) {
    final l = context.l10n;
    final entries = <(String id, int ppm, String name, bool manual)>[];
    void add(String id, int ppm, String name, {bool manual = false}) {
      if (!entries.any((e) => e.$1 == id && e.$2 == ppm))
        entries.add((id, ppm, name, manual));
    }

    for (final k in karats) {
      add(k.id, k.ppm, k.name);
      for (final a in altKarats.where((a) => a.id == k.id)) {
        add(k.id, a.ppm, k.name);
      }
    }
    final current = line.factorPpm ??
        karats.where((k) => k.id == line.karatId).map((k) => k.ppm).firstOrNull;
    final name = karats
        .where((k) => k.id == line.karatId)
        .map((k) => k.name)
        .firstOrNull;
    if (line.karatId != null && current != null && name != null) {
      add(line.karatId!, current, name, manual: true);
    }

    final selected = (line.karatId == null || current == null)
        ? null
        : '${line.karatId}|$current';

    Future<void> askFactor() async {
      final ctrl =
          TextEditingController(text: current == null ? '' : _fmt(current));
      final ppm = await showDialog<int>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('${l.otherFactor} — ${name ?? ''}'),
          content: SizedBox(
            width: 320,
            child: TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: decimalInputFormatters,
              textDirection: TextDirection.ltr,
              decoration:
                  InputDecoration(labelText: l.factorLabel, hintText: '0.820'),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            FilledButton(
              onPressed: () {
                final p = parseKaratFactor(ctrl.text);
                if (p != null && p > 0 && p <= karatPpmScale)
                  Navigator.pop(ctx, p);
              },
              child: Text(l.save),
            ),
          ],
        ),
      );
      if (ppm != null) {
        final base = karats
            .where((k) => k.id == line.karatId)
            .map((k) => k.ppm)
            .firstOrNull;
        line.factor.text = ppm == base ? '' : _fmt(ppm);
      }
      line.rev++;
      onChanged();
    }

    return DropdownButtonFormField<String>(
      key: ValueKey(
          'kf|${line.karatId}|${line.factor.text}|${karats.length}|${altKarats.length}|${line.rev}'),
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(labelText: l.karatAndFactor),
      // المختار يُعرض مضغوطاً ليتسع في نصف عرض الهاتف
      selectedItemBuilder: (context) => [
        for (final e in entries)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                  '${e.$3} · ${(e.$2 / karatPpmScale).toStringAsFixed(3)}'),
            ),
          ),
        const SizedBox(),
        if (onAddKarat != null) const SizedBox(),
      ],
      items: [
        for (final e in entries)
          DropdownMenuItem(
            value: '${e.$1}|${e.$2}',
            child: Text(
              '${e.$3}  ·  ${(e.$2 / karatPpmScale).toStringAsFixed(3)}'
              '${e.$4 && !karats.any((k) => k.id == e.$1 && k.ppm == e.$2) && !altKarats.any((k) => k.id == e.$1 && k.ppm == e.$2) ? '  ✎' : ''}',
            ),
          ),
        DropdownMenuItem(
          value: _customFactorValue,
          child: Row(children: [
            const Icon(Icons.edit_rounded, size: 16, color: AppColors.goldDark),
            const SizedBox(width: 6),
            Text(l.otherFactor,
                style: const TextStyle(color: AppColors.goldDark)),
          ]),
        ),
        if (onAddKarat != null)
          DropdownMenuItem(
            value: _newKaratValue,
            child: Row(children: [
              const Icon(Icons.add_rounded,
                  size: 18, color: AppColors.goldDark),
              const SizedBox(width: 6),
              Text(l.newKarat,
                  style: const TextStyle(color: AppColors.goldDark)),
            ]),
          ),
      ],
      onChanged: (v) {
        if (v == null) return;
        if (v == _newKaratValue) {
          onAddKarat?.call();
          return;
        }
        if (v == _customFactorValue) {
          askFactor();
          return;
        }
        final parts = v.split('|');
        final ppm = int.parse(parts[1]);
        final base =
            karats.where((k) => k.id == parts[0]).map((k) => k.ppm).firstOrNull;
        line.karatId = parts[0];
        // معامل العيار نفسه = بلا تجاوز؛ غيره يُحفظ كمعامل يدوي للبند
        line.factor.text = ppm == base ? '' : _fmt(ppm);
        onChanged();
      },
    );
  }

  /// نص الصنف في القائمة — في البيع يُظهر المتوفر في الشنطة.
  final String Function(Item)? itemLabel;

  /// نص العيار في القائمة — في البيع يُظهر المتوفر من الصنف بهذا العيار.
  final String Function(KaratOption)? karatLabel;

  final int index;
  final GoodsLineState line;
  final List<Item> items;
  final List<KaratOption> karats;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback? onNewItem;
  final VoidCallback onChanged;

  /// عنوان البند — "بند 1" افتراضياً.
  final String? title;

  static const _newItemValue = '__new__';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final g = line.toGoods(karats);

    // على الهاتف: الخانات الطويلة تملأ السطر، والقصيرة (العدد، الوزن، العيار،
    // المصنوعية) تتجاور اثنتين اثنتين
    Widget field(double width, Widget child, {bool half = false}) =>
        AdaptiveBox(width: width, half: half, child: child);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: line.scrap ? AppColors.surfaceMuted : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                title ?? l.lineNumber(index + 1),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.goldDark),
              ),
              const Spacer(),
              if (canRemove)
                IconButton(
                  tooltip: l.remove,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                  onPressed: onRemove,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // البيع: المنتج (صنف + عيار) في خانة واحدة
              if (!line.scrap && products != null)
                field(
                  360,
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                        'product|${line.itemId}|${line.karatId}|${products!.length}'),
                    initialValue: products!.any((p) =>
                            p.itemId == line.itemId &&
                            p.karatId == line.karatId)
                        ? '${line.itemId}|${line.karatId}'
                        : null,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.product),
                    items: [
                      for (final p in products!)
                        DropdownMenuItem(
                          value: p.key,
                          child: Text(
                            '${p.itemName} — ${p.karatName}  ·  '
                            '${p.quantity > 0 ? '${l.piecesCount(p.quantity)} · ' : ''}'
                            '${formatGrams(p.grossMg)} ${l.gramsUnit}',
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      final parts = v.split('|');
                      line.itemId = parts[0];
                      line.karatId = parts[1];
                      onChanged();
                    },
                    validator: (v) =>
                        line.isBlank || v != null ? null : l.requiredField,
                  ),
                ),
              if (!line.scrap && products == null)
                field(
                  200,
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                        'item|${line.itemId}|${items.length}|${line.rev}'),
                    initialValue: items.any((i) => i.id == line.itemId)
                        ? line.itemId
                        : null,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.item),
                    items: [
                      for (final i in items)
                        DropdownMenuItem(
                            value: i.id,
                            child: Text(itemLabel?.call(i) ?? i.name)),
                      if (onNewItem != null)
                        DropdownMenuItem(
                          value: _newItemValue,
                          child: Row(children: [
                            const Icon(Icons.add_rounded,
                                size: 18, color: AppColors.goldDark),
                            const SizedBox(width: 6),
                            Text(l.newItem,
                                style:
                                    const TextStyle(color: AppColors.goldDark)),
                          ]),
                        ),
                    ],
                    onChanged: (v) {
                      if (v == _newItemValue) {
                        onNewItem?.call();
                      } else {
                        line.itemId = v;
                        onChanged();
                      }
                    },
                    validator: (v) =>
                        line.isBlank || (v != null && v != _newItemValue)
                            ? null
                            : l.requiredField,
                  ),
                ),
              if (!line.scrap)
                field(
                  half: true,
                  110,
                  TextFormField(
                    controller: line.count,
                    keyboardType: TextInputType.number,
                    inputFormatters: integerInputFormatters,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(labelText: l.count),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              field(
                half: true,
                170,
                TextFormField(
                  controller: line.gross,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: decimalInputFormatters,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                      labelText: l.grossWeight, suffixText: l.gramsUnit),
                  onChanged: (_) => onChanged(),
                  validator: (v) {
                    // البند الفارغ يُتجاهل ولا يُعدّ خطأ
                    if (line.isBlank) return null;
                    final mg = parseGrams(v ?? '');
                    if (mg == null || mg <= 0) return l.invalidWeight;
                    return null;
                  },
                ),
              ),
              // البيع: المنتج يحدد العيار، والعيار اللحظي معامل لهذا البند فقط
              if (products != null && !line.scrap)
                field(
                  half: true,
                  170,
                  TextFormField(
                    controller: line.factor,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: decimalInputFormatters,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                        labelText: l.instantKarat, hintText: '0.885'),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              // العيار والمعامل في قائمة واحدة، ومعها العيار اللحظي
              if (editableFactor)
                field(half: true, 300, _karatFactorDropdown(context))
              else if (line.scrap || products == null)
                field(
                  half: true,
                  200,
                  DropdownButtonFormField<String>(
                    key: ValueKey(
                        'karat|${line.karatId}|${karats.length}|${line.rev}'),
                    initialValue: line.karatId,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.karat),
                    selectedItemBuilder: (context) => [
                      for (final k in karats)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(karatLabel?.call(k) ??
                                '${k.name} · ${(k.ppm / 1000000).toStringAsFixed(3)}'),
                          ),
                        ),
                      if (onAddKarat != null) const SizedBox(),
                    ],
                    items: [
                      for (final k in karats)
                        DropdownMenuItem(
                          value: k.id,
                          child: Text(karatLabel?.call(k) ??
                              '${k.name}  ·  ${(k.ppm / 1000000).toStringAsFixed(3)}'),
                        ),
                      if (onAddKarat != null)
                        DropdownMenuItem(
                          value: _newKaratValue,
                          child: Row(children: [
                            const Icon(Icons.add_rounded,
                                size: 18, color: AppColors.goldDark),
                            const SizedBox(width: 6),
                            Text(l.newKarat,
                                style:
                                    const TextStyle(color: AppColors.goldDark)),
                          ]),
                        ),
                    ],
                    onChanged: (v) {
                      if (v == _newKaratValue) {
                        onAddKarat?.call();
                        return;
                      }
                      line.karatId = v;
                      onChanged();
                    },
                  ),
                ),
              if (!line.scrap)
                field(
                  half: true,
                  170,
                  TextFormField(
                    controller: line.making,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: decimalInputFormatters,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                        labelText: makingLabel ??
                            (line.perPiece
                                ? l.makingPerPiece
                                : l.makingPerGram),
                        suffixText: l.dinarUnit),
                    onChanged: (_) => onChanged(),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final f = parseDinars(v);
                      return (f == null || f < 0) ? l.invalidAmount : null;
                    },
                  ),
                ),
            ],
          ),
          if (perPieceOption && !line.scrap) ...[
            const SizedBox(height: 10),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l.perGram)),
                ButtonSegment(value: true, label: Text(l.perPiece)),
              ],
              selected: {line.perPiece},
              showSelectedIcon: false,
              onSelectionChanged: (s) {
                line.perPiece = s.first;
                onChanged();
              },
            ),
          ],
          if (line.makingHint != null) ...[
            const SizedBox(height: 8),
            Text(line.makingHint!,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.goldDark,
                    fontWeight: FontWeight.w700)),
          ],
          if (g != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                Pill('${l.net24}: ${formatGrams(g.netMg)} ${l.gramsUnit}'),
                if (!line.scrap)
                  Pill(
                    '${l.making}: ${formatDinars(g.makingFils)} ${l.dinarUnit}',
                    fg: AppColors.textSecondary,
                    bg: AppColors.surfaceMuted,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// نافذة إدخال اسم — لمشغل أو محل أو صنف جديد.
Future<String?> askName(BuildContext context,
    {required String title, required String label}) {
  final ctrl = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 380,
        child: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(labelText: label),
          onSubmitted: (v) =>
              v.trim().isEmpty ? null : Navigator.pop(ctx, v.trim()),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: Text(ctx.l10n.cancel)),
        FilledButton(
          onPressed: () {
            final v = ctrl.text.trim();
            if (v.isNotEmpty) Navigator.pop(ctx, v);
          },
          child: Text(ctx.l10n.save),
        ),
      ],
    ),
  );
}
