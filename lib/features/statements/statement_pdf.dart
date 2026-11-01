import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/phone.dart';
import '../../core/units.dart';
import '../../domain/models.dart';
import '../../platform/labels.dart';
import '../pdf/pdf_kit.dart';
import '../../domain/ledger.dart';
import 'account_statement.dart';

/// نصوص الكشف بلغته — مستقلة عن لغة الواجهة.
class _T {
  const _T(this.ar);
  final bool ar;

  String get title => ar ? 'كشف حساب' : 'Account Statement';
  String get issuedAt => ar ? 'تاريخ الإصدار' : 'Issued on';
  String get period => ar ? 'الفترة' : 'Period';
  String get from => ar ? 'من' : 'From';
  String get to => ar ? 'إلى' : 'To';
  String get party => ar ? 'الحساب' : 'Account';
  String get phone => ar ? 'الهاتف' : 'Phone';
  String get type => ar ? 'النوع' : 'Type';
  String get date => ar ? 'التاريخ' : 'Date';
  String get doc => ar ? 'رقم الحركة' : 'Ref.';
  String get desc => ar ? 'البيان' : 'Description';
  String get goldShort => ar ? 'ذهب' : 'Gold';
  String get cashShort => ar ? 'نقد' : 'Cash';
  String get gold => '$goldShort ($gramsUnit)';
  String get cash => '$cashShort ($dinarUnit)';
  String get goldBal => ar ? 'رصيد الذهب' : 'Gold balance';
  String get cashBal => ar ? 'رصيد النقد' : 'Cash balance';
  String get opening => ar ? 'الرصيد السابق' : 'Opening balance';
  String get totals => ar ? 'مجموع الفترة' : 'Period total';
  String get closing => ar ? 'الرصيد الختامي' : 'Closing balance';
  String get noMoves =>
      ar ? 'لا توجد حركات في هذه الفترة' : 'No movements in this period';
  String get summary => ar ? 'ملخص' : 'Summary';
  String get debit => ar ? 'عليه' : 'Dr';
  String get credit => ar ? 'له' : 'Cr';
  String get settled => ar ? 'مسدد' : 'Settled';
  String get legend => ar
      ? '(+) يزيد ما عليه  ·  (−) يزيد ما له  ·  الذهب بالغرام الصافي عيار 24'
      : '(+) increases what the account owes  ·  (−) increases what it is owed  ·  Gold in net 24K grams';
  String get reversed => ar ? 'ملغاة' : 'Cancelled';
  String get gramsUnit => ar ? 'غ' : 'g';
  String get dinarUnit => ar ? 'د.أ' : 'JOD';
}

/// يبني ملف PDF لكشف الحساب — بلا أي ملاحظات من الحركات أو الحساب.
Future<Uint8List> buildStatementPdf({
  required AccountStatement st,
  required Account account,
  required PdfIssuer issuer,
  required bool arabic,
  PdfPageFormat format = PdfPageFormat.a4,
}) async {
  final t = _T(arabic);

  String signed(int v, String Function(int) fmt) =>
      v == 0 ? '—' : '${v > 0 ? '+' : '−'}${fmt(v.abs())}';
  String bal(int v, String Function(int) fmt) =>
      v == 0 ? t.settled : '${fmt(v.abs())} ${v > 0 ? t.debit : t.credit}';
  PdfColor balColor(int v) => v < 0 ? PdfPalette.red : PdfColors.black;

  // صف ملوّن للرصيد السابق والمجموع والرصيد الختامي
  pw.TableRow bandRow(String label, String g, String c, String gb, String cb,
          {PdfColor? gbColor, PdfColor? cbColor}) =>
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfPalette.goldSoft),
        children: [
          pdfCell(''),
          pdfCell(''),
          pdfCell(label, bold: true),
          pdfCell(g, bold: true, ltr: true),
          pdfCell(c, bold: true, ltr: true),
          pdfCell(gb, bold: true, color: gbColor),
          pdfCell(cb, bold: true, color: cbColor),
        ],
      );

  final table = pw.Table(
    border: pdfTableBorder,
    columnWidths: const {
      0: pw.FlexColumnWidth(1.25),
      1: pw.FlexColumnWidth(1.35),
      2: pw.FlexColumnWidth(2.6),
      3: pw.FlexColumnWidth(1.3),
      4: pw.FlexColumnWidth(1.4),
      5: pw.FlexColumnWidth(1.5),
      6: pw.FlexColumnWidth(1.6),
    },
    children: [
      pdfHeadRow([
        t.date,
        t.doc,
        t.desc,
        t.gold,
        t.cash,
        t.goldBal,
        t.cashBal,
      ]),
      bandRow(
        t.opening,
        '',
        '',
        bal(st.openingGold, formatGrams),
        bal(st.openingCash, formatDinars),
        gbColor: balColor(st.openingGold),
        cbColor: balColor(st.openingCash),
      ),
      for (final r in st.rows)
        pw.TableRow(children: [
          pdfCell(formatDate(r.date), ltr: true),
          pdfCell(r.docNumber, ltr: true),
          pdfCell(
            [
              pdfTxType(r.type, arabic) +
                  (r.fixClass == noteFixScrap
                      ? (arabic ? ' — كسر' : ' — scrap')
                      : r.fixClass == noteFixGold
                          ? (arabic ? ' — حلة' : ' — gold')
                          : '') +
                  (r.isReversed ? ' (${t.reversed})' : ''),
              for (final e in r.grossByKarat.entries)
                '${e.key.isEmpty ? '' : '${pdfKarat(e.key, arabic)}: '}${formatGrams(e.value)} ${t.gramsUnit}',
            ].join('\n'),
            align: arabic ? pw.TextAlign.right : pw.TextAlign.left,
          ),
          pdfCell(signed(r.gold, formatGrams), ltr: true),
          pdfCell(signed(r.cash, formatDinars), ltr: true),
          pdfCell(bal(r.goldAfter, formatGrams), color: balColor(r.goldAfter)),
          pdfCell(bal(r.cashAfter, formatDinars), color: balColor(r.cashAfter)),
        ]),
      if (st.rows.isEmpty)
        pw.TableRow(children: [
          pdfCell(''),
          pdfCell(''),
          pdfCell(t.noMoves, color: PdfPalette.muted),
          pdfCell(''),
          pdfCell(''),
          pdfCell(''),
          pdfCell(''),
        ]),
      bandRow(
        t.totals,
        signed(st.goldTotal, formatGrams),
        signed(st.cashTotal, formatDinars),
        '',
        '',
      ),
      bandRow(
        t.closing,
        '',
        '',
        bal(st.closingGold, formatGrams),
        bal(st.closingCash, formatDinars),
        gbColor: balColor(st.closingGold),
        cbColor: balColor(st.closingCash),
      ),
    ],
  );

  pw.Widget summaryBox(String title, int opening, int debit, int credit,
          int closing, String Function(int) fmt) =>
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfPalette.line),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(title,
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfPalette.gold)),
              pw.SizedBox(height: 6),
              pdfKv(t.opening, bal(opening, fmt)),
              pdfKv('${t.totals} (+)', fmt(debit)),
              pdfKv('${t.totals} (−)', fmt(credit)),
              pw.Divider(color: PdfPalette.line, height: 8),
              pdfKv(t.closing, bal(closing, fmt)),
            ],
          ),
        ),
      );

  final doc = pw.Document(
    title: '${t.title} - ${account.name}',
    author: issuer.name,
    theme: await pdfTheme(),
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      textDirection: arabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 32),
      header: (ctx) =>
          pdfHeader(issuer: issuer, title: t.title, issuedLabel: t.issuedAt),
      footer: (ctx) =>
          pdfFooter(ctx, '${issuer.name} · ${account.name}', arabic),
      build: (ctx) => [
        // معلومات الحساب والفترة — بلا ملاحظات
        pdfInfoBox(
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pdfKv(t.party, account.name),
                    pw.SizedBox(height: 3),
                    pdfKv(t.type, pdfKind(account.kind, arabic)),
                    if (account.phone != null && account.phone!.isNotEmpty) ...[
                      pw.SizedBox(height: 3),
                      pdfKv(t.phone, displayPhone(account.phone)),
                    ],
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(t.period,
                      style: pw.TextStyle(
                          fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 3),
                  pdfKv(t.from, formatDate(st.from)),
                  pw.SizedBox(height: 3),
                  pdfKv(t.to, formatDate(st.to)),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        table,
        pw.SizedBox(height: 6),
        pw.Text(t.legend,
            style: const pw.TextStyle(fontSize: 7.5, color: PdfPalette.muted)),
        pw.SizedBox(height: 14),
        pw.Text(t.summary,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        pw.Row(children: [
          summaryBox(t.gold, st.openingGold, st.goldDebit, st.goldCredit,
              st.closingGold, formatGrams),
          pw.SizedBox(width: 10),
          summaryBox(t.cash, st.openingCash, st.cashDebit, st.cashCredit,
              st.closingCash, formatDinars),
        ]),
      ],
    ),
  );
  return doc.save();
}

/// اسم ملف مناسب: كشف-اسم-الحساب-2026-10-01_2026-10-31.pdf
String statementFileName(Account a, AccountStatement st, bool arabic) =>
    '${arabic ? 'كشف' : 'statement'}-${pdfSafeName(a.name)}-'
    '${pdfDateTag(st.from)}_${pdfDateTag(st.to)}.pdf';
