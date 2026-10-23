import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/locale.dart';
import '../../core/units.dart';
import '../../domain/enums.dart';
import '../../platform/labels.dart';
import '../common/inputs.dart';
import '../common/ui.dart';
import '../pdf/pdf_kit.dart';
import '../pdf/reports_pdf.dart';
import 'period_picker.dart';
import 'report_models.dart';

/// تقرير المبيعات لفترة (يوم، أسبوع، شهر…) — ملخص على الشاشة وPDF كامل.
class SalesReportPage extends ConsumerStatefulWidget {
  const SalesReportPage({super.key});

  @override
  ConsumerState<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends ConsumerState<SalesReportPage> {
  Period _period = Period.of(PeriodPreset.thisWeek);
  SalesReport? _r;
  Object? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!_period.valid) return setState(() => _r = null);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final sys = await ref.read(systemAccountsProvider.future);
      final rows = await ref
          .read(repositoryProvider)
          .periodPostings(from: _period.from, to: _period.endExclusive);
      if (!mounted) return;
      setState(() {
        _r = SalesReport.build(
          from: _period.from,
          to: _period.to,
          postings: rows,
          bagId: sys[SystemAccount.shanta],
          makingIncomeId: sys[SystemAccount.makingIncome],
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
    final r = _r;
    if (r == null) return;
    final issuer = PdfIssuer.of(ref);
    PdfPreviewPage.open(
      context,
      title: context.l10n.salesReport,
      build: (arabic, format) =>
          buildSalesPdf(r: r, issuer: issuer, arabic: arabic, format: format),
      fileName: (arabic) =>
          '${arabic ? 'المبيعات' : 'sales'}-${pdfDateTag(r.from)}_${pdfDateTag(r.to)}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final r = _r;
    final g = l.gramsUnit;
    final jd = l.dinarUnit;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(l.salesReport)),
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
                  else if (r != null) ...[
                    ReportStats(stats: [
                      (
                        l.soldNet,
                        '${formatGrams(r.sold.netMg)} $g',
                        l.piecesCount(r.sold.pieces)
                      ),
                      (
                        l.returnedGoods,
                        '${formatGrams(r.returned.netMg)} $g',
                        l.piecesCount(r.returned.pieces)
                      ),
                      (l.netSales, '${formatGrams(r.netMg)} $g', null),
                      (
                        l.makingCharges,
                        '${formatDinars(r.makingFils)} $jd',
                        null
                      ),
                      (
                        l.makingProfit,
                        '${formatDinars(r.profitFils)} $jd',
                        null
                      ),
                      (l.invoicesCount, '${r.invoices}', null),
                    ]),
                    const SizedBox(height: 16),
                    if (r.parties.isNotEmpty) ...[
                      SectionTitle(l.byShop),
                      GoldCard(
                        child: Column(children: [
                          for (final p in r.partiesSorted)
                            ReportRow(
                              title: p.name,
                              sub: '${l.invoicesCount}: ${p.invoices}',
                              value: '${formatGrams(p.netMg)} $g',
                              value2: '${formatDinars(p.makingFils)} $jd',
                            ),
                        ]),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (r.days.isNotEmpty) ...[
                      SectionTitle(l.byDay),
                      GoldCard(
                        child: Column(children: [
                          for (final e in r.daysSorted)
                            ReportRow(
                              title: ltrIsolate(formatDate(e.key)),
                              sub: '${l.invoicesCount}: ${e.value.invoices}',
                              value: '${formatGrams(e.value.netMg)} $g',
                              value2: '${formatDinars(e.value.profitFils)} $jd',
                            ),
                        ]),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (r.days.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(l.noSalesInPeriod,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textMuted)),
                      ),
                    const SizedBox(height: 6),
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
}

/// أرقام التقرير في شبكة نصفين.
class ReportStats extends StatelessWidget {
  const ReportStats({super.key, required this.stats});

  final List<(String, String, String?)> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final perRow = c.maxWidth >= 600 ? 3 : 2;
      final w = (c.maxWidth - 10 * (perRow - 1)) / perRow;
      return Wrap(spacing: 10, runSpacing: 10, children: [
        for (final (label, value, sub) in stats)
          SizedBox(
            width: w,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.goldContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.goldBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(value,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: AppColors.goldDark)),
                  ),
                  if (sub != null)
                    Text(sub,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
      ]);
    });
  }
}

/// سطر في قائمة تقرير: عنوان وتحته وصف، وقيمتان في الطرف.
class ReportRow extends StatelessWidget {
  const ReportRow(
      {super.key,
      required this.title,
      this.sub,
      required this.value,
      this.value2});

  final String title;
  final String? sub;
  final String value;
  final String? value2;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              if (sub != null)
                Text(sub!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(value,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.goldDark)),
          if (value2 != null)
            Text(value2!,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
        ]),
      ]),
    );
  }
}
