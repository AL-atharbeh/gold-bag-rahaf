import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../core/phone.dart';
import '../../domain/enums.dart';
import '../../platform/labels.dart';
import '../../platform/session.dart';

/// أدوات مشتركة لكل ملفات PDF في النظام: الخطوط، الألوان، الترويسة،
/// التذييل، وشاشة المعاينة. اللغة الافتراضية للملفات العربية.

/// الموزّع الذي يُصدر الملف — يظهر في ترويسة كل ملف.
class PdfIssuer {
  const PdfIssuer({required this.name, this.phone, this.city});
  final String name;
  final String? phone;
  final String? city;

  /// من بيانات المنشأة في الإعدادات، وإلا اسم المنشأة ورقم المستخدم.
  static PdfIssuer of(WidgetRef ref) {
    final org = ref.read(orgProfileProvider).valueOrNull;
    final phone = org?.phone;
    return PdfIssuer(
      name: (org?.name.isNotEmpty ?? false)
          ? org!.name
          : ref.read(activeMembershipProvider)?.orgName ?? '',
      phone: (phone != null && phone.isNotEmpty)
          ? phone
          : ref.read(sessionProvider).valueOrNull?.phone,
      city: org?.city,
    );
  }
}

abstract final class PdfPalette {
  static const gold = PdfColor.fromInt(0xFF9A7B3A);
  static const goldSoft = PdfColor.fromInt(0xFFF8F3E8);
  static const line = PdfColor.fromInt(0xFFE3D9C6);
  static const muted = PdfColor.fromInt(0xFF6B6459);
  static const red = PdfColor.fromInt(0xFFB3261E);
}

/// خط عربي (نسخ) مع خط لاتيني احتياطي — يُحمَّل مرة ويُخزَّن.
Future<pw.ThemeData> pdfTheme() async => pw.ThemeData.withFont(
      base: await PdfGoogleFonts.notoNaskhArabicRegular(),
      bold: await PdfGoogleFonts.notoNaskhArabicBold(),
      fontFallback: [
        await PdfGoogleFonts.notoSansRegular(),
        await PdfGoogleFonts.notoSansBold(),
      ],
    );

String pdfStamp(DateTime d) =>
    '${formatDate(d)}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// ترويسة موحّدة: اسم الموزّع وهاتفه، وعنوان الملف وتاريخ إصداره.
pw.Widget pdfHeader({
  required PdfIssuer issuer,
  required String title,
  required String issuedLabel,
  String? subtitle,
}) =>
    pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(issuer.name,
                      textDirection: pdfDirFor(issuer.name),
                      style: pw.TextStyle(
                          fontSize: 17,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfPalette.gold)),
                  if (issuer.phone != null && issuer.phone!.isNotEmpty)
                    pw.Text(displayPhone(issuer.phone),
                        textDirection: pw.TextDirection.ltr,
                        style: const pw.TextStyle(
                            fontSize: 9.5, color: PdfPalette.muted)),
                  if (issuer.city != null && issuer.city!.isNotEmpty)
                    pw.Text(issuer.city!,
                        textDirection: pdfDirFor(issuer.city!),
                        style: const pw.TextStyle(
                            fontSize: 9.5, color: PdfPalette.muted)),
                ],
              ),
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(title,
                    style: pw.TextStyle(
                        fontSize: 15, fontWeight: pw.FontWeight.bold)),
                if (subtitle != null)
                  pw.Text(subtitle,
                      style: const pw.TextStyle(
                          fontSize: 10, color: PdfPalette.muted)),
                pw.Text('$issuedLabel: ${pdfStamp(DateTime.now())}',
                    style: const pw.TextStyle(
                        fontSize: 9, color: PdfPalette.muted)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(height: 1.2, color: PdfPalette.gold),
        pw.SizedBox(height: 10),
      ],
    );

pw.Widget pdfFooter(pw.Context ctx, String left, bool arabic) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(left,
              textDirection: pdfDirFor(left),
              style: const pw.TextStyle(fontSize: 8, color: PdfPalette.muted)),
          pw.Text(
              arabic
                  ? 'صفحة ${ctx.pageNumber} من ${ctx.pagesCount}'
                  : 'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: PdfPalette.muted)),
        ],
      ),
    );

/// خلية جدول — الأرقام تُكتب من اليسار لليمين حتى في الملف العربي.
pw.Widget pdfCell(String s,
        {bool bold = false,
        PdfColor? color,
        pw.TextAlign align = pw.TextAlign.center,
        bool ltr = false,
        double size = 8.5}) =>
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        s,
        textAlign: align,
        textDirection: ltr ? pw.TextDirection.ltr : pdfDirFor(s),
        style: pw.TextStyle(
          fontSize: size,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color,
        ),
      ),
    );

pw.TableRow pdfHeadRow(List<String> titles) => pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfPalette.gold),
      children: [
        for (final h in titles) pdfCell(h, bold: true, color: PdfColors.white),
      ],
    );

const pdfTableBorder = pw.TableBorder(
  horizontalInside: pw.BorderSide(color: PdfPalette.line, width: 0.5),
  bottom: pw.BorderSide(color: PdfPalette.line, width: 0.5),
);

/// النص العربي يُكتب من اليمين دائماً — حتى داخل ملف إنجليزي، وإلا
/// ظهرت حروفه مفككة ومقلوبة.
final _arabic = RegExp('[؀-ۿ]');
pw.TextDirection? pdfDirFor(String s) =>
    _arabic.hasMatch(s) ? pw.TextDirection.rtl : null;

pw.Widget pdfKv(String k, String v) => pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text('$k: ',
            textDirection: pdfDirFor(k),
            style: const pw.TextStyle(fontSize: 9.5, color: PdfPalette.muted)),
        pw.Flexible(
          child: pw.Text(v,
              textDirection: pdfDirFor(v),
              style:
                  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ),
      ],
    );

/// صندوق معلومات بخلفية ذهبية فاتحة.
pw.Widget pdfInfoBox(pw.Widget child) => pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfPalette.goldSoft,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: child,
    );

pw.Widget pdfSectionTitle(String s) => pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12, bottom: 6),
      child: pw.Text(s,
          style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfPalette.gold)),
    );

/// «عيار 21» تبقى بالعربية، وتُعرض بالإنجليزية «21K».
String pdfKarat(String name, bool arabic) {
  if (arabic) return name;
  final d = RegExp(r'\d+').firstMatch(name)?.group(0);
  return d == null ? name : '${d}K';
}

String pdfKind(AccountKind k, bool arabic) => arabic
    ? (k == AccountKind.showroom ? 'محل ذهب' : k.label)
    : switch (k) {
        AccountKind.showroom => 'Gold shop',
        AccountKind.trader => 'Trader',
        AccountKind.factory => 'Workshop / Factory',
        AccountKind.customer => 'Customer',
        _ => k.wire,
      };

String pdfTxType(TxType t, bool arabic) => arabic
    ? t.label
    : switch (t) {
        TxType.openingBalance => 'Opening balance',
        TxType.sale => 'Sale',
        TxType.purchase => 'Purchase',
        TxType.goodsIn => 'Goods in',
        TxType.consignmentOut => 'Consignment out',
        TxType.consignmentReturn => 'Consignment return',
        TxType.consignmentSold => 'Consignment sold',
        TxType.cashPayment => 'Cash payment',
        TxType.goldPayment => 'Gold payment',
        TxType.pricing => 'Price fixing',
        TxType.transfer => 'Stock transfer',
        TxType.goodsReturn => 'Goods return',
        TxType.cashReturn => 'Cash return',
        TxType.adjustment => 'Adjustment',
        TxType.reversal => 'Reversal',
        TxType.expense => 'Expense',
        TxType.cashAdjust => 'Cash adjustment',
        TxType.chequeClear => 'Cheque cleared',
      };

/// اسم ملف آمن من اسم الحساب أو العنوان.
String pdfSafeName(String s) =>
    s.trim().replaceAll(RegExp(r'[\\/:*?"<>|\s]+'), '-');

String pdfDateTag(DateTime x) =>
    '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';

/// شاشة معاينة الملف مع اختيار اللغة (العربية افتراضياً)، والمشاركة والطباعة.
class PdfPreviewPage extends StatefulWidget {
  const PdfPreviewPage({
    super.key,
    required this.title,
    required this.build,
    required this.fileName,
  });

  final String title;
  final Future<Uint8List> Function(bool arabic, PdfPageFormat format) build;
  final String Function(bool arabic) fileName;

  static Future<void> open(
    BuildContext context, {
    required String title,
    required Future<Uint8List> Function(bool arabic, PdfPageFormat format)
        build,
    required String Function(bool arabic) fileName,
  }) =>
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PdfPreviewPage(title: title, build: build, fileName: fileName),
        ),
      );

  @override
  State<PdfPreviewPage> createState() => _PdfPreviewPageState();
}

class _PdfPreviewPageState extends State<PdfPreviewPage> {
  bool _arabic = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('عربي')),
                ButtonSegment(value: false, label: Text('EN')),
              ],
              selected: {_arabic},
              showSelectedIcon: false,
              style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              onSelectionChanged: (s) => setState(() => _arabic = s.first),
            ),
          ),
        ],
      ),
      body: PdfPreview(
        key: ValueKey(_arabic),
        build: (format) => widget.build(_arabic, format),
        pdfFileName: widget.fileName(_arabic),
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
      ),
    );
  }
}
