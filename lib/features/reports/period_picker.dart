import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/locale.dart';
import '../../platform/labels.dart';
import '../common/ui.dart';

enum PeriodPreset {
  today,
  thisWeek,
  thisMonth,
  lastMonth,
  last3Months,
  thisYear,
  custom
}

/// فترة تقرير: من بداية يوم إلى نهاية يوم.
class Period {
  const Period(this.from, this.to, this.preset);

  final DateTime from;
  final DateTime to;
  final PeriodPreset preset;

  bool get valid => !from.isAfter(to);

  /// نهاية الفترة الحصرية: بداية اليوم التالي لـ [to].
  DateTime get endExclusive =>
      DateTime(to.year, to.month, to.day).add(const Duration(days: 1));

  static Period of(PeriodPreset p) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (p) {
      PeriodPreset.today => Period(today, today, p),
      // الأسبوع يبدأ السبت كما في السوق
      PeriodPreset.thisWeek => Period(
          today.subtract(Duration(days: (today.weekday + 1) % 7)), today, p),
      PeriodPreset.thisMonth => Period(DateTime(now.year, now.month), today, p),
      PeriodPreset.lastMonth => Period(DateTime(now.year, now.month - 1),
          DateTime(now.year, now.month, 0), p),
      PeriodPreset.last3Months =>
        Period(DateTime(now.year, now.month - 2), today, p),
      PeriodPreset.thisYear => Period(DateTime(now.year), today, p),
      PeriodPreset.custom => Period(today, today, p),
    };
  }
}

/// اختيار الفترة: أزرار جاهزة + من/إلى.
class PeriodPicker extends StatelessWidget {
  const PeriodPicker({super.key, required this.value, required this.onChanged});

  final Period value;
  final ValueChanged<Period> onChanged;

  Future<void> _pick(BuildContext context, bool isFrom) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isFrom ? value.from : value.to,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (d == null) return;
    onChanged(isFrom
        ? Period(d, value.to, PeriodPreset.custom)
        : Period(value.from, d, PeriodPreset.custom));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final presets = {
      PeriodPreset.today: l.today,
      PeriodPreset.thisWeek: l.thisWeek,
      PeriodPreset.thisMonth: l.thisMonth,
      PeriodPreset.lastMonth: l.lastMonth,
      PeriodPreset.last3Months: l.last3Months,
      PeriodPreset.thisYear: l.thisYear,
    };

    Widget dateBox(String label, DateTime d, bool isFrom) => AdaptiveBox(
          width: 200,
          half: true,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _pick(context, isFrom),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: const Icon(Icons.calendar_today_rounded),
              ),
              child: Text(formatDate(d),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final e in presets.entries)
            ChoiceChip(
              label: Text(e.value),
              selected: value.preset == e.key,
              onSelected: (_) => onChanged(Period.of(e.key)),
            ),
        ]),
        const SizedBox(height: 14),
        Wrap(spacing: 12, runSpacing: 12, children: [
          dateBox(l.fromDate, value.from, true),
          dateBox(l.toDate, value.to, false),
        ]),
        if (!value.valid)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l.invalidRange,
                style: const TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}
