import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/locale.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../platform/platform_models.dart';
import '../bag/bag_inventory.dart';
import '../bags/bags_page.dart';
import '../cheques/cheques_page.dart';
import '../common/ui.dart';
import '../pdf/pdf_kit.dart';
import '../pdf/reports_pdf.dart';
import '../statements/statement_page.dart';
import 'bag_statement_page.dart';
import 'sales_report_page.dart';

/// كل التقارير والكشوفات في مكان واحد.
class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    void push(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(l.reports)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionTitle(l.accountStatements),
                  _Tile(
                    icon: Icons.storefront_outlined,
                    title: l.shopStatement,
                    subtitle: l.statementTileHint,
                    onTap: () => pickPartyForStatement(
                        context, ref, AccountKind.showroom),
                  ),
                  _Tile(
                    icon: Icons.handshake_outlined,
                    title: l.traderStatement,
                    subtitle: l.statementTileHint,
                    onTap: () =>
                        pickPartyForStatement(context, ref, AccountKind.trader),
                  ),
                  _Tile(
                    icon: Icons.precision_manufacturing_outlined,
                    title: l.workshopStatement,
                    subtitle: l.statementTileHint,
                    onTap: () => pickPartyForStatement(
                        context, ref, AccountKind.factory),
                  ),
                  SectionTitle(l.salesAndBag),
                  _Tile(
                    icon: Icons.insights_rounded,
                    title: l.salesReport,
                    subtitle: l.salesReportHint,
                    onTap: () => push(const SalesReportPage()),
                  ),
                  _Tile(
                    icon: Icons.work_history_outlined,
                    title: l.bagStatement,
                    subtitle: l.bagStatementHint,
                    onTap: () => push(const BagStatementPage()),
                  ),
                  _Tile(
                    icon: Icons.inventory_2_outlined,
                    title: l.bagInventoryNow,
                    subtitle: l.bagInventoryHint,
                    onTap: () => openBagStockPdf(context, ref),
                  ),
                  SectionTitle(l.receivablesSummary),
                  _Tile(
                    icon: Icons.storefront_outlined,
                    title: l.shopsBalances,
                    onTap: () =>
                        openBalancesPdf(context, ref, AccountKind.showroom),
                  ),
                  _Tile(
                    icon: Icons.handshake_outlined,
                    title: l.tradersBalances,
                    onTap: () =>
                        openBalancesPdf(context, ref, AccountKind.trader),
                  ),
                  _Tile(
                    icon: Icons.receipt_long_outlined,
                    title: l.tabCheques,
                    subtitle: l.chequesReportHint,
                    onTap: () => push(const ChequesPage()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// يختار محلاً أو تاجراً أو مشغلاً ثم يفتح كشف حسابه.
Future<void> pickPartyForStatement(
    BuildContext context, WidgetRef ref, AccountKind kind) async {
  final l = context.l10n;
  final list = (await ref.read(accountsProvider.future))
      .where((a) => a.kind == kind)
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));
  if (!context.mounted) return;
  if (list.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.noAccountsOfKind)));
    return;
  }
  final a = await showModalBottomSheet<Account>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.7),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(l.chooseAccount,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
            ),
            for (final x in list)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.goldContainer,
                  child: Icon(Icons.person_rounded, color: AppColors.goldDark),
                ),
                title: Text(x.name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                onTap: () => Navigator.pop(ctx, x),
              ),
          ],
        ),
      ),
    ),
  );
  if (a != null && context.mounted) {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => StatementPage(account: a)));
  }
}

/// جرد الشنطة الآن PDF: البضاعة والكسر والكاش والشيكات.
void openBagStockPdf(BuildContext context, WidgetRef ref) {
  final bagId =
      ref.read(systemAccountsProvider).valueOrNull?[SystemAccount.shanta];
  if (bagId == null) return;
  final issuer = PdfIssuer.of(ref);
  final holder = (ref.read(bagsProvider).valueOrNull ?? const <Bag>[])
      .where((b) => b.accountId == bagId)
      .firstOrNull
      ?.holderName;
  PdfPreviewPage.open(
    context,
    title: context.l10n.bagInventoryNow,
    build: (arabic, format) async {
      final inv = await ref.read(bagInventoryProvider.future);
      return buildStockPdf(
        inv: inv!,
        holderName: holder,
        issuer: issuer,
        arabic: arabic,
        format: format,
      );
    },
    fileName: (arabic) =>
        '${arabic ? 'جرد-الشنطة' : 'bag-inventory'}-${pdfDateTag(DateTime.now())}.pdf',
  );
}

/// ذمم المحلات أو التجار PDF.
void openBalancesPdf(BuildContext context, WidgetRef ref, AccountKind kind) {
  final issuer = PdfIssuer.of(ref);
  PdfPreviewPage.open(
    context,
    title: balancesTitle(kind, context.isArabic),
    build: (arabic, format) async {
      final list = (await ref.read(accountsProvider.future))
          .where((a) => a.kind == kind);
      final bals = await ref.read(balancesProvider.future);
      return buildBalancesPdf(
        title: balancesTitle(kind, arabic),
        rows: [
          for (final a in list)
            (a, bals.where((b) => b.accountId == a.id).firstOrNull),
        ],
        issuer: issuer,
        arabic: arabic,
        format: format,
      );
    },
    fileName: (arabic) =>
        '${pdfSafeName(balancesTitle(kind, arabic))}-${pdfDateTag(DateTime.now())}.pdf',
  );
}

class _Tile extends StatelessWidget {
  const _Tile(
      {required this.icon, required this.title, this.subtitle, this.onTap});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GoldCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Icon(icon, color: AppColors.goldDark),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          const Icon(Icons.picture_as_pdf_outlined,
              size: 20, color: AppColors.textMuted),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ]),
      ),
    );
  }
}
