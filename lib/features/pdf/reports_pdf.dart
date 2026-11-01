import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/phone.dart';
import '../../core/units.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../platform/labels.dart';
import '../bag/bag_inventory.dart';
import '../home/day_summary.dart';
import '../reports/report_models.dart';
import 'pdf_kit.dart';

/// جرد الشنطة الآن: البضاعة صنفاً صنفاً، والكسر عياراً عياراً، والكاش
/// النقدي، والشيكات بالصندوق، ورأس مال المصنوعية.
Future<Uint8List> buildStockPdf({
  required BagInventory inv,
  required String? holderName,
  required PdfIssuer issuer,
  required bool arabic,
  PdfPageFormat format = PdfPageFormat.a4,
}) async {
  final ar = arabic;
  final g = ar ? 'غ' : 'g';
  final jd = ar ? 'د.أ' : 'JOD';

  pw.Widget table(List<ItemStock> rows, bool scrap) {
    final pieces = rows.fold<int>(0, (a, r) => a + r.quantity);
    final gross = rows.fold<int>(0, (a, r) => a + r.grossMg);
    final net = rows.fold<int>(0, (a, r) => a + r.netMg);
    return pw.Table(
      border: pdfTableBorder,
      columnWidths: const {0: pw.FlexColumnWidth(2.2)},
      children: [
        pdfHeadRow(ar
            ? [
                scrap ? 'الكسر' : 'الصنف',
                'العيار',
                if (!scrap) 'العدد',
                'القائم ($g)',
                'الصافي 24 ($g)'
              ]
            : [
                scrap ? 'Scrap' : 'Item',
                'Karat',
                if (!scrap) 'Pcs',
                'Gross ($g)',
                'Net 24K ($g)'
              ]),
        for (final r in rows)
          pw.TableRow(children: [
            pdfCell(scrap
                ? (ar ? 'كسر' : 'Scrap')
                : (r.itemName ?? (ar ? 'صنف' : 'Item'))),
            pdfCell(r.karatName == null ? '—' : pdfKarat(r.karatName!, ar)),
            if (!scrap) pdfCell('${r.quantity}', ltr: true),
            pdfCell(formatGrams(r.grossMg), ltr: true),
            pdfCell(formatGrams(r.netMg), ltr: true, bold: true),
          ]),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfPalette.goldSoft),
          children: [
            pdfCell(ar ? 'المجموع' : 'Total', bold: true),
            pdfCell(''),
            if (!scrap) pdfCell('$pieces', ltr: true, bold: true),
            pdfCell(formatGrams(gross), ltr: true, bold: true),
            pdfCell(formatGrams(net), ltr: true, bold: true),
          ],
        ),
      ],
    );
  }

  final doc = pw.Document(theme: await pdfTheme(), author: issuer.name);
  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      textDirection: ar ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 32),
      header: (ctx) => pdfHeader(
        issuer: issuer,
        title: ar ? 'جرد الشنطة' : 'Bag Inventory',
        issuedLabel: ar ? 'تاريخ الجرد' : 'As of',
      ),
      footer: (ctx) => pdfFooter(ctx, issuer.name, ar),
      build: (ctx) => [
        pdfInfoBox(pw.Wrap(spacing: 24, runSpacing: 6, children: [
          if (holderName != null && holderName.isNotEmpty)
            pdfKv(ar ? 'حامل الشنطة' : 'Bag holder', holderName),
          pdfKv(ar ? 'البضاعة' : 'Goods',
              '${inv.goodsPieces} ${ar ? 'قطعة' : 'pcs'} · ${formatGrams(inv.goodsNetMg)} $g'),
          pdfKv(ar ? 'الكسر' : 'Scrap', '${formatGrams(inv.scrapNetMg)} $g'),
          pdfKv(ar ? 'إجمالي الذهب (صافي)' : 'Total gold (net)',
              '${formatGrams(inv.totalNetMg)} $g'),
          pdfKv(ar ? 'الكاش' : 'Cash', '${formatDinars(inv.cashFils)} $jd'),
          if (inv.chequesInFils != 0)
            pdfKv(ar ? 'شيكات بالصندوق' : 'Cheques in hand',
                '${formatDinars(inv.chequesInFils)} $jd'),
          if (inv.chequesOutFils != 0)
            pdfKv(ar ? 'شيكات صادرة لم تُصرف' : 'Outgoing cheques pending',
                '${formatDinars(inv.chequesOutFils)} $jd'),
          pdfKv(ar ? 'رأس المال (مصنوعية)' : 'Capital (making)',
              '${formatDinars(inv.capitalFils)} $jd'),
        ])),
        pdfSectionTitle(ar ? 'البضاعة' : 'Goods'),
        if (inv.goods.isEmpty) pw.Text('—') else table(inv.goods, false),
        if (inv.scrap.isNotEmpty) ...[
          pdfSectionTitle(ar ? 'الكسر' : 'Scrap'),
          table(inv.scrap, true),
        ],
      ],
    ),
  );
  return doc.save();
}

/// تقرير الذمم: كل المحلات أو التجار وأرصدتهم الآن، الأكبر أولاً.
Future<Uint8List> buildBalancesPdf({
  required String title,
  required List<(Account, AccountBalance?)> rows,
  required PdfIssuer issuer,
  required bool arabic,
  PdfPageFormat format = PdfPageFormat.a4,
}) async {
  final ar = arabic;
  String bal(int v, String Function(int) fmt) => v == 0
      ? (ar ? 'مسدد' : 'Settled')
      : '${fmt(v.abs())} ${v > 0 ? (ar ? 'عليه' : 'Dr') : (ar ? 'له' : 'Cr')}';
  PdfColor color(int v) => v < 0 ? PdfPalette.red : PdfColors.black;

  final sorted = [...rows]..sort(
      (a, b) => (b.$2?.goldMg.abs() ?? 0).compareTo(a.$2?.goldMg.abs() ?? 0));
  int sum(bool gold, bool positive) => rows.fold(0, (a, r) {
        final v = (gold ? r.$2?.goldMg : r.$2?.cashFils) ?? 0;
        return a + ((positive ? v > 0 : v < 0) ? v.abs() : 0);
      });

  final doc = pw.Document(theme: await pdfTheme(), author: issuer.name);
  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      textDirection: ar ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 32),
      header: (ctx) => pdfHeader(
        issuer: issuer,
        title: title,
        issuedLabel: ar ? 'الأرصدة حتى' : 'Balances as of',
      ),
      footer: (ctx) => pdfFooter(ctx, issuer.name, ar),
      build: (ctx) => [
        pw.Table(
          border: pdfTableBorder,
          columnWidths: const {
            0: pw.FlexColumnWidth(0.5),
            1: pw.FlexColumnWidth(2.4),
            2: pw.FlexColumnWidth(1.5),
            3: pw.FlexColumnWidth(1.7),
            4: pw.FlexColumnWidth(1.8),
          },
          children: [
            pdfHeadRow(ar
                ? ['#', 'الاسم', 'الهاتف', 'رصيد الذهب (غ)', 'رصيد النقد (د.أ)']
                : ['#', 'Name', 'Phone', 'Gold (g)', 'Cash (JOD)']),
            for (final (i, r) in sorted.indexed)
              pw.TableRow(children: [
                pdfCell('${i + 1}', ltr: true),
                pdfCell(r.$1.name,
                    align: ar ? pw.TextAlign.right : pw.TextAlign.left),
                pdfCell(displayPhone(r.$1.phone), ltr: true),
                pdfCell(bal(r.$2?.goldMg ?? 0, formatGrams),
                    color: color(r.$2?.goldMg ?? 0)),
                pdfCell(bal(r.$2?.cashFils ?? 0, formatDinars),
                    color: color(r.$2?.cashFils ?? 0)),
              ]),
          ],
        ),
        pw.SizedBox(height: 14),
        pdfInfoBox(
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pdfKv(ar ? 'مجموع ما عليهم ذهباً' : 'Total gold owed to us',
                  '${formatGrams(sum(true, true))} ${ar ? 'غ' : 'g'}'),
              pdfKv(ar ? 'مجموع ما لهم ذهباً' : 'Total gold we owe',
                  '${formatGrams(sum(true, false))} ${ar ? 'غ' : 'g'}'),
              pdfKv(ar ? 'مجموع ما عليهم نقداً' : 'Total cash owed to us',
                  '${formatDinars(sum(false, true))} ${ar ? 'د.أ' : 'JOD'}'),
              pdfKv(ar ? 'مجموع ما لهم نقداً' : 'Total cash we owe',
                  '${formatDinars(sum(false, false))} ${ar ? 'د.أ' : 'JOD'}'),
            ],
          ),
        ),
      ],
    ),
  );
  return doc.save();
}

String balancesTitle(AccountKind kind, bool arabic) => switch (kind) {
      AccountKind.showroom => arabic ? 'ذمم المحلات' : 'Shops Balances',
      AccountKind.trader => arabic ? 'ذمم التجار' : 'Traders Balances',
      AccountKind.factory => arabic ? 'ذمم المشاغل' : 'Workshops Balances',
      _ => arabic ? 'الذمم' : 'Balances',
    };

/// سجل الشيكات: المعلّقة بالاستحقاق أولاً، ثم المنتهية.
Future<Uint8List> buildChequesPdf({
  required List<Cheque> cheques,
  required PdfIssuer issuer,
  required bool arabic,
  PdfPageFormat format = PdfPageFormat.a4,
}) async {
  final ar = arabic;
  final jd = ar ? 'د.أ' : 'JOD';
  final pending = cheques
      .where((c) => c.status == ChequeStatus.pending)
      .toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  final done = cheques.where((c) => c.status != ChequeStatus.pending).toList()
    ..sort((a, b) => b.dueDate.compareTo(a.dueDate));

  String status(Cheque c) => switch (c.status) {
        ChequeStatus.pending => c.isOverdue
            ? (ar
                ? 'متأخر ${-c.daysUntilDue} يوماً'
                : '${-c.daysUntilDue} days overdue')
            : (ar ? 'معلّق' : 'Pending'),
        ChequeStatus.cleared => ar ? 'محصّل' : 'Cleared',
        ChequeStatus.bounced => ar ? 'مرتجع' : 'Bounced',
        ChequeStatus.cancelled => ar ? 'ملغى' : 'Cancelled',
      };

  pw.Widget table(List<Cheque> list) => pw.Table(
        border: pdfTableBorder,
        columnWidths: const {
          0: pw.FlexColumnWidth(1.3),
          1: pw.FlexColumnWidth(2.2),
          2: pw.FlexColumnWidth(1),
          3: pw.FlexColumnWidth(1.2),
          4: pw.FlexColumnWidth(1.3),
          5: pw.FlexColumnWidth(1.5),
          6: pw.FlexColumnWidth(1.4),
        },
        children: [
          pdfHeadRow(ar
              ? [
                  'الاستحقاق',
                  'الطرف',
                  'النوع',
                  'رقم الشيك',
                  'البنك',
                  'المبلغ ($jd)',
                  'الحالة'
                ]
              : [
                  'Due',
                  'Party',
                  'Type',
                  'No.',
                  'Bank',
                  'Amount ($jd)',
                  'Status'
                ]),
          for (final c in list)
            pw.TableRow(children: [
              pdfCell(formatDate(c.dueDate), ltr: true),
              pdfCell(c.accountName ?? '—'),
              pdfCell(c.direction == ChequeDirection.incoming
                  ? (ar ? 'وارد' : 'In')
                  : (ar ? 'صادر' : 'Out')),
              pdfCell(c.chequeNumber ?? '—', ltr: true),
              pdfCell(c.bankName ?? '—'),
              pdfCell(formatDinars(c.amountFils), ltr: true, bold: true),
              pdfCell(status(c), color: c.isOverdue ? PdfPalette.red : null),
            ]),
        ],
      );

  int sum(ChequeDirection d) => pending
      .where((c) => c.direction == d)
      .fold(0, (a, c) => a + c.amountFils);

  final doc = pw.Document(theme: await pdfTheme(), author: issuer.name);
  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      textDirection: ar ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 32),
      header: (ctx) => pdfHeader(
        issuer: issuer,
        title: ar ? 'سجل الشيكات' : 'Cheques Register',
        issuedLabel: ar ? 'تاريخ الإصدار' : 'Issued on',
      ),
      footer: (ctx) => pdfFooter(ctx, issuer.name, ar),
      build: (ctx) => [
        pdfInfoBox(pw.Row(children: [
          pw.Expanded(
              child: pdfKv(ar ? 'شيكات واردة معلّقة' : 'Pending incoming',
                  '${formatDinars(sum(ChequeDirection.incoming))} $jd')),
          pw.Expanded(
              child: pdfKv(ar ? 'شيكات صادرة معلّقة' : 'Pending outgoing',
                  '${formatDinars(sum(ChequeDirection.outgoing))} $jd')),
        ])),
        pdfSectionTitle(ar ? 'الشيكات المعلّقة' : 'Pending cheques'),
        if (pending.isEmpty)
          pw.Text(ar ? 'لا توجد شيكات معلّقة' : 'No pending cheques',
              style: const pw.TextStyle(fontSize: 9, color: PdfPalette.muted))
        else
          table(pending),
        if (done.isNotEmpty) ...[
          pdfSectionTitle(ar ? 'شيكات منتهية' : 'Closed cheques'),
          table(done),
        ],
      ],
    ),
  );
  return doc.save();
}

String _period(DateTime from, DateTime to, bool ar) =>
    '${ar ? 'من' : 'From'} ${formatDate(from)}  ${ar ? 'إلى' : 'to'} ${formatDate(to)}';

String _signed(int v, String Function(int) fmt) =>
    v == 0 ? '—' : '${v > 0 ? '+' : '−'}${fmt(v.abs())}';

String _karatOf(String? name, bool ar) =>
    name == null ? '—' : pdfKarat(name, ar);

/// تقرير المبيعات لفترة: الإجماليات، ثم بالأيام والمحلات والأصناف.
Future<Uint8List> buildSalesPdf({
  required SalesReport r,
  required PdfIssuer issuer,
  required bool arabic,
  PdfPageFormat format = PdfPageFormat.a4,
}) async {
  final ar = arabic;
  final g = ar ? 'غ' : 'g';
  final jd = ar ? 'د.أ' : 'JOD';
  final pcsWord = ar ? 'قطعة' : 'pcs';
  final total = ar ? 'المجموع' : 'Total';

  final doc = pw.Document(theme: await pdfTheme(), author: issuer.name);
  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      textDirection: ar ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 32),
      header: (ctx) => pdfHeader(
        issuer: issuer,
        title: ar ? 'تقرير المبيعات' : 'Sales Report',
        subtitle: _period(r.from, r.to, ar),
        issuedLabel: ar ? 'تاريخ الإصدار' : 'Issued on',
      ),
      footer: (ctx) => pdfFooter(ctx, issuer.name, ar),
      build: (ctx) => [
        pdfInfoBox(pw.Wrap(spacing: 24, runSpacing: 6, children: [
          pdfKv(ar ? 'المبيع (صافي)' : 'Sold (net)',
              '${formatGrams(r.sold.netMg)} $g · ${r.sold.pieces} $pcsWord'),
          pdfKv(ar ? 'المرتجع' : 'Returned',
              '${formatGrams(r.returned.netMg)} $g · ${r.returned.pieces} $pcsWord'),
          pdfKv(
              ar ? 'صافي المبيعات' : 'Net sales', '${formatGrams(r.netMg)} $g'),
          pdfKv(ar ? 'المصنوعية' : 'Making charges',
              '${formatDinars(r.makingFils)} $jd'),
          pdfKv(ar ? 'عدد الفواتير' : 'Invoices', '${r.invoices}'),
        ])),
        pdfSectionTitle(ar ? 'حسب اليوم' : 'By day'),
        pw.Table(
          border: pdfTableBorder,
          children: [
            pdfHeadRow(ar
                ? [
                    'التاريخ',
                    'الفواتير',
                    'القطع',
                    'الصافي ($g)',
                    'المصنوعية ($jd)'
                  ]
                : [
                    'Date',
                    'Invoices',
                    'Pcs',
                    'Net ($g)',
                    'Making ($jd)'
                  ]),
            for (final e in r.daysSorted)
              pw.TableRow(children: [
                pdfCell(formatDate(e.key), ltr: true),
                pdfCell('${e.value.invoices}', ltr: true),
                pdfCell('${e.value.sold.pieces - e.value.returned.pieces}',
                    ltr: true),
                pdfCell(formatGrams(e.value.netMg), ltr: true, bold: true),
                pdfCell(formatDinars(e.value.makingFils), ltr: true),
              ]),
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfPalette.goldSoft),
              children: [
                pdfCell(total, bold: true),
                pdfCell('${r.invoices}', ltr: true, bold: true),
                pdfCell('${r.sold.pieces - r.returned.pieces}',
                    ltr: true, bold: true),
                pdfCell(formatGrams(r.netMg), ltr: true, bold: true),
                pdfCell(formatDinars(r.makingFils), ltr: true, bold: true),
              ],
            ),
          ],
        ),
        pdfSectionTitle(ar ? 'حسب المحل' : 'By shop'),
        pw.Table(
          border: pdfTableBorder,
          columnWidths: const {0: pw.FlexColumnWidth(2.2)},
          children: [
            pdfHeadRow(ar
                ? [
                    'المحل',
                    'الفواتير',
                    'المبيع ($g)',
                    'المرتجع ($g)',
                    'الصافي ($g)',
                    'المصنوعية ($jd)'
                  ]
                : [
                    'Shop',
                    'Invoices',
                    'Sold ($g)',
                    'Returned ($g)',
                    'Net ($g)',
                    'Making ($jd)'
                  ]),
            for (final p in r.partiesSorted)
              pw.TableRow(children: [
                pdfCell(p.name,
                    align: ar ? pw.TextAlign.right : pw.TextAlign.left),
                pdfCell('${p.invoices}', ltr: true),
                pdfCell(formatGrams(p.sold.netMg), ltr: true),
                pdfCell(formatGrams(p.returned.netMg), ltr: true),
                pdfCell(formatGrams(p.netMg), ltr: true, bold: true),
                pdfCell(formatDinars(p.makingFils), ltr: true),
              ]),
          ],
        ),
        pdfSectionTitle(ar ? 'حسب الصنف' : 'By item'),
        pw.Table(
          border: pdfTableBorder,
          columnWidths: const {0: pw.FlexColumnWidth(2)},
          children: [
            pdfHeadRow(ar
                ? ['الصنف', 'العيار', 'القطع', 'القائم ($g)', 'الصافي ($g)']
                : ['Item', 'Karat', 'Pcs', 'Gross ($g)', 'Net ($g)']),
            for (final (k, q) in r.itemsSorted)
              pw.TableRow(children: [
                pdfCell(k.itemName ?? '—'),
                pdfCell(_karatOf(k.karatName, ar)),
                pdfCell('${q.pieces}', ltr: true),
                pdfCell(formatGrams(q.grossMg), ltr: true),
                pdfCell(formatGrams(q.netMg), ltr: true, bold: true),
              ]),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Text(
            ar
                ? 'المرتجع من المحلات مطروح من الأرقام. الحركات الملغاة غير محسوبة.'
                : 'Shop returns are deducted. Cancelled transactions are excluded.',
            style: const pw.TextStyle(fontSize: 7.5, color: PdfPalette.muted)),
      ],
    ),
  );
  return doc.save();
}

/// كشف الشنطة لفترة: الافتتاحي والداخل والخارج والختامي لكل صنف،
/// ثم رأس المال، ثم كل الحركات.
Future<Uint8List> buildBagStatementPdf({
  required BagStatement s,
  required String? holderName,
  required PdfIssuer issuer,
  required bool arabic,
  PdfPageFormat format = PdfPageFormat.a4,
}) async {
  final ar = arabic;
  final g = ar ? 'غ' : 'g';
  final jd = ar ? 'د.أ' : 'JOD';
  String q(Qty x, {bool pcs = true}) => pcs && x.pieces != 0
      ? '${x.pieces} · ${formatGrams(x.netMg)}'
      : formatGrams(x.netMg);

  pw.TableRow totalRow(String label, bool scrap) {
    final o = s.total(scrap, s.openingOf);
    final i = s.total(scrap, s.inOf);
    final x = s.total(scrap, s.outOf);
    final c = s.total(scrap, s.closing);
    return pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfPalette.goldSoft),
      children: [
        pdfCell(label, bold: true),
        pdfCell(''),
        pdfCell(q(o, pcs: !scrap), ltr: true, bold: true),
        pdfCell(q(i, pcs: !scrap), ltr: true, bold: true),
        pdfCell(q(x, pcs: !scrap), ltr: true, bold: true),
        pdfCell(q(c, pcs: !scrap), ltr: true, bold: true),
      ],
    );
  }

  final cancelled = ar ? ' (ملغاة)' : ' (cancelled)';
  final doc = pw.Document(theme: await pdfTheme(), author: issuer.name);
  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      textDirection: ar ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 32),
      header: (ctx) => pdfHeader(
        issuer: issuer,
        title: ar ? 'كشف الشنطة' : 'Bag Statement',
        subtitle: _period(s.from, s.to, ar),
        issuedLabel: ar ? 'تاريخ الإصدار' : 'Issued on',
      ),
      footer: (ctx) => pdfFooter(ctx, issuer.name, ar),
      build: (ctx) => [
        if (holderName != null && holderName.isNotEmpty)
          pdfInfoBox(pdfKv(ar ? 'حامل الشنطة' : 'Bag holder', holderName)),
        pdfSectionTitle(ar ? 'المخزون حسب الصنف' : 'Stock by item'),
        pw.Table(
          border: pdfTableBorder,
          columnWidths: const {0: pw.FlexColumnWidth(1.8)},
          children: [
            pdfHeadRow(ar
                ? ['الصنف', 'العيار', 'افتتاحي', 'داخل', 'خارج', 'ختامي']
                : ['Item', 'Karat', 'Opening', 'In', 'Out', 'Closing']),
            for (final k in s.rows)
              pw.TableRow(children: [
                pdfCell(
                    k.isScrap ? (ar ? 'كسر' : 'Scrap') : (k.itemName ?? '—')),
                pdfCell(_karatOf(k.karatName, ar)),
                pdfCell(q(s.openingOf(k.id), pcs: !k.isScrap), ltr: true),
                pdfCell(q(s.inOf(k.id), pcs: !k.isScrap), ltr: true),
                pdfCell(q(s.outOf(k.id), pcs: !k.isScrap), ltr: true),
                pdfCell(q(s.closing(k.id), pcs: !k.isScrap),
                    ltr: true, bold: true),
              ]),
            totalRow(ar ? 'مجموع البضاعة' : 'Goods total', false),
            if (s.keys.values.any((k) => k.isScrap))
              totalRow(ar ? 'مجموع الكسر' : 'Scrap total', true),
          ],
        ),
        pw.SizedBox(height: 4),
        pw.Text(
            ar
                ? 'كل خانة: عدد القطع · الوزن الصافي عيار 24 بالغرام.'
                : 'Each cell: pieces · net 24K grams.',
            style: const pw.TextStyle(fontSize: 7.5, color: PdfPalette.muted)),
        pdfSectionTitle(ar ? 'رأس المال (مصنوعية)' : 'Capital (making)'),
        pdfInfoBox(pw.Wrap(spacing: 24, runSpacing: 6, children: [
          pdfKv(ar ? 'افتتاحي' : 'Opening',
              '${formatDinars(s.openingCapitalFils)} $jd'),
          pdfKv(ar ? 'التغير' : 'Change',
              '${_signed(s.capitalChangeFils, formatDinars)} $jd'),
          pdfKv(ar ? 'ختامي' : 'Closing',
              '${formatDinars(s.closingCapitalFils)} $jd'),
        ])),
        pdfSectionTitle(ar ? 'الحركات' : 'Movements'),
        if (s.moves.isEmpty)
          pw.Text(
              ar
                  ? 'لا توجد حركات في هذه الفترة'
                  : 'No movements in this period',
              style: const pw.TextStyle(fontSize: 9, color: PdfPalette.muted))
        else
          pw.Table(
            border: pdfTableBorder,
            columnWidths: const {3: pw.FlexColumnWidth(1.8)},
            children: [
              pdfHeadRow(ar
                  ? [
                      'التاريخ',
                      'الرقم',
                      'النوع',
                      'الطرف',
                      'القطع',
                      'بضاعة ($g)',
                      'كسر ($g)',
                      'رأس المال ($jd)'
                    ]
                  : [
                      'Date',
                      'Ref.',
                      'Type',
                      'Party',
                      'Pcs',
                      'Goods ($g)',
                      'Scrap ($g)',
                      'Capital ($jd)'
                    ]),
              for (final m in s.moves)
                pw.TableRow(children: [
                  pdfCell(formatDate(m.first.occurredAt), ltr: true, size: 7.5),
                  pdfCell(m.first.docNumber, ltr: true, size: 7.5),
                  pdfCell(
                      pdfTxType(m.first.txType, ar) +
                          (m.first.txReversed ? cancelled : ''),
                      size: 7.5),
                  pdfCell(m.first.partyName ?? '—', size: 7.5),
                  pdfCell(
                      m.pieces == 0
                          ? '—'
                          : (m.pieces > 0 ? '+${m.pieces}' : '−${-m.pieces}'),
                      ltr: true,
                      size: 7.5),
                  pdfCell(_signed(m.goodsNetMg, formatGrams),
                      ltr: true, size: 7.5),
                  pdfCell(_signed(m.scrapNetMg, formatGrams),
                      ltr: true, size: 7.5),
                  pdfCell(_signed(m.capitalFils, formatDinars),
                      ltr: true, size: 7.5),
                ]),
            ],
          ),
      ],
    ),
  );
  return doc.save();
}

/// يومية الشنطة: ملخص اليوم، والمصاريف، وجرد البضاعة والكسر، والكاش.
Future<Uint8List> buildDayReportPdf({
  required DateTime day,
  required DaySummary d,
  required BagInventory inv,
  required int openingCashFils,
  required int expectedCashFils,
  required int countedCashFils,
  required PdfIssuer issuer,
  required bool arabic,
  PdfPageFormat format = PdfPageFormat.a4,
}) async {
  final ar = arabic;
  final g = ar ? 'غ' : 'g';
  final jd = ar ? 'د.أ' : 'JOD';
  final diff = countedCashFils - expectedCashFils;

  String exp(ExpenseCategory? c) => switch (c) {
        ExpenseCategory.fuel => ar ? 'بنزين' : 'Fuel',
        ExpenseCategory.food => ar ? 'أكل' : 'Food',
        ExpenseCategory.transport => ar ? 'مواصلات' : 'Transport',
        ExpenseCategory.maintenance => ar ? 'صيانة' : 'Maintenance',
        ExpenseCategory.personal => ar ? 'سحب شخصي' : 'Personal',
        ExpenseCategory.other || null => ar ? 'أخرى' : 'Other',
      };

  pw.Widget stockTable(List<ItemStock> rows, bool scrap) => pw.Table(
        border: pdfTableBorder,
        columnWidths: const {0: pw.FlexColumnWidth(2)},
        children: [
          pdfHeadRow(ar
              ? [
                  scrap ? 'الكسر' : 'الصنف',
                  'العيار',
                  if (!scrap) 'القطع',
                  'القائم ($g)',
                  'الصافي ($g)'
                ]
              : [
                  scrap ? 'Scrap' : 'Item',
                  'Karat',
                  if (!scrap) 'Pcs',
                  'Gross ($g)',
                  'Net ($g)'
                ]),
          for (final r in rows)
            pw.TableRow(children: [
              pdfCell(scrap
                  ? (ar ? 'كسر' : 'Scrap')
                  : (r.itemName ?? (ar ? 'صنف' : 'Item'))),
              pdfCell(r.karatName == null ? '—' : pdfKarat(r.karatName!, ar)),
              if (!scrap) pdfCell('${r.quantity}', ltr: true),
              pdfCell(formatGrams(r.grossMg), ltr: true),
              pdfCell(formatGrams(r.netMg), ltr: true, bold: true),
            ]),
        ],
      );

  final doc = pw.Document(theme: await pdfTheme(), author: issuer.name);
  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      textDirection: ar ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 32),
      header: (ctx) => pdfHeader(
        issuer: issuer,
        title: ar ? 'يومية الشنطة' : 'Bag Day Report',
        subtitle: formatDate(day),
        issuedLabel: ar ? 'تاريخ الإصدار' : 'Issued on',
      ),
      footer: (ctx) => pdfFooter(ctx, issuer.name, ar),
      build: (ctx) => [
        pdfSectionTitle(ar ? 'ملخص اليوم' : 'Day summary'),
        pdfInfoBox(pw.Wrap(spacing: 24, runSpacing: 6, children: [
          pdfKv(ar ? 'المبيعات (صافي)' : 'Sales (net)',
              '${formatGrams(d.soldNetMg)} $g · ${d.soldPieces} ${ar ? 'قطعة' : 'pcs'}'),
          pdfKv(ar ? 'الكسر المستلم' : 'Scrap received',
              '${formatGrams(d.scrapInMg)} $g'),
          pdfKv(ar ? 'النقد المقبوض' : 'Cash received',
              '${formatDinars(d.cashInFils)} $jd'),
          if (d.chequesInFils != 0)
            pdfKv(ar ? 'شيكات مستلمة' : 'Cheques received',
                '${formatDinars(d.chequesInFils)} $jd'),
          pdfKv(ar ? 'المصاريف' : 'Expenses',
              '${formatDinars(d.expensesFils)} $jd'),
          pdfKv(ar ? 'مجموع الكاش اليومي' : 'Daily cash total',
              '${formatDinars(expectedCashFils + d.cashOutFils)} $jd'),
          pdfKv(ar ? 'الكاش الصافي' : 'Net cash',
              '${formatDinars(expectedCashFils)} $jd'),
        ])),
        if (d.expenses.isNotEmpty) ...[
          pdfSectionTitle(ar ? 'المصاريف' : 'Expenses'),
          pw.Table(
            border: pdfTableBorder,
            columnWidths: const {1: pw.FlexColumnWidth(3)},
            children: [
              pdfHeadRow(ar
                  ? ['البند', 'الوصف', 'المبلغ ($jd)']
                  : ['Category', 'Description', 'Amount ($jd)']),
              for (final (c, label, amount) in d.expenses)
                pw.TableRow(children: [
                  pdfCell(exp(c)),
                  pdfCell(label ?? '—',
                      align: ar ? pw.TextAlign.right : pw.TextAlign.left),
                  pdfCell(formatDinars(amount), ltr: true, bold: true),
                ]),
            ],
          ),
        ],
        pdfSectionTitle(ar ? 'الكاش' : 'Cash'),
        pdfInfoBox(pw.Wrap(spacing: 24, runSpacing: 6, children: [
          pdfKv(ar ? 'كاش بداية اليوم' : 'Opening cash',
              '${formatDinars(openingCashFils)} $jd'),
          pdfKv(ar ? 'المتوقع آخر اليوم' : 'Expected at close',
              '${formatDinars(expectedCashFils)} $jd'),
          pdfKv(ar ? 'المعدود فعلاً' : 'Counted',
              '${formatDinars(countedCashFils)} $jd'),
          if (diff != 0)
            pdfKv(
                diff < 0
                    ? (ar ? 'عجز' : 'Shortage')
                    : (ar ? 'زيادة' : 'Surplus'),
                '${formatDinars(diff.abs())} $jd'),
          if (inv.chequesInFils != 0)
            pdfKv(ar ? 'شيكات بالصندوق' : 'Cheques in hand',
                '${formatDinars(inv.chequesInFils)} $jd'),
        ])),
        pdfSectionTitle(ar
            ? 'البضاعة في الشنطة · ${inv.goodsPieces} قطعة · ${formatGrams(inv.goodsNetMg)} $g'
            : 'Goods in bag · ${inv.goodsPieces} pcs · ${formatGrams(inv.goodsNetMg)} $g'),
        if (inv.goods.isEmpty) pw.Text('—') else stockTable(inv.goods, false),
        if (inv.scrap.isNotEmpty) ...[
          pdfSectionTitle(ar
              ? 'الكسر في الشنطة · ${formatGrams(inv.scrapNetMg)} $g'
              : 'Scrap in bag · ${formatGrams(inv.scrapNetMg)} $g'),
          stockTable(inv.scrap, true),
        ],
        pw.SizedBox(height: 30),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Column(children: [
              pw.Container(width: 160, height: 0.8, color: PdfPalette.muted),
              pw.SizedBox(height: 4),
              pw.Text(ar ? 'توقيع حامل الشنطة' : 'Bag holder signature',
                  style:
                      const pw.TextStyle(fontSize: 9, color: PdfPalette.muted)),
            ]),
          ],
        ),
      ],
    ),
  );
  return doc.save();
}
