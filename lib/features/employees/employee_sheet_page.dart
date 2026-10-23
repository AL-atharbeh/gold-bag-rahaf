import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/units.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../common/inputs.dart';

/// كشف الموظف الشهري — نظير ورقة "عبد" في الدفتر.
///
/// شهر واحد على الشاشة في كل مرة: راتبه، وما سحبه فيه، والمتبقي له.
/// التنقل بين الشهور بسهمين، تماماً كتقليب صفحات الدفتر.
class EmployeeSheetPage extends ConsumerStatefulWidget {
  const EmployeeSheetPage({super.key, required this.employee});

  final Account employee;

  @override
  ConsumerState<EmployeeSheetPage> createState() => _EmployeeSheetPageState();
}

class _EmployeeSheetPageState extends ConsumerState<EmployeeSheetPage> {
  DateTime _month = monthStart(DateTime.now());

  void _shift(int delta) => setState(() => _month = shiftMonth(_month, delta));

  bool get _isCurrentMonth => inSameMonth(DateTime.now(), _month);

  Future<void> _addWithdrawal() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _WithdrawalDialog(
        employee: widget.employee,
        month: _month,
      ),
    );
    if (saved == true && mounted) {
      ref.invalidate(statementProvider(widget.employee.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final statement = ref.watch(statementProvider(widget.employee.id));
    final salary = widget.employee.monthlySalaryFils;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.employee.name),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.invalidate(statementProvider(widget.employee.id)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-withdrawal',
        onPressed: _addWithdrawal,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'تسجيل سحبة',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: statement.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.goldPrimary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('خطأ: $e'),
          ),
        ),
        data: (lines) {
          // سحوبات الشهر المعروض فقط — نقد، غير ملغاة، مرتّبة زمنياً.
          final rows = lines
              .where((l) =>
                  l.ledger == LedgerKind.cash &&
                  !l.isReversed &&
                  inSameMonth(l.occurredAt, _month))
              .toList()
            ..sort((a, b) => a.occurredAt.compareTo(b.occurredAt));

          final withdrawn = rows.fold<int>(0, (a, l) => a + l.amount);
          final remaining = salary - withdrawn;

          return RefreshIndicator(
            color: AppColors.goldPrimary,
            backgroundColor: Colors.white,
            onRefresh: () async =>
                ref.invalidate(statementProvider(widget.employee.id)),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                _MonthBar(
                  month: _month,
                  onPrevious: () => _shift(-1),
                  // لا نسمح بتجاوز الشهر الحالي: دفتر لشهر لم يبدأ بعد
                  // يعطي انطباعاً بأن الراتب صُرف مسبقاً.
                  onNext: _isCurrentMonth ? null : () => _shift(1),
                ),
                const SizedBox(height: 16),
                _SalaryCard(
                  salary: salary,
                  withdrawn: withdrawn,
                  remaining: remaining,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      'السحوبات',
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
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined,
                            size: 36, color: AppColors.textMuted),
                        const SizedBox(height: 10),
                        Text(
                          'لا توجد سحوبات في ${monthLabel(_month)}',
                          style: const TextStyle(
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

/// شريط التنقل بين الشهور.
class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
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
            tooltip: 'الشهر السابق',
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: onPrevious,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  monthLabel(month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'من ${shortDate(monthStart(month))}'
                  '  إلى  '
                  '${shortDate(monthEnd(month).subtract(const Duration(days: 1)))}',
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
            tooltip: 'الشهر التالي',
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

/// بطاقة الراتب: المستحق، المسحوب، والمتبقي.
class _SalaryCard extends StatelessWidget {
  const _SalaryCard({
    required this.salary,
    required this.withdrawn,
    required this.remaining,
  });

  final MoneyFils salary;
  final MoneyFils withdrawn;
  final MoneyFils remaining;

  @override
  Widget build(BuildContext context) {
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
              Expanded(
                child: _Stat(
                  label: 'الراتب الشهري',
                  value: salary == 0 ? 'غير محدَّد' : formatDinars(salary),
                  muted: salary == 0,
                ),
              ),
              Container(width: 1, height: 40, color: AppColors.goldBorder),
              Expanded(
                child: _Stat(
                  label: 'المسحوب',
                  value: formatDinars(withdrawn),
                ),
              ),
            ],
          ),
          if (salary > 0) ...[
            const SizedBox(height: 16),
            Container(height: 1, color: AppColors.goldBorder),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  overdrawn ? 'مسحوب زيادة' : 'المتبقي له',
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
                    dayAndMonth(line.occurredAt),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      'رقم ${line.docNumber}',
                      if (line.note != null && line.note!.isNotEmpty)
                        line.note!,
                    ].join('  ·  '),
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

/// تسجيل سحبة: مبلغ وتاريخ وملاحظة — لا أكثر.
class _WithdrawalDialog extends ConsumerStatefulWidget {
  const _WithdrawalDialog({required this.employee, required this.month});

  final Account employee;
  final DateTime month;

  @override
  ConsumerState<_WithdrawalDialog> createState() => _WithdrawalDialogState();
}

class _WithdrawalDialogState extends ConsumerState<_WithdrawalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  late DateTime _date;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // السحبة تُسجَّل داخل الشهر المعروض، لا في تاريخ اليوم — وإلا
    // اختفت من الشاشة التي سجّلها المستخدم فيها.
    final now = DateTime.now();
    _date = inSameMonth(now, widget.month) ? now : monthStart(widget.month);
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

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
      final doc = await ref.read(repositoryProvider).payCash(
            counterpartyId: widget.employee.id,
            cashboxId: cashbox,
            amountFils: parseDinars(_amount.text)!,
            occurredAt: _date,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );

      if (!mounted) return;
      invalidateAfterPosting(ref);
      navigator.pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text('تم تسجيل السحبة — رقم $doc'),
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
                    'سحبة — ${widget.employee.name}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'المبلغ يخرج من الصندوق ويُخصم من راتب الشهر.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  DinarsField(
                    controller: _amount,
                    label: 'المبلغ المسحوب',
                    autofocus: true,
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
                      labelText: 'ملاحظات (اختياري)',
                      hintText: 'مثال: من الشهر السابق',
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
                        label: const Text(
                          'تسجيل السحبة',
                          style: TextStyle(fontWeight: FontWeight.w700),
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
