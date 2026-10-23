import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/locale.dart';
import '../../core/units.dart';
import '../../domain/enums.dart';
import '../../l10n/app_localizations.dart';
import '../common/inputs.dart';
import '../common/ui.dart';
import 'bag_day_state.dart';

String expenseLabel(AppLocalizations l, ExpenseCategory? c) => switch (c) {
      ExpenseCategory.fuel => l.expFuel,
      ExpenseCategory.food => l.expFood,
      ExpenseCategory.transport => l.expTransport,
      ExpenseCategory.maintenance => l.expMaintenance,
      ExpenseCategory.personal => l.expPersonal,
      ExpenseCategory.other || null => l.expOther,
    };

IconData expenseIcon(ExpenseCategory? c) => switch (c) {
      ExpenseCategory.fuel => Icons.local_gas_station_outlined,
      ExpenseCategory.food => Icons.restaurant_outlined,
      ExpenseCategory.transport => Icons.directions_car_outlined,
      ExpenseCategory.maintenance => Icons.build_outlined,
      ExpenseCategory.personal => Icons.person_outline_rounded,
      ExpenseCategory.other || null => Icons.more_horiz_rounded,
    };

/// مصروف من كاش الشنطة: بند + مبلغ + ملاحظة.
class ExpensePage extends ConsumerStatefulWidget {
  const ExpensePage({super.key});

  @override
  ConsumerState<ExpensePage> createState() => _ExpensePageState();
}

class _ExpensePageState extends ConsumerState<ExpensePage> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();
  ExpenseCategory _cat = ExpenseCategory.fuel;
  DateTime _date = DateTime.now();
  bool _saving = false;

  /// "أخرى" و"سحب شخصي" بلا وصف لا تُفهم لاحقاً.
  bool get _noteRequired =>
      _cat == ExpenseCategory.other || _cat == ExpenseCategory.personal;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!ensureOnline(context, ref)) return;
    final l = context.l10n;
    setState(() => _saving = true);
    try {
      final sys = await ref.read(systemAccountsProvider.future);
      final cashbox = sys[SystemAccount.cashbox];
      final expenses = sys[SystemAccount.expenses];
      if (cashbox == null || expenses == null) {
        throw Exception(l.needMigration14);
      }
      final doc = await ref.read(repositoryProvider).addExpense(
            cashboxId: cashbox,
            expensesId: expenses,
            amountFils: parseDinars(_amount.text)!,
            category: _cat,
            label: expenseLabel(l, _cat),
            note: _note.text,
            occurredAt: _date,
          );
      invalidateBagDay(ref);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${l.expenseSaved} — $doc'),
        backgroundColor: AppColors.goldDark,
      ));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(readableError(e)),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(l.newExpense)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SectionTitle(l.expenseCategory),
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      for (final c in ExpenseCategory.values)
                        ChoiceChip(
                          avatar: Icon(expenseIcon(c), size: 18),
                          label: Text(expenseLabel(l, c)),
                          selected: _cat == c,
                          onSelected: (_) => setState(() => _cat = c),
                        ),
                    ]),
                    const SizedBox(height: 18),
                    DinarsField(
                      controller: _amount,
                      label: l.cashAmount,
                      onChanged: (_) {},
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _note,
                      decoration: InputDecoration(
                        labelText: _noteRequired
                            ? l.expenseNoteRequired
                            : l.noteOptional,
                        prefixIcon: const Icon(Icons.notes_rounded, size: 20),
                      ),
                      validator: (v) =>
                          _noteRequired && (v == null || v.trim().isEmpty)
                              ? l.requiredField
                              : null,
                    ),
                    const SizedBox(height: 14),
                    DateField(
                        value: _date,
                        onChanged: (d) => setState(() => _date = d)),
                    const SizedBox(height: 10),
                    Text(l.expenseHint,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_rounded),
                      label: Text(l.save),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
