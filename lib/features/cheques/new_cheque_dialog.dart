import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/units.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../common/inputs.dart';
import '../common/pickers.dart';

class NewChequeDialog extends ConsumerStatefulWidget {
  const NewChequeDialog({super.key});

  @override
  ConsumerState<NewChequeDialog> createState() => _NewChequeDialogState();
}

class _NewChequeDialogState extends ConsumerState<NewChequeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _number = TextEditingController();
  final _bank = TextEditingController();
  final _note = TextEditingController();

  String? _accountId;
  ChequeDirection _direction = ChequeDirection.incoming;
  DateTime _due = DateTime.now().add(const Duration(days: 30));
  bool _busy = false;

  @override
  void dispose() {
    _amount.dispose();
    _number.dispose();
    _bank.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);

    try {
      await ref.read(repositoryProvider).addCheque(
            accountId: _accountId!,
            direction: _direction,
            amountFils: parseDinars(_amount.text)!,
            dueDate: _due,
            chequeNumber:
                _number.text.trim().isEmpty ? null : _number.text.trim(),
            bankName: _bank.text.trim().isEmpty ? null : _bank.text.trim(),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (!mounted) return;
      ref.invalidate(pendingChequesProvider);
      ref.invalidate(allChequesProvider);
      navigator.pop(true);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('تم تسجيل الشيك بنجاح'),
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
    final counterparties = ref.watch(counterpartiesProvider).valueOrNull ?? [];
    final customers = ref.watch(customersProvider).valueOrNull ?? [];
    final all = <Account>[...counterparties, ...customers];

    return AlertDialog(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.goldContainer,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.goldBorder),
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: AppColors.goldDark, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('تسجيل شيك جديد'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<ChequeDirection>(
                  segments: const [
                    ButtonSegment(
                      value: ChequeDirection.incoming,
                      label: Text('شيك وارد إلينا'),
                      icon: Icon(Icons.call_received_rounded, size: 16),
                    ),
                    ButtonSegment(
                      value: ChequeDirection.outgoing,
                      label: Text('شيك صادر منّا'),
                      icon: Icon(Icons.call_made_rounded, size: 16),
                    ),
                  ],
                  selected: {_direction},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) =>
                      setState(() => _direction = s.first),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'الشيك لا يُنقص الدين الآن — يبقى معلقاً حتى تسجيل تحصيله في الصندوق.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                AccountPicker(
                  accounts: all,
                  value: _accountId,
                  onChanged: (v) => setState(() => _accountId = v),
                  label: _direction == ChequeDirection.incoming
                      ? 'الساحب (الطرف)'
                      : 'المستفيد (الطرف)',
                ),
                const SizedBox(height: 16),
                DinarsField(controller: _amount, label: 'قيمة الشيك'),
                const SizedBox(height: 16),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _due,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.goldPrimary,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: AppColors.textPrimary,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) setState(() => _due = picked);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'تاريخ الاستحقاق',
                      prefixIcon: Icon(Icons.event_rounded, size: 20),
                    ),
                    child: Text(
                      '${_due.year}/${_due.month.toString().padLeft(2, '0')}/${_due.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _number,
                        textAlign: TextAlign.left,
                        decoration: const InputDecoration(
                          labelText: 'رقم الشيك',
                          prefixIcon: Icon(Icons.tag_rounded, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _bank,
                        decoration: const InputDecoration(
                          labelText: 'اسم البنك',
                          prefixIcon:
                              Icon(Icons.account_balance_rounded, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _note,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات (اختياري)',
                    prefixIcon: Icon(Icons.notes_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('تسجيل الشيك'),
        ),
      ],
    );
  }
}
