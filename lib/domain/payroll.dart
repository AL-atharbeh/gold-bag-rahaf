import 'enums.dart';
import 'models.dart';

/// دورة راتب واحدة: من [start] إلى [end] (حصري).
class SalaryPeriod {
  const SalaryPeriod(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);

  @override
  bool operator ==(Object other) =>
      other is SalaryPeriod && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// يوم [day] من الشهر، أو آخر يوم فيه إن كان أقصر (31 في شباط = 28).
DateTime _anchor(int year, int month, int day) {
  final last = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day > last ? last : day);
}

/// الدورة التي يقع فيها [d]. بلا [startDate]: الشهر الميلادي من أوله.
/// مع [startDate]: من يومه في الشهر إلى مثله في الشهر التالي.
SalaryPeriod salaryPeriodOf(DateTime d, {DateTime? startDate}) {
  final day = startDate?.day ?? 1;
  var start = _anchor(d.year, d.month, day);
  if (DateTime(d.year, d.month, d.day).isBefore(start)) {
    start = _anchor(d.year, d.month - 1, day);
  }
  return SalaryPeriod(start, _anchor(start.year, start.month + 1, day));
}

/// الدورة السابقة أو التالية.
SalaryPeriod shiftSalaryPeriod(SalaryPeriod p, int delta,
    {DateTime? startDate}) {
  final day = startDate?.day ?? 1;
  return salaryPeriodOf(_anchor(p.start.year, p.start.month + delta, day),
      startDate: startDate);
}

/// عدد الدورات بين بداية دورتين.
int _cyclesBetween(SalaryPeriod from, SalaryPeriod to) =>
    (to.start.year - from.start.year) * 12 + to.start.month - from.start.month;

/// كشف راتب دورة: المرحَّل من قبلها، وراتبها، وما خُصم فيها، والباقي.
///
/// كل ما يُقيَّد على حساب الموظف نقداً (سحبة، مصروف باسمه، صرف راتب)
/// مدين عليه — يُخصم من راتبه. الملغاة وعكسها لا تُحسب.
class PayrollSheet {
  const PayrollSheet({
    required this.period,
    required this.salaryFils,
    required this.carriedFils,
    required this.lines,
    required this.started,
  });

  factory PayrollSheet.of(
    List<StatementLine> all, {
    required SalaryPeriod period,
    required int monthlySalaryFils,
    DateTime? startDate,
  }) {
    final valid = all
        .where((x) =>
            x.ledger == LedgerKind.cash &&
            !x.isReversed &&
            x.txType != TxType.reversal)
        .toList()
      ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));
    final lines = valid.where((x) => period.contains(x.occurredAt)).toList();

    // بلا تاريخ بداية: كل شهر وحده كما كان، بلا ترحيل
    if (startDate == null) {
      return PayrollSheet(
        period: period,
        salaryFils: monthlySalaryFils,
        carriedFils: 0,
        lines: lines,
        started: true,
      );
    }

    final first = salaryPeriodOf(startDate, startDate: startDate);
    final before = _cyclesBetween(first, period);
    if (before < 0) {
      // دورة قبل بداية العمل: لا راتب ولا ترحيل
      return PayrollSheet(
        period: period,
        salaryFils: 0,
        carriedFils: 0,
        lines: lines,
        started: false,
      );
    }
    final deductedBefore = valid
        .where((x) =>
            !x.occurredAt.isBefore(first.start) &&
            x.occurredAt.isBefore(period.start))
        .fold<int>(0, (a, x) => a + x.amount);
    return PayrollSheet(
      period: period,
      salaryFils: monthlySalaryFils,
      carriedFils: before * monthlySalaryFils - deductedBefore,
      lines: lines,
      started: true,
    );
  }

  final SalaryPeriod period;
  final int salaryFils;

  /// باقي الدورات السابقة: موجب = له علينا، سالب = سحب زيادة.
  final int carriedFils;

  /// ما قُيِّد في هذه الدورة، من الأقدم.
  final List<StatementLine> lines;

  /// خطأ = الدورة قبل تاريخ بداية الراتب.
  final bool started;

  int get deductedFils => lines.fold<int>(0, (a, x) => a + x.amount);

  /// المستحق له الآن: المرحَّل + راتب الدورة − ما خُصم فيها.
  int get remainingFils => carriedFils + salaryFils - deductedFils;
}
