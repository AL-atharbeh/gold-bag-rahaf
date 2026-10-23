import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/locale.dart';
import '../../domain/models.dart';
import '../../l10n/app_localizations.dart';
import '../pdf/pdf_kit.dart';
import '../common/inputs.dart';
import '../common/ui.dart';
import '../parties/balance_widgets.dart';
import '../reports/period_picker.dart';
import 'account_statement.dart';
import 'statement_pdf.dart';

/// كشف حساب طرف لفترة يختارها الموزّع — يُعرض ملخصه ثم يُصدَّر PDF.
class StatementPage extends ConsumerStatefulWidget {
  const StatementPage({super.key, required this.account});

  final Account account;

  @override
  ConsumerState<StatementPage> createState() => _StatementPageState();
}

class _StatementPageState extends ConsumerState<StatementPage> {
  Period _period = Period.of(PeriodPreset.thisMonth);

  AccountStatement? _st;
  Object? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final from = _period.from;
    final to = _period.to;
    if (!_period.valid) {
      setState(() {
        _st = null;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(repositoryProvider);
      final since = await repo.statementSince(widget.account.id, from);
      ref.invalidate(balancesProvider);
      final balances = await ref.read(balancesProvider.future);
      final b =
          balances.where((x) => x.accountId == widget.account.id).firstOrNull;
      if (!mounted) return;
      setState(() {
        _st = AccountStatement.build(
          from: from,
          to: to,
          since: since,
          goldNow: b?.goldMg ?? 0,
          cashNow: b?.cashFils ?? 0,
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _preview(AppLocalizations l) {
    final st = _st;
    if (st == null) return;
    final issuer = PdfIssuer.of(ref);
    PdfPreviewPage.open(
      context,
      title: '${l.accountStatement} — ${widget.account.name}',
      build: (arabic, format) => buildStatementPdf(
        st: st,
        account: widget.account,
        issuer: issuer,
        arabic: arabic,
        format: format,
      ),
      fileName: (arabic) => statementFileName(widget.account, st, arabic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final st = _st;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar:
          AppBar(title: Text('${l.accountStatement} — ${widget.account.name}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionTitle(l.statementPeriod),
                  PeriodPicker(
                    value: _period,
                    onChanged: (p) {
                      setState(() => _period = p);
                      _load();
                    },
                  ),
                  const SizedBox(height: 18),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    CenteredMessage(
                      icon: Icons.error_outline_rounded,
                      title: readableError(_error!),
                      action:
                          TextButton(onPressed: _load, child: Text(l.retry)),
                    )
                  else if (st != null) ...[
                    _Summary(st: st, l: l),
                    const SizedBox(height: 10),
                    Text(l.statementHint,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _preview(l),
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: Text(l.previewPdf),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.st, required this.l});

  final AccountStatement st;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, int gold, int cash, {bool strong = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Expanded(
              flex: 4,
              child: Text(label,
                  style: TextStyle(
                      fontWeight: strong ? FontWeight.w800 : FontWeight.w600)),
            ),
            Expanded(
              flex: 5,
              child: Text(goldPhrase(l, gold),
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: balanceColor(gold))),
            ),
            Expanded(
              flex: 5,
              child: Text(cashPhrase(l, cash),
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: balanceColor(cash))),
            ),
          ]),
        );

    return GoldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            const Expanded(flex: 4, child: SizedBox()),
            Expanded(
                flex: 5,
                child: Text(l.goldBalance,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted))),
            Expanded(
                flex: 5,
                child: Text(l.cashBalance,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted))),
          ]),
          row(l.openingBalance, st.openingGold, st.openingCash),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text('${l.periodMovements}: ${st.rows.length}',
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          const Divider(height: 1),
          row(l.closingBalance, st.closingGold, st.closingCash, strong: true),
        ],
      ),
    );
  }
}
