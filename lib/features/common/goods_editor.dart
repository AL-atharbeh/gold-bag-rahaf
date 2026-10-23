import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/units.dart';
import '../../domain/ledger.dart';
import '../../domain/models.dart';
import 'inputs.dart';
import 'pickers.dart';

/// محرّر بنود البضاعة — وزن وعيار، وعدد ومصنعية اختيارياً.
class GoodsEditor extends StatefulWidget {
  const GoodsEditor({
    super.key,
    required this.karats,
    required this.onChanged,
    this.showMaking = false,
    this.showCount = true,
    this.singleLine = false,
  });

  final List<KaratOption> karats;
  final ValueChanged<List<GoodsLine>> onChanged;

  /// أجور المصنعية تظهر في البيع فقط.
  final bool showMaking;
  final bool showCount;

  /// دفعة الكسر بند واحد دائماً.
  final bool singleLine;

  @override
  State<GoodsEditor> createState() => _GoodsEditorState();
}

class _GoodsEditorState extends State<GoodsEditor> {
  late final List<_LineState> _lines;

  @override
  void initState() {
    super.initState();
    _lines = [_LineState(_defaultKarat)];
    for (final l in _lines) {
      l.attach(_emit);
    }
  }

  String? get _defaultKarat =>
      widget.karats.isEmpty ? null : widget.karats.first.id;

  @override
  void didUpdateWidget(GoodsEditor old) {
    super.didUpdateWidget(old);
    final changed = old.karats.length != widget.karats.length ||
        [
          for (var i = 0; i < old.karats.length; i++)
            old.karats[i].ppm != widget.karats[i].ppm
        ].any((c) => c);
    if (changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _emit();
      });
    }
  }

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  void _emit() {
    final out = <GoodsLine>[];
    for (final l in _lines) {
      final line = l.build(widget.karats);
      if (line != null) out.add(line);
    }
    widget.onChanged(out);
  }

  void _add() {
    setState(() {
      final l = _LineState(_defaultKarat)..attach(_emit);
      _lines.add(l);
    });
    _emit();
  }

  void _remove(int i) {
    setState(() {
      _lines.removeAt(i).dispose();
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _LineForm(
            state: _lines[i],
            karats: widget.karats,
            showMaking: widget.showMaking,
            showCount: widget.showCount,
            index: i,
            canRemove: _lines.length > 1,
            onRemove: () => _remove(i),
            onChanged: () {
              setState(() {});
              _emit();
            },
          ),
        ],
        if (!widget.singleLine) ...[
          const SizedBox(height: 12),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text('إضافة بند آخر'),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.goldContainer,
                side: const BorderSide(color: AppColors.goldBorder),
                foregroundColor: AppColors.goldDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LineState {
  _LineState(this.karatId);

  String? karatId;
  final weight = TextEditingController();
  final count = TextEditingController();
  final making = TextEditingController();

  void attach(VoidCallback cb) {
    weight.addListener(cb);
    count.addListener(cb);
    making.addListener(cb);
  }

  void dispose() {
    weight.dispose();
    count.dispose();
    making.dispose();
  }

  GoodsLine? build(List<KaratOption> karats) {
    final mg = parseGrams(weight.text);
    if (mg == null || mg <= 0 || karatId == null) return null;
    final karat = karats.where((k) => k.id == karatId).firstOrNull;
    if (karat == null) return null;
    return GoodsLine.of(
      karat,
      grossWeightMg: mg,
      quantity: int.tryParse(count.text.trim()),
      makingPerGramFils: parseDinars(making.text) ?? 0,
    );
  }
}

String _factorText(int ppm) {
  return (ppm / 1000000).toStringAsFixed(3);
}

class _LineForm extends StatelessWidget {
  const _LineForm({
    required this.state,
    required this.karats,
    required this.showMaking,
    required this.showCount,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    required this.onChanged,
  });

  final _LineState state;
  final List<KaratOption> karats;
  final bool showMaking;
  final bool showCount;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final line = state.build(karats);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.goldContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.goldBorder),
                ),
                child: Text(
                  'بند ${index + 1}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldDark,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KaratPicker(
                  karats: karats,
                  value: state.karatId,
                  onChanged: (v) {
                    state.karatId = v;
                    onChanged();
                  },
                ),
              ),
              if (canRemove) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'حذف البند',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: AppColors.error),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: GramsField(
                  controller: state.weight,
                  autofocus: index == 0,
                ),
              ),
              if (showCount) ...[
                const SizedBox(width: 12),
                Expanded(flex: 2, child: CountField(controller: state.count)),
              ],
              if (showMaking) ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DinarsField(
                    controller: state.making,
                    label: 'مصنعية/غرام',
                    required: false,
                    allowZero: true,
                  ),
                ),
              ],
            ],
          ),
          if (line != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.goldDark, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'الصافي: ${formatGrams(line.netMg)} غرام (معامل: ${_factorText(line.karatPpm)})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (line.makingFils > 0) ...[
                    const Spacer(),
                    Text(
                      'مصنعية: ${formatDinars(line.makingFils)} د.أ',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.goldDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
