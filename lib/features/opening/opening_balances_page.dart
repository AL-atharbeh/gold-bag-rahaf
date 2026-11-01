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

/// بدء النظام: أرصدة الأطراف السابقة، ومحتوى الشنطة.
class OpeningBalancesPage extends ConsumerWidget {
  const OpeningBalancesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final parties = ref.watch(counterpartiesProvider);
    final balances =
        ref.watch(balancesProvider).valueOrNull ?? const <AccountBalance>[];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(l.openingBalances)),
      body: AsyncBody<List<Account>>(
        value: parties,
        data: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            GoldCard(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OpeningBagPage()),
              ),
              child: Row(children: [
                const Icon(Icons.work_rounded, color: AppColors.goldDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.openingBag,
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(l.openingBagHint,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),
            for (final a in list) ...[
              GoldCard(
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => _OpeningPartyDialog(account: a),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(a.name,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    BalanceChips(
                      goldMg: balances
                              .where((b) => b.accountId == a.id)
                              .firstOrNull
                              ?.goldMg ??
                          0,
                      cashFils: balances
                              .where((b) => b.accountId == a.id)
                              .firstOrNull
                              ?.cashFils ??
                          0,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _OpeningPartyDialog extends ConsumerStatefulWidget {
  const _OpeningPartyDialog({required this.account});

  final Account account;

  @override
  ConsumerState<_OpeningPartyDialog> createState() =>
      _OpeningPartyDialogState();
}

class _OpeningPartyDialogState extends ConsumerState<_OpeningPartyDialog> {
  final _gold = TextEditingController();
  final _cash = TextEditingController();
  bool _goldForUs = true;
  bool _cashForUs = true;
  DateTime _date = DateTime.now();
  bool _busy = false;

  @override
  void dispose() {
    _gold.dispose();
    _cash.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final gold = parseGrams(_gold.text) ?? 0;
    final cash = parseDinars(_cash.text) ?? 0;
    if (gold <= 0 && cash <= 0) {
      showResult(context, l.emptyTx, error: true);
      return;
    }
    if (!ensureOnline(context, ref)) return;
    final capital = (ref.read(systemAccountsProvider).valueOrNull ??
        {})[SystemAccount.capital];
    if (capital == null) {
      showResult(context, 'حسابات النظام غير مهيّأة', error: true);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final doc = await ref.read(repositoryProvider).openingParty(
            partyId: widget.account.id,
            capitalId: capital,
            goldMg: _goldForUs ? gold : -gold,
            cashFils: _cashForUs ? cash : -cash,
            occurredAt: _date,
          );
      invalidateAfterPosting(ref);
      navigator.pop();
      messenger.showSnackBar(SnackBar(
          content: Text(l.openingSaved(doc)),
          backgroundColor: AppColors.goldDark));
    } catch (e) {
      if (mounted) showResult(context, readableError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _direction(AppLocalizations l, bool value, ValueChanged<bool> onChange) =>
      SegmentedButton<bool>(
        segments: [
          ButtonSegment(value: true, label: Text(l.openingForUs)),
          ButtonSegment(value: false, label: Text(l.openingForHim)),
        ],
        selected: {value},
        showSelectedIcon: false,
        onSelectionChanged: (s) => onChange(s.first),
      );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text('${l.openingBalances} — ${widget.account.name}'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _gold,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: decimalInputFormatters,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                    labelText: l.openingGold, suffixText: l.gramsUnit),
              ),
              const SizedBox(height: 8),
              _direction(l, _goldForUs, (v) => setState(() => _goldForUs = v)),
              const SizedBox(height: 16),
              TextField(
                controller: _cash,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: decimalInputFormatters,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                    labelText: l.openingCash, suffixText: l.dinarUnit),
              ),
              const SizedBox(height: 8),
              _direction(l, _cashForUs, (v) => setState(() => _cashForUs = v)),
              const SizedBox(height: 16),
              DateField(
                  value: _date, onChanged: (d) => setState(() => _date = d)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: Text(l.cancel)),
        FilledButton(
            onPressed: _busy ? null : _save, child: Text(l.save)),
      ],
    );
  }
}

/// ما في الشنطة عند بدء النظام: بضاعة وكسر وكاش.
class OpeningBagPage extends ConsumerStatefulWidget {
  const OpeningBagPage({super.key});

  @override
  ConsumerState<OpeningBagPage> createState() => _OpeningBagPageState();
}

class _OpeningBagPageState extends ConsumerState<OpeningBagPage> {
  final _form = GlobalKey<FormState>();
  final _cash = TextEditingController();
  final List<GoodsLineState> _goods = [GoodsLineState()];
  final List<GoodsLineState> _scrap = [];
  DateTime _date = DateTime.now();
  bool _busy = false;

  @override
  void dispose() {
    _cash.dispose();
    for (final s in [..._goods, ..._scrap]) {
      s.dispose();
    }
    super.dispose();
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

  Future<void> _save(
      List<KaratOption> goodsKarats, List<KaratOption> scrapKarats) async {
    final l = context.l10n;
    if (!_form.currentState!.validate()) return;
    final goods = _collect(_goods, goodsKarats);
    final scrap = _collect(_scrap, scrapKarats);
    if (goods == null || scrap == null) {
      showResult(context, l.fillLines, error: true);
      return;
    }
    final cash = parseDinars(_cash.text) ?? 0;
    if (goods.isEmpty && scrap.isEmpty && cash <= 0) {
      showResult(context, l.emptyTx, error: true);
      return;
    }
    if (!ensureOnline(context, ref)) return;
    final sys = ref.read(systemAccountsProvider).valueOrNull ?? {};
    final bag = sys[SystemAccount.shanta];
    final cashbox = sys[SystemAccount.cashbox];
    final capital = sys[SystemAccount.capital];
    if (bag == null || cashbox == null || capital == null) {
      showResult(context, 'حسابات النظام غير مهيّأة', error: true);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final doc = await ref.read(repositoryProvider).openingBag(
            bagAccountId: bag,
            cashboxId: cashbox,
            capitalId: capital,
            goods: goods,
            scrap: scrap,
            cashFils: cash,
            occurredAt: _date,
          );
      invalidateAfterPosting(ref);
      navigator.pop();
      messenger.showSnackBar(SnackBar(
          content: Text(l.openingSaved(doc)),
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
    final items = ref.watch(itemsProvider).valueOrNull ?? const <Item>[];
    final goodsKarats = ref.watch(karatOptionsProvider(
        (accountId: null, direction: GoldDirection.out)));
    final scrapKarats = ref.watch(karatOptionsProvider(
            (accountId: null, direction: GoldDirection.incoming)))
        .valueOrNull ??
        const <KaratOption>[];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(l.openingBag)),
      body: AsyncBody<List<KaratOption>>(
        value: goodsKarats,
        data: (ks) {
          ensureKarats(_goods, ks);
          ensureKarats(_scrap, scrapKarats);
          return Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 820),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AdaptiveBox(
                          width: 240,
                          child: DateField(
                              value: _date,
                              onChanged: (d) => setState(() => _date = d)),
                        ),
                        const SizedBox(height: 16),
                        SectionTitle(l.goodsInBag),
                        for (var i = 0; i < _goods.length; i++) ...[
                          GoodsLineCard(
                            key: ObjectKey(_goods[i]),
                            index: i,
                            line: _goods[i],
                            items: items,
                            karats: ks,
                            editableFactor: true,
                            onNewItem: () => _newItem(_goods[i]),
                            canRemove: _goods.length > 1,
                            onRemove: () => setState(
                                () => _goods.removeAt(i).dispose()),
                            onChanged: () => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: _busy
                                ? null
                                : () => setState(
                                    () => _goods.add(GoodsLineState())),
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            label: Text(l.addLine),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.goldDark),
                          ),
                        ),
                        SectionTitle(l.scrapInBag),
                        for (var i = 0; i < _scrap.length; i++) ...[
                          GoodsLineCard(
                            key: ObjectKey(_scrap[i]),
                            index: i,
                            title: l.scrapLine(i + 1),
                            line: _scrap[i],
                            karats: scrapKarats,
                            editableFactor: true,
                            canRemove: true,
                            onRemove: () => setState(
                                () => _scrap.removeAt(i).dispose()),
                            onChanged: () => setState(() {}),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: _busy
                                ? null
                                : () => setState(() =>
                                    _scrap.add(GoodsLineState(scrap: true))),
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            label: Text(l.addScrap),
                            style: TextButton.styleFrom(
                                foregroundColor: AppColors.goldDark),
                          ),
                        ),
                        const SizedBox(height: 8),
                        AdaptiveBox(
                          width: 260,
                          child: DinarsField(
                            controller: _cash,
                            label: l.cashAmount,
                            required: false,
                            allowZero: true,
                            onChanged: (_) {},
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed:
                              _busy ? null : () => _save(ks, scrapKarats),
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: Text(l.saveTx),
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
}
