import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/phone.dart';
import '../../core/units.dart';
import '../../domain/enums.dart';
import '../../domain/ledger.dart';
import '../../domain/models.dart';
import '../../platform/labels.dart';
import 'pdf_kit.dart';

/// فاتورة حركة واحدة لطرف — البضاعة والكسر والمصنوعية والنقد،
/// وأثرها على حسابه. لا تُطبع الملاحظات.
Future<Uint8List> buildInvoicePdf({
  required TxDetail tx,
  required Account party,
  required PdfIssuer issuer,
  required bool arabic,
  PdfPageFormat format = PdfPageFormat.a4,
}) async {
  final ar = arabic;
  final g = ar ? 'غ' : 'g';
  final jd = ar ? 'د.أ' : 'JOD';

  final mine = tx.lines.where((x) => x.accountId == party.id).toList();
  final gold = mine.where((x) => x.ledger == LedgerKind.gold);
  final cash = mine.where((x) => x.ledger == LedgerKind.cash);
  final goodsOut =
      gold.where((x) => x.itemName != null && x.amount > 0).toList();
  final goodsIn =
      gold.where((x) => x.itemName != null && x.amount < 0).toList();
  final scrapIn =
      gold.where((x) => x.itemName == null && x.amount < 0).toList();
  final scrapOut =
      gold.where((x) => x.itemName == null && x.amount > 0).toList();
  bool isFix(TxLine x) => x.note == noteFixGold || x.note == noteFixScrap;
  bool special(TxLine x) =>
      x.makingPerGramFils != null ||
      x.note == noteMakingDiscount ||
      x.note == noteExchangeFee ||
      isFix(x);
  final making = cash
      .where(
          (x) => x.makingPerGramFils != null && x.note != noteRecoveredMaking)
      .toList();
  final recoveredMaking =
      cash.where((x) => x.note == noteRecoveredMaking).toList();
  final discount = cash.where((x) => x.note == noteMakingDiscount).toList();
  final exchangeFee = cash.where((x) => x.note == noteExchangeFee).toList();
  final fixValue = cash.where(isFix).toList();
  final cashIn = cash.where((x) => !special(x) && x.amount < 0).toList();
  final cashOut = cash.where((x) => !special(x) && x.amount > 0).toList();
  final goldTotal = gold.fold<int>(0, (a, x) => a + x.amount);
  final cashTotal = cash.fold<int>(0, (a, x) => a + x.amount);

  String karat(TxLine x) => [
        if (x.karatName != null) pdfKarat(x.karatName!, ar),
        if (x.karatPpm != null) (x.karatPpm! / 1000000).toStringAsFixed(3),
      ].join(' · ');

  pw.Widget goodsTable(String title, List<TxLine> lines) {
    final qty = lines.fold<int>(0, (a, x) => a + (x.quantity ?? 0).abs());
    final gross =
        lines.fold<int>(0, (a, x) => a + (x.grossWeightMg ?? 0).abs());
    final net = lines.fold<int>(0, (a, x) => a + x.amount.abs());
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pdfSectionTitle(title),
        pw.Table(
          border: pdfTableBorder,
          columnWidths: const {
            0: pw.FlexColumnWidth(2.2),
            1: pw.FlexColumnWidth(1.8),
            2: pw.FlexColumnWidth(0.9),
            3: pw.FlexColumnWidth(1.4),
            4: pw.FlexColumnWidth(1.4),
          },
          children: [
            pdfHeadRow(ar
                ? [
                    'الصنف',
                    'العيار · المعامل',
                    'العدد',
                    'القائم ($g)',
                    'الصافي 24 ($g)'
                  ]
                : [
                    'Item',
                    'Karat · factor',
                    'Pcs',
                    'Gross ($g)',
                    'Net 24K ($g)'
                  ]),
            for (final x in lines)
              pw.TableRow(children: [
                pdfCell(x.itemName ?? (ar ? 'كسر' : 'Scrap')),
                pdfCell(karat(x)),
                pdfCell(x.quantity == null ? '—' : '${x.quantity!.abs()}',
                    ltr: true),
                pdfCell(formatGrams((x.grossWeightMg ?? 0).abs()), ltr: true),
                pdfCell(formatGrams(x.amount.abs()), ltr: true, bold: true),
              ]),
            if (lines.length > 1)
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfPalette.goldSoft),
                children: [
                  pdfCell(ar ? 'المجموع' : 'Total', bold: true),
                  pdfCell(''),
                  pdfCell(qty == 0 ? '—' : '$qty', ltr: true, bold: true),
                  pdfCell(formatGrams(gross), ltr: true, bold: true),
                  pdfCell(formatGrams(net), ltr: true, bold: true),
                ],
              ),
          ],
        ),
      ],
    );
  }

  pw.Widget cashTable(String title, List<TxLine> lines, {bool rate = false}) {
    final total = lines.fold<int>(0, (a, x) => a + x.amount.abs());
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pdfSectionTitle(title),
        pw.Table(
          border: pdfTableBorder,
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(1.6),
          },
          children: [
            for (final x in lines)
              pw.TableRow(children: [
                pdfCell(
                  rate
                      ? '${formatDinars(x.makingPerGramFils!)} $jd / ${x.note == noteMakingPiece ? (ar ? 'قطعة' : 'piece') : g}'
                      : (ar ? 'مبلغ' : 'Amount'),
                  align: ar ? pw.TextAlign.right : pw.TextAlign.left,
                ),
                pdfCell('${formatDinars(x.amount.abs())} $jd', ltr: true),
              ]),
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfPalette.goldSoft),
              children: [
                pdfCell(ar ? 'المجموع' : 'Total',
                    bold: true,
                    align: ar ? pw.TextAlign.right : pw.TextAlign.left),
                pdfCell('${formatDinars(total)} $jd', ltr: true, bold: true),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String effect(int v, String Function(int) fmt, String unit) => v == 0
      ? '—'
      : '${fmt(v.abs())} $unit ${v > 0 ? (ar ? 'عليه' : 'Dr') : (ar ? 'له' : 'Cr')}';

  final title = ar ? 'فاتورة' : 'Invoice';
  final doc = pw.Document(
    title: '$title ${tx.docNumber}',
    author: issuer.name,
    theme: await pdfTheme(),
  );
  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      textDirection: ar ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 32),
      header: (ctx) => pdfHeader(
        issuer: issuer,
        title: '$title — ${pdfTxType(tx.type, ar)}',
        subtitle: tx.isReversed ? (ar ? 'ملغاة' : 'Cancelled') : null,
        issuedLabel: ar ? 'تاريخ الإصدار' : 'Issued on',
      ),
      footer: (ctx) => pdfFooter(ctx, '${issuer.name} · ${party.name}', ar),
      build: (ctx) => [
        pdfInfoBox(
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pdfKv(ar ? 'الحساب' : 'Account', party.name),
                    pw.SizedBox(height: 3),
                    pdfKv(ar ? 'النوع' : 'Type', pdfKind(party.kind, ar)),
                    if (party.phone != null && party.phone!.isNotEmpty) ...[
                      pw.SizedBox(height: 3),
                      pdfKv(ar ? 'الهاتف' : 'Phone', displayPhone(party.phone)),
                    ],
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pdfKv(ar ? 'رقم الفاتورة' : 'Invoice no.', tx.docNumber),
                  pw.SizedBox(height: 3),
                  pdfKv(ar ? 'التاريخ' : 'Date', formatDate(tx.occurredAt)),
                ],
              ),
            ],
          ),
        ),
        if (goodsOut.isNotEmpty)
          goodsTable(ar ? 'البضاعة المباعة' : 'Goods sold', goodsOut),
        if (goodsIn.isNotEmpty)
          goodsTable(
              tx.type == TxType.sale
                  ? (ar ? 'المسترد من المحل' : 'Recovered goods')
                  : (ar ? 'البضاعة المستلمة' : 'Goods received'),
              goodsIn),
        if (scrapIn.isNotEmpty)
          goodsTable(ar ? 'الكسر المستلم' : 'Scrap received', scrapIn),
        if (scrapOut.isNotEmpty)
          goodsTable(ar ? 'الكسر المسلّم' : 'Scrap delivered', scrapOut),
        if (making.isNotEmpty)
          cashTable(ar ? 'المصنوعية' : 'Making charges', making, rate: true),
        if (cashIn.isNotEmpty)
          cashTable(ar ? 'نقد مقبوض' : 'Cash received', cashIn),
        if (recoveredMaking.isNotEmpty)
          cashTable(ar ? 'مصنوعية المسترد' : 'Recovered making',
              recoveredMaking,
              rate: true),
        if (discount.isNotEmpty)
          cashTable(ar ? 'خصم المصنوعية' : 'Making discount', discount),
        if (exchangeFee.isNotEmpty)
          cashTable(ar ? 'أجور البدل' : 'Exchange fee', exchangeFee),
        if (fixValue.isNotEmpty)
          cashTable(
              fixValue.first.note == noteFixScrap
                  ? (ar ? 'تسكير كسر' : 'Fix — scrap')
                  : (ar ? 'تسكير حلة' : 'Fix — gold'),
              fixValue),
        if (cashOut.isNotEmpty)
          cashTable(ar ? 'نقد مدفوع' : 'Cash paid', cashOut),
        pdfSectionTitle(ar ? 'الأثر على الحساب' : 'Effect on account'),
        pdfInfoBox(
          pw.Row(children: [
            pw.Expanded(
                child: pdfKv(
                    ar ? 'ذهب' : 'Gold', effect(goldTotal, formatGrams, g))),
            pw.Expanded(
                child: pdfKv(
                    ar ? 'نقد' : 'Cash', effect(cashTotal, formatDinars, jd))),
          ]),
        ),
        pw.SizedBox(height: 40),
        // توقيع الاستلام
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            for (final who in ar
                ? ['توقيع المستلم', 'توقيع الموزّع']
                : ['Receiver signature', 'Distributor signature'])
              pw.Column(children: [
                pw.Container(width: 150, height: 0.8, color: PdfPalette.muted),
                pw.SizedBox(height: 4),
                pw.Text(who,
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfPalette.muted)),
              ]),
          ],
        ),
      ],
    ),
  );
  return doc.save();
}

String invoiceFileName(TxDetail tx, Account party, bool arabic) =>
    '${arabic ? 'فاتورة' : 'invoice'}-${tx.docNumber}-${pdfSafeName(party.name)}.pdf';
