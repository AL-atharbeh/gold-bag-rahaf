import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/units.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../common/inputs.dart';

/// تسجيل دفعة من زبون دون مغادرة قائمة الذمم.
///
/// هذه أكثر حركة تتكرر في اليوم، فلا تستحق شاشة كاملة ولا اختيار طرف:
/// الزبون معروف سلفاً، ويبقى المبلغ والتاريخ فقط.
class CustomerPaymentDialog extends ConsumerStatefulWidget {
  const CustomerPaymentDialog({
    super.key,
    required this.customer,
    required this.dueFils,
  });

  final Account customer;

  /// الدين القائم لحظة فتح النافذة — لزر "سداد كامل" ولتقدير المتبقي.
  final MoneyFils dueFils;

  @override
  ConsumerState<CustomerPaymentDialog> createState() =>
      _CustomerPaymentDialogState();
}

class _CustomerPaymentDialogState extends ConsumerState<CustomerPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  bool _busy = false;

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
      final doc = await ref.read(repositoryProvider).receiveCash(
            counterpartyId: widget.customer.id,
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
          content: Text('تم قبض الدفعة — رقم $doc'),
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
    final entered = parseDinars(_amount.text) ?? 0;
    final after = widget.dueFils - entered;

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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.goldContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.payments_rounded,
                            color: AppColors.goldDark, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'دفعة من ${widget.customer.name}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'الدين الحالي ${formatDinars(widget.dueFils)} د.أ',
                              style: const TextStyle(
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
                  DinarsField(
                    controller: _amount,
                    label: 'المبلغ المقبوض',
                    autofocus: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (widget.dueFils > 0) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() {
                          _amount.text = formatDinars(widget.dueFils);
                        }),
                        icon: const Icon(Icons.done_all_rounded, size: 16),
                        label:
                            Text('سداد كامل — ${formatDinars(widget.dueFils)}'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.goldDark,
                          side: const BorderSide(color: AppColors.goldBorder),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                        ),
                      ),
                    ),
                  ],
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
                      prefixIcon: Icon(Icons.notes_rounded, size: 20),
                    ),
                  ),
                  if (entered > 0) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: after <= 0
                            ? AppColors.successContainer
                            : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            after <= 0 ? 'يصبح مسدَّداً' : 'المتبقي بعد الدفعة',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            after <= 0
                                ? (after == 0
                                    ? '0.000 د.أ'
                                    : 'له ${formatDinars(after.abs())} د.أ')
                                : '${formatDinars(after)} د.أ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: after <= 0
                                  ? AppColors.success
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 26),
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
                          'تسجيل الدفعة',
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
