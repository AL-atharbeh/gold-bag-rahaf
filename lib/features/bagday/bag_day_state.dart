import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import '../../platform/session.dart';
import '../bags/bags_page.dart';
import '../home/day_summary.dart';

DateTime today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

bool sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// آخر يوم شنطة — يحدد هل يلزم فتح يوم أو إغلاق يوم سابق.
final latestBagDayProvider = FutureProvider.autoDispose<BagDay?>((ref) async {
  await ref.watch(tenantProvider.future);
  return ref.watch(repositoryProvider).latestBagDay();
});

/// ماذا يجب على حامل الشنطة الآن.
enum DayGateState { ready, mustOpen, mustCloseOld }

/// يُلزم حامل الشنطة (أو المالك إن لم يكن لها حامل) بفتح اليوم وإغلاقه.
final dayGateProvider =
    FutureProvider.autoDispose<(DayGateState, BagDay?)>((ref) async {
  final m = ref.watch(activeMembershipProvider);
  final me = ref.watch(sessionProvider).valueOrNull?.userId;
  final sys = await ref.watch(systemAccountsProvider.future);
  final bags = await ref.watch(bagsProvider.future);
  final bag =
      bags.where((b) => b.accountId == sys[SystemAccount.shanta]).firstOrNull;
  final holder = bag?.holderUserId;
  final isHolder = holder == null ? (m?.isOwner ?? false) : holder == me;
  if (!isHolder) return (DayGateState.ready, null);

  final last = await ref.watch(latestBagDayProvider.future);
  if (last != null && !last.isClosed && last.day.isBefore(today())) {
    return (DayGateState.mustCloseOld, last);
  }
  if (last == null || last.day.isBefore(today())) {
    return (DayGateState.mustOpen, last);
  }
  return (DayGateState.ready, last);
});

/// ملخص يوم بكل حساباته: المبيعات، والكسر، والكاش، والشيكات، والمصاريف.
final daySummaryProvider =
    FutureProvider.autoDispose.family<DaySummary, DateTime>((ref, day) async {
  await ref.watch(tenantProvider.future);
  // يُعاد الحساب بعد كل حركة (invalidateAfterPosting يُبطل قيود اليوم)
  ref.watch(todayPostingsProvider);
  ref.watch(balancesProvider);
  final sys = await ref.watch(systemAccountsProvider.future);
  final start = DateTime(day.year, day.month, day.day);
  final rows = await ref
      .watch(repositoryProvider)
      .postingsSince(start, to: start.add(const Duration(days: 1)));
  return DaySummary.from(
    rows,
    bagId: sys[SystemAccount.shanta],
    cashboxId: sys[SystemAccount.cashbox],
    makingIncomeId: sys[SystemAccount.makingIncome],
    expensesId: sys[SystemAccount.expenses],
    chequesId: sys[SystemAccount.cheques],
  );
});

/// بعد أي حركة على الكاش أو فتح اليوم وإغلاقه.
void invalidateBagDay(WidgetRef ref) {
  ref.invalidate(latestBagDayProvider);
  ref.invalidate(dayGateProvider);
  ref.invalidate(daySummaryProvider);
  ref.invalidate(balancesProvider);
  invalidateAfterPosting(ref);
}
