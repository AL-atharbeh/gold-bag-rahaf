import 'dart:async';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/connectivity.dart';
import '../domain/enums.dart';
import '../domain/ledger.dart';
import '../domain/models.dart';
import 'gold_repository.dart';

/// مستودع الدفاتر على Supabase.
///
/// • القراءة من الجداول والعروض مباشرة، وسياسات RLS تحصرها في المنشأة
///   النشطة للمستخدم — لا فلترة بالـ tenant في التطبيق.
/// • كل كتابة في الدفتر عبر post_entry: صلاحية واشتراك وتوازن وعدم
///   تكرار، في معاملة واحدة على السيرفر.
class SupabaseGoldRepository implements GoldRepository {
  SupabaseGoldRepository({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;
  static const _uuid = Uuid();
  static const _builder = LedgerBuilder();

  String? _tenantId;

  /// المنشأة النشطة — يضبطها tenantProvider عند الدخول والتبديل.
  String? get tenantId => _tenantId;
  set tenantId(String? id) {
    if (id == _tenantId) return;
    _tenantId = id;
    _cachedBalances = null;
  }

  /// يضبطه مزوّد الاتصال. بدون اتصال تُرفض الكتابة قبل محاولتها.
  bool online = true;

  void _ensureOnline() {
    if (!online) throw const OfflineException();
  }

  String _requireTenant() {
    final t = _tenantId;
    if (t == null) throw StateError('لا توجد منشأة نشطة');
    return t;
  }

  // ---------------------------------------------------------------------------
  // القراءة
  // ---------------------------------------------------------------------------

  @override
  Future<List<Karat>> karats() async {
    final rows = await _client
        .from('karats')
        .select()
        .eq('is_active', true)
        .order('sort_order');
    return [
      for (final r in rows)
        Karat(
          id: r['id'] as String,
          name: r['name'] as String,
          outFactorPpm: (r['out_factor_ppm'] ?? r['factor_ppm'] as num).toInt(),
          inFactorPpm: (r['in_factor_ppm'] ?? r['factor_ppm'] as num).toInt(),
          sortOrder: (r['sort_order'] as num?)?.toInt() ?? 0,
        ),
    ];
  }

  @override
  Future<List<Account>> accounts({AccountKind? kind}) async {
    var q = _client
        .from('accounts')
        .select()
        .isFilter('deleted_at', null)
        .eq('is_active', true);
    if (kind != null) q = q.eq('kind', kind.wire);
    final rows = await q.order('created_at');
    return [for (final r in rows) Account.fromJson(r)];
  }

  Future<List<AccountBalance>> _balances() async {
    final rows = await _client.from('account_balances').select();
    return [for (final r in rows) AccountBalance.fromJson(r)];
  }

  final _balancesController =
      StreamController<List<AccountBalance>>.broadcast();
  List<AccountBalance>? _cachedBalances;

  Future<void> _refreshBalances() async {
    try {
      final b = await _balances();
      _cachedBalances = b;
      _balancesController.add(b);
    } catch (_) {
      // التحديث بعد الحفظ فقط — الفشل هنا لا يُفشل الحركة نفسها
    }
  }

  @override
  Stream<List<AccountBalance>> watchBalances() async* {
    _cachedBalances ??= await _balances();
    yield _cachedBalances!;
    yield* _balancesController.stream;
  }

  @override
  Future<List<StatementLine>> statement(String accountId,
      {int limit = 200}) async {
    final rows = await _client
        .from('account_statement')
        .select()
        .eq('account_id', accountId)
        .order('occurred_at', ascending: false)
        .limit(limit);
    return [for (final r in rows) StatementLine.fromJson(r)];
  }

  @override
  Future<List<StatementLine>> statementSince(
      String accountId, DateTime from) async {
    final rows = await _client
        .from('account_statement')
        .select()
        .eq('account_id', accountId)
        .gte('occurred_at', from.toUtc().toIso8601String())
        .order('occurred_at');
    return [for (final r in rows) StatementLine.fromJson(r)];
  }

  @override
  Future<List<RecentTx>> recentTransactions({int limit = 8}) async {
    final rows = await _client
        .from('transactions')
        .select(
            'id, type, doc_number, occurred_at, reversed_by_tx_id, counterparty_id, accounts(name, kind)')
        .order('occurred_at', ascending: false)
        .order('doc_number', ascending: false)
        .limit(limit);
    return [for (final r in rows) RecentTx.fromJson(r)];
  }

  @override
  Future<List<DayPosting>> postingsSince(DateTime from, {DateTime? to}) async {
    var q = _client
        .from('postings')
        .select(
            'tx_id, account_id, ledger, amount, item_id, quantity, note, transactions!inner(type, occurred_at, reversed_by_tx_id, note)')
        .gte('transactions.occurred_at', from.toUtc().toIso8601String());
    if (to != null) {
      q = q.lt('transactions.occurred_at', to.toUtc().toIso8601String());
    }
    final rows = await q;
    return [for (final r in rows) DayPosting.fromJson(r)];
  }

  @override
  Future<List<PeriodPosting>> periodPostings(
      {String? accountId, required DateTime from, DateTime? to}) async {
    // الخادم يعيد 1000 سطر كحد أقصى في الطلب — تُجلب الصفحات تباعاً
    const page = 1000;
    final rows = <Map<String, dynamic>>[];
    for (var start = 0;; start += page) {
      var q = _client.from('postings').select(
          'tx_id, account_id, ledger, amount, gross_weight_mg, quantity, item_id, karat_id, making_per_gram_fils, note, '
          'items(name), karats(name), '
          'transactions!inner(type, doc_number, occurred_at, reversed_by_tx_id, counterparty_id, note, accounts(name, kind))');
      if (accountId != null) q = q.eq('account_id', accountId);
      q = q.gte('transactions.occurred_at', from.toUtc().toIso8601String());
      if (to != null) {
        q = q.lt('transactions.occurred_at', to.toUtc().toIso8601String());
      }
      final chunk =
          await q.order('tx_id').order('seq').range(start, start + page - 1);
      rows.addAll(chunk);
      if (chunk.length < page) break;
    }
    final list = [for (final r in rows) PeriodPosting.fromJson(r)]
      ..sort((a, b) {
        final c = a.occurredAt.compareTo(b.occurredAt);
        return c != 0 ? c : a.docNumber.compareTo(b.docNumber);
      });
    return list;
  }

  @override
  Future<String> addExpense({
    required String cashboxId,
    required String expensesId,
    required int amountFils,
    required ExpenseCategory category,
    required String label,
    String? note,
    DateTime? occurredAt,
  }) {
    if (amountFils <= 0) throw ArgumentError('المبلغ يجب أن يكون أكبر من صفر');
    final n = note?.trim();
    return _post(
      TxType.expense,
      null,
      occurredAt,
      [label, if (n != null && n.isNotEmpty) n].join(' — '),
      [
        PostingDraft.cash(
            accountId: expensesId,
            amountFils: amountFils,
            debit: true,
            note: category.key),
        PostingDraft.cash(
            accountId: cashboxId, amountFils: amountFils, debit: false),
      ],
    );
  }

  static String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<BagDay?> latestBagDay() async {
    final rows = await _client
        .from('bag_days')
        .select()
        .order('day', ascending: false)
        .limit(1);
    return rows.isEmpty ? null : BagDay.fromJson(rows.first);
  }

  @override
  Future<void> openBagDay(DateTime day, int cashFils, {String? note}) async {
    _ensureOnline();
    await _client.rpc('open_bag_day', params: {
      'p_day': _day(day),
      'p_cash_fils': cashFils,
      'p_note': note,
    });
    unawaited(_refreshBalances());
  }

  @override
  Future<void> closeBagDay(DateTime day, int cashFils,
      {required bool goodsConfirmed, String? note}) async {
    _ensureOnline();
    await _client.rpc('close_bag_day', params: {
      'p_day': _day(day),
      'p_cash_fils': cashFils,
      'p_goods_confirmed': goodsConfirmed,
      'p_note': note,
    });
    unawaited(_refreshBalances());
  }

  @override
  Future<List<Item>> items() async {
    final rows = await _client
        .from('items')
        .select()
        .eq('is_active', true)
        .order('sort_order')
        .order('created_at');
    return [for (final r in rows) Item.fromJson(r)];
  }

  @override
  Future<Item> createItem(String name) async {
    _ensureOnline();
    final row = await _client
        .from('items')
        .insert({
          'tenant_id': _requireTenant(),
          'name': name.trim(),
          'is_custom': true
        })
        .select()
        .single();
    return Item.fromJson(row);
  }

  @override
  Future<List<ItemStock>> itemStock(String accountId) async {
    final rows = await _client
        .from('account_item_stock')
        .select()
        .eq('account_id', accountId)
        .order('item_sort')
        .order('karat_sort');
    return [
      for (final r in rows)
        if (!ItemStock.fromJson(r).isEmpty) ItemStock.fromJson(r),
    ];
  }

  @override
  Future<String> goodsIn({
    required String workshopId,
    required String bagAccountId,
    required List<GoodsLine> lines,
    DateTime? occurredAt,
    String? note,
  }) =>
      _post(
        TxType.goodsIn,
        workshopId,
        occurredAt,
        note,
        _builder.goodsIn(
          workshopId: workshopId,
          bagAccountId: bagAccountId,
          lines: lines,
        ),
      );

  @override
  Future<String> shopSale({
    required String shopId,
    required String bagAccountId,
    required String cashboxId,
    required String makingIncomeId,
    List<GoodsLine> goods = const [],
    List<GoodsLine> scrap = const [],
    List<GoodsLine> recovered = const [],
    int cashReceivedFils = 0,
    int costOutFils = 0,
    int costBackFils = 0,
    int makingDiscountFils = 0,
    SaleFix? saleFix,
    String? tradingIncomeId,
    DateTime? occurredAt,
    String? note,
  }) =>
      _post(
        // نوع الحركة يتبع أهم ما فيها: بيع، أو دفعة كسر، أو تسكير، أو نقد
        goods.isNotEmpty || recovered.isNotEmpty
            ? TxType.sale
            : scrap.isNotEmpty
                ? TxType.goldPayment
                : saleFix != null
                    ? TxType.pricing
                : TxType.cashPayment,
        shopId,
        occurredAt,
        note,
        _builder.shopSale(
          shopId: shopId,
          bagAccountId: bagAccountId,
          cashboxId: cashboxId,
          makingIncomeId: makingIncomeId,
          goods: goods,
          scrap: scrap,
          recovered: recovered,
          cashReceivedFils: cashReceivedFils,
          costOutFils: costOutFils,
          costBackFils: costBackFils,
          makingDiscountFils: makingDiscountFils,
          saleFix: saleFix,
          tradingIncomeId: tradingIncomeId,
        ),
        pricePerGramFils: saleFix?.priceFils,
      );

  @override
  Future<List<LastMaking>> recentMakings(
      String partyId, String itemId, String karatId,
      {int limit = 3}) async {
    // سطور مصنوعية البيع وحدها (موجبة على المحل)، من الحركات غير الملغاة
    final rows = await _client
        .from('postings')
        .select('amount, making_per_gram_fils, note, created_at, '
            'transactions!inner(occurred_at, reversed_by_tx_id)')
        .eq('account_id', partyId)
        .eq('ledger', LedgerKind.cash.wire)
        .eq('item_id', itemId)
        .eq('karat_id', karatId)
        .gt('amount', 0)
        .not('making_per_gram_fils', 'is', null)
        .isFilter('transactions.reversed_by_tx_id', null)
        .order('created_at', ascending: false)
        .limit(limit);
    return [
      for (final r in rows)
        LastMaking(
          (r['making_per_gram_fils'] as num).toInt(),
          r['note'] == noteMakingPiece,
          DateTime.tryParse(
                  (r['transactions'] as Map)['occurred_at'] as String? ?? '')
              ?.toLocal(),
        ),
    ];
  }

  @override
  Future<String> fix({
    required String partyId,
    required String tradingIncomeId,
    required String cashboxId,
    required int netWeightMg,
    required int pricePerGramFils,
    required bool owedToUs,
    int cashFils = 0,
    String? traderId,
    int traderNetMg = 0,
    int traderPriceFils = 0,
    String? classNote,
    DateTime? occurredAt,
    String? note,
  }) =>
      _post(
        TxType.pricing,
        partyId,
        occurredAt,
        note,
        _builder.fix(
          counterpartyId: partyId,
          tradingIncomeId: tradingIncomeId,
          cashboxId: cashboxId,
          netWeightMg: netWeightMg,
          pricePerGramFils: pricePerGramFils,
          owedToUs: owedToUs,
          cashFils: cashFils,
          traderId: traderId,
          traderNetMg: traderNetMg,
          traderPriceFils: traderPriceFils,
          classNote: classNote,
        ),
        pricePerGramFils: pricePerGramFils,
      );

  @override
  Future<String> exchange({
    required String partyId,
    required String bagAccountId,
    required String makingIncomeId,
    List<GoodsLine> received = const [],
    List<GoodsLine> delivered = const [],
    int feePerGramFils = 0,
    bool feeForUs = false,
    DateTime? occurredAt,
    String? note,
  }) =>
      _post(
        TxType.goldPayment,
        partyId,
        occurredAt,
        // "بدل" في ملاحظة الحركة: يميّزها عن دفعة الذهب العادية في الكشف
        [noteExchange, if (note != null && note.trim().isNotEmpty) note.trim()]
            .join(' — '),
        _builder.exchange(
          partyId: partyId,
          bagAccountId: bagAccountId,
          makingIncomeId: makingIncomeId,
          received: received,
          delivered: delivered,
          feePerGramFils: feePerGramFils,
          feeForUs: feeForUs,
        ),
      );

  @override
  Future<String> employeeDraw({
    required String employeeId,
    required String cashboxId,
    required int amountFils,
    String? label,
    bool salaryPay = false,
    DateTime? occurredAt,
    String? note,
  }) {
    if (amountFils <= 0) throw ArgumentError('المبلغ يجب أن يكون أكبر من صفر');
    final n = note?.trim();
    final kind = salaryPay ? noteSalaryPay : noteEmployeeDraw;
    // البند والتفاصيل في ملاحظة الحركة، فتظهر في كشف الموظف ومصاريف اليوم
    final txNote = [
      if (salaryPay) noteSalaryPay,
      if (label != null) label,
      if (n != null && n.isNotEmpty) n,
    ].join(' — ');
    return _post(
      TxType.cashPayment,
      employeeId,
      occurredAt,
      txNote.isEmpty ? null : txNote,
      [
        PostingDraft.cash(
            accountId: cashboxId, amountFils: amountFils, debit: false, note: kind),
        // بلا ملاحظة على سطر الموظف: كشفه يعرض ملاحظة الحركة بتفاصيلها
        PostingDraft.cash(
            accountId: employeeId, amountFils: amountFils, debit: true),
      ],
    );
  }

  @override
  Future<String> openingParty({
    required String partyId,
    required String capitalId,
    int goldMg = 0,
    int cashFils = 0,
    DateTime? occurredAt,
  }) =>
      _post(
        TxType.openingBalance,
        partyId,
        occurredAt,
        null,
        _builder.openingParty(
          partyId: partyId,
          capitalId: capitalId,
          goldMg: goldMg,
          cashFils: cashFils,
        ),
      );

  @override
  Future<String> openingBag({
    required String bagAccountId,
    required String cashboxId,
    required String capitalId,
    List<GoodsLine> goods = const [],
    List<GoodsLine> scrap = const [],
    int cashFils = 0,
    DateTime? occurredAt,
  }) =>
      _post(
        TxType.openingBalance,
        null,
        occurredAt,
        null,
        _builder.openingBag(
          bagAccountId: bagAccountId,
          cashboxId: cashboxId,
          capitalId: capitalId,
          goods: goods,
          scrap: scrap,
          cashFils: cashFils,
        ),
      );

  @override
  Future<String> goodsReturn({
    required String partyId,
    required String bagAccountId,
    required String makingIncomeId,
    required List<GoodsLine> lines,
    required bool fromShop,
    int costBackFils = 0,
    DateTime? occurredAt,
    String? note,
  }) =>
      _post(
        TxType.goodsReturn,
        partyId,
        occurredAt,
        note,
        _builder.goodsReturn(
          partyId: partyId,
          bagAccountId: bagAccountId,
          makingIncomeId: makingIncomeId,
          lines: lines,
          fromShop: fromShop,
          costBackFils: costBackFils,
        ),
      );

  @override
  Future<TxDetail> transactionDetail(String txId) async {
    final tx =
        await _client.from('transactions').select().eq('id', txId).single();
    final rows = await _client
        .from('postings')
        .select('*, accounts(name), items(name), karats(name)')
        .eq('tx_id', txId)
        .order('seq');
    return TxDetail(
      id: tx['id'] as String,
      type: TxType.fromWire(tx['type'] as String),
      docNumber: tx['doc_number'] as String,
      occurredAt: DateTime.parse(tx['occurred_at'] as String).toLocal(),
      note: tx['note'] as String?,
      isReversed: tx['reversed_by_tx_id'] != null,
      reversesTxId: tx['reverses_tx_id'] as String?,
      lines: [for (final r in rows) TxLine.fromJson(r)],
    );
  }

  @override
  Future<String> traderPrice({
    required String traderId,
    required String tradingIncomeId,
    required int netWeightMg,
    required int pricePerGramFils,
    required bool owedToUs,
    required TxType type,
    DateTime? occurredAt,
    String? note,
  }) =>
      _post(
        type,
        traderId,
        occurredAt,
        note,
        _builder.price(
          counterpartyId: traderId,
          tradingIncomeId: tradingIncomeId,
          netWeightMg: netWeightMg,
          pricePerGramFils: pricePerGramFils,
          owedToUs: owedToUs,
        ),
        pricePerGramFils: pricePerGramFils,
      );

  @override
  Future<String> scrapMove({
    required String partyId,
    required String bagAccountId,
    required List<GoodsLine> lines,
    required bool toParty,
    PartialPricing? pricing,
    DateTime? occurredAt,
    String? note,
  }) {
    final drafts = [
      ..._builder.scrapMove(
        partyId: partyId,
        bagAccountId: bagAccountId,
        lines: lines,
        toParty: toParty,
      ),
      // جزء من الكسر المستلم يُشترى نقداً: يخرج من رصيد ذهبه، ويصير له علينا ثمنه
      if (pricing != null)
        ..._builder.price(
          counterpartyId: partyId,
          tradingIncomeId: pricing.tradingIncomeId,
          netWeightMg: pricing.netWeightMg,
          pricePerGramFils: pricing.pricePerGramFils,
          owedToUs: false,
        ),
    ];
    return _post(
      pricing == null ? TxType.goldPayment : TxType.purchase,
      partyId,
      occurredAt,
      note,
      drafts,
      pricePerGramFils: pricing?.pricePerGramFils,
    );
  }

  @override
  Future<String> createKarat(String name, int ppm) async {
    _ensureOnline();
    final row = await _client
        .from('karats')
        .insert({
          'tenant_id': _requireTenant(),
          'name': name.trim(),
          'factor_ppm': ppm,
          'out_factor_ppm': ppm,
          'in_factor_ppm': ppm,
          'sort_order': 50,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  @override
  Future<String> cashMove({
    required String partyId,
    required String cashboxId,
    required int amountFils,
    required bool incoming,
    ChequeInfo? cheque,
    DateTime? occurredAt,
    String? note,
  }) async {
    final drafts = incoming
        ? _builder.receiveCash(
            counterpartyId: partyId,
            cashboxId: cashboxId,
            amountFils: amountFils)
        : _builder.payCash(
            counterpartyId: partyId,
            cashboxId: cashboxId,
            amountFils: amountFils);
    final r = await _postFull(
      TxType.cashPayment,
      partyId,
      occurredAt,
      note ?? (cheque == null ? null : 'شيك ${cheque.number ?? ''}'.trim()),
      drafts,
    );
    // الشيك يُعدّ نقداً فوراً، ويُسجَّل في دفتر الشيكات مربوطاً بحركته
    // لمتابعة استحقاقه — تحصيله لاحقاً لا يقيّد المبلغ مرة ثانية.
    if (cheque != null) {
      await _client.from('cheques').insert({
        'tenant_id': _requireTenant(),
        'account_id': partyId,
        'direction': incoming ? 'incoming' : 'outgoing',
        'amount_fils': amountFils,
        'due_date': cheque.dueDate.toIso8601String().split('T').first,
        'cheque_number': cheque.number,
        'bank_name': cheque.bank,
        'note': note,
        'settled_tx_id': r.txId,
        'created_by': _client.auth.currentUser?.id,
      });
    }
    return r.doc;
  }

  @override
  Future<List<KaratFactor>> karatFactors(String accountId) async {
    final rows = await _client
        .from('effective_karat_factors')
        .select()
        .eq('account_id', accountId)
        .order('sort_order');
    return [for (final r in rows) KaratFactor.fromJson(r)];
  }

  @override
  Future<List<Cheque>> cheques(
      {ChequeStatus? status, String? accountId}) async {
    var q = _client.from('cheques').select('*, accounts(name)');
    if (status != null) q = q.eq('status', status.wire);
    if (accountId != null) q = q.eq('account_id', accountId);
    final rows = await q.order('due_date');
    return [for (final r in rows) Cheque.fromJson(r)];
  }

  // ---------------------------------------------------------------------------
  // الحسابات والمعاملات والشيكات
  // ---------------------------------------------------------------------------

  @override
  Future<String> createShowroom(String name,
      {String? phone, String? note}) async {
    _ensureOnline();
    final id = await _client.rpc('create_showroom', params: {
      'p_name': name,
      'p_phone': phone,
      'p_note': note,
    });
    return id as String;
  }

  Future<String> _insertAccount(Map<String, dynamic> data) async {
    _ensureOnline();
    final row = await _client
        .from('accounts')
        .insert({'tenant_id': _requireTenant(), ...data})
        .select('id')
        .single();
    return row['id'] as String;
  }

  @override
  Future<String> createAccount(String name, AccountKind kind,
          {String? phone, String? note}) =>
      _insertAccount(
          {'name': name, 'kind': kind.wire, 'phone': phone, 'note': note});

  @override
  Future<String> createEmployee(
    String name, {
    String? phone,
    String? note,
    int monthlySalaryFils = 0,
    DateTime? salaryStartDate,
  }) =>
      _insertAccount({
        'name': name,
        'kind': AccountKind.employee.wire,
        'phone': phone,
        'note': note,
        'monthly_salary_fils': monthlySalaryFils,
        if (salaryStartDate != null)
          'salary_start_date': _day(salaryStartDate),
      });

  @override
  Future<void> updateEmployee(
    String accountId, {
    String? name,
    String? phone,
    String? note,
    int? monthlySalaryFils,
    DateTime? salaryStartDate,
    bool clearSalaryStart = false,
  }) async {
    final patch = <String, dynamic>{
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (note != null) 'note': note,
      if (monthlySalaryFils != null) 'monthly_salary_fils': monthlySalaryFils,
      if (salaryStartDate != null)
        'salary_start_date': _day(salaryStartDate)
      else if (clearSalaryStart)
        'salary_start_date': null,
    };
    if (patch.isEmpty) return;
    _ensureOnline();
    await _client.from('accounts').update(patch).eq('id', accountId);
  }

  @override
  Future<void> setKaratFactor({
    required String accountId,
    required String karatId,
    int? outFactorPpm,
    int? inFactorPpm,
    String? note,
  }) async {
    _ensureOnline();
    // المعاملان فارغان = عودة للعام: يُحذف الاستثناء بدل حفظ صف فارغ
    if (outFactorPpm == null && inFactorPpm == null) {
      await _client
          .from('account_karat_factors')
          .delete()
          .eq('account_id', accountId)
          .eq('karat_id', karatId);
      return;
    }
    await _client.from('account_karat_factors').upsert({
      'tenant_id': _requireTenant(),
      'account_id': accountId,
      'karat_id': karatId,
      'out_factor_ppm': outFactorPpm,
      'in_factor_ppm': inFactorPpm,
      'note': note,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'account_id,karat_id');
  }

  @override
  Future<String> addCheque({
    required String accountId,
    required ChequeDirection direction,
    required int amountFils,
    required DateTime dueDate,
    String? chequeNumber,
    String? bankName,
    String? note,
  }) async {
    _ensureOnline();
    final row = await _client
        .from('cheques')
        .insert({
          'tenant_id': _requireTenant(),
          'account_id': accountId,
          'direction': direction.wire,
          'amount_fils': amountFils,
          'due_date': dueDate.toIso8601String().split('T').first,
          'cheque_number': chequeNumber,
          'bank_name': bankName,
          'note': note,
          'created_by': _client.auth.currentUser?.id,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  @override
  Future<String> clearCheque({
    required String chequeId,
    required String cashboxId,
    DateTime? occurredAt,
    String? note,
    bool toCash = true,
  }) async {
    _ensureOnline();
    final doc = await _client.rpc('clear_cheque', params: {
      'p_cheque_id': chequeId,
      'p_cashbox_id': cashboxId,
      'p_occurred_at': (occurredAt ?? DateTime.now()).toUtc().toIso8601String(),
      'p_note': note,
      'p_to_cash': toCash,
    });
    unawaited(_refreshBalances());
    return doc as String;
  }

  @override
  Future<String> cancelTransaction(String txId, String reason) async {
    _ensureOnline();
    final r = await _client.rpc('cancel_transaction', params: {
      'p_tx_id': txId,
      'p_reason': reason,
    });
    unawaited(_refreshBalances());
    return (r as Map)['doc_number'] as String;
  }

  @override
  Future<String?> voidCheque(String chequeId, ChequeStatus status,
      {String? note}) async {
    _ensureOnline();
    final doc = await _client.rpc('void_cheque', params: {
      'p_cheque_id': chequeId,
      'p_status': status.wire,
      'p_note': note,
    });
    unawaited(_refreshBalances());
    return doc as String?;
  }

  // ---------------------------------------------------------------------------
  // الحركات — تُبنى السطور محلياً وتُحفظ في معاملة واحدة على السيرفر
  // ---------------------------------------------------------------------------

  @override
  Future<String> receiveCash({
    required String counterpartyId,
    required String cashboxId,
    required int amountFils,
    DateTime? occurredAt,
    String? note,
  }) =>
      _post(
        TxType.cashPayment,
        counterpartyId,
        occurredAt,
        note,
        _builder.receiveCash(
          counterpartyId: counterpartyId,
          cashboxId: cashboxId,
          amountFils: amountFils,
        ),
      );

  @override
  Future<String> payCash({
    required String counterpartyId,
    required String cashboxId,
    required int amountFils,
    DateTime? occurredAt,
    String? note,
  }) =>
      _post(
        TxType.cashPayment,
        counterpartyId,
        occurredAt,
        note,
        _builder.payCash(
          counterpartyId: counterpartyId,
          cashboxId: cashboxId,
          amountFils: amountFils,
        ),
      );

  @override
  Future<String> reverse(String txId, {String? reason}) async {
    _ensureOnline();
    final r = await _client.rpc('reverse_entry', params: {
      'p_tx_id': txId,
      'p_reason': reason,
    });
    unawaited(_refreshBalances());
    return (r as Map)['doc_number'] as String;
  }

  /// يحفظ الحركة ويُرجع رقم المستند.
  ///
  /// client_ref يُولَّد مرة واحدة قبل الإرسال: لو انقطع الاتصال بعد أن
  /// حفظ السيرفر الحركة وقبل وصول الرد، تعيد المحاولة الحركة نفسها
  /// بدل تسجيلها مرتين.
  Future<String> _post(
    TxType type,
    String? counterpartyId,
    DateTime? occurredAt,
    String? note,
    List<PostingDraft> drafts, {
    int? pricePerGramFils,
  }) async =>
      (await _postFull(type, counterpartyId, occurredAt, note, drafts,
              pricePerGramFils: pricePerGramFils))
          .doc;

  /// مثل [_post] ويُرجع معرّف الحركة أيضاً — لربط الشيك بها.
  Future<({String txId, String doc})> _postFull(
    TxType type,
    String? counterpartyId,
    DateTime? occurredAt,
    String? note,
    List<PostingDraft> drafts, {
    int? pricePerGramFils,
  }) async {
    _ensureOnline();
    final params = {
      'p_client_ref': _uuid.v4(),
      'p_type': type.wire,
      'p_occurred_at': (occurredAt ?? DateTime.now()).toUtc().toIso8601String(),
      'p_postings': [for (final d in drafts) d.toJson()],
      'p_counterparty_id': counterpartyId,
      'p_price_per_gram_fils': pricePerGramFils,
      'p_note': note,
    };

    for (var attempt = 1;; attempt++) {
      try {
        final r = await _client.rpc('post_entry', params: params) as Map;
        unawaited(_refreshBalances());
        return (txId: r['tx_id'] as String, doc: r['doc_number'] as String);
      } on ClientException {
        if (attempt >= 3) rethrow;
      } on TimeoutException {
        if (attempt >= 3) rethrow;
      }
      await Future<void>.delayed(Duration(seconds: attempt));
    }
  }
}
