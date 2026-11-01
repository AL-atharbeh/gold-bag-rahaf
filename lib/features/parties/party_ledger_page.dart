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
import '../bag/goods_in_page.dart';
import '../common/ui.dart';
import '../factors/karat_factors_page.dart';
import '../shops/shop_sale_page.dart';
import '../traders/trader_tx_page.dart';
import '../statements/statement_page.dart';
import 'balance_widgets.dart';
import 'transaction_detail_page.dart';

/// حركة واحدة على حساب الطرف — مجموع سطورها في الدفترين.
class _Movement {
  _Movement(this.line);

  final StatementLine line;
  int gold = 0;
  int cash = 0;
  int goldAfter = 0;
  int cashAfter = 0;
}

/// دفتر طرف (محل، مشغل…): رصيدان دائمان — ذهب ونقد — وتحتهما
/// الحركات من الأحدث، مع الرصيد بعد كل حركة.
class PartyLedgerPage extends ConsumerWidget {
  const PartyLedgerPage({super.key, required this.account});

  final Account account;

  Future<void> _newMovement(BuildContext context, WidgetRef ref) async {
    if (account.kind == AccountKind.trader ||
        account.kind == AccountKind.factory) {
      await showTraderOps(context, account);
      return;
    }
    if (account.kind == AccountKind.showroom) {
      await showShopOps(context, account);
      return;
    }
    final page = switch (account.kind) {
      AccountKind.showroom => ShopSalePage(shopId: account.id),
      AccountKind.factory => GoodsInPage(workshopId: account.id),
      _ => null,
    };
    if (page == null) return;
    final saved = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => page));
    if (saved == true) ref.invalidate(statementProvider(account.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lines = ref.watch(statementProvider(account.id));
    final balance =
        (ref.watch(balancesProvider).valueOrNull ?? const <AccountBalance>[])
            .where((b) => b.accountId == account.id)
            .firstOrNull;

    final action = switch (account.kind) {
      AccountKind.showroom => (l.shopOps, Icons.swap_vert_rounded),
      AccountKind.factory => (l.goodsIn, Icons.move_to_inbox_rounded),
      AccountKind.trader => (l.traderOps, Icons.swap_vert_rounded),
      _ => null,
    };

    void refresh() {
      ref.invalidate(statementProvider(account.id));
      ref.invalidate(balancesProvider);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(account.name),
        actions: [
          IconButton(
            tooltip: l.accountStatement,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => StatementPage(account: account)),
            ),
          ),
          IconButton(
            tooltip: 'معاملات العيار',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => KaratFactorsPage(
                    accountId: account.id, accountName: account.name),
              ),
            ),
          ),
          IconButton(
              tooltip: l.retry,
              icon: const Icon(Icons.refresh_rounded),
              onPressed: refresh),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: action == null
          ? null
          : FloatingActionButton.extended(
              heroTag: 'fab-party-${account.id}',
              onPressed: () => _newMovement(context, ref),
              icon: Icon(action.$2),
              label: Text(action.$1,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
      body: AsyncBody<List<StatementLine>>(
        value: lines,
        onRetry: refresh,
        data: (rows) {
          final moves =
              _group(rows, balance?.goldMg ?? 0, balance?.cashFils ?? 0);
          return RefreshIndicator(
            onRefresh: () async => refresh(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                BalanceChips(
                  goldMg: balance?.goldMg ?? 0,
                  cashFils: balance?.cashFils ?? 0,
                  large: true,
                ),
                const SizedBox(height: 20),
                SectionTitle(l.movements),
                if (moves.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Text(l.noMovements,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted)),
                  )
                else
                  for (final m in moves) ...[
                    _MovementTile(
                      m: m,
                      l: l,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TransactionDetailPage(
                              txId: m.line.txId, partyId: account.id),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// يجمع سطور الكشف في حركات من الأحدث، ويحسب الرصيد بعد كل حركة
  /// رجوعاً من الرصيد الحالي الفعلي — فيبقى صحيحاً حتى لو لم يُحمَّل
  /// إلا آخر الحركات.
  List<_Movement> _group(List<StatementLine> lines, int goldNow, int cashNow) {
    final byTx = <String, _Movement>{};
    for (final s in lines) {
      final m = byTx.putIfAbsent(s.txId, () => _Movement(s));
      if (s.ledger == LedgerKind.gold) {
        m.gold += s.amount;
      } else {
        m.cash += s.amount;
      }
    }
    final newestFirst = byTx.values.toList()
      ..sort((a, b) {
        final c = b.line.occurredAt.compareTo(a.line.occurredAt);
        return c != 0 ? c : b.line.docNumber.compareTo(a.line.docNumber);
      });
    var gold = goldNow;
    var cash = cashNow;
    for (final m in newestFirst) {
      m.goldAfter = gold;
      m.cashAfter = cash;
      gold -= m.gold;
      cash -= m.cash;
    }
    return newestFirst;
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.m, required this.l, required this.onTap});

  final _Movement m;
  final AppLocalizations l;
  final VoidCallback onTap;

  String _signed(int v, String Function(int) fmt, String unit) =>
      '${v > 0 ? '+' : '−'}${fmt(v.abs())} $unit';

  @override
  Widget build(BuildContext context) {
    final s = m.line;
    final strike = s.isReversed ? TextDecoration.lineThrough : null;

    return GoldCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.note == noteFixGold || s.note == noteFixScrap
                      ? s.note!
                      : s.txType.label,
                  style: TextStyle(
                      fontWeight: FontWeight.w800, decoration: strike),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    formatDate(s.occurredAt),
                    '#${s.docNumber}',
                    if (s.note != null && s.note!.isNotEmpty) s.note!,
                  ].join('  ·  '),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 4, children: [
                  if (m.gold != 0)
                    Pill(
                      '${l.goldChange}: ${_signed(m.gold, formatGrams, l.gramsUnit)}',
                      fg: balanceColor(m.gold),
                      bg: AppColors.goldContainer,
                    ),
                  if (m.cash != 0)
                    Pill(
                      '${l.cashChange}: ${_signed(m.cash, formatDinars, l.dinarUnit)}',
                      fg: balanceColor(m.cash),
                      bg: AppColors.surfaceMuted,
                    ),
                ]),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // الرصيد بعد الحركة
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(l.balanceAfter,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(goldPhrase(l, m.goldAfter),
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: balanceColor(m.goldAfter))),
              Text(cashPhrase(l, m.cashAfter),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: balanceColor(m.cashAfter))),
            ],
          ),
        ],
      ),
    );
  }
}
