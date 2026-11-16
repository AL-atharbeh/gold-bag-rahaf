import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/locale.dart';
import '../../core/units.dart';
import '../../domain/enums.dart';
import '../../domain/ledger.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/labels.dart';
import '../common/inputs.dart';
import '../common/ui.dart';
import '../pdf/invoice_pdf.dart';
import '../pdf/pdf_kit.dart';
import '../returns/partial_return_page.dart';
import 'balance_widgets.dart';

/// فاتورة حركة محفوظة — للعرض فقط، بلا أي تعديل.
///
/// تُعرض سطور الطرف [partyId] مقسّمة: بضاعة، كسر، مصنوعية، نقد —
/// وفي آخرها أثر الحركة على رصيديه.
class TransactionDetailPage extends ConsumerWidget {
  const TransactionDetailPage(
      {super.key, required this.txId, required this.partyId});

  final String txId;
  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final detail = ref.watch(txDetailProvider(txId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l.txDetails),
        actions: [
          IconButton(
            tooltip: 'PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () async {
              final tx = detail.valueOrNull;
              if (tx == null) return;
              final party = (await ref.read(accountsProvider.future))
                  .where((a) => a.id == partyId)
                  .firstOrNull;
              if (party == null || !context.mounted) return;
              final issuer = PdfIssuer.of(ref);
              PdfPreviewPage.open(
                context,
                title: '${l.txDetails} ${ltrIsolate('#${tx.docNumber}')}',
                build: (arabic, format) => buildInvoicePdf(
                  tx: tx,
                  party: party,
                  issuer: issuer,
                  arabic: arabic,
                  format: format,
                ),
                fileName: (arabic) => invoiceFileName(tx, party, arabic),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AsyncBody<TxDetail>(
        value: detail,
        onRetry: () => ref.invalidate(txDetailProvider(txId)),
        data: (tx) {
          final mine = tx.lines.where((x) => x.accountId == partyId).toList();
          final gold = mine.where((x) => x.ledger == LedgerKind.gold);
          final cash = mine.where((x) => x.ledger == LedgerKind.cash);

          final goodsOut =
              gold.where((x) => x.itemName != null && x.amount > 0).toList();
          final goodsIn =
              gold.where((x) => x.itemName != null && x.amount < 0).toList();
          bool isFix(TxLine x) =>
              x.note == noteFixGold || x.note == noteFixScrap;
          // غرامات التسكير ليست كسراً مستلماً أو مسلَّماً
          final scrapIn = gold
              .where((x) => x.itemName == null && x.amount < 0 && !isFix(x))
              .toList();
          final scrapOut = gold
              .where((x) => x.itemName == null && x.amount > 0 && !isFix(x))
              .toList();
          final fixGoldMg =
              gold.where(isFix).fold<int>(0, (a, x) => a + x.amount.abs());
          bool special(TxLine x) =>
              x.makingPerGramFils != null ||
              x.note == noteMakingDiscount ||
              x.note == noteExchangeFee ||
              isFix(x);
          final making = cash
              .where((x) =>
                  x.makingPerGramFils != null && x.note != noteRecoveredMaking)
              .toList();
          final recoveredMaking =
              cash.where((x) => x.note == noteRecoveredMaking).toList();
          final discount =
              cash.where((x) => x.note == noteMakingDiscount).toList();
          final exchangeFee =
              cash.where((x) => x.note == noteExchangeFee).toList();
          final fixValue = cash.where(isFix).toList();
          final cashIn =
              cash.where((x) => !special(x) && x.amount < 0).toList();
          final cashOut =
              cash.where((x) => !special(x) && x.amount > 0).toList();

          final goldTotal = gold.fold<int>(0, (a, x) => a + x.amount);
          final cashTotal = cash.fold<int>(0, (a, x) => a + x.amount);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(tx: tx, l: l),
                      const SizedBox(height: 16),
                      if (goodsOut.isNotEmpty)
                        _GoodsSection(
                            title: tx.type == TxType.goodsReturn
                                ? l.returnedGoods
                                : l.soldGoods,
                            lines: goodsOut,
                            l: l),
                      if (goodsIn.isNotEmpty)
                        _GoodsSection(
                            title: tx.type == TxType.goodsReturn
                                ? l.returnedGoods
                                : tx.type == TxType.sale
                                    ? l.recoveredGoods
                                    : l.receivedGoods,
                            lines: goodsIn,
                            l: l),
                      if (scrapIn.isNotEmpty)
                        _GoodsSection(
                            title: l.receivedScrap, lines: scrapIn, l: l),
                      if (scrapOut.isNotEmpty)
                        _GoodsSection(
                            title: l.deliveredScrap, lines: scrapOut, l: l),
                      if (making.isNotEmpty)
                        _CashSection(
                            title: l.making,
                            lines: making,
                            l: l,
                            showRate: true),
                      if (recoveredMaking.isNotEmpty)
                        _CashSection(
                            title: l.recoveredMaking,
                            lines: recoveredMaking,
                            l: l,
                            showRate: true),
                      if (discount.isNotEmpty)
                        _CashSection(
                            title: l.makingDiscount, lines: discount, l: l),
                      if (exchangeFee.isNotEmpty)
                        _CashSection(
                            title: l.exchangeFee, lines: exchangeFee, l: l),
                      if (fixValue.isNotEmpty)
                        _CashSection(
                            title: [
                              l.opFix,
                              fixValue.first.note == noteFixScrap
                                  ? l.fixClassScrap
                                  : l.fixClassGold,
                              if (fixGoldMg > 0)
                                '${formatGrams(fixGoldMg)} ${l.gramsUnit}',
                            ].join(' — '),
                            lines: fixValue,
                            l: l),
                      if (cashIn.isNotEmpty)
                        _CashSection(
                            title: l.receivedCash, lines: cashIn, l: l),
                      if (cashOut.isNotEmpty)
                        _CashSection(title: l.paidCash, lines: cashOut, l: l),
                      const SizedBox(height: 8),
                      SectionTitle(l.accountEffect),
                      Wrap(spacing: 10, runSpacing: 8, children: [
                        if (goldTotal != 0)
                          Pill(
                            '${l.goldChange}: ${goldTotal > 0 ? '+' : '−'}${formatGrams(goldTotal.abs())} ${l.gramsUnit}',
                            fg: balanceColor(goldTotal),
                          ),
                        if (cashTotal != 0)
                          Pill(
                            '${l.cashChange}: ${cashTotal > 0 ? '+' : '−'}${formatDinars(cashTotal.abs())} ${l.dinarUnit}',
                            fg: balanceColor(cashTotal),
                            bg: AppColors.surfaceMuted,
                          ),
                      ]),
                      const SizedBox(height: 24),
                      if (tx.type == TxType.reversal)
                        _Notice(l.txIsReversal)
                      else if (tx.isReversed)
                        _Notice(l.txIsReversed, error: true)
                      else
                        Wrap(spacing: 12, runSpacing: 10, children: [
                          // البيع للمحل يُسترد منه داخل حركة البيع نفسها
                          if (tx.type == TxType.goodsIn &&
                              goodsWithMaking(tx, partyId, fromShop: false)
                                  .isNotEmpty)
                            FilledButton.icon(
                              onPressed: () => _partialReturn(context, ref, tx),
                              icon: const Icon(Icons.assignment_return_rounded),
                              label: Text(l.partialReturn),
                            ),
                          OutlinedButton.icon(
                            onPressed: () => _cancel(context, ref, tx),
                            icon: const Icon(Icons.undo_rounded),
                            label: Text(l.cancelTx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                            ),
                          ),
                        ]),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _partialReturn(
      BuildContext context, WidgetRef ref, TxDetail tx) async {
    final party = (await ref.read(accountsProvider.future))
        .where((a) => a.id == partyId)
        .firstOrNull;
    if (party == null || !context.mounted) return;
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (_) => PartialReturnPage(tx: tx, party: party)),
    );
    if (saved == true && context.mounted) Navigator.pop(context);
  }

  /// إلغاء الحركة بقيد عكسي بعد تأكيد وسبب.
  Future<void> _cancel(BuildContext context, WidgetRef ref, TxDetail tx) async {
    final l = context.l10n;
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('${l.cancelTx} ${ltrIsolate('#${tx.docNumber}')}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.cancelTxBody,
                    style: const TextStyle(color: AppColors.textSecondary)),
                const SizedBox(height: 14),
                TextField(
                  controller: reason,
                  autofocus: true,
                  onChanged: (_) => setLocal(() {}),
                  decoration: InputDecoration(labelText: l.cancelReason),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(l.cancel)),
            FilledButton(
              onPressed: reason.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: Text(l.cancelConfirm),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final doc = await ref
          .read(repositoryProvider)
          .cancelTransaction(tx.id, reason.text.trim());
      invalidateAfterPosting(ref);
      ref.invalidate(txDetailProvider(tx.id));
      messenger.showSnackBar(SnackBar(
        content: Text(l.txCancelledDoc(doc)),
        backgroundColor: AppColors.goldDark,
      ));
    } catch (e) {
      final missing = e.toString().contains('cancel_transaction');
      messenger.showSnackBar(SnackBar(
        content: Text(missing ? l.needMigration12 : readableError(e)),
        backgroundColor: AppColors.error,
      ));
    }
  }
}

class _Notice extends StatelessWidget {
  const _Notice(this.text, {this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: error ? AppColors.errorContainer : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(Icons.info_outline_rounded,
              size: 18,
              color: error ? AppColors.error : AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: error ? AppColors.error : AppColors.textSecondary)),
          ),
        ]),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.tx, required this.l});

  final TxDetail tx;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    return GoldCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tx.type.label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    decoration:
                        tx.isReversed ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (tx.isReversed)
                Pill(l.reversedTx,
                    fg: AppColors.error, bg: AppColors.errorContainer),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 18, runSpacing: 6, children: [
            _kv(l.docNumber, ltrIsolate(tx.docNumber)),
            _kv(l.date, formatDate(tx.occurredAt)),
          ]),
          if (tx.note != null && tx.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(tx.note!,
                style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

Widget _kv(String k, String v) => Text.rich(TextSpan(children: [
      TextSpan(
          text: '$k: ',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      TextSpan(
          text: v,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
    ]));

/// بنود ذهب: الصنف والعيار والعدد والقائم والصافي.
class _GoodsSection extends StatelessWidget {
  const _GoodsSection(
      {required this.title, required this.lines, required this.l});

  final String title;
  final List<TxLine> lines;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final qty = lines.fold<int>(0, (a, x) => a + (x.quantity ?? 0).abs());
    final gross =
        lines.fold<int>(0, (a, x) => a + (x.grossWeightMg ?? 0).abs());
    final net = lines.fold<int>(0, (a, x) => a + x.amount.abs());

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GoldCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.goldDark)),
            const SizedBox(height: 10),
            if (AdaptiveBox.isPhone(context))
              ..._phoneRows(qty, gross, net)
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowHeight: 36,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 44,
                  columnSpacing: 22,
                  headingTextStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppColors.textSecondary),
                  columns: [
                    DataColumn(label: Text(l.item)),
                    DataColumn(label: Text(l.karat)),
                    DataColumn(label: Text(l.count), numeric: true),
                    DataColumn(label: Text(l.grossWeight), numeric: true),
                    DataColumn(label: Text(l.net24), numeric: true),
                  ],
                  rows: [
                    for (final x in lines)
                      DataRow(cells: [
                        DataCell(Text(x.itemName ?? l.unknownItem)),
                        DataCell(Text(
                            '${x.karatName ?? '—'}${x.karatPpm == null ? '' : '  ·  ${(x.karatPpm! / 1000000).toStringAsFixed(3)}'}')),
                        DataCell(Text(
                            x.quantity == null ? '—' : '${x.quantity!.abs()}')),
                        DataCell(
                            Text(formatGrams((x.grossWeightMg ?? 0).abs()))),
                        DataCell(Text(formatGrams(x.amount.abs()),
                            style:
                                const TextStyle(fontWeight: FontWeight.w700))),
                      ]),
                    if (lines.length > 1)
                      DataRow(
                        color: const WidgetStatePropertyAll(
                            AppColors.goldContainer),
                        cells: [
                          DataCell(Text(l.total,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800))),
                          const DataCell(Text('')),
                          DataCell(Text(qty == 0 ? '—' : '$qty',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800))),
                          DataCell(Text(formatGrams(gross),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800))),
                          DataCell(Text(formatGrams(net),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800))),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

extension on _GoodsSection {
  String _karat(TxLine x) =>
      '${x.karatName ?? '—'}${x.karatPpm == null ? '' : ' · ${(x.karatPpm! / 1000000).toStringAsFixed(3)}'}';

  /// على الهاتف: كل بند سطر مستقل بدل جدول يحتاج تمريراً أفقياً.
  List<Widget> _phoneRows(int qty, int gross, int net) {
    const muted = TextStyle(fontSize: 12, color: AppColors.textSecondary);
    Widget row(String title, String sub, String value, {bool total = false}) =>
        Container(
          color: total ? AppColors.goldContainer : null,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight:
                              total ? FontWeight.w800 : FontWeight.w700)),
                  if (sub.isNotEmpty) Text(sub, style: muted),
                ],
              ),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(l.net24, style: muted),
              Text('$value ${l.gramsUnit}',
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
          ]),
        );
    String sub(int? count, int grossMg) => [
          if (count != null && count != 0) '${l.count}: ${count.abs()}',
          '${l.grossWeight}: ${formatGrams(grossMg.abs())}',
        ].join('  ·  ');
    return [
      for (final x in lines) ...[
        row('${x.itemName ?? l.unknownItem}  ·  ${_karat(x)}',
            sub(x.quantity, x.grossWeightMg ?? 0), formatGrams(x.amount.abs())),
        const Divider(height: 1),
      ],
      if (lines.length > 1)
        row(l.total, sub(qty, gross), formatGrams(net), total: true),
    ];
  }
}

/// بنود نقد: المصنوعية (مع سعر الغرام) أو المبالغ المقبوضة والمدفوعة.
class _CashSection extends StatelessWidget {
  const _CashSection(
      {required this.title,
      required this.lines,
      required this.l,
      this.showRate = false});

  final String title;
  final List<TxLine> lines;
  final AppLocalizations l;
  final bool showRate;

  @override
  Widget build(BuildContext context) {
    final total = lines.fold<int>(0, (a, x) => a + x.amount.abs());
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GoldCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.goldDark)),
              ),
              Text('${formatDinars(total)} ${l.dinarUnit}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16)),
            ]),
            if (showRate && lines.length > 1) ...[
              const SizedBox(height: 8),
              for (final x in lines)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '${formatDinars(x.makingPerGramFils!)} ${l.dinarUnit} / ${x.note == noteMakingPiece ? l.perPiece : l.gramsUnit}'
                    '  =  ${formatDinars(x.amount.abs())} ${l.dinarUnit}',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
            ] else if (showRate) ...[
              const SizedBox(height: 6),
              Text(
                  '${formatDinars(lines.first.makingPerGramFils!)} ${l.dinarUnit} / ${lines.first.note == noteMakingPiece ? l.perPiece : l.gramsUnit}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}
