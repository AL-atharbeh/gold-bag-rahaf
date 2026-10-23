import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/locale.dart';
import '../../core/units.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../accounts/accounts_page.dart';
import '../common/ui.dart';
import '../../platform/platform_models.dart';
import '../../platform/session.dart';
import '../bags/bags_page.dart';
import '../reports/sales_report_page.dart';
import '../bagday/bag_day_state.dart';
import '../bagday/day_pages.dart';
import '../bagday/expense_page.dart';
import '../reports/reports_page.dart';
import 'bag_inventory.dart';
import 'goods_in_page.dart';

/// الشنطة بتبويبين: المخزون (ما فيها الآن ووارد البضاعة)، والمشاغل
/// التي تأتي منها البضاعة — كل مشغل طرف له دفتره كأي تاجر.
class BagPage extends ConsumerWidget {
  const BagPage({super.key});

  void _stockPdf(BuildContext context, WidgetRef ref) =>
      openBagStockPdf(context, ref);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(l.tabBag),
          actions: [
            IconButton(
              tooltip: 'PDF',
              icon: const Icon(Icons.picture_as_pdf_outlined),
              onPressed: () => _stockPdf(context, ref),
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            labelColor: AppColors.goldDark,
            indicatorColor: AppColors.goldPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800),
            tabs: [
              Tab(
                  icon: const Icon(Icons.inventory_2_outlined, size: 20),
                  text: l.bagStock),
              Tab(
                  icon: const Icon(Icons.precision_manufacturing_outlined,
                      size: 20),
                  text: l.bagWorkshops),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _StockView(),
            AccountsPage(
              kind: AccountKind.factory,
              title: l.bagWorkshops,
              addLabel: l.newWorkshop,
              emptyTitle: l.noWorkshops,
              emptyHint: l.noWorkshopsHint,
              showAppBar: false,
            ),
          ],
        ),
      ),
    );
  }
}

/// جرد الشنطة الآن: البضاعة صنفاً صنفاً، والكسر عياراً عياراً، والنقد
/// والشيكات التي بحوزة حاملها، ورأس المال المدفوع مصنوعيةً.
class _StockView extends ConsumerWidget {
  const _StockView();

  Future<void> _goodsIn(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GoodsInPage()),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final bagId =
        ref.watch(systemAccountsProvider).valueOrNull?[SystemAccount.shanta];
    final inv = ref.watch(bagInventoryProvider);

    // الشنطة لبائع واحد: حاملها وحده يُدخل إليها ويبيع منها
    final me = ref.watch(sessionProvider).valueOrNull?.userId;
    final bagInfo = (ref.watch(bagsProvider).valueOrNull ?? const <Bag>[])
        .where((b) => b.accountId == bagId)
        .firstOrNull;
    final isHolder =
        bagInfo?.holderUserId == null || bagInfo!.holderUserId == me;

    void refresh() {
      ref.invalidate(bagsProvider);
      ref.invalidate(itemStockProvider);
      ref.invalidate(balancesProvider);
      ref.invalidate(pendingChequesProvider);
      ref.invalidate(bagInventoryProvider);
    }

    final g = l.gramsUnit;
    final jd = l.dinarUnit;
    final todaySummary = ref.watch(daySummaryProvider(today())).valueOrNull;
    final last = ref.watch(latestBagDayProvider).valueOrNull;
    final openDay = last != null && !last.isClosed && sameDay(last.day, today())
        ? last
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: !isHolder
          ? null
          : FloatingActionButton.extended(
              heroTag: 'fab-goods-in',
              onPressed: () => _goodsIn(context),
              icon: const Icon(Icons.move_to_inbox_rounded),
              label: Text(l.goodsIn,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
      body: AsyncBody<BagInventory?>(
        value: inv,
        onRetry: refresh,
        data: (b) {
          if (b == null || b.isEmpty) {
            return CenteredMessage(
              icon: Icons.work_outline_rounded,
              title: l.bagEmpty,
              body: l.bagEmptyHint,
              action: FilledButton.icon(
                onPressed: () => _goodsIn(context),
                icon: const Icon(Icons.move_to_inbox_rounded, size: 18),
                label: Text(l.goodsIn),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              children: [
                if (bagInfo?.holderName != null &&
                    bagInfo!.holderName!.isNotEmpty) ...[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Pill('${l.bagHolder}: ${bagInfo.holderName}'),
                  ),
                  const SizedBox(height: 10),
                ],
                if (!isHolder) ...[
                  Text(l.onlyHolderSells,
                      style: const TextStyle(
                          color: AppColors.error, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                ],

                // ── الملخص ──
                ReportStats(stats: [
                  (
                    l.goodsInBag,
                    '${formatGrams(b.goodsNetMg)} $g',
                    l.piecesCount(b.goodsPieces)
                  ),
                  (
                    l.scrapInBag,
                    '${formatGrams(b.scrapNetMg)} $g',
                    '${l.grossWeight}: ${formatGrams(b.scrapGrossMg)}'
                  ),
                  (l.totalGoldNet, '${formatGrams(b.totalNetMg)} $g', null),
                  (l.cashInBag, '${formatDinars(b.cashFils)} $jd', null),
                  if (b.chequesInFils != 0)
                    (
                      l.chequesInHand,
                      '${formatDinars(b.chequesInFils)} $jd',
                      null
                    ),
                  (l.bagCapital, '${formatDinars(b.capitalFils)} $jd', null),
                ]),
                const SizedBox(height: 18),

                // ── الكاش والشيكات ومصاريف اليوم ──
                SectionTitle(l.cashInBag),
                GoldCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _line(l.cashInBag, '${formatDinars(b.cashFils)} $jd',
                          strong: true),
                      if (b.chequesInFils != 0)
                        _line(l.chequesInHand,
                            '${formatDinars(b.chequesInFils)} $jd'),
                      if (b.chequesOutFils != 0)
                        _line(l.chequesOutPending,
                            '${formatDinars(b.chequesOutFils)} $jd',
                            muted: true),
                      if (todaySummary != null &&
                          todaySummary.expensesFils != 0) ...[
                        const Divider(height: 16),
                        _line(l.expensesToday,
                            '${formatDinars(todaySummary.expensesFils)} $jd',
                            muted: true),
                        for (final (c, label, amount) in todaySummary.expenses)
                          Padding(
                            padding:
                                const EdgeInsetsDirectional.only(start: 12),
                            child: _line('• ${label ?? expenseLabel(l, c)}',
                                '${formatDinars(amount)} $jd',
                                muted: true),
                          ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(spacing: 10, runSpacing: 8, children: [
                        OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ExpensePage())),
                          icon: const Icon(Icons.receipt_outlined, size: 18),
                          label: Text(l.newExpense),
                        ),
                        if (openDay != null)
                          FilledButton.icon(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        CloseDayPage(day: openDay))),
                            icon:
                                const Icon(Icons.nightlight_outlined, size: 18),
                            label: Text(l.closeDay),
                          ),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── البضاعة ──
                if (b.goods.isNotEmpty) ...[
                  SectionTitle(
                      '${l.goodsInBag} · ${l.piecesCount(b.goodsPieces)}'),
                  for (final e in b.goodsByItem(l.unknownItem).entries) ...[
                    _ItemCard(name: e.key, rows: e.value, l: l),
                    const SizedBox(height: 10),
                  ],
                ],

                // ── الكسر ──
                if (b.scrap.isNotEmpty) ...[
                  SectionTitle(l.scrapInBag),
                  _ItemCard(name: l.scrap, rows: b.scrap, l: l),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _line(String label, String value,
          {bool strong = false, bool muted = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                    color: muted ? AppColors.textSecondary : null)),
          ),
          Text(value,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                  fontWeight: strong ? FontWeight.w900 : FontWeight.w700,
                  fontSize: strong ? 17 : 14,
                  color: strong ? AppColors.goldDark : null)),
        ]),
      );
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.name, required this.rows, required this.l});

  final String name;
  final List<ItemStock> rows;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final pieces = rows.fold<int>(0, (a, r) => a + r.quantity);

    return GoldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.goldContainer,
                child: Icon(Icons.diamond_outlined,
                    size: 18, color: AppColors.goldDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              if (pieces != 0) Pill(l.piecesCount(pieces)),
            ],
          ),
          const SizedBox(height: 10),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      r.karatName ?? '—',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldDark),
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      children: [
                        if (r.quantity != 0) _kv(l.count, '${r.quantity}'),
                        _kv(l.grossWeight,
                            '${formatGrams(r.grossMg)} ${l.gramsUnit}'),
                        _kv(l.net24, '${formatGrams(r.netMg)} ${l.gramsUnit}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Text.rich(
        TextSpan(children: [
          TextSpan(
              text: '$k: ',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          TextSpan(
              text: v,
              style:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      );
}
