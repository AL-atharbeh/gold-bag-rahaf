import 'dart:async';

import '../domain/enums.dart';
import '../domain/ledger.dart';
import '../domain/models.dart';

/// الواجهة المشتركة لجميع عمليات مستودع البيانات
abstract class GoldRepository {
  Future<List<Karat>> karats();
  Future<List<Account>> accounts({AccountKind? kind});
  Stream<List<AccountBalance>> watchBalances();
  Future<List<StatementLine>> statement(String accountId, {int limit = 200});
  Future<String> createShowroom(String name, {String? phone, String? note});
  Future<String> createAccount(String name, AccountKind kind,
      {String? phone, String? note});

  /// الموظف حساب نقدي براتب شهري ثابت وسحوبات تُخصم منه.
  ///
  /// له دالته الخاصة لا `createAccount` لأن الراتب عمود على الحساب
  /// لا يعرفه أي نوع آخر.
  Future<String> createEmployee(
    String name, {
    String? phone,
    String? note,
    int monthlySalaryFils = 0,
  }) =>
      throw UnimplementedError('createEmployee غير مدعوم في هذا المستودع');

  Future<void> updateEmployee(
    String accountId, {
    String? name,
    String? phone,
    String? note,
    int? monthlySalaryFils,
  }) =>
      throw UnimplementedError('updateEmployee غير مدعوم في هذا المستودع');

  /// كل سطور كشف الحساب من تاريخ [from] فما بعد — من الأقدم، بلا حد.
  /// منها يُستخرج الرصيد السابق لكشف فترة ما.
  Future<List<StatementLine>> statementSince(String accountId, DateTime from) =>
      throw UnimplementedError('statementSince غير مدعوم في هذا المستودع');

  /// آخر الحركات في المنشأة كلها — للرئيسية.
  Future<List<RecentTx>> recentTransactions({int limit = 8}) =>
      throw UnimplementedError('recentTransactions غير مدعوم في هذا المستودع');

  /// كل سطور القيود منذ [from] مع نوع حركتها — لملخص اليوم.
  Future<List<DayPosting>> postingsSince(DateTime from, {DateTime? to}) =>
      throw UnimplementedError('postingsSince غير مدعوم في هذا المستودع');

  /// سطور القيود في فترة، لكل الحسابات أو لحساب واحد [accountId].
  /// [to] فارغ = حتى الآن.
  Future<List<PeriodPosting>> periodPostings(
          {String? accountId, required DateTime from, DateTime? to}) =>
      throw UnimplementedError('periodPostings غير مدعوم في هذا المستودع');

  /// مصروف من كاش الشنطة (بنزين، أكل، سحب شخصي…).
  Future<String> addExpense({
    required String cashboxId,
    required String expensesId,
    required int amountFils,
    required ExpenseCategory category,
    required String label,
    String? note,
    DateTime? occurredAt,
  }) =>
      throw UnimplementedError('addExpense غير مدعوم في هذا المستودع');

  /// آخر يوم شنطة مسجّل (مفتوح أو مغلق)، أو null إن لم يُفتح يوم بعد.
  Future<BagDay?> latestBagDay() =>
      throw UnimplementedError('latestBagDay غير مدعوم في هذا المستودع');

  Future<void> openBagDay(DateTime day, int cashFils, {String? note}) =>
      throw UnimplementedError('openBagDay غير مدعوم في هذا المستودع');

  Future<void> closeBagDay(DateTime day, int cashFils,
          {required bool goodsConfirmed, String? note}) =>
      throw UnimplementedError('closeBagDay غير مدعوم في هذا المستودع');

  /// أصناف البضاعة: الأساسية (خاتم، حلق…) وما أضافه الموزّع.
  Future<List<Item>> items() =>
      throw UnimplementedError('items غير مدعوم في هذا المستودع');

  Future<Item> createItem(String name) =>
      throw UnimplementedError('createItem غير مدعوم في هذا المستودع');

  /// مخزون حساب لكل صنف وعيار — العدد والقائم والصافي.
  Future<List<ItemStock>> itemStock(String accountId) =>
      throw UnimplementedError('itemStock غير مدعوم في هذا المستودع');

  /// وارد بضاعة من مشغل إلى الشنطة.
  Future<String> goodsIn({
    required String workshopId,
    required String bagAccountId,
    required List<GoodsLine> lines,
    DateTime? occurredAt,
    String? note,
  }) =>
      throw UnimplementedError('goodsIn غير مدعوم في هذا المستودع');

  /// بيع للمحل مع استلام كسر و/أو نقد في نفس الحركة.
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
    DateTime? occurredAt,
    String? note,
  }) =>
      throw UnimplementedError('shopSale غير مدعوم في هذا المستودع');

  /// آخر مصنوعية بيع لكل صنف وعيار عند هذا الطرف.
  Future<Map<String, LastMaking>> lastMakings(String partyId) =>
      throw UnimplementedError('lastMakings غير مدعوم في هذا المستودع');

  /// تسكير مع دفعة نقدية اختيارية وتسكير مقابل مع تاجر.
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
      throw UnimplementedError('fix غير مدعوم في هذا المستودع');

  /// بدل ذهب بأجور على الغرام.
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
      throw UnimplementedError('exchange غير مدعوم في هذا المستودع');

  /// سحب موظف من كاش الشنطة: يُخصم من راتبه ويُحسب ضمن مصاريف اليوم.
  Future<String> employeeDraw({
    required String employeeId,
    required String cashboxId,
    required int amountFils,
    DateTime? occurredAt,
    String? note,
  }) =>
      throw UnimplementedError('employeeDraw غير مدعوم في هذا المستودع');

  /// رصيد سابق لطرف عند بدء النظام.
  Future<String> openingParty({
    required String partyId,
    required String capitalId,
    int goldMg = 0,
    int cashFils = 0,
    DateTime? occurredAt,
  }) =>
      throw UnimplementedError('openingParty غير مدعوم في هذا المستودع');

  /// ما في الشنطة عند بدء النظام.
  Future<String> openingBag({
    required String bagAccountId,
    required String cashboxId,
    required String capitalId,
    List<GoodsLine> goods = const [],
    List<GoodsLine> scrap = const [],
    int cashFils = 0,
    DateTime? occurredAt,
  }) =>
      throw UnimplementedError('openingBag غير مدعوم في هذا المستودع');

  /// مرتجع جزئي من فاتورة بيع لمحل أو وارد من مشغل.
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
      throw UnimplementedError('goodsReturn غير مدعوم في هذا المستودع');

  /// حركة محفوظة بكل سطورها — للعرض فقط.
  Future<TxDetail> transactionDetail(String txId) =>
      throw UnimplementedError('transactionDetail غير مدعوم في هذا المستودع');

  /// تسعير ذهب مع التاجر: بيع (يصير علينا ذهب ولنا نقد)، شراء (العكس)،
  /// أو تسكير بأي اتجاه. الغرامات صافية (حلة) والسعر لغرام الحلة.
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
      throw UnimplementedError('traderPrice غير مدعوم في هذا المستودع');

  /// عيار جديد للمنشأة بمعامل واحد للبضاعة والكسر — يعدّله لاحقاً من معاملات العيار.
  Future<String> createKarat(String name, int ppm) =>
      throw UnimplementedError('createKarat غير مدعوم في هذا المستودع');

  /// تسليم كسر للطرف من الشنطة، أو استلامه منه إليها — مع تسعير جزء منه نقداً اختيارياً.
  Future<String> scrapMove({
    required String partyId,
    required String bagAccountId,
    required List<GoodsLine> lines,
    required bool toParty,
    PartialPricing? pricing,
    DateTime? occurredAt,
    String? note,
  }) =>
      throw UnimplementedError('scrapMove غير مدعوم في هذا المستودع');

  /// قبض نقد من الطرف أو دفعه له — نقداً أو بشيك يُسجَّل في دفتر الشيكات.
  Future<String> cashMove({
    required String partyId,
    required String cashboxId,
    required int amountFils,
    required bool incoming,
    ChequeInfo? cheque,
    DateTime? occurredAt,
    String? note,
  }) =>
      throw UnimplementedError('cashMove غير مدعوم في هذا المستودع');

  Future<List<KaratFactor>> karatFactors(String accountId);
  Future<void> setKaratFactor({
    required String accountId,
    required String karatId,
    int? outFactorPpm,
    int? inFactorPpm,
    String? note,
  });
  Future<List<Cheque>> cheques({ChequeStatus? status, String? accountId});
  Future<String> addCheque({
    required String accountId,
    required ChequeDirection direction,
    required int amountFils,
    required DateTime dueDate,
    String? chequeNumber,
    String? bankName,
    String? note,
  });

  /// [toCash] للشيك المحفوظ في حساب الشيكات: صُرف نقداً (يدخل الكاش)
  /// أو أُودع في البنك (يخرج للمالك).
  Future<String> clearCheque({
    required String chequeId,
    required String cashboxId,
    DateTime? occurredAt,
    String? note,
    bool toCash = true,
  });
  /// إلغاء حركة محفوظة بقيد عكسي (مع سبب) — يرجع رقم القيد العكسي.
  Future<String> cancelTransaction(String txId, String reason) =>
      throw UnimplementedError('cancelTransaction غير مدعوم في هذا المستودع');

  /// ارتجاع الشيك أو إلغاؤه — ويُعكس قيده النقدي إن كان قد حُسب نقداً.
  /// يرجع رقم القيد العكسي إن وُجد.
  Future<String?> voidCheque(String chequeId, ChequeStatus status,
          {String? note}) =>
      throw UnimplementedError('voidCheque غير مدعوم في هذا المستودع');
  Future<String> receiveCash({
    required String counterpartyId,
    required String cashboxId,
    required int amountFils,
    DateTime? occurredAt,
    String? note,
  });
  Future<String> payCash({
    required String counterpartyId,
    required String cashboxId,
    required int amountFils,
    DateTime? occurredAt,
    String? note,
  });
  Future<String> reverse(String txId, {String? reason});
}

/// آخر مصنوعية بيعت بها قطعة لطرف: السعر، وهل هو للقطعة.
class LastMaking {
  const LastMaking(this.rateFils, this.perPiece);

  final int rateFils;
  final bool perPiece;
}

/// بيانات شيك مرافق لدفعة نقدية.
class ChequeInfo {
  const ChequeInfo({required this.dueDate, this.number, this.bank});

  final DateTime dueDate;
  final String? number;
  final String? bank;
}

/// تسعير جزء من الكسر المستلم نقداً بدل إضافته كله لرصيد الذهب.
class PartialPricing {
  const PartialPricing({
    required this.tradingIncomeId,
    required this.netWeightMg,
    required this.pricePerGramFils,
  });

  final String tradingIncomeId;
  final int netWeightMg;
  final int pricePerGramFils;
}
