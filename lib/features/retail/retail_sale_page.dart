import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/units.dart';
import '../../domain/enums.dart';
import '../../domain/ledger.dart';
import '../common/goods_editor.dart';
import '../common/inputs.dart';
import '../common/pickers.dart';
import '../transactions/transaction_scaffold.dart';

/// بيع تجزئة لزبون.
class RetailSalePage extends ConsumerStatefulWidget {
  const RetailSalePage({super.key});

  @override
  ConsumerState<RetailSalePage> createState() => _RetailSalePageState();
}

class _RetailSalePageState extends ConsumerState<RetailSalePage> {
  final _formKey = GlobalKey<FormState>();
  final _total = TextEditingController();
  final _paid = TextEditingController();
  final _note = TextEditingController();

  String? _customerId;
  DateTime _date = DateTime.now();
  List<GoodsLine> _lines = const [];
  bool _busy = false;

  @override
  void dispose() {
    _total.dispose();
    _paid.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _totalFils => parseDinars(_total.text) ?? 0;
  int get _paidFils => parseDinars(_paid.text) ?? 0;
  int get _remaining => _totalFils - _paidFils;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_lines.isEmpty) {
      showResult(context, 'أضف القطعة المباعة', error: true);
      return;
    }
    if (_paidFils > _totalFils) {
      showResult(context, 'الدفعة المقدمة أكبر من المبلغ الإجمالي',
          error: true);
      return;
    }

    final sys = ref.read(systemAccountsProvider).valueOrNull ?? {};
    final shanta = sys[SystemAccount.shanta];
    final trading = sys[SystemAccount.tradingIncome];
    final cashbox = sys[SystemAccount.cashbox];
    if (shanta == null || trading == null || cashbox == null) {
      showResult(context, 'حسابات النظام غير مهيّأة', error: true);
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);

    try {
      final doc = await ref.read(repositoryProvider).retailSale(
            customerId: _customerId!,
            inventoryAccountId: shanta,
            incomeAccountId: trading,
            totalFils: _totalFils,
            lines: _lines,
            paidFils: _paidFils,
            cashboxId: _paidFils > 0 ? cashbox : null,
            occurredAt: _date,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      if (!mounted) return;
      invalidateAfterPosting(ref);
      navigator.pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text('تم بيع التجزئة بنجاح — رقم $doc'),
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
    final customers = ref.watch(customersProvider);
    final karats = ref.watch(karatOptionsProvider(
        (accountId: _customerId, direction: GoldDirection.out)));

    if (customers.isLoading || karats.isLoading) {
      return const AsyncGate(
          title: 'بيع تجزئة لزبون', loading: true, error: null);
    }
    if (customers.hasError || karats.hasError) {
      return AsyncGate(
        title: 'بيع تجزئة لزبون',
        loading: false,
        error: customers.error ?? karats.error,
      );
    }

    if (customers.value!.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('بيع تجزئة لزبون')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Container(
              padding: const EdgeInsets.all(32),
              constraints: const BoxConstraints(maxWidth: 380),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.goldBorder),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_outline_rounded,
                      size: 40, color: AppColors.goldDark),
                  SizedBox(height: 16),
                  Text(
                    'لا يوجد زبائن مسجلون بعد',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'أضف زبوناً من شاشة الزبائن أولاً لتسجيل عملية البيع باسمه.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final gross = _lines.fold<int>(0, (a, l) => a + l.grossWeightMg);

    return TransactionScaffold(
      title: 'بيع تجزئة لزبون',
      formKey: _formKey,
      busy: _busy,
      onSubmit: _submit,
      submitLabel: 'حفظ عملية البيع',
      children: [
        AccountPicker(
          accounts: customers.value!,
          value: _customerId,
          onChanged: (v) => setState(() => _customerId = v),
          label: 'الزبون',
        ),
        const SizedBox(height: 16),
        DateField(value: _date, onChanged: (d) => setState(() => _date = d)),
        const SizedBox(height: 28),
        const Text(
          'القطعة المباعة',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'الوزن يُسجَّل لينقص مخزون الشنطة، والسعر يؤخذ من المبلغ الإجمالي أدناه.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        GoodsEditor(
          karats: karats.value!,
          onChanged: (l) => setState(() => _lines = l),
        ),
        const SizedBox(height: 28),
        const Text(
          'الحساب والاتفاق المالي',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        DinarsField(
          controller: _total,
          label: 'المبلغ الإجمالي المتفق عليه (د.أ)',
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 16),
        DinarsField(
          controller: _paid,
          label: 'دفعة نقدية مقدّمة (اختياري)',
          required: false,
          allowZero: true,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _note,
          decoration: const InputDecoration(
            labelText: 'ملاحظات (اختياري)',
            prefixIcon: Icon(Icons.notes_rounded, size: 20),
          ),
        ),
        if (_totalFils > 0) ...[
          const SizedBox(height: 24),
          SummaryBar(items: [
            if (gross > 0) ('الوزن القائم', '${formatGrams(gross)} غ'),
            ('إجمالي المبلغ', '${formatDinars(_totalFils)} د.أ'),
            if (_paidFils > 0)
              ('المدفوع نقداً', '${formatDinars(_paidFils)} د.أ'),
            ('المتبقي على الزبون', '${formatDinars(_remaining)} د.أ'),
          ]),
        ],
      ],
    );
  }
}
