import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/locale.dart';
import '../../core/units.dart';
import '../../l10n/app_localizations.dart';

/// رصيد الطرف بلغة التاجر: موجب = لنا عليه، سالب = له علينا.
String goldPhrase(AppLocalizations l, int mg) => mg == 0
    ? l.settledZero
    : mg > 0
        ? l.owedToUs('${formatGrams(mg)} ${l.gramsUnit}')
        : l.owedByUs('${formatGrams(-mg)} ${l.gramsUnit}');

String cashPhrase(AppLocalizations l, int fils) => fils == 0
    ? l.settledZero
    : fils > 0
        ? l.owedToUs('${formatDinars(fils)} ${l.dinarUnit}')
        : l.owedByUs('${formatDinars(-fils)} ${l.dinarUnit}');

Color balanceColor(int v) => v == 0
    ? AppColors.textSecondary
    : (v > 0 ? AppColors.goldDark : AppColors.error);

/// الرصيدان الدائمان للطرف — ذهب ونقد — جنباً إلى جنب.
class BalanceChips extends StatelessWidget {
  const BalanceChips(
      {super.key,
      required this.goldMg,
      required this.cashFils,
      this.large = false});

  final int goldMg;
  final int cashFils;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    // بطاقتان متساويتان دائماً — على الهاتف والتابلت
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
                child: _chip(l.goldBalance, goldPhrase(l, goldMg),
                    balanceColor(goldMg), Icons.balance_rounded)),
            const SizedBox(width: 10),
            Expanded(
                child: _chip(l.cashBalance, cashPhrase(l, cashFils),
                    balanceColor(cashFils), Icons.payments_outlined)),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value, Color color, IconData icon) =>
      Container(
        padding:
            EdgeInsets.symmetric(horizontal: 14, vertical: large ? 14 : 10),
        decoration: BoxDecoration(
          color: AppColors.goldContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.goldBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: large ? 22 : 18, color: AppColors.goldDark),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  // الرقم يصغر ليتسع في نصف شاشة الهاتف بدل أن يلتف
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      value,
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: large ? 20 : 15,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

/// الرصيد قبل الحركة وبعدها — ليرى التاجر أثرها قبل الحفظ.
class BalanceChange extends StatelessWidget {
  const BalanceChange({
    super.key,
    required this.title,
    required this.goldBefore,
    required this.goldAfter,
    required this.cashBefore,
    required this.cashAfter,
  });

  final String title;
  final int goldBefore;
  final int goldAfter;
  final int cashBefore;
  final int cashAfter;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    TableRow row(String label, String before, String after, Color afterColor) =>
        TableRow(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(before,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(after,
                style:
                    TextStyle(fontWeight: FontWeight.w800, color: afterColor)),
          ),
        ]);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.w800, color: AppColors.goldDark)),
          const SizedBox(height: 8),
          Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(),
              2: FlexColumnWidth()
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(children: [
                const SizedBox(),
                Text(l.balanceBefore,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
                Text(l.balanceAfter,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ]),
              row('${l.goldBalance}   ', goldPhrase(l, goldBefore),
                  goldPhrase(l, goldAfter), balanceColor(goldAfter)),
              row('${l.cashBalance}   ', cashPhrase(l, cashBefore),
                  cashPhrase(l, cashAfter), balanceColor(cashAfter)),
            ],
          ),
        ],
      ),
    );
  }
}
