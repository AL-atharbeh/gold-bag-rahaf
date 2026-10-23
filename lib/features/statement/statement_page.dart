import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/units.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../common/balance_text.dart';
import '../common/inputs.dart';
import '../factors/karat_factors_page.dart';

class StatementPage extends ConsumerWidget {
  const StatementPage(
      {super.key, required this.accountId, required this.title});

  final String accountId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(statementProvider(accountId));
    final balances = ref.watch(balancesProvider);
    final balance = (balances.valueOrNull ?? const <AccountBalance>[])
        .where((b) => b.accountId == accountId)
        .firstOrNull;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'معاملات العيار',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    KaratFactorsPage(accountId: accountId, accountName: title),
              ),
            ),
          ),
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(statementProvider(accountId)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          if (balance != null) _BalanceHeader(balance: balance),
          Expanded(
            child: lines.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.goldPrimary),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('تعذّر تحميل الكشف: ${readableError(e)}'),
                ),
              ),
              data: (rows) => rows.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          constraints: const BoxConstraints(maxWidth: 360),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.goldBorder),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.list_alt_rounded,
                                  size: 40, color: AppColors.goldDark),
                              SizedBox(height: 16),
                              Text(
                                'لا توجد حركات مسجلة',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'لم يتم تسجيل أي حركات مالية أو ذهبية على هذا الحساب بعد.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      itemCount: rows.length,
                      itemBuilder: (_, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _StatementCard(
                          line: rows[i],
                          accountId: accountId,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  const _BalanceHeader({required this.balance});

  final AccountBalance balance;

  @override
  Widget build(BuildContext context) {
    final lines = describeBalance(balance);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBF8F1), Color(0xFFFAF3E3)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.goldBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الرصيد الحالي للحساب',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          if (lines.isEmpty)
            const Text(
              'الحساب مُصفّى — لا دين ولا رصيد.',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.goldDark,
              ),
            )
          else
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  l,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: l.startsWith('له علينا') || l.startsWith('عجز')
                        ? AppColors.error
                        : AppColors.goldDark,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _StatementCard extends ConsumerWidget {
  const _StatementCard({required this.line, required this.accountId});

  final StatementLine line;
  final String accountId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGold = line.ledger == LedgerKind.gold;
    final value = isGold
        ? '${formatGrams(line.amount.abs())} غ صافي'
        : '${formatDinars(line.amount.abs())} د.أ';

    final sign = line.amount > 0 ? '+' : '−';
    final color = line.isReversed
        ? AppColors.textMuted
        : (line.amount > 0 ? AppColors.goldDark : AppColors.error);

    final style = line.isReversed
        ? const TextStyle(
            decoration: TextDecoration.lineThrough, color: AppColors.textMuted)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: line.isReversed ? AppColors.borderSubtle : AppColors.border,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.goldContainer,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.goldBorder, width: 0.8),
                        ),
                        child: Text(
                          line.txType.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: line.isReversed
                                ? AppColors.textMuted
                                : AppColors.goldDark,
                          ),
                        ),
                      ),
                      if (line.isReversed) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.errorContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ملغاة بقيد عكسي',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'رقم ${line.docNumber}  ·  ${_date(line.occurredAt)}'
                    '${line.karatName != null ? '  ·  ${line.karatName}' : ''}'
                    '${line.grossWeightMg != null ? '  ·  قائم ${formatGrams(line.grossWeightMg!.abs())} غ' : ''}',
                    style: style ??
                        const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                  ),
                  if (line.note != null && line.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      line.note!,
                      style: (style ??
                              const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary))
                          .copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$sign $value',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                    decoration:
                        line.isReversed ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (!line.isReversed)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: IconButton(
                      tooltip: 'إلغاء بقيد عكسي',
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(6),
                        minimumSize: const Size(32, 32),
                        backgroundColor: AppColors.surfaceMuted,
                      ),
                      icon: const Icon(Icons.undo_rounded,
                          size: 16, color: AppColors.textSecondary),
                      onPressed: () => _confirmReverse(context, ref),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _date(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  Future<void> _confirmReverse(BuildContext context, WidgetRef ref) async {
    final reason = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إلغاء الحركة بقيد عكسي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الحركة رقم ${line.docNumber} — ${line.txType.label}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'لن تُحذف الحركة من السجلات. سيُسجَّل قيد عكسي يلغي أثرها المحاسبي، وتبقى الحركتان ظاهرتين للشفافية.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reason,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'سبب الإلغاء (اختياري)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final doc = await ref.read(repositoryProvider).reverse(
            line.txId,
            reason: reason.text.trim().isEmpty ? null : reason.text.trim(),
          );
      ref.invalidate(statementProvider(accountId));
      ref.invalidate(accountsProvider);
      ref.invalidate(balancesProvider);
      messenger.showSnackBar(
        SnackBar(
          content: Text('تم إلغاء الحركة بنجاح — القيد العكسي رقم $doc'),
          backgroundColor: AppColors.goldDark,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(readableError(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
