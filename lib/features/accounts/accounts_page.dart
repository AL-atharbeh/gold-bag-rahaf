import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/locale.dart';
import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/units.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../common/balance_text.dart';
import 'new_account_dialog.dart';
import '../bag/goods_in_page.dart';
import '../parties/party_ledger_page.dart';
import '../pdf/pdf_kit.dart';
import '../pdf/reports_pdf.dart';
import '../traders/trader_tx_page.dart';

/// قائمة أطراف من نوع واحد: محلات، أو تجار، أو مشاغل.
///
/// بلا [kind] تعرض كل الأطراف كما كانت. [showAppBar] = false حين تكون
/// داخل صفحة لها شريطها (المشاغل داخل الشنطة).
class AccountsPage extends ConsumerWidget {
  const AccountsPage({
    super.key,
    this.kind,
    this.title = 'الموزّعون',
    this.addLabel = 'طرف جديد',
    this.emptyTitle = 'لا يوجد أطراف أو موزّعون بعد',
    this.emptyHint = 'أضف محل عرض أو تاجراً أو مصنعاً للبدء.',
    this.showAppBar = true,
  });

  final AccountKind? kind;
  final String title;
  final String addLabel;
  final String emptyTitle;
  final String emptyHint;
  final bool showAppBar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(counterpartiesProvider);
    final accounts = kind == null
        ? all
        : all.whenData((l) => l.where((a) => a.kind == kind).toList());
    final balances = ref.watch(balancesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: !showAppBar
          ? null
          : AppBar(
              title: Text(title),
              actions: [
                if (kind != null)
                  IconButton(
                    tooltip: 'PDF',
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    onPressed: () {
                      final list = accounts.valueOrNull ?? const <Account>[];
                      final bals =
                          balances.valueOrNull ?? const <AccountBalance>[];
                      final issuer = PdfIssuer.of(ref);
                      PdfPreviewPage.open(
                        context,
                        title: title,
                        build: (arabic, format) => buildBalancesPdf(
                          title: balancesTitle(kind!, arabic),
                          rows: [
                            for (final a in list)
                              (
                                a,
                                bals
                                    .where((b) => b.accountId == a.id)
                                    .firstOrNull
                              ),
                          ],
                          issuer: issuer,
                          arabic: arabic,
                          format: format,
                        ),
                        fileName: (arabic) =>
                            '${pdfSafeName(balancesTitle(kind!, arabic))}-${pdfDateTag(DateTime.now())}.pdf',
                      );
                    },
                  ),
                IconButton(
                  tooltip: 'تحديث',
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () => ref.invalidate(accountsProvider),
                ),
                const SizedBox(width: 8),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-accounts-${kind?.wire ?? 'all'}',
        onPressed: () => showDialog<bool>(
          context: context,
          builder: (_) => NewAccountDialog(kind: kind),
        ),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(
          addLabel,
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: accounts.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.goldPrimary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('خطأ: $e'),
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
                          Icons.storefront_rounded,
                          size: 40,
                          color: AppColors.goldDark,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        emptyTitle,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        emptyHint,
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

          final byId = {
            for (final b in balances.valueOrNull ?? const <AccountBalance>[])
              b.accountId: b,
          };

          return RefreshIndicator(
            color: AppColors.goldPrimary,
            backgroundColor: Colors.white,
            onRefresh: () async {
              ref.invalidate(counterpartiesProvider);
              ref.invalidate(balancesProvider);
            },
            child: ListView.builder(
              key: PageStorageKey('accounts-page-list-${kind?.wire ?? 'all'}'),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final a = list[i];
                final b = byId[a.id];
                final consign = a.consignmentAccountId == null
                    ? null
                    : byId[a.consignmentAccountId!];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border, width: 1.2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x05000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            // دفتر برصيدين ذهب ونقد وحركاته
                            builder: (_) => PartyLedgerPage(account: a),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // أفاتار بنقش ذهبي
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                  color: AppColors.goldContainer,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.goldBorder,
                                    width: 1.2,
                                  ),
                                ),
                                child: Icon(
                                  switch (a.kind) {
                                    AccountKind.showroom =>
                                      Icons.storefront_rounded,
                                    AccountKind.factory =>
                                      Icons.precision_manufacturing_rounded,
                                    _ => Icons.person_rounded,
                                  },
                                  color: AppColors.goldDark,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          a.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.goldContainer,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: AppColors.goldBorder,
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            a.kind.label,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.goldDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (b != null) ...[
                                      const SizedBox(height: 6),
                                      for (final line in describeBalance(b))
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Text(
                                            line,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  line.startsWith('له علينا') ||
                                                          line.startsWith('عجز')
                                                      ? AppColors.error
                                                      : AppColors.goldDark,
                                            ),
                                          ),
                                        ),
                                    ],
                                    if (consign != null &&
                                        consign.goldMg != 0) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceMuted,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'عهدة معروضة: ${formatGrams(consign.goldMg)} غ صافي',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // تسجيل حركة دون فتح الدفتر — أكثر ما يُفعل
                              // في القائمة هو قيد بضاعة أو تسليم.
                              TextButton.icon(
                                onPressed: () => a.kind == AccountKind.trader
                                    ? showTraderOps(context, a)
                                    : a.kind == AccountKind.showroom
                                        ? showShopOps(context, a)
                                        : Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  GoodsInPage(workshopId: a.id),
                                            ),
                                          ),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: Text(switch (a.kind) {
                                  AccountKind.showroom => context.l10n.movement,
                                  AccountKind.factory => 'وارد',
                                  _ => 'حركة',
                                }),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.goldDark,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  textStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_left_rounded,
                                color: AppColors.textMuted,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
