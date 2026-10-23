import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/units.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../common/inputs.dart';
import '../common/ui.dart';
import '../pdf/pdf_kit.dart';
import '../pdf/reports_pdf.dart';
import 'new_cheque_dialog.dart';

/// دفتر الشيكات، مرتّباً بالاستحقاق، بتصميم أبيض وذهبي فاخر.
class ChequesPage extends ConsumerWidget {
  const ChequesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cheques = ref.watch(allChequesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('سجل الشيكات'),
        actions: [
          IconButton(
            tooltip: 'PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () {
              final list = cheques.valueOrNull;
              if (list == null) return;
              final issuer = PdfIssuer.of(ref);
              PdfPreviewPage.open(
                context,
                title: 'سجل الشيكات',
                build: (arabic, format) => buildChequesPdf(
                  cheques: list,
                  issuer: issuer,
                  arabic: arabic,
                  format: format,
                ),
                fileName: (arabic) =>
                    '${arabic ? 'الشيكات' : 'cheques'}-${pdfDateTag(DateTime.now())}.pdf',
              );
            },
          ),
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(allChequesProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-cheques',
        onPressed: () => showDialog<bool>(
          context: context,
          builder: (_) => const NewChequeDialog(),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'شيك جديد',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: cheques.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.goldPrimary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(readableError(e), textAlign: TextAlign.center),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: AppColors.goldContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          size: 40,
                          color: AppColors.goldDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'لا توجد شيكات مسجّلة بعد',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'سجّل الشيكات الواردة أو الصادرة لمتابعة استحقاقها وتحصيلها.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final pending = list.where((c) => c.status == ChequeStatus.pending);
          final overdue = pending.where((c) => c.isOverdue).toList();
          final soon = pending.where((c) => c.isDueSoon).toList();
          final later =
              pending.where((c) => !c.isOverdue && !c.isDueSoon).toList();
          final settled =
              list.where((c) => c.status != ChequeStatus.pending).toList();

          final pendingTotal = pending.fold<int>(
              0,
              (a, c) =>
                  a +
                  (c.direction == ChequeDirection.incoming
                      ? c.amountFils
                      : -c.amountFils));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
            children: [
              _Header(
                total: pendingTotal,
                count: pending.length,
                overdue: overdue.length,
              ),
              const SizedBox(height: 16),
              if (overdue.isNotEmpty)
                _Group(title: 'شيكات فات موعدها', items: overdue, urgent: true),
              if (soon.isNotEmpty)
                _Group(title: 'تستحق خلال أسبوع', items: soon, urgent: true),
              if (later.isNotEmpty) _Group(title: 'تستحق لاحقاً', items: later),
              if (settled.isNotEmpty)
                _Group(title: 'شيكات منتهية (محصلة / ملغاة)', items: settled),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(
      {required this.total, required this.count, required this.overdue});

  final int total;
  final int count;
  final int overdue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            'صافي قيمة الشيكات المعلّقة',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${formatDinars(total.abs())} د.أ ${total >= 0 ? '(صافي لنا)' : '(صافي علينا)'}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: total >= 0 ? AppColors.goldDark : AppColors.error,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.goldBorder),
                ),
                child: Text(
                  '$count شيكاً معلّقاً',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (overdue > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$overdue فات موعده!',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.items, this.urgent = false});

  final String title;
  final List<Cheque> items;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: urgent ? AppColors.error : AppColors.goldPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: urgent ? AppColors.error : AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                decoration: BoxDecoration(
                  color: urgent
                      ? AppColors.errorContainer
                      : AppColors.goldContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: urgent ? AppColors.error : AppColors.goldDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        for (final c in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ChequeCard(cheque: c),
          ),
      ],
    );
  }
}

class _ChequeCard extends ConsumerWidget {
  const _ChequeCard({required this.cheque});

  final Cheque cheque;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incoming = cheque.direction == ChequeDirection.incoming;
    final done = cheque.status != ChequeStatus.pending;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cheque.isOverdue && !done
              ? AppColors.error.withValues(alpha: 0.5)
              : AppColors.border,
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // أيقونة وارد أم صادر
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: done
                    ? AppColors.surfaceMuted
                    : (incoming
                        ? AppColors.goldContainer
                        : AppColors.errorContainer),
                shape: BoxShape.circle,
                border: Border.all(
                  color: done
                      ? AppColors.borderSubtle
                      : (incoming
                          ? AppColors.goldBorder
                          : AppColors.error.withValues(alpha: 0.3)),
                ),
              ),
              child: Icon(
                incoming
                    ? Icons.call_received_rounded
                    : Icons.call_made_rounded,
                color: done
                    ? AppColors.textMuted
                    : (incoming ? AppColors.goldDark : AppColors.error),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cheque.accountName ?? '—',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      decoration: cheque.status == ChequeStatus.cancelled
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      'الاستحقاق: ${cheque.dueDate.year}/${cheque.dueDate.month}/${cheque.dueDate.day}',
                      if (cheque.chequeNumber != null)
                        'رقم ${cheque.chequeNumber}',
                      if (cheque.bankName != null) cheque.bankName!,
                    ].join('  ·  '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (!done && cheque.settledTxId != null) ...[
                    const SizedBox(height: 3),
                    const Text(
                      'محسوب نقداً على الحساب — بانتظار الصرف',
                      style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldDark),
                    ),
                  ],
                  if (!done && cheque.isOverdue) ...[
                    const SizedBox(height: 3),
                    Text(
                      'متأخر ${-cheque.daysUntilDue} يوماً',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${formatDinars(cheque.amountFils)} د.أ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: done
                        ? AppColors.textMuted
                        : (incoming ? AppColors.goldDark : AppColors.error),
                  ),
                ),
                if (done)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      cheque.status.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
            if (!done) ...[
              const SizedBox(width: 4),
              PopupMenuButton<ChequeStatus>(
                tooltip: 'إجراءات الشيك',
                icon: const Icon(Icons.more_vert_rounded,
                    color: AppColors.textSecondary),
                onSelected: (s) => _act(context, ref, s),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: ChequeStatus.cleared,
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded,
                            color: AppColors.success, size: 18),
                        SizedBox(width: 8),
                        Text('تحصيل الشيك'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ChequeStatus.bounced,
                    child: Row(
                      children: [
                        Icon(Icons.replay_rounded,
                            color: AppColors.error, size: 18),
                        SizedBox(width: 8),
                        Text('ارتجاع'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: ChequeStatus.cancelled,
                    child: Row(
                      children: [
                        Icon(Icons.cancel_outlined,
                            color: AppColors.textMuted, size: 18),
                        SizedBox(width: 8),
                        Text('إلغاء'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _act(
      BuildContext context, WidgetRef ref, ChequeStatus status) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(repositoryProvider);

    try {
      if (status == ChequeStatus.cleared) {
        final cashbox = (ref.read(systemAccountsProvider).valueOrNull ??
            {})[SystemAccount.cashbox];
        if (cashbox == null) throw Exception('الصندوق غير مهيّأ');
        // الشيك المحفوظ في حساب الشيكات: صُرف نقداً أم أُودع في البنك؟
        var toCash = true;
        if (cheque.settledTxId != null) {
          final choice = await showDialog<bool>(
            context: context,
            builder: (ctx) => SimpleDialog(
              title: Text('صرف الشيك ${cheque.chequeNumber ?? ''}'),
              children: [
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const ListTile(
                    leading: Icon(Icons.payments_outlined,
                        color: AppColors.goldDark),
                    title: Text('صُرف نقداً'),
                    subtitle: Text('يدخل المبلغ كاش الشنطة'),
                  ),
                ),
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const ListTile(
                    leading: Icon(Icons.account_balance_outlined,
                        color: AppColors.goldDark),
                    title: Text('أُودع في البنك'),
                    subtitle: Text('يخرج من الشنطة إلى حساب المالك'),
                  ),
                ),
              ],
            ),
          );
          if (choice == null) return;
          toCash = choice;
        }
        final doc = await repo.clearCheque(
          chequeId: cheque.id,
          cashboxId: cashbox,
          toCash: toCash,
        );
        messenger.showSnackBar(
          SnackBar(
            content: Text('تم تحصيل الشيك — الدفعة رقم $doc'),
            backgroundColor: AppColors.goldDark,
          ),
        );
      } else {
        // الشيك المحسوب نقداً يُعاد مبلغه على حساب الطرف عند ارتجاعه أو إلغائه
        final counted = cheque.settledTxId != null;
        final incoming = cheque.direction == ChequeDirection.incoming;
        final amount = '${formatDinars(cheque.amountFils)} د.أ';
        final ok = await confirmDialog(
          context,
          title: status == ChequeStatus.bounced
              ? 'ارتجاع الشيك ${cheque.chequeNumber ?? ''}'
              : 'إلغاء الشيك ${cheque.chequeNumber ?? ''}',
          body: counted
              ? (incoming
                  ? 'هذا الشيك حُسب نقداً عند استلامه. سيُعاد مبلغ $amount على حساب ${cheque.accountName ?? ''} ليصبح عليه من جديد.'
                  : 'هذا الشيك حُسب نقداً عند تسليمه. سيُعاد مبلغ $amount لحساب ${cheque.accountName ?? ''} ليصبح له علينا من جديد.')
              : 'ستتغير حالة الشيك فقط، ولا يتأثر أي رصيد.',
          confirmLabel: status == ChequeStatus.bounced
              ? 'تأكيد الارتجاع'
              : 'تأكيد الإلغاء',
          destructive: true,
        );
        if (!ok) return;
        final doc = await repo.voidCheque(cheque.id, status);
        messenger.showSnackBar(
          SnackBar(
            content: Text(doc == null
                ? 'تم تعديل حالة الشيك إلى: ${status.label}'
                : 'تم ${status == ChequeStatus.bounced ? 'ارتجاع' : 'إلغاء'} الشيك وإعادة المبلغ على الحساب — قيد رقم $doc'),
            backgroundColor: AppColors.goldDark,
          ),
        );
        invalidateAfterPosting(ref);
      }
      ref.invalidate(allChequesProvider);
      ref.invalidate(pendingChequesProvider);
      ref.invalidate(accountsProvider);
    } catch (e) {
      // الدالة غير موجودة: لم يُنفَّذ ملف 0012 على قاعدة البيانات بعد
      final missing = e.toString().contains('void_cheque');
      messenger.showSnackBar(
        SnackBar(
          content: Text(missing
              ? 'يلزم تنفيذ ملف 0012_void_cheque.sql في Supabase أولاً'
              : readableError(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
