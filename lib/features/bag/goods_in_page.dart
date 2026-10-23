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
import 'goods_lines.dart';

/// وارد بضاعة من مشغل إلى الشنطة.
///
/// كل بند: صنف، عدد، وزن قائم، عيار، مصنوعية للغرام. الصافي بمعامل
/// البضاعة لهذا المشغل، والمصنوعية على القائم وتُدفع نقداً.
class GoodsInPage extends ConsumerStatefulWidget {
  const GoodsInPage({super.key, this.workshopId});

  /// المشغل إن فُتحت الشاشة من دفتره.
  final String? workshopId;

  @override
  ConsumerState<GoodsInPage> createState() => _GoodsInPageState();
}

class _GoodsInPageState extends ConsumerState<GoodsInPage> {
  final _form = GlobalKey<FormState>();
  final _note = TextEditingController();
  final List<GoodsLineState> _lines = [GoodsLineState()];
  String? _workshopId;
  DateTime _date = DateTime.now();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _workshopId = widget.workshopId;
  }

  @override
  void dispose() {
    _note.dispose();
    for (final l in _lines) {
      l.dispose();
    }
    super.dispose();
  }

  void _addLine() {
    // البند الجديد يرث عيار ومصنوعية ما قبله — غالباً فاتورة المشغل بعيار واحد
    final last = _lines.last;
    setState(() => _lines
        .add(GoodsLineState(karatId: last.karatId, making: last.making.text)));
  }

  void _removeLine(int i) {
    setState(() => _lines.removeAt(i).dispose());
  }

  Future<void> _newWorkshop() async {
    final l = context.l10n;
    final name =
        await askName(context, title: l.newWorkshop, label: l.workshopName);
    if (name == null || !mounted || !ensureOnline(context, ref)) return;
    try {
      final id = await ref
          .read(repositoryProvider)
          .createAccount(name, AccountKind.factory);
      ref.invalidate(accountsProvider);
      setState(() => _workshopId = id);
    } catch (e) {
      if (mounted) showResult(context, readableError(e), error: true);
    }
  }

  Future<void> _newItem(GoodsLineState line) async {
    final l = context.l10n;
    final name = await askName(context, title: l.newItem, label: l.itemName);
    if (!mounted) return;
    setState(() => line.rev++);
    if (name == null || !ensureOnline(context, ref)) return;
    try {
      final item = await ref.read(repositoryProvider).createItem(name);
      ref.invalidate(itemsProvider);
      setState(() => line.itemId = item.id);
    } catch (e) {
      if (mounted) showResult(context, readableError(e), error: true);
    }
  }

  List<GoodsLine> _buildLines(List<KaratOption> karats) => [
        for (final line in _lines)
          if (line.toGoods(karats) case final g?) g,
      ];

  Future<void> _submit(List<KaratOption> karats) async {
    final l = context.l10n;
    if (!_form.currentState!.validate()) return;
    final goods = _buildLines(karats);
    if (goods.length != _lines.length) {
      showResult(context, l.fillLines, error: true);
      return;
    }
    if (!ensureOnline(context, ref)) return;

    final bag = (ref.read(systemAccountsProvider).valueOrNull ??
        {})[SystemAccount.shanta];
    if (bag == null) {
      showResult(context, 'حسابات النظام غير مهيّأة', error: true);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final doc = await ref.read(repositoryProvider).goodsIn(
            workshopId: _workshopId!,
            bagAccountId: bag,
            lines: goods,
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
    final workshops = ref.watch(suppliersProvider);
    final items = ref.watch(itemsProvider);
    final karats = ref.watch(karatOptionsProvider((
      accountId: _workshopId,
      direction: GoldDirection.out,
    )));

    final loading = workshops.isLoading || items.isLoading || karats.isLoading;
    final error = workshops.error ?? items.error ?? karats.error;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(l.goodsInTitle)),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.goldPrimary))
          : error != null
              ? CenteredMessage(
                  icon: Icons.error_outline_rounded,
                  title: readableError(error))
              : _body(l, workshops.value!, items.value!, karats.value!),
    );
  }

  Widget _body(
    AppLocalizations l,
    List<Account> workshops,
    List<Item> items,
    List<KaratOption> karats,
  ) {
    ensureKarats(_lines, karats);

    final goods = _buildLines(karats);
    final pieces = goods.fold<int>(0, (a, g) => a + (g.quantity ?? 0));
    final gross = goods.fold<int>(0, (a, g) => a + g.grossWeightMg);
    final net = goods.fold<int>(0, (a, g) => a + g.netMg);
    final making = goods.fold<int>(0, (a, g) => a + g.makingFils);

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
                  // المشغل + التاريخ
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AdaptiveBox(
                        width: 360,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(
                              'workshop|$_workshopId|${workshops.length}'),
                          initialValue:
                              workshops.any((w) => w.id == _workshopId)
                                  ? _workshopId
                                  : null,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: l.supplier,
                            prefixIcon: const Icon(
                                Icons.precision_manufacturing_outlined,
                                size: 20),
                            helperText:
                                workshops.isEmpty ? l.noWorkshops : null,
                          ),
                          items: [
                            for (final w in workshops)
                              DropdownMenuItem(
                                  value: w.id, child: Text(w.name)),
                          ],
                          onChanged: (v) => setState(() => _workshopId = v),
                          validator: (v) => v == null ? l.requiredField : null,
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _newWorkshop,
                        icon: const Icon(Icons.add_business_outlined, size: 18),
                        label: Text(l.newWorkshop),
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
                  const SizedBox(height: 20),

                  for (var i = 0; i < _lines.length; i++) ...[
                    GoodsLineCard(
                      key: ObjectKey(_lines[i]),
                      index: i,
                      line: _lines[i],
                      items: items,
                      karats: karats,
                      canRemove: _lines.length > 1,
                      onRemove: () => _removeLine(i),
                      onNewItem: () => _newItem(_lines[i]),
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: _busy ? null : _addLine,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: Text(l.addLine),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.goldDark),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _note,
                    decoration: InputDecoration(
                      labelText: l.noteOptional,
                      prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // الملخص وأثره على المشغل
                  if (gross > 0) ...[
                    SummaryBar(title: l.summary, items: [
                      (l.totalPieces, '$pieces'),
                      (l.totalGross, '${formatGrams(gross)} ${l.gramsUnit}'),
                      (l.totalNet, '${formatGrams(net)} ${l.gramsUnit}'),
                      (l.totalMaking, '${formatDinars(making)} ${l.dinarUnit}'),
                    ]),
                    const SizedBox(height: 10),
                    Text(
                      l.effectWorkshop(formatGrams(net), formatDinars(making)),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _submit(karats),
                    icon: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(l.saveInvoice),
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
