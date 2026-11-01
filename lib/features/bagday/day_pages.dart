import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../app/providers.dart';
import '../../core/locale.dart';
import '../../core/units.dart';
import '../../domain/models.dart';
import '../../platform/labels.dart';
import '../../platform/session.dart';
import '../bag/bag_inventory.dart';
import '../common/inputs.dart';
import '../common/ui.dart';
import '../home/day_summary.dart';
import '../pdf/pdf_kit.dart';
import '../pdf/reports_pdf.dart';
import '../reports/sales_report_page.dart';
import 'bag_day_state.dart';
import 'expense_page.dart';

// ---------------------------------------------------------------------------
// فتح اليوم
// ---------------------------------------------------------------------------

/// أول ما يراه حامل الشنطة كل يوم: تأكيد الكاش المحمول معه.
/// الافتراضي ما بقي من الأمس، ويمكنه الزيادة أو النقص بسبب مكتوب.
class OpenDayPage extends ConsumerStatefulWidget {
  const OpenDayPage({super.key, this.last});

  final BagDay? last;

  @override
  ConsumerState<OpenDayPage> createState() => _OpenDayPageState();
}

class _OpenDayPageState extends ConsumerState<OpenDayPage> {
  final _form = GlobalKey<FormState>();
  final _cash = TextEditingController();
  final _note = TextEditingController();
  bool _filled = false;
  bool _saving = false;

  @override
  void dispose() {
    _cash.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _open(int expected) async {
    if (!_form.currentState!.validate()) return;
    if (!ensureOnline(context, ref)) return;
    setState(() => _saving = true);
    try {
      await ref.read(repositoryProvider).openBagDay(
          today(), parseDinars(_cash.text) ?? 0,
          note: _note.text.trim());
      invalidateBagDay(ref);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(readableError(e)), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final inv = ref.watch(bagInventoryProvider);
    final name = ref.watch(activeMembershipProvider)?.displayName ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l.openDay),
        actions: [
          TextButton(
            onPressed: () => ref.read(sessionProvider.notifier).signOut(),
            child: Text(l.signOut),
          ),
        ],
      ),
      body: AsyncBody<BagInventory?>(
        value: inv,
        onRetry: () => ref.invalidate(bagInventoryProvider),
        data: (b) {
          final expected = b?.cashFils ?? 0;
          if (!_filled) {
            _cash.text = formatDinars(expected);
            _filled = true;
          }
          final entered = parseDinars(_cash.text) ?? 0;
          final diff = entered - expected;

          return Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                            name.isEmpty
                                ? l.goodMorning
                                : l.goodMorningName(name),
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900)),
                        Text(
                            '${l.openDayFor} ${ltrIsolate(formatDate(today()))}',
                            style: const TextStyle(
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 16),
                        if (b != null)
                          ReportStats(stats: [
                            (
                              l.goodsInBag,
                              '${formatGrams(b.goodsNetMg)} ${l.gramsUnit}',
                              l.piecesCount(b.goodsPieces)
                            ),
                            (
                              l.scrapInBag,
                              '${formatGrams(b.scrapNetMg)} ${l.gramsUnit}',
                              null
                            ),
                            if (b.chequesInFils != 0)
                              (
                                l.chequesInHand,
                                '${formatDinars(b.chequesInFils)} ${l.dinarUnit}',
                                null
                              ),
                          ]),
                        const SizedBox(height: 18),
                        SectionTitle(l.cashYouCarry),
                        GoldCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                  '${l.cashLeftYesterday}: ${formatDinars(expected)} ${l.dinarUnit}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary)),
                              const SizedBox(height: 12),
                              DinarsField(
                                controller: _cash,
                                label: l.cashYouCarry,
                                allowZero: true,
                                onChanged: (_) => setState(() {}),
                              ),
                              if (diff != 0) ...[
                                const SizedBox(height: 10),
                                Text(
                                  diff > 0
                                      ? l.cashAddedNote(formatDinars(diff))
                                      : l.cashTakenNote(formatDinars(-diff)),
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: diff > 0
                                          ? AppColors.goldDark
                                          : AppColors.error),
                                ),
                                const SizedBox(height: 10),
                                TextFormField(
                                  controller: _note,
                                  decoration: InputDecoration(
                                    labelText: l.reasonRequired,
                                    prefixIcon: const Icon(Icons.notes_rounded,
                                        size: 20),
                                  ),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                          ? l.requiredField
                                          : null,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _saving ? null : () => _open(expected),
                          icon: const Icon(Icons.wb_sunny_outlined),
                          label: Text(l.startDay),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// إغلاق اليوم
// ---------------------------------------------------------------------------

/// جرد آخر اليوم — إلزامي: ملخص اليوم، وعدّ الكاش، وتأكيد البضاعة والكسر.
class CloseDayPage extends ConsumerStatefulWidget {
  const CloseDayPage({super.key, required this.day, this.mandatory = false});

  final BagDay day;

  /// يوم سابق لم يُغلق: لا رجوع منه حتى يُغلق.
  final bool mandatory;

  @override
  ConsumerState<CloseDayPage> createState() => _CloseDayPageState();
}

class _CloseDayPageState extends ConsumerState<CloseDayPage> {
  final _form = GlobalKey<FormState>();
  final _cash = TextEditingController();
  final _note = TextEditingController();
  bool _confirmed = false;
  bool _saving = false;
  bool _done = false;

  @override
  void dispose() {
    _cash.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (!_form.currentState!.validate()) return;
    final l = context.l10n;
    if (!_confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l.confirmGoodsFirst),
          backgroundColor: AppColors.error));
      return;
    }
    if (!ensureOnline(context, ref)) return;
    setState(() => _saving = true);
    try {
      await ref.read(repositoryProvider).closeBagDay(
            widget.day.day,
            parseDinars(_cash.text) ?? 0,
            goodsConfirmed: true,
            note: _note.text.trim(),
          );
      setState(() => _done = true);
      if (!widget.mandatory) invalidateBagDay(ref);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(readableError(e)), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _pdf(DaySummary d, BagInventory b, int expected) {
    final issuer = PdfIssuer.of(ref);
    final counted = parseDinars(_cash.text) ?? expected;
    PdfPreviewPage.open(
      context,
      title: context.l10n.dayReport,
      build: (arabic, format) => buildDayReportPdf(
        day: widget.day.day,
        d: d,
        inv: b,
        openingCashFils: widget.day.openingCashFils,
        expectedCashFils: expected,
        countedCashFils: counted,
        issuer: issuer,
        arabic: arabic,
        format: format,
      ),
      fileName: (arabic) =>
          '${arabic ? 'يومية' : 'day'}-${pdfDateTag(widget.day.day)}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final summary = ref.watch(daySummaryProvider(widget.day.day));
    final inv = ref.watch(bagInventoryProvider);
    final g = l.gramsUnit;
    final jd = l.dinarUnit;

    final ready = summary.valueOrNull != null && inv.valueOrNull != null;

    return PopScope(
      canPop: !widget.mandatory || _done,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          automaticallyImplyLeading: !widget.mandatory,
          title:
              Text('${l.closeDay} — ${ltrIsolate(formatDate(widget.day.day))}'),
        ),
        body: !ready
            ? AsyncBody<DaySummary>(
                value: summary,
                onRetry: () => ref.invalidate(daySummaryProvider),
                data: (_) => const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.goldPrimary)),
              )
            : () {
                final d = summary.value!;
                final b = inv.value!;
                final expected = b.cashFils;
                final counted = parseDinars(_cash.text);
                final diff = counted == null ? 0 : counted - expected;
                final paidOut = d.cashOutFils - d.expensesFils;

                return Form(
                  key: _form,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (widget.mandatory)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(l.closeOldDayFirst,
                                      style: const TextStyle(
                                          color: AppColors.error,
                                          fontWeight: FontWeight.w700)),
                                ),
                              SectionTitle(l.daySummary),
                              ReportStats(stats: [
                                (
                                  l.todaySales,
                                  '${formatGrams(d.soldNetMg)} $g',
                                  l.piecesCount(d.soldPieces)
                                ),
                                (
                                  l.receivedScrap,
                                  '${formatGrams(d.scrapInMg)} $g',
                                  null
                                ),
                                (
                                  l.cashIn,
                                  '${formatDinars(d.cashInFils)} $jd',
                                  null
                                ),
                                if (d.chequesInFils != 0)
                                  (
                                    l.chequesReceived,
                                    '${formatDinars(d.chequesInFils)} $jd',
                                    null
                                  ),
                                (
                                  l.expensesToday,
                                  '${formatDinars(d.expensesFils)} $jd',
                                  null
                                ),
                                if (paidOut != 0)
                                  (
                                    l.cashPaidParties,
                                    '${formatDinars(paidOut)} $jd',
                                    null
                                  ),
                                (
                                  l.dailyCashTotal,
                                  '${formatDinars(expected + d.cashOutFils)} $jd',
                                  l.dailyCashHint
                                ),
                                (
                                  l.netCash,
                                  '${formatDinars(expected)} $jd',
                                  null
                                ),
                              ]),
                              if (d.expenses.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                GoldCard(
                                  child: Column(children: [
                                    for (final (c, label, amount) in d.expenses)
                                      ReportRow(
                                        title: label ?? expenseLabel(l, c),
                                        value: '${formatDinars(amount)} $jd',
                                      ),
                                  ]),
                                ),
                              ],
                              const SizedBox(height: 16),
                              SectionTitle(l.bagCount),
                              GoldCard(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ReportRow(
                                      title: l.goodsInBag,
                                      sub: l.piecesCount(b.goodsPieces),
                                      value: '${formatGrams(b.goodsNetMg)} $g',
                                    ),
                                    ReportRow(
                                      title: l.scrapInBag,
                                      sub:
                                          '${l.grossWeight}: ${formatGrams(b.scrapGrossMg)}',
                                      value: '${formatGrams(b.scrapNetMg)} $g',
                                    ),
                                    if (b.chequesInFils != 0)
                                      ReportRow(
                                        title: l.chequesInHand,
                                        value:
                                            '${formatDinars(b.chequesInFils)} $jd',
                                      ),
                                    CheckboxListTile(
                                      value: _confirmed,
                                      onChanged: _done
                                          ? null
                                          : (v) => setState(
                                              () => _confirmed = v ?? false),
                                      contentPadding: EdgeInsets.zero,
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      activeColor: AppColors.goldDark,
                                      title: Text(l.confirmGoodsScrap,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              SectionTitle(l.countCash),
                              GoldCard(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                        '${l.cashExpected}: ${formatDinars(expected)} $jd',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 10),
                                    Row(children: [
                                      Expanded(
                                        child: DinarsField(
                                          controller: _cash,
                                          label: l.cashCounted,
                                          allowZero: true,
                                          onChanged: (_) => setState(() {}),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: _done
                                            ? null
                                            : () => setState(() => _cash.text =
                                                formatDinars(expected)),
                                        child: Text(l.matches),
                                      ),
                                    ]),
                                    if (counted != null && diff != 0) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        diff < 0
                                            ? l.cashShortage(
                                                formatDinars(-diff))
                                            : l.cashSurplus(formatDinars(diff)),
                                        style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: diff < 0
                                                ? AppColors.error
                                                : AppColors.goldDark),
                                      ),
                                      const SizedBox(height: 10),
                                      TextFormField(
                                        controller: _note,
                                        decoration: InputDecoration(
                                          labelText: l.reasonRequired,
                                          prefixIcon: const Icon(
                                              Icons.notes_rounded,
                                              size: 20),
                                        ),
                                        validator: (v) =>
                                            (v == null || v.trim().isEmpty)
                                                ? l.requiredField
                                                : null,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              if (!_done) ...[
                                OutlinedButton.icon(
                                  onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const ExpensePage())),
                                  icon: const Icon(Icons.receipt_outlined),
                                  label: Text(l.newExpense),
                                ),
                                const SizedBox(height: 10),
                                FilledButton.icon(
                                  onPressed: _saving ? null : _close,
                                  icon: const Icon(Icons.nightlight_outlined),
                                  label: Text(l.closeDay),
                                ),
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.goldContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(l.dayClosed,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.goldDark)),
                                ),
                                const SizedBox(height: 10),
                                FilledButton.icon(
                                  onPressed: () => _pdf(d, b, expected),
                                  icon:
                                      const Icon(Icons.picture_as_pdf_rounded),
                                  label: Text(l.dayReport),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton(
                                  onPressed: () {
                                    if (widget.mandatory) {
                                      invalidateBagDay(ref);
                                    } else {
                                      Navigator.pop(context, true);
                                    }
                                  },
                                  child: Text(l.continueLabel),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }(),
      ),
    );
  }
}
