import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/locale.dart';
import '../../core/units.dart';
import '../../domain/enums.dart';
import '../../platform/platform_models.dart';
import '../bags/bags_page.dart';
import '../common/inputs.dart';
import '../common/ui.dart';
import '../pdf/pdf_kit.dart';
import '../pdf/reports_pdf.dart';
import 'period_picker.dart';
import 'report_models.dart';
import 'sales_report_page.dart';

/// كشف الشنطة الكامل لفترة: افتتاحي، داخل، خارج، ختامي لكل صنف،
/// ورأس المال، وكل الحركات.
class BagStatementPage extends ConsumerStatefulWidget {
  const BagStatementPage({super.key});

  @override
  ConsumerState<BagStatementPage> createState() => _BagStatementPageState();
}

class _BagStatementPageState extends ConsumerState<BagStatementPage> {
  Period _period = Period.of(PeriodPreset.thisMonth);
  BagStatement? _s;
  Object? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!_period.valid) return setState(() => _s = null);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(repositoryProvider);
      final sys = await ref.read(systemAccountsProvider.future);
      final bagId = sys[SystemAccount.shanta];
      if (bagId == null) throw Exception('الشنطة غير مهيّأة');
      // كل ما جرى منذ بداية الفترة حتى الآن — منه يُستخرج الافتتاحي
      final since =
          await repo.periodPostings(accountId: bagId, from: _period.from);
      final stock = await repo.itemStock(bagId);
      final balances = await ref.read(balancesProvider.future);
      final capital =
          balances.where((b) => b.accountId == bagId).firstOrNull?.cashFils ??
              0;
      if (!mounted) return;
      setState(() {
        _s = BagStatement.build(
          from: _period.from,
          to: _period.to,
          sinceFrom: since,
          stockNow: stock,
          capitalNowFils: capital,
        );
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  void _pdf() {
    final s = _s;
    if (s == null) return;
    final bagId =
        ref.read(systemAccountsProvider).valueOrNull?[SystemAccount.shanta];
    final holder = (ref.read(bagsProvider).valueOrNull ?? const <Bag>[])
        .where((b) => b.accountId == bagId)
        .firstOrNull
        ?.holderName;
    final issuer = PdfIssuer.of(ref);
    PdfPreviewPage.open(
      context,
      title: context.l10n.bagStatement,
      build: (arabic, format) => buildBagStatementPdf(
          s: s,
          holderName: holder,
          issuer: issuer,
          arabic: arabic,
          format: format),
      fileName: (arabic) =>
          '${arabic ? 'كشف-الشنطة' : 'bag-statement'}-${pdfDateTag(s.from)}_${pdfDateTag(s.to)}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = _s;
    final g = l.gramsUnit;
    final jd = l.dinarUnit;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(l.bagStatement)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PeriodPicker(
                    value: _period,
                    onChanged: (p) {
                      setState(() => _period = p);
                      _load();
                    },
                  ),
                  const SizedBox(height: 18),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    CenteredMessage(
                      icon: Icons.error_outline_rounded,
                      title: readableError(_error!),
                      action:
                          TextButton(onPressed: _load, child: Text(l.retry)),
                    )
                  else if (s != null) ...[
                    () {
                      final o = s.total(false, s.openingOf);
                      final i = s.total(false, s.inOf);
                      final x = s.total(false, s.outOf);
                      final c = s.total(false, s.closing);
                      return ReportStats(stats: [
                        (
                          l.openingBalance,
                          '${formatGrams(o.netMg)} $g',
                          l.piecesCount(o.pieces)
                        ),
                        (
                          l.goodsInPeriod,
                          '${formatGrams(i.netMg)} $g',
                          l.piecesCount(i.pieces)
                        ),
                        (
                          l.goodsOutPeriod,
                          '${formatGrams(x.netMg)} $g',
                          l.piecesCount(x.pieces)
                        ),
                        (
                          l.closingBalance,
                          '${formatGrams(c.netMg)} $g',
                          l.piecesCount(c.pieces)
                        ),
                        (
                          l.bagCapital,
                          '${formatDinars(s.closingCapitalFils)} $jd',
                          '${l.openingBalance}: ${formatDinars(s.openingCapitalFils)}'
                        ),
                        (l.periodMovements, '${s.moves.length}', null),
                      ]);
                    }(),
                    const SizedBox(height: 16),
                    if (s.rows.isNotEmpty) ...[
                      SectionTitle(l.stockByItem),
                      GoldCard(
                        child: Column(children: [
                          for (final k in s.rows)
                            ReportRow(
                              title: [
                                k.isScrap ? l.scrap : (k.itemName ?? '—'),
                                if (k.karatName != null) k.karatName!,
                              ].join(' · '),
                              sub:
                                  '${l.openingShort} ${_q(s.openingOf(k.id), k)}  ·  '
                                  '${l.inShort} ${_q(s.inOf(k.id), k)}  ·  '
                                  '${l.outShort} ${_q(s.outOf(k.id), k)}',
                              value: '${formatGrams(s.closing(k.id).netMg)} $g',
                              value2: k.isScrap
                                  ? null
                                  : l.piecesCount(s.closing(k.id).pieces),
                            ),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _pdf,
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: Text(l.previewPdf),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _q(Qty q, ItemKey k) => k.isScrap || q.pieces == 0
      ? formatGrams(q.netMg)
      : '${q.pieces}/${formatGrams(q.netMg)}';
}
