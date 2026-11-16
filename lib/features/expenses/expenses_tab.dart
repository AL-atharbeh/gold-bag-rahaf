import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/locale.dart';
import '../../core/units.dart';
import '../../domain/enums.dart';
import '../../domain/ledger.dart';
import '../../domain/models.dart';
import '../../platform/labels.dart';
import '../bagday/expense_page.dart';
import '../common/inputs.dart';
import '../common/ui.dart';
import '../employees/employees_page.dart';
import '../parties/transaction_detail_page.dart';
import '../reports/period_picker.dart';

/// تبويب المصاريف والموظفين: ما خرج من كاش الشنطة مصاريفَ، والموظفون
/// برواتبهم وما خُصم منهم.
class ExpensesTab extends StatelessWidget {
  const ExpensesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(l.tabExpenses),
          bottom: TabBar(
            labelColor: AppColors.goldDark,
            indicatorColor: AppColors.goldPrimary,
            tabs: [
              Tab(text: l.expensesTitle),
              Tab(text: l.tabEmployees),
            ],
          ),
        ),
        body: const TabBarView(children: [
          _ExpensesList(),
          EmployeesPage(showAppBar: false),
        ]),
      ),
    );
  }
}

/// سطر مصروف: من كاش الشنطة إلى المصاريف، أو باسم موظف.
bool isExpenseLine(PeriodPosting p) =>
    p.ledger == LedgerKind.cash &&
    p.amount < 0 &&
    !p.cancelled &&
    (p.txType == TxType.expense ||
        p.lineNote == noteEmployeeDraw ||
        p.lineNote == noteSalaryPay);

/// قيود كاش الشنطة في فترة — منها تُستخرج المصاريف.
final cashboxPostingsProvider = FutureProvider.autoDispose
    .family<List<PeriodPosting>, ({DateTime from, DateTime to})>(
        (ref, r) async {
  ref.watch(recentTxProvider); // يُعاد التحميل بعد كل حركة
  final sys = await ref.watch(systemAccountsProvider.future);
  final cashbox = sys[SystemAccount.cashbox];
  if (cashbox == null) return const [];
  return ref
      .watch(repositoryProvider)
      .periodPostings(accountId: cashbox, from: r.from, to: r.to);
});

class _ExpensesList extends ConsumerStatefulWidget {
  const _ExpensesList();

  @override
  ConsumerState<_ExpensesList> createState() => _ExpensesListState();
}

class _ExpensesListState extends ConsumerState<_ExpensesList> {
  Period _period = Period.of(PeriodPreset.thisMonth);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final sys = ref.watch(systemAccountsProvider).valueOrNull;
    final cashbox = sys?[SystemAccount.cashbox];
    final expensesId = sys?[SystemAccount.expenses];
    if (cashbox == null) return const SizedBox.shrink();
    final range = (from: _period.from, to: _period.endExclusive);
    final rows = ref.watch(cashboxPostingsProvider(range));

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-expense',
        onPressed: () async {
          final saved = await Navigator.push<bool>(context,
              MaterialPageRoute(builder: (_) => const ExpensePage()));
          if (saved == true) ref.invalidate(cashboxPostingsProvider(range));
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l.newExpense,
            style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          PeriodPicker(
            value: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              if (rows.hasError) {
                return Text(readableError(rows.error!),
                    style: const TextStyle(color: AppColors.error));
              }
              if (!rows.hasValue) {
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.all(24),
                  child:
                      CircularProgressIndicator(color: AppColors.goldPrimary),
                ));
              }
              final list = rows.value!.where(isExpenseLine).toList()
                ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
              if (list.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(l.noExpenses,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted)),
                );
              }
              final total = list.fold<int>(0, (a, p) => a - p.amount);
              final onEmployees = list
                  .where((p) => p.txType != TxType.expense)
                  .fold<int>(0, (a, p) => a - p.amount);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    Pill(
                        '${l.expensesTotal}: ${formatDinars(total)} ${l.dinarUnit}'),
                    if (onEmployees > 0)
                      Pill(
                          '${l.expensesOnEmployees}: ${formatDinars(onEmployees)} ${l.dinarUnit}'),
                  ]),
                  const SizedBox(height: 12),
                  for (final p in list) ...[
                    GoldCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          // من جهة المصاريف أو الموظف: يظهر "نقد مدفوع"
                          builder: (_) => TransactionDetailPage(
                              txId: p.txId,
                              partyId: p.partyId ?? expensesId ?? cashbox),
                        ),
                      ),
                      child: Row(children: [
                        Icon(
                          p.txType == TxType.expense
                              ? Icons.receipt_long_outlined
                              : Icons.badge_outlined,
                          size: 20,
                          color: AppColors.goldDark,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                [
                                  if (p.partyName != null) p.partyName!,
                                  p.txNote ?? p.lineNote ?? l.expOther,
                                ].join(' — '),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800),
                              ),
                              Text(
                                '${ltrIsolate(formatDate(p.occurredAt))} · ${ltrIsolate('#${p.docNumber}')}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Text('${formatDinars(-p.amount)} ${l.dinarUnit}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                      ]),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
