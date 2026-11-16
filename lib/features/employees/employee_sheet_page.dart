import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/units.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../domain/payroll.dart';
import '../bagday/expense_page.dart';
import '../common/inputs.dart';
import '../common/ui.dart';

/// كشف راتب الموظف — نظير ورقة "عبد" في الدفتر.
///
/// دورة واحدة على الشاشة في كل مرة: المرحَّل من قبلها، وراتبها، وما سحبه
/// أو صُرف باسمه فيها، والباقي له. الدورة الشهر الميلادي، أو من يوم بداية
/// راتبه إلى مثله في الشهر التالي إن حُدّد.
class EmployeeSheetPage extends ConsumerStatefulWidget {
  const EmployeeSheetPage({super.key, required this.employee});

  final Account employee;

  @override
  ConsumerState<EmployeeSheetPage> createState() => _EmployeeSheetPageState();
}

class _EmployeeSheetPageState extends ConsumerState<EmployeeSheetPage> {
  late SalaryPeriod _period = salaryPeriodOf(DateTime.now(),
      startDate: widget.employee.salaryStartDate);

  DateTime? get _start => widget.employee.salaryStartDate;

  ({String id, DateTime? start}) get _key =>
      (id: widget.employee.id, start: _start);

  void _shift(int delta) => setState(
      () => _period = shiftSalaryPeriod(_period, delta, startDate: _start));

  bool get _isCurrent => _period.contains(DateTime.now());

  Future<void> _record({int? salaryPay}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _WithdrawalDialog(
        employee: widget.employee,
        period: _period,
        salaryPay: salaryPay,
      ),
    );
    if (saved == true && mounted) ref.invalidate(employeeLinesProvider(_key));
  }

  Future<void> _expense() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => ExpensePage(employee: widget.employee)),
    );
    if (saved == true && mounted) ref.invalidate(employeeLinesProvider(_key));
  }

  @override
  Widget build(BuildContext context) {
    final lines = ref.watch(employeeLinesProvider(_key));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.employee.name),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(employeeLinesProvider(_key)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: lines.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.goldPrimary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('خطأ: ${readableError(e)}'),
          ),
        ),
        data: (all) {
          final sheet = PayrollSheet.of(
            all,
            period: _period,
            monthlySalaryFils: widget.employee.monthlySalaryFils,
            startDate: _start,
          );
          final rows = sheet.lines;

          return RefreshIndicator(
            color: AppColors.goldPrimary,
            backgroundColor: Colors.white,
            onRefresh: () async => ref.invalidate(employeeLinesProvider(_key)),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                _PeriodBar(
                  period: _period,
                  calendar: _start == null,
                  onPrevious: () => _shift(-1),
                  // لا دورة بعد الحالية: راتب لم يبدأ يوحي بأنه صُرف مسبقاً
                  onNext: _isCurrent ? null : () => _shift(1),
                ),
                const SizedBox(height: 16),
                if (!sheet.started)
                  const _Notice(
                      'هذه الفترة قبل تاريخ بداية الراتب — لا راتب فيها.')
                else
                  _SalaryCard(sheet: sheet, carries: _start != null),
                if (_start == null) ...[
                  const SizedBox(height: 10),
                  const _Notice(
                      'لترحيل الباقي من شهر لشهر، حدّد تاريخ بداية الراتب من تعديل بيانات الموظف.'),
                ],
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  FilledButton.icon(
                    onPressed: () => _record(),
                    icon: const Icon(Icons.north_east_rounded, size: 18),
                    label: const Text('سحبة'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _expense,
                    icon: const Icon(Icons.receipt_long_outlined, size: 18),
                    label: const Text('مصروف باسمه'),
                  ),
                  // دورة سابقة: باقيها مرحَّل للحالية، فلا يُصرف بتاريخ قديم
                  if (_isCurrent && sheet.started && sheet.remainingFils > 0)
                    OutlinedButton.icon(
                      onPressed: () => _record(salaryPay: sheet.remainingFils),
                      icon: const Icon(Icons.payments_outlined, size: 18),
                      label: Text(
                          'صرف الباقي ${formatDinars(sheet.remainingFils)}'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.goldDark),
                    ),
                ]),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'الخصومات',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.goldContainer,
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: AppColors.goldBorder, width: 0.8),
                      ),
                      child: Text(
                        '${rows.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 36),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 36, color: AppColors.textMuted),
                        SizedBox(height: 10),
                        Text(
                          'لا سحوبات ولا مصاريف في هذه الفترة',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final l in rows) _WithdrawalTile(line: l),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// "4 أيلول 2026"
String _date(DateTime d) => '${dayAndMonth(d)} ${d.year}';

/// شريط التنقل بين دورات الراتب.
class _PeriodBar extends StatelessWidget {
  const _PeriodBar({
    required this.period,
    required this.calendar,
    required this.onPrevious,
    required this.onNext,
  });

  final SalaryPeriod period;

  /// دورة الشهر الميلادي: يُعرض اسم الشهر عنواناً.
  final bool calendar;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final last = period.end.subtract(const Duration(days: 1));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          IconButton(
            tooltip: 'الفترة السابقة',
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: onPrevious,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  calendar
                      ? monthLabel(period.start)
                      : '${_date(period.start)} — ${_date(last)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'من ${shortDate(period.start)}  إلى  ${shortDate(last)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'الفترة التالية',
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
        ]),
      );
}

/// بطاقة الراتب: المرحَّل، الراتب، المخصوم، والباقي.
class _SalaryCard extends StatelessWidget {
  const _SalaryCard({required this.sheet, required this.carries});

  final PayrollSheet sheet;
  final bool carries;

  @override
  Widget build(BuildContext context) {
    final salary = sheet.salaryFils;
    final remaining = sheet.remainingFils;
    final overdrawn = remaining < 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBF8F1), Color(0xFFFAF3E3)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.goldBorder, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (carries) ...[
                Expanded(
                  child: _Stat(
                    label: sheet.carriedFils < 0 ? 'مرحَّل عليه' : 'مرحَّل له',
                    value: formatDinars(sheet.carriedFils.abs()),
                  ),
                ),
                Container(width: 1, height: 40, color: AppColors.goldBorder),
              ],
              Expanded(
                child: _Stat(
                  label: 'الراتب',
                  value: salary == 0 ? 'غير محدَّد' : formatDinars(salary),
                  muted: salary == 0,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.goldBorder),
              Expanded(
                child: _Stat(
                  label: 'المخصوم',
                  value: formatDinars(sheet.deductedFils),
                ),
              ),
            ],
          ),
          if (salary > 0 || sheet.carriedFils != 0) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.goldBorder),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  overdrawn ? 'مسحوب زيادة' : 'الباقي له',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${formatDinars(remaining.abs())} د.أ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: overdrawn ? AppColors.error : AppColors.goldDark,
                  ),
                ),
              ],
            ),
            if (carries) ...[
              const SizedBox(height: 4),
              const Text(
                'ما لا يُصرف يُرحَّل للفترة التالية.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.muted = false});

  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          muted ? value : '$value د.أ',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: muted ? AppColors.textMuted : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _WithdrawalTile extends StatelessWidget {
  const _WithdrawalTile({required this.line});

  final StatementLine line;

  @override
  Widget build(BuildContext context) {
    // مبلغ سالب = مبلغ رُدّ إلينا لا سحبة.
    final isRefund = line.amount < 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1.1),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isRefund
                    ? AppColors.successContainer
                    : AppColors.goldContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isRefund ? Icons.south_west_rounded : Icons.north_east_rounded,
                size: 18,
                color: isRefund ? AppColors.success : AppColors.goldDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.note == null || line.note!.isEmpty
                        ? 'سحبة'
                        : line.note!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${dayAndMonth(line.occurredAt)}  ·  رقم ${line.docNumber}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${formatDinars(line.amount.abs())} د.أ',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isRefund ? AppColors.success : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// تسجيل سحبة أو صرف باقي الراتب: مبلغ وتاريخ وملاحظة.
class _WithdrawalDialog extends ConsumerStatefulWidget {
  const _WithdrawalDialog({
    required this.employee,
    required this.period,
    this.salaryPay,
  });

  final Account employee;
  final SalaryPeriod period;

  /// صرف باقي الراتب: المبلغ المقترح. فارغ = سحبة عادية.
  final int? salaryPay;

  @override
  ConsumerState<_WithdrawalDialog> createState() => _WithdrawalDialogState();
}

class _WithdrawalDialogState extends ConsumerState<_WithdrawalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
      text: widget.salaryPay == null ? '' : formatDinars(widget.salaryPay!));
  final _note = TextEditingController();
  late DateTime _date;
  bool _busy = false;

  bool get _isPay => widget.salaryPay != null;

  @override
  void initState() {
    super.initState();
    // تُسجَّل داخل الفترة المعروضة، لا في تاريخ اليوم — وإلا اختفت من
    // الشاشة التي سجّلها المستخدم فيها.
    final now = DateTime.now();
    _date = widget.period.contains(now) ? now : widget.period.start;
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!ensureOnline(context, ref)) return;

    final sys = ref.read(systemAccountsProvider).valueOrNull ?? {};
    final cashbox = sys[SystemAccount.cashbox];
    if (cashbox == null) {
      showResult(context, 'حساب الصندوق غير مهيّأ', error: true);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);

    try {
      final doc = await ref.read(repositoryProvider).employeeDraw(
            employeeId: widget.employee.id,
            cashboxId: cashbox,
            amountFils: parseDinars(_amount.text)!,
            salaryPay: _isPay,
            occurredAt: _date,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );

      if (!mounted) return;
      invalidateAfterPosting(ref);
      navigator.pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(_isPay
              ? 'تم صرف الراتب — رقم $doc'
              : 'تم تسجيل السحبة — رقم $doc'),
          backgroundColor: AppColors.goldDark,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showResult(context, readableError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${_isPay ? 'صرف الراتب' : 'سحبة'} — ${widget.employee.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isPay
                        ? 'يخرج من كاش الشنطة ويُغلق به ما بقي له. ما لا يُصرف يبقى مرحَّلاً.'
                        : 'المبلغ يخرج من كاش الشنطة ويُخصم من راتبه.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  DinarsField(
                    controller: _amount,
                    label: _isPay ? 'المبلغ المصروف' : 'المبلغ المسحوب',
                    autofocus: !_isPay,
                  ),
                  const SizedBox(height: 16),
                  DateField(
                    value: _date,
                    onChanged: (d) => setState(() => _date = d),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _note,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _busy ? null : _submit(),
                    decoration: const InputDecoration(
                      labelText: 'تفاصيل (اختياري)',
                      prefixIcon: Icon(Icons.notes_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _busy ? null : () => Navigator.pop(context),
                        child: const Text('إلغاء'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _busy ? null : _submit,
                        icon: _busy
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          _isPay ? 'صرف' : 'تسجيل السحبة',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
