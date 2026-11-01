import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/enums.dart';
import '../common/inputs.dart';

/// إضافة طرف جديد.
class NewAccountDialog extends ConsumerStatefulWidget {
  const NewAccountDialog({super.key, this.kind, this.withWorkshop = false});

  /// صفحة التجار: اختيار بين تاجر ومشغل.
  final bool withWorkshop;

  /// نوع ثابت حين تُفتح من صفحة المحلات أو التجار أو المشاغل — لا اختيار.
  final AccountKind? kind;

  @override
  ConsumerState<NewAccountDialog> createState() => _NewAccountDialogState();
}

class _NewAccountDialogState extends ConsumerState<NewAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();

  late AccountKind _kind = widget.kind ?? AccountKind.showroom;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
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
      final phone = _phone.text.trim().isEmpty ? null : _phone.text.trim();
      final note = _note.text.trim().isEmpty ? null : _note.text.trim();

      if (_kind == AccountKind.showroom) {
        await repo.createShowroom(name, phone: phone, note: note);
      } else {
        await repo.createAccount(name, _kind, phone: phone, note: note);
      }

      if (!mounted) return;
      ref.invalidate(accountsProvider);
      navigator.pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text('تمت إضافة $name بنجاح'),
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
            child: const Icon(Icons.person_add_alt_1_rounded,
                color: AppColors.goldDark, size: 20),
          ),
          const SizedBox(width: 12),
          Text(switch (widget.kind) {
            AccountKind.showroom => 'إضافة محل جديد',
            AccountKind.trader => 'إضافة تاجر جديد',
            AccountKind.factory => 'إضافة مشغل جديد',
            _ => 'إضافة موزع / طرف جديد',
          }),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.withWorkshop)
                  SegmentedButton<AccountKind>(
                    segments: const [
                      ButtonSegment(
                        value: AccountKind.trader,
                        label: Text('تاجر ذهب'),
                        icon: Icon(Icons.person_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: AccountKind.factory,
                        label: Text('مشغل / مصنع'),
                        icon: Icon(Icons.precision_manufacturing_rounded,
                            size: 16),
                      ),
                    ],
                    selected: {_kind},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() => _kind = s.first),
                  )
                else if (widget.kind == null)
                  SegmentedButton<AccountKind>(
                    segments: const [
                      ButtonSegment(
                        value: AccountKind.showroom,
                        label: Text('محل عرض'),
                        icon: Icon(Icons.storefront_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: AccountKind.trader,
                        label: Text('تاجر ذهب'),
                        icon: Icon(Icons.person_rounded, size: 16),
                      ),
                      ButtonSegment(
                        value: AccountKind.factory,
                        label: Text('مشغل / مصنع'),
                        icon: Icon(Icons.precision_manufacturing_rounded,
                            size: 16),
                      ),
                    ],
                    selected: {_kind},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() => _kind = s.first),
                  ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    switch (_kind) {
                      AccountKind.showroom =>
                        'يُنشأ معه حساب عهدة تلقائياً لاستقبال وتتبع بضاعة العرض.',
                      AccountKind.factory =>
                        'مشغل / مصنع لتصنيع وصب الذهب والمصنعيات.',
                      _ => 'تاجر ذهب — حساب مديونية بالذهب والكسر والمصنعية.',
                    },
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _name,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'اسم الطرف / المحل',
                    prefixIcon: Icon(Icons.badge_outlined, size: 20),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'أدخل الاسم' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: phoneInputFormatters,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.left,
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف (اختياري)',
                    prefixIcon: Icon(Icons.phone_outlined, size: 20),
                  ),
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
              : const Text('إضافة الطرف'),
        ),
      ],
    );
  }
}
