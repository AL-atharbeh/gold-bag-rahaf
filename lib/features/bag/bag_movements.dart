import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/locale.dart';
import '../../core/units.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../platform/labels.dart';
import '../common/inputs.dart';
import '../common/ui.dart';
import '../parties/transaction_detail_page.dart';
import '../pdf/pdf_kit.dart';
import '../reports/period_picker.dart';

/// حركة واحدة على ذهب الشنطة: مجموع سطورها، وكل ما يدخل منها وما يخرج.
class BagMovement {
  BagMovement(this.first);

  final PeriodPosting first;
  int netMg = 0;
  int pieces = 0;
}

/// يجمع سطور ذهب الشنطة في حركات، الأحدث أولاً. الملغاة وعكسها لا تُعرض.
List<BagMovement> bagMovements(List<PeriodPosting> rows) {
  final byTx = <String, BagMovement>{};
  for (final p in rows) {
    if (p.ledger != LedgerKind.gold) continue;
    if (p.txReversed || p.txType == TxType.reversal) continue;
    final m = byTx.putIfAbsent(p.txId, () => BagMovement(p));
    m.netMg += p.amount;
    m.pieces += p.quantity ?? 0;
  }
  return byTx.values.toList()
    ..sort((a, b) => b.first.occurredAt.compareTo(a.first.occurredAt));
}

/// مراجعة ما دخل الشنطة وما خرج منها: وارد المشاغل، والكسر، والمبيعات…
class BagMovementsView extends ConsumerStatefulWidget {
  const BagMovementsView({super.key});

  @override
  ConsumerState<BagMovementsView> createState() => _BagMovementsViewState();
}

class _BagMovementsViewState extends ConsumerState<BagMovementsView> {
  Period _period = Period.of(PeriodPreset.thisMonth);
  int _filter = 0; // 0 الكل، 1 وارد، -1 صادر
  Future<List<PeriodPosting>>? _rows;
  String? _bagId;

  void _load(String bagId) {
    _bagId = bagId;
    _rows = ref.read(repositoryProvider).periodPostings(
        accountId: bagId, from: _period.from, to: _period.endExclusive);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bagId =
        ref.watch(systemAccountsProvider).valueOrNull?[SystemAccount.shanta];
    if (bagId == null) return const SizedBox.shrink();
    // يُعاد التحميل بعد كل حركة
    ref.listen(recentTxProvider, (_, __) => setState(() => _rows = null));
    if (_rows == null || _bagId != bagId) _load(bagId);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        PeriodPicker(
          value: _period,
          onChanged: (p) => setState(() {
            _period = p;
            _rows = null;
          }),
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: [
          for (final (v, t) in [
            (0, l.allMovements),
            (1, l.movementsIn),
            (-1, l.movementsOut),
          ])
            ChoiceChip(
              label: Text(t),
              selected: _filter == v,
              onSelected: (_) => setState(() => _filter = v),
            ),
        ]),
        const SizedBox(height: 12),
        FutureBuilder<List<PeriodPosting>>(
          future: _rows,
          builder: (context, snap) {
            if (snap.hasError) {
              return Text(readableError(snap.error!),
                  style: const TextStyle(color: AppColors.error));
            }
            if (!snap.hasData) {
              return const Center(
                  child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.goldPrimary),
              ));
            }
            final list = bagMovements(snap.data!)
                .where((m) =>
                    _filter == 0 ||
                    (_filter > 0 ? m.netMg > 0 : m.netMg < 0))
                .toList();
            if (list.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l.noBagMovements,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted)),
              );
            }
            return Column(children: [
              for (final m in list) ...[
                GoldCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TransactionDetailPage(
                        txId: m.first.txId,
                        partyId: m.first.partyId ?? bagId,
                      ),
                    ),
                  ),
                  child: Row(children: [
                    Icon(
                      m.netMg >= 0
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      size: 20,
                      color:
                          m.netMg >= 0 ? AppColors.goldDark : AppColors.error,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [
                              pdfTxType(m.first.txType, context.isArabic),
                              if (m.first.partyName != null) m.first.partyName!,
                            ].join(' — '),
                            style:
                                const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${ltrIsolate(formatDate(m.first.occurredAt))} · ${ltrIsolate('#${m.first.docNumber}')}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${m.netMg >= 0 ? '+' : '−'}${formatGrams(m.netMg.abs())} ${l.gramsUnit}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        if (m.pieces != 0)
                          Text(l.piecesCount(m.pieces.abs()),
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                      ],
                    ),
                  ]),
                ),
                const SizedBox(height: 8),
              ],
            ]);
          },
        ),
      ],
    );
  }
}
