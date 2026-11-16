import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/units.dart';
import '../../domain/models.dart';
import '../common/inputs.dart';

/// إضافة موظف أو تعديل بياناته.
///
/// تمرير [employee] يحوّلها إلى وضع التعديل — نفس الحقول ونفس التحقق،
/// فلا داعي لنافذتين متطابقتين.
class NewEmployeeDialog extends ConsumerStatefulWidget {
  const NewEmployeeDialog({super.key, this.employee});

  final Account? employee;

  @override
  ConsumerState<NewEmployeeDialog> createState() => _NewEmployeeDialogState();
}

class _NewEmployeeDialogState extends ConsumerState<NewEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _salary;
  late final TextEditingController _note;

  /// بداية الراتب: منها تبدأ الدورة ويُرحَّل الباقي. فارغ = الشهر الميلادي.
  DateTime? _start;
  bool _busy = false;

  bool get _isEdit => widget.employee != null;

  @override
  void initState() {
    super.initState();
    final e = widget.employee;
    _name = TextEditingController(text: e?.name ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _salary = TextEditingController(
      text: e == null || e.monthlySalaryFils == 0
          ? ''
          : formatDinars(e.monthlySalaryFils),
    );
    _note = TextEditingController(text: e?.note ?? '');
    _start = e?.salaryStartDate;
  }

  Future<void> _pickStart() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _start = d);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _salary.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);

    try {
      final repo = ref.read(repositoryProvider);
      final name = _name.text.trim();
      final phone = _phone.text.trim();
      final note = _note.text.trim();
      final salary = parseDinars(_salary.text) ?? 0;

      if (_isEdit) {
        await repo.updateEmployee(
          widget.employee!.id,
          name: name,
          phone: phone,
          note: note,
          monthlySalaryFils: salary,
          salaryStartDate: _start,
          clearSalaryStart: _start == null,
        );
      } else {
        await repo.createEmployee(
          name,
          phone: phone.isEmpty ? null : phone,
          note: note.isEmpty ? null : note,
          monthlySalaryFils: salary,
          salaryStartDate: _start,
        );
      }

      if (!mounted) return;
      ref.invalidate(accountsProvider);
      ref.invalidate(employeesProvider);
      navigator.pop(true);
      messenger.showSnackBar(
        SnackBar(
          content:
              Text(_isEdit ? 'تم حفظ بيانات $name' : 'تمت إضافة الموظف $name'),
          backgroundColor: AppColors.goldDark,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(readableError(e)),
          backgroundColor: AppColors.error,
        ),
      );
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
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.goldContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isEdit ? Icons.edit_rounded : Icons.badge_outlined,
                          color: AppColors.goldDark,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEdit
                                  ? 'تعديل بيانات الموظف'
                                  : 'إضافة موظف جديد',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'راتب شهري ثابت، والسحوبات والمصاريف باسمه تُخصم منه',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _name,
                    autofocus: !_isEdit,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'اسم الموظف',
                      hintText: 'مثال: عبد',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'يرجى إدخال اسم الموظف'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DinarsField(
                    controller: _salary,
                    label: 'الراتب الشهري',
                    allowZero: true,
                    required: false,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _pickStart,
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'تاريخ بداية الراتب (اختياري)',
                        prefixIcon: const Icon(Icons.event_outlined),
                        suffixIcon: _start == null
                            ? null
                            : IconButton(
                                tooltip: 'بلا تاريخ',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () => setState(() => _start = null),
                              ),
                      ),
                      child: Text(
                        _start == null
                            ? 'الشهر من أوله لآخره'
                            : '${shortDate(_start!)} — الدورة من يوم ${_start!.day} لمثله، والباقي يُرحَّل',
                        style: TextStyle(
                            color: _start == null
                                ? AppColors.textMuted
                                : AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: phoneInputFormatters,
                    textDirection: TextDirection.ltr,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'رقم الهاتف (اختياري)',
                      hintText: 'مثال: 0791234567',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _note,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _busy ? null : _submit(),
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات (اختياري)',
                      hintText: 'مثال: صائغ — دوام كامل',
                      prefixIcon: Icon(Icons.note_alt_outlined),
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
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.goldPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
                          _isEdit ? 'حفظ التعديل' : 'إضافة الموظف',
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
