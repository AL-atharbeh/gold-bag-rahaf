import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/connectivity.dart';
import '../data/gold_repository.dart';
import '../data/supabase_gold_repository.dart';
import '../domain/enums.dart';
import '../domain/models.dart';
import '../platform/session.dart';

final repositoryProvider = Provider<SupabaseGoldRepository>((ref) {
  final repo =
      SupabaseGoldRepository(client: ref.watch(supabaseClientProvider));
  ref.listen<bool>(isOnlineProvider, (_, v) => repo.online = v,
      fireImmediately: true);
  return repo;
});

/// المنشأة النشطة. كل دفاتر المنشأة تتبعها: تبديل الحساب يعيد تحميلها
/// كلها تلقائياً، ولا يبقى شيء من بيانات المنشأة السابقة على الشاشة.
final tenantProvider = FutureProvider<String>((ref) async {
  final id = ref.watch(activeTenantIdProvider);
  if (id == null) throw StateError('لا توجد منشأة مفعّلة');
  ref.watch(repositoryProvider).tenantId = id;
  return id;
});

final balancesProvider = StreamProvider<List<AccountBalance>>((ref) async* {
  await ref.watch(tenantProvider.future);
  yield* ref.watch(repositoryProvider).watchBalances();
});

final karatsProvider = FutureProvider<List<Karat>>((ref) async {
  await ref.watch(tenantProvider.future);
  return ref.watch(repositoryProvider).karats();
});

final accountsProvider = FutureProvider<List<Account>>((ref) async {
  await ref.watch(tenantProvider.future);
  return ref.watch(repositoryProvider).accounts();
});

/// حسابات النظام مفهرسة بمفتاحها — الشنطة، الصندوق، حسابات الإيراد.
/// الشاشات تحتاجها في كل حركة، فتُشتق مرة واحدة بدل جلبها كل مرة.
final systemAccountsProvider = FutureProvider<Map<String, String>>((ref) async {
  final all = await ref.watch(accountsProvider.future);
  return {
    for (final a in all)
      if (a.systemKey != null) a.systemKey!: a.id,
  };
});

/// الأطراف التي يتعامل معها التاجر — بلا حسابات النظام ولا حسابات العهدة.
final counterpartiesProvider = FutureProvider<List<Account>>((ref) async {
  final all = await ref.watch(accountsProvider.future);
  const kinds = {AccountKind.showroom, AccountKind.trader, AccountKind.factory};
  return all.where((a) => kinds.contains(a.kind)).toList();
});

/// محلات العرض فقط — وحدها تملك حساب عهدة.
final showroomsProvider = FutureProvider<List<Account>>((ref) async {
  final all = await ref.watch(accountsProvider.future);
  return all.where((a) => a.kind == AccountKind.showroom).toList();
});

/// عملاء التجزئة — دفتر منفصل عن الموزعين، بالدينار لا بالغرام.
final customersProvider = FutureProvider<List<Account>>((ref) async {
  final all = await ref.watch(accountsProvider.future);
  return all.where((a) => a.kind == AccountKind.customer).toList();
});

/// الموظفون — دفتر نقدي بحت: راتب شهري وسحوبات تُخصم منه.
final employeesProvider = FutureProvider<List<Account>>((ref) async {
  final all = await ref.watch(accountsProvider.future);
  return all.where((a) => a.kind == AccountKind.employee).toList();
});

/// المشاغل والمصانع التي يأخذ منها الموزّع بضاعته.
final workshopsProvider = FutureProvider<List<Account>>((ref) async {
  final all = await ref.watch(accountsProvider.future);
  return all.where((a) => a.kind == AccountKind.factory).toList();
});

/// من تأتي منهم البضاعة: المشاغل والتجار.
final suppliersProvider = FutureProvider<List<Account>>((ref) async {
  final all = await ref.watch(accountsProvider.future);
  return all
      .where(
          (a) => a.kind == AccountKind.factory || a.kind == AccountKind.trader)
      .toList();
});

/// أصناف البضاعة.
final itemsProvider = FutureProvider<List<Item>>((ref) async {
  await ref.watch(tenantProvider.future);
  return ref.watch(repositoryProvider).items();
});

/// مخزون حساب (الشنطة) لكل صنف وعيار.
final itemStockProvider =
    FutureProvider.family<List<ItemStock>, String>((ref, accountId) async {
  await ref.watch(tenantProvider.future);
  return ref.watch(repositoryProvider).itemStock(accountId);
});

/// حركة محفوظة بكل سطورها — صفحة التفاصيل للعرض فقط.
final txDetailProvider =
    FutureProvider.autoDispose.family<TxDetail, String>((ref, txId) async {
  await ref.watch(tenantProvider.future);
  return ref.watch(repositoryProvider).transactionDetail(txId);
});

/// المعاملات السارية على طرف بعينه.
final karatFactorsProvider =
    FutureProvider.family<List<KaratFactor>, String>((ref, accountId) async {
  await ref.watch(tenantProvider.future);
  return ref.watch(repositoryProvider).karatFactors(accountId);
});

/// مفتاح اختيار العيارات: أي طرف، وفي أي اتجاه.
typedef KaratQuery = ({String? accountId, GoldDirection direction});

/// العيارات بمعاملها النهائي — الشاشات لا تحسب المعامل بنفسها.
///
/// بلا طرف مختار تُستعمل المعاملات العامة؛ وبمجرد اختياره تُستبدل
/// بمعاملاته الخاصة إن كان له اتفاق.
final karatOptionsProvider =
    FutureProvider.family<List<KaratOption>, KaratQuery>((ref, q) async {
  if (q.accountId == null) {
    final karats = await ref.watch(karatsProvider.future);
    return karats
        .map((k) =>
            KaratOption(id: k.id, name: k.name, ppm: k.factorFor(q.direction)))
        .toList();
  }
  final factors = await ref.watch(karatFactorsProvider(q.accountId!).future);
  return factors.map((f) => f.optionFor(q.direction)).toList();
});

/// الشيكات المعلّقة، مرتّبة بالاستحقاق.
final pendingChequesProvider = FutureProvider<List<Cheque>>((ref) async {
  await ref.watch(tenantProvider.future);
  return ref.watch(repositoryProvider).cheques(status: ChequeStatus.pending);
});

final allChequesProvider = FutureProvider<List<Cheque>>((ref) async {
  await ref.watch(tenantProvider.future);
  return ref.watch(repositoryProvider).cheques();
});

final statementProvider =
    FutureProvider.family<List<StatementLine>, String>((ref, accountId) async {
  await ref.watch(tenantProvider.future);
  return ref.watch(repositoryProvider).statement(accountId);
});

/// قيود اليوم منذ منتصف الليل — لملخص الرئيسية.
final todayPostingsProvider =
    FutureProvider.autoDispose<List<DayPosting>>((ref) async {
  await ref.watch(tenantProvider.future);
  final now = DateTime.now();
  return ref
      .watch(repositoryProvider)
      .postingsSince(DateTime(now.year, now.month, now.day));
});

final recentTxProvider =
    FutureProvider.autoDispose<List<RecentTx>>((ref) async {
  await ref.watch(tenantProvider.future);
  return ref.watch(repositoryProvider).recentTransactions();
});

/// تُنادى بعد كل حركة ناجحة. الأرصدة يحدّثها المستودع بعد الحفظ،
/// أما القوائم والكشوف فتحتاج إعادة جلب صريحة.
void invalidateAfterPosting(WidgetRef ref) {
  ref.invalidate(accountsProvider);
  ref.invalidate(statementProvider);
  ref.invalidate(itemStockProvider);
  ref.invalidate(pendingChequesProvider);
  ref.invalidate(allChequesProvider);
  ref.invalidate(todayPostingsProvider);
  ref.invalidate(recentTxProvider);
  ref.invalidate(recentMakingsProvider);
  ref.invalidate(employeeLinesProvider);
}

/// حركات الموظف لحساب راتبه: كلها من تاريخ بداية الراتب، وإلا آخرها.
final employeeLinesProvider = FutureProvider.autoDispose
    .family<List<StatementLine>, ({String id, DateTime? start})>(
        (ref, e) async {
  await ref.watch(tenantProvider.future);
  final repo = ref.watch(repositoryProvider);
  final start = e.start;
  return start == null
      ? repo.statement(e.id)
      : repo.statementSince(e.id, start);
});

/// محل + صنف + عيار.
typedef MakingKey = ({String partyId, String itemId, String karatId});

/// آخر 3 مصنوعيات بيع بها هذا الصنف لهذا المحل — الأحدث يُعبّأ تلقائياً.
final recentMakingsProvider = FutureProvider.autoDispose
    .family<List<LastMaking>, MakingKey>((ref, k) async {
  await ref.watch(tenantProvider.future);
  return ref
      .watch(repositoryProvider)
      .recentMakings(k.partyId, k.itemId, k.karatId);
});
