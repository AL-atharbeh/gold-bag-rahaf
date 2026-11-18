import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/locale.dart';
import '../../core/units.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/labels.dart';
import '../../platform/session.dart';
import '../bag/goods_in_page.dart';
import '../cheques/cheques_page.dart';
import '../common/ui.dart';
import '../parties/balance_widgets.dart';
import '../parties/party_ledger_page.dart';
import '../parties/transaction_detail_page.dart';
import '../shops/shop_sale_page.dart';
import '../traders/trader_tx_page.dart';
import '../reports/reports_page.dart';
import 'day_summary.dart';

/// الرئيسية: ملخص اليوم، الشنطة، الذمم، الشيكات، وآخر الحركات —
/// مع اختصارات لأكثر العمليات استعمالاً.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _refresh(WidgetRef ref) {
    ref.invalidate(todayPostingsProvider);
    ref.invalidate(recentTxProvider);
    ref.invalidate(balancesProvider);
    ref.invalidate(itemStockProvider);
    ref.invalidate(pendingChequesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final m = ref.watch(activeMembershipProvider);
    final ctx = ref.watch(sessionProvider).valueOrNull;
    final name = (m?.displayName.isNotEmpty ?? false)
        ? m!.displayName
        : (ctx?.fullName ?? '');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l.tabHome),
        actions: [
          IconButton(
            tooltip: l.retry,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _refresh(ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(ref),
        child: LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth >= 900;
          final colWidth = wide ? (c.maxWidth - 40 - 16) / 2 : c.maxWidth - 40;
          Widget col(List<Widget> children) => SizedBox(
                width: colWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              );

          final left = [
            const _TodayCard(),
            const SizedBox(height: 16),
            const _BagCard(),
            const SizedBox(height: 16),
            const _ChequesCard(),
          ];
          final right = [
            const _ReceivablesCard(),
            const SizedBox(height: 16),
            const _RecentCard(),
          ];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              _Greeting(name: name, l: l),
              const SizedBox(height: 14),
              const _QuickActions(),
              const SizedBox(height: 18),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [col(left), const SizedBox(width: 16), col(right)],
                )
              else
                col([...left, const SizedBox(height: 16), ...right]),
            ],
          );
        }),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name, required this.l});

  final String name;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name.isEmpty ? l.welcome : l.welcomeName(name),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        const SizedBox(height: 2),
        Text(ltrIsolate(formatDate(now)),
            style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// اختصارات
// ---------------------------------------------------------------------------

class _QuickActions extends ConsumerWidget {
  const _QuickActions();

  Future<void> _pickTrader(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final traders = (await ref.read(accountsProvider.future))
        .where((a) =>
            a.kind == AccountKind.trader || a.kind == AccountKind.factory)
        .toList();
    if (!context.mounted) return;
    if (traders.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.noTradersYet)));
      return;
    }
    final t = await showModalBottomSheet<Account>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l.chooseTrader,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            for (final a in traders)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.goldContainer,
                  child:
                      Icon(Icons.handshake_outlined, color: AppColors.goldDark),
                ),
                title: Text(a.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(ctx, a),
              ),
          ],
        ),
      ),
    );
    if (t != null && context.mounted) await showTraderOps(context, t);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    void push(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    final actions = [
      (Icons.sell_rounded, l.quickSellShop, () => push(const ShopSalePage())),
      (Icons.move_to_inbox_rounded, l.goodsIn, () => push(const GoodsInPage())),
      (Icons.swap_vert_rounded, l.traderOps, () => _pickTrader(context, ref)),
      (Icons.summarize_outlined, l.reports, () => push(const ReportsPage())),
    ];

    return LayoutBuilder(builder: (context, c) {
      // أربعة في صف على التابلت، واثنان في صف على الهاتف
      final perRow = c.maxWidth >= 600 ? 4 : 2;
      final w = (c.maxWidth - 10 * (perRow - 1)) / perRow;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final (icon, label, onTap) in actions)
            SizedBox(
              width: w,
              child: Material(
                color: AppColors.goldContainer,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.goldBorder),
                    ),
                    child: Column(children: [
                      Icon(icon, color: AppColors.goldDark, size: 26),
                      const SizedBox(height: 6),
                      Text(label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.goldDark)),
                    ]),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

// ---------------------------------------------------------------------------
// بطاقات
// ---------------------------------------------------------------------------

class _Section extends StatelessWidget {
  const _Section(
      {required this.title,
      required this.icon,
      required this.child,
      this.onTap});

  final String title;
  final IconData icon;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GoldCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Icon(icon, size: 20, color: AppColors.goldDark),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: AppColors.goldDark)),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// رقم واحد بعنوانه — نصف عرض البطاقة.
class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.sub, this.color});

  final String label;
  final String value;
  final String? sub;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(value,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: color ?? AppColors.textPrimary)),
            ),
            if (sub != null)
              Text(sub!,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textMuted)),
          ],
        ),
      );
    });
  }
}

Widget _statGrid(List<Widget> stats) => LayoutBuilder(builder: (context, c) {
      final w = (c.maxWidth - 10) / 2;
      return Wrap(spacing: 10, runSpacing: 10, children: [
        for (final s in stats) SizedBox(width: w, child: s),
      ]);
    });

class _TodayCard extends ConsumerWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final sys = ref.watch(systemAccountsProvider).valueOrNull ?? const {};
    final postings = ref.watch(todayPostingsProvider);
    final g = l.gramsUnit;
    final jd = l.dinarUnit;

    return _Section(
      title: l.today,
      icon: Icons.today_rounded,
      child: AsyncBody<List<DayPosting>>(
        value: postings,
        onRetry: () => ref.invalidate(todayPostingsProvider),
        data: (rows) {
          final d = DaySummary.from(
            rows,
            bagId: sys[SystemAccount.shanta],
            cashboxId: sys[SystemAccount.cashbox],
            expensesId: sys[SystemAccount.expenses],
            chequesId: sys[SystemAccount.cheques],
          );
          final netCash = (ref.watch(balancesProvider).valueOrNull ??
                      const <AccountBalance>[])
                  .where((b) => b.accountId == sys[SystemAccount.cashbox])
                  .firstOrNull
                  ?.cashFils ??
              0;
          if (d.txCount == 0) {
            return Text(l.noMovesToday,
                style: const TextStyle(color: AppColors.textMuted));
          }
          return _statGrid([
            _Stat(l.todaySales, '${formatGrams(d.soldNetMg)} $g',
                sub: d.soldPieces > 0 ? l.piecesCount(d.soldPieces) : null,
                color: AppColors.goldDark),
            _Stat(l.dailyCashTotal,
                '${formatDinars(netCash + d.cashOutFils)} $jd',
                sub: l.dailyCashHint),
            _Stat(l.netCash, '${formatDinars(netCash)} $jd',
                color: AppColors.goldDark),
            _Stat(l.cashIn, '${formatDinars(d.cashInFils)} $jd'),
            _Stat(l.expensesToday, '${formatDinars(d.expensesFils)} $jd',
                sub: d.cashOutFils - d.expensesFils == 0
                    ? null
                    : '${l.cashPaidParties}: ${formatDinars(d.cashOutFils - d.expensesFils)}'),
            _Stat(l.receivedScrap, '${formatGrams(d.scrapInMg)} $g'),
            _Stat(l.movementsToday, '${d.txCount}',
                sub: d.goodsInNetMg > 0
                    ? '${l.goodsIn}: ${formatGrams(d.goodsInNetMg)} $g'
                    : null),
          ]);
        },
      ),
    );
  }
}

class _BagCard extends ConsumerWidget {
  const _BagCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final bagId =
        ref.watch(systemAccountsProvider).valueOrNull?[SystemAccount.shanta];
    if (bagId == null) return const SizedBox.shrink();
    final stock = ref.watch(itemStockProvider(bagId));
    final capital =
        (ref.watch(balancesProvider).valueOrNull ?? const <AccountBalance>[])
                .where((b) => b.accountId == bagId)
                .firstOrNull
                ?.cashFils ??
            0;

    return _Section(
      title: l.tabBag,
      icon: Icons.work_rounded,
      child: AsyncBody<List<ItemStock>>(
        value: stock,
        onRetry: () => ref.invalidate(itemStockProvider(bagId)),
        data: (rows) {
          final goods = rows.where((r) => r.itemId != null);
          final scrap = rows.where((r) => r.itemId == null);
          final pieces = goods.fold<int>(0, (a, r) => a + r.quantity);
          final net = goods.fold<int>(0, (a, r) => a + r.netMg);
          final scrapNet = scrap.fold<int>(0, (a, r) => a + r.netMg);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _statGrid([
                _Stat(l.totalPieces, '$pieces'),
                _Stat(l.goodsNet24, '${formatGrams(net)} ${l.gramsUnit}',
                    color: AppColors.goldDark),
                _Stat(l.scrapInBag, '${formatGrams(scrapNet)} ${l.gramsUnit}'),
                _Stat(l.bagCapital, '${formatDinars(capital)} ${l.dinarUnit}'),
              ]),
              // الكسر مفروزاً بعياراته
              if (scrap.any((r) => r.grossMg != 0)) ...[
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 6, children: [
                  for (final r in scrap)
                    if (r.grossMg != 0)
                      Pill(
                        '${r.karatName ?? l.scrapInBag}: '
                        '${formatGrams(r.grossMg)} ${l.gramsUnit}'
                        ' · ${l.net24} ${formatGrams(r.netMg)}',
                        fg: AppColors.textSecondary,
                        bg: AppColors.surfaceMuted,
                      ),
                ]),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ReceivablesCard extends ConsumerWidget {
  const _ReceivablesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final balances = ref.watch(balancesProvider);

    return _Section(
      title: l.receivablesSummary,
      icon: Icons.account_balance_wallet_outlined,
      child: AsyncBody<List<AccountBalance>>(
        value: balances,
        onRetry: () => ref.invalidate(balancesProvider),
        data: (all) {
          Widget kindRow(AccountKind k, String label) {
            final rows = all.where((b) => b.kind == k);
            final gold = rows.fold<int>(0, (a, b) => a + b.goldMg);
            final cash = rows.fold<int>(0, (a, b) => a + b.cashFils);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                SizedBox(
                  width: 70,
                  child: Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                Expanded(
                  child: Text(goldPhrase(l, gold),
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: balanceColor(gold))),
                ),
                Expanded(
                  child: Text(cashPhrase(l, cash),
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: balanceColor(cash))),
                ),
              ]),
            );
          }

          // أكبر المدينين لنا بالذهب
          final top = all
              .where((b) =>
                  (b.kind == AccountKind.showroom ||
                      b.kind == AccountKind.trader ||
                      b.kind == AccountKind.factory) &&
                  b.goldMg > 0)
              .toList()
            ..sort((a, b) => b.goldMg.compareTo(a.goldMg));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              kindRow(AccountKind.showroom, l.tabShops),
              const Divider(height: 1),
              kindRow(AccountKind.trader, l.tabTraders),
              const Divider(height: 1),
              kindRow(AccountKind.factory, l.bagWorkshops),
              if (top.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(l.topDebtors,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                for (final b in top.take(5))
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () async {
                      final acc = (await ref.read(accountsProvider.future))
                          .where((a) => a.id == b.accountId)
                          .firstOrNull;
                      if (acc == null || !context.mounted) return;
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PartyLedgerPage(account: acc)));
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(children: [
                        Expanded(
                          child: Text(b.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        Text(goldPhrase(l, b.goldMg),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.goldDark)),
                        if (b.cashFils != 0) ...[
                          const SizedBox(width: 10),
                          Text(cashPhrase(l, b.cashFils),
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: balanceColor(b.cashFils))),
                        ],
                      ]),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _ChequesCard extends ConsumerWidget {
  const _ChequesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cheques = ref.watch(pendingChequesProvider).valueOrNull;
    if (cheques == null || cheques.isEmpty) return const SizedBox.shrink();

    final overdue = cheques.where((c) => c.isOverdue).toList();
    final soon = cheques.where((c) => c.isDueSoon).toList();
    int sum(Iterable<Cheque> x) => x.fold(0, (a, c) => a + c.amountFils);

    return _Section(
      title: l.tabCheques,
      icon: Icons.receipt_long_outlined,
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ChequesPage())),
      child: _statGrid([
        _Stat(l.chequesOverdue, '${overdue.length}',
            sub: '${formatDinars(sum(overdue))} ${l.dinarUnit}',
            color: overdue.isEmpty ? null : AppColors.error),
        _Stat(l.chequesThisWeek, '${soon.length}',
            sub: '${formatDinars(sum(soon))} ${l.dinarUnit}',
            color: soon.isEmpty ? null : AppColors.goldDark),
      ]),
    );
  }
}

class _RecentCard extends ConsumerWidget {
  const _RecentCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final recent = ref.watch(recentTxProvider);

    return _Section(
      title: l.recentMovements,
      icon: Icons.history_rounded,
      child: AsyncBody<List<RecentTx>>(
        value: recent,
        onRetry: () => ref.invalidate(recentTxProvider),
        data: (rows) {
          if (rows.isEmpty) {
            return Text(l.noMovements,
                style: const TextStyle(color: AppColors.textMuted));
          }
          return Column(children: [
            for (final t in rows)
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: t.partyId == null
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TransactionDetailPage(
                                txId: t.id, partyId: t.partyId!),
                          ),
                        ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.goldContainer,
                      child:
                          Icon(_icon(t), size: 18, color: AppColors.goldDark),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [
                              t.type.label,
                              if (t.partyName != null) t.partyName!
                            ].join(' — '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                decoration: t.isReversed
                                    ? TextDecoration.lineThrough
                                    : null),
                          ),
                          Text(
                            '${ltrIsolate(formatDate(t.occurredAt))}  ·  ${ltrIsolate('#${t.docNumber}')}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ),
          ]);
        },
      ),
    );
  }

  IconData _icon(RecentTx t) => switch (t.type) {
        TxType.sale => Icons.sell_rounded,
        TxType.goodsIn => Icons.move_to_inbox_rounded,
        TxType.goodsReturn => Icons.assignment_return_rounded,
        TxType.cashPayment => Icons.payments_outlined,
        TxType.goldPayment => Icons.recycling_rounded,
        TxType.pricing => Icons.lock_clock_outlined,
        TxType.reversal => Icons.undo_rounded,
        _ => Icons.swap_horiz_rounded,
      };
}
