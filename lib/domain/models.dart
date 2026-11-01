import '../core/units.dart';
import 'enums.dart';

class Karat {
  const Karat({
    required this.id,
    required this.name,
    required this.outFactorPpm,
    required this.inFactorPpm,
    required this.sortOrder,
  });

  factory Karat.fromJson(Map<String, dynamic> j) => Karat(
        id: j['id'] as String,
        name: j['name'] as String,
        outFactorPpm: j['out_factor_ppm'] as int,
        inFactorPpm: j['in_factor_ppm'] as int,
        sortOrder: j['sort_order'] as int? ?? 0,
      );

  final String id;
  final String name;

  /// معامل خروج البضاعة — الأعلى.
  final KaratPpm outFactorPpm;

  /// معامل دخول الذهب أو الكسر — الأدنى. الفارق هامش التاجر.
  final KaratPpm inFactorPpm;

  final int sortOrder;

  KaratPpm factorFor(GoldDirection d) =>
      d == GoldDirection.out ? outFactorPpm : inFactorPpm;
}

/// المعامل الساري على طرف معيّن — من عرض effective_karat_factors.
///
/// قد يكون موروثاً من العيار العام أو متفقاً عليه مع هذا الطرف وحده.
class KaratFactor {
  const KaratFactor({
    required this.karatId,
    required this.karatName,
    required this.outFactorPpm,
    required this.inFactorPpm,
    required this.sortOrder,
    this.outIsCustom = false,
    this.inIsCustom = false,
  });

  factory KaratFactor.fromJson(Map<String, dynamic> j) => KaratFactor(
        karatId: j['karat_id'] as String,
        karatName: j['karat_name'] as String,
        outFactorPpm: j['out_factor_ppm'] as int,
        inFactorPpm: j['in_factor_ppm'] as int,
        sortOrder: j['sort_order'] as int? ?? 0,
        outIsCustom: j['out_is_custom'] as bool? ?? false,
        inIsCustom: j['in_is_custom'] as bool? ?? false,
      );

  final String karatId;
  final String karatName;
  final KaratPpm outFactorPpm;
  final KaratPpm inFactorPpm;
  final int sortOrder;
  final bool outIsCustom;
  final bool inIsCustom;

  KaratPpm factorFor(GoldDirection d) =>
      d == GoldDirection.out ? outFactorPpm : inFactorPpm;

  bool isCustomFor(GoldDirection d) =>
      d == GoldDirection.out ? outIsCustom : inIsCustom;

  KaratOption optionFor(GoldDirection d) =>
      KaratOption(id: karatId, name: karatName, ppm: factorFor(d));
}

/// عيار جاهز للاستعمال في شاشة معيّنة: المعامل محسوم سلفاً.
///
/// الشاشات لا تعرف عن الاتجاهات ولا التجاوزات — تتلقى القيمة النهائية.
class KaratOption {
  const KaratOption({
    required this.id,
    required this.name,
    required this.ppm,
  });

  final String id;
  final String name;
  final KaratPpm ppm;
}

/// صنف بضاعة: خاتم، حلق، سلسال… أو صنف خاص أضافه الموزّع.
class Item {
  const Item(
      {required this.id,
      required this.name,
      this.sortOrder = 100,
      this.isCustom = true});

  factory Item.fromJson(Map<String, dynamic> j) => Item(
        id: j['id'] as String,
        name: j['name'] as String,
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 100,
        isCustom: j['is_custom'] as bool? ?? true,
      );

  final String id;
  final String name;
  final int sortOrder;
  final bool isCustom;
}

/// مخزون صنف بعيار معيّن في حساب (الشنطة عادةً) — من عرض account_item_stock.
class ItemStock {
  const ItemStock({
    required this.quantity,
    required this.grossMg,
    required this.netMg,
    this.itemId,
    this.itemName,
    this.karatId,
    this.karatName,
    this.itemSort = 999,
    this.karatSort = 99,
  });

  factory ItemStock.fromJson(Map<String, dynamic> j) => ItemStock(
        itemId: j['item_id'] as String?,
        itemName: j['item_name'] as String?,
        karatId: j['karat_id'] as String?,
        karatName: j['karat_name'] as String?,
        itemSort: (j['item_sort'] as num?)?.toInt() ?? 999,
        karatSort: (j['karat_sort'] as num?)?.toInt() ?? 99,
        quantity: (j['quantity'] as num?)?.toInt() ?? 0,
        grossMg: (j['gross_mg'] as num?)?.toInt() ?? 0,
        netMg: (j['net_mg'] as num?)?.toInt() ?? 0,
      );

  final String? itemId;
  final String? itemName;
  final String? karatId;
  final String? karatName;
  final int itemSort;
  final int karatSort;
  final int quantity;
  final WeightMg grossMg;
  final WeightMg netMg;

  bool get isEmpty => quantity == 0 && grossMg == 0 && netMg == 0;
}

/// سطر من قيد حركة، مع أسماء الحساب والصنف والعيار — لعرض الفاتورة.
class TxLine {
  const TxLine({
    required this.accountId,
    required this.ledger,
    required this.amount,
    this.accountName,
    this.grossWeightMg,
    this.quantity,
    this.itemName,
    this.karatName,
    this.karatPpm,
    this.makingPerGramFils,
    this.note,
    this.itemId,
    this.karatId,
  });

  factory TxLine.fromJson(Map<String, dynamic> j) => TxLine(
        accountId: j['account_id'] as String,
        accountName: (j['accounts'] as Map?)?['name'] as String?,
        ledger: LedgerKind.fromWire(j['ledger'] as String),
        amount: (j['amount'] as num).toInt(),
        grossWeightMg: (j['gross_weight_mg'] as num?)?.toInt(),
        quantity: (j['quantity'] as num?)?.toInt(),
        itemName: (j['items'] as Map?)?['name'] as String?,
        karatName: (j['karats'] as Map?)?['name'] as String?,
        karatPpm: (j['karat_ppm'] as num?)?.toInt(),
        makingPerGramFils: (j['making_per_gram_fils'] as num?)?.toInt(),
        note: j['note'] as String?,
        itemId: j['item_id'] as String?,
        karatId: j['karat_id'] as String?,
      );

  final String accountId;
  final String? accountName;
  final LedgerKind ledger;
  final int amount;
  final WeightMg? grossWeightMg;
  final int? quantity;
  final String? itemName;
  final String? karatName;
  final KaratPpm? karatPpm;
  final MoneyFils? makingPerGramFils;
  final String? note;
  final String? itemId;
  final String? karatId;
}

/// حركة محفوظة كاملة — للعرض فقط.
class TxDetail {
  const TxDetail({
    required this.id,
    required this.type,
    required this.docNumber,
    required this.occurredAt,
    required this.lines,
    this.note,
    this.isReversed = false,
    this.reversesTxId,
  });

  final String id;
  final TxType type;
  final String docNumber;
  final DateTime occurredAt;
  final String? note;
  final bool isReversed;
  final String? reversesTxId;
  final List<TxLine> lines;
}

class Cheque {
  const Cheque({
    required this.id,
    required this.accountId,
    required this.direction,
    required this.status,
    required this.amountFils,
    required this.dueDate,
    this.accountName,
    this.chequeNumber,
    this.bankName,
    this.note,
    this.settledAt,
    this.settledTxId,
  });

  factory Cheque.fromJson(Map<String, dynamic> j) => Cheque(
        id: j['id'] as String,
        accountId: j['account_id'] as String,
        accountName:
            (j['accounts'] as Map<String, dynamic>?)?['name'] as String?,
        direction: ChequeDirection.fromWire(j['direction'] as String),
        status: ChequeStatus.fromWire(j['status'] as String),
        amountFils: (j['amount_fils'] as num).toInt(),
        dueDate: DateTime.parse(j['due_date'] as String),
        chequeNumber: j['cheque_number'] as String?,
        bankName: j['bank_name'] as String?,
        note: j['note'] as String?,
        settledAt: j['settled_at'] == null
            ? null
            : DateTime.parse(j['settled_at'] as String).toLocal(),
        settledTxId: j['settled_tx_id'] as String?,
      );

  final String id;
  final String accountId;
  final String? accountName;
  final ChequeDirection direction;
  final ChequeStatus status;
  final MoneyFils amountFils;
  final DateTime dueDate;
  final String? chequeNumber;
  final String? bankName;
  final String? note;
  final DateTime? settledAt;

  /// الحركة التي قُيِّد بها الشيك نقداً — موجودة إذا حُسب الشيك نقداً عند تسجيله.
  final String? settledTxId;

  /// كم يوماً يفصلنا عن الاستحقاق. سالب = فات موعده.
  int get daysUntilDue {
    final today = DateTime.now();
    return DateTime(dueDate.year, dueDate.month, dueDate.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
  }

  bool get isOverdue => status == ChequeStatus.pending && daysUntilDue < 0;
  bool get isDueSoon =>
      status == ChequeStatus.pending && daysUntilDue >= 0 && daysUntilDue <= 7;
}

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.kind,
    this.phone,
    this.note,
    this.consignmentAccountId,
    this.systemKey,
    this.isSystem = false,
    this.monthlySalaryFils = 0,
  });

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String,
        name: j['name'] as String,
        kind: AccountKind.fromWire(j['kind'] as String),
        phone: j['phone'] as String?,
        note: j['note'] as String?,
        consignmentAccountId: j['consignment_account_id'] as String?,
        systemKey: j['system_key'] as String?,
        isSystem: j['is_system'] as bool? ?? false,
        monthlySalaryFils: (j['monthly_salary_fils'] as num?)?.toInt() ?? 0,
      );

  final String id;
  final String name;
  final AccountKind kind;
  final String? phone;
  final String? note;

  /// حساب العهدة المرتبط بمحل العرض — الذهب المعروض عنده وما زال ملكنا.
  final String? consignmentAccountId;
  final String? systemKey;
  final bool isSystem;

  /// الراتب الشهري — للموظفين وحدهم، صفر لبقية الأنواع.
  final MoneyFils monthlySalaryFils;
}

class AccountBalance {
  const AccountBalance({
    required this.accountId,
    required this.name,
    required this.kind,
    required this.goldMg,
    required this.cashFils,
    this.systemKey,
    this.consignmentAccountId,
  });

  factory AccountBalance.fromJson(Map<String, dynamic> j) => AccountBalance(
        accountId: j['account_id'] as String,
        name: j['name'] as String,
        kind: AccountKind.fromWire(j['kind'] as String),
        goldMg: (j['gold_mg'] as num).toInt(),
        cashFils: (j['cash_fils'] as num).toInt(),
        systemKey: j['system_key'] as String?,
        consignmentAccountId: j['consignment_account_id'] as String?,
      );

  final String accountId;
  final String name;
  final AccountKind kind;

  /// موجب = الطرف مدين لنا بالذهب (أو الذهب لدينا في موقع مخزون).
  final WeightMg goldMg;

  /// موجب = الطرف مدين لنا نقداً.
  final MoneyFils cashFils;

  final String? systemKey;
  final String? consignmentAccountId;
}

class StatementLine {
  const StatementLine({
    required this.postingId,
    required this.txId,
    required this.docNumber,
    required this.txType,
    required this.occurredAt,
    required this.ledger,
    required this.amount,
    required this.isReversed,
    this.grossWeightMg,
    this.karatName,
    this.note,
  });

  factory StatementLine.fromJson(Map<String, dynamic> j) => StatementLine(
        postingId: j['posting_id'] as String,
        txId: j['tx_id'] as String,
        docNumber: j['doc_number'] as String,
        txType: TxType.fromWire(j['tx_type'] as String),
        occurredAt: DateTime.parse(j['occurred_at'] as String).toLocal(),
        ledger: LedgerKind.fromWire(j['ledger'] as String),
        amount: (j['amount'] as num).toInt(),
        isReversed: j['is_reversed'] as bool? ?? false,
        grossWeightMg: (j['gross_weight_mg'] as num?)?.toInt(),
        karatName: j['karat_name'] as String?,
        note: (j['line_note'] ?? j['tx_note']) as String?,
      );

  final String postingId;
  final String txId;
  final String docNumber;
  final TxType txType;
  final DateTime occurredAt;
  final LedgerKind ledger;
  final int amount;
  final bool isReversed;
  final WeightMg? grossWeightMg;
  final String? karatName;
  final String? note;
}

/// حركة مختصرة لقائمة آخر الحركات في الرئيسية.
class RecentTx {
  const RecentTx({
    required this.id,
    required this.type,
    required this.docNumber,
    required this.occurredAt,
    required this.isReversed,
    this.partyId,
    this.partyName,
    this.partyKind,
  });

  factory RecentTx.fromJson(Map<String, dynamic> j) {
    final a = j['accounts'] as Map?;
    return RecentTx(
      id: j['id'] as String,
      type: TxType.fromWire(j['type'] as String),
      docNumber: j['doc_number'] as String,
      occurredAt: DateTime.parse(j['occurred_at'] as String).toLocal(),
      isReversed: j['reversed_by_tx_id'] != null,
      partyId: j['counterparty_id'] as String?,
      partyName: a?['name'] as String?,
      partyKind: a?['kind'] == null
          ? null
          : AccountKind.fromWire(a!['kind'] as String),
    );
  }

  final String id;
  final TxType type;
  final String docNumber;
  final DateTime occurredAt;
  final bool isReversed;
  final String? partyId;
  final String? partyName;
  final AccountKind? partyKind;
}

/// سطر قيد مع نوع حركته — لحساب ملخص اليوم.
class DayPosting {
  const DayPosting({
    required this.txId,
    required this.accountId,
    required this.ledger,
    required this.amount,
    required this.txType,
    required this.txReversed,
    this.itemId,
    this.quantity,
    this.lineNote,
    this.txNote,
  });

  factory DayPosting.fromJson(Map<String, dynamic> j) {
    final t = j['transactions'] as Map;
    return DayPosting(
      txId: j['tx_id'] as String,
      accountId: j['account_id'] as String,
      ledger: LedgerKind.fromWire(j['ledger'] as String),
      amount: (j['amount'] as num).toInt(),
      itemId: j['item_id'] as String?,
      quantity: (j['quantity'] as num?)?.toInt(),
      txType: TxType.fromWire(t['type'] as String),
      txReversed: t['reversed_by_tx_id'] != null,
      lineNote: j['note'] as String?,
      txNote: t['note'] as String?,
    );
  }

  final String txId;
  final String accountId;
  final LedgerKind ledger;
  final int amount;
  final String? itemId;
  final int? quantity;
  final TxType txType;
  final bool txReversed;
  final String? lineNote;
  final String? txNote;
}

/// سطر قيد مع حركته وطرفها وصنفه وعياره — أساس تقارير الفترات.
class PeriodPosting {
  const PeriodPosting({
    required this.txId,
    required this.txType,
    required this.docNumber,
    required this.occurredAt,
    required this.txReversed,
    required this.accountId,
    required this.ledger,
    required this.amount,
    this.partyId,
    this.partyName,
    this.partyKind,
    this.grossWeightMg,
    this.quantity,
    this.itemId,
    this.itemName,
    this.karatId,
    this.karatName,
    this.makingPerGramFils,
    this.lineNote,
  });

  factory PeriodPosting.fromJson(Map<String, dynamic> j) {
    final t = j['transactions'] as Map;
    final a = t['accounts'] as Map?;
    return PeriodPosting(
      txId: j['tx_id'] as String,
      txType: TxType.fromWire(t['type'] as String),
      docNumber: t['doc_number'] as String,
      occurredAt: DateTime.parse(t['occurred_at'] as String).toLocal(),
      txReversed: t['reversed_by_tx_id'] != null,
      partyId: t['counterparty_id'] as String?,
      partyName: a?['name'] as String?,
      partyKind: a?['kind'] == null
          ? null
          : AccountKind.fromWire(a!['kind'] as String),
      accountId: j['account_id'] as String,
      ledger: LedgerKind.fromWire(j['ledger'] as String),
      amount: (j['amount'] as num).toInt(),
      grossWeightMg: (j['gross_weight_mg'] as num?)?.toInt(),
      quantity: (j['quantity'] as num?)?.toInt(),
      itemId: j['item_id'] as String?,
      itemName: (j['items'] as Map?)?['name'] as String?,
      karatId: j['karat_id'] as String?,
      karatName: (j['karats'] as Map?)?['name'] as String?,
      makingPerGramFils: (j['making_per_gram_fils'] as num?)?.toInt(),
      lineNote: j['note'] as String?,
    );
  }

  final String? lineNote;
  final String txId;
  final TxType txType;
  final String docNumber;
  final DateTime occurredAt;
  final bool txReversed;
  final String? partyId;
  final String? partyName;
  final AccountKind? partyKind;
  final String accountId;
  final LedgerKind ledger;
  final int amount;
  final WeightMg? grossWeightMg;
  final int? quantity;
  final String? itemId;
  final String? itemName;
  final String? karatId;
  final String? karatName;
  final MoneyFils? makingPerGramFils;

  /// حركة ملغاة أو قيد عكسي — لا تدخل في أرقام التقارير.
  bool get cancelled => txReversed || txType == TxType.reversal;
}

/// يوم عمل الشنطة: فتحه بتأكيد الكاش، وإغلاقه بالجرد.
class BagDay {
  const BagDay({
    required this.id,
    required this.day,
    required this.openingExpectedFils,
    required this.openingCashFils,
    this.openingNote,
    this.closingExpectedFils,
    this.closingCashFils,
    this.closingNote,
    this.closedAt,
  });

  factory BagDay.fromJson(Map<String, dynamic> j) => BagDay(
        id: j['id'] as String,
        day: DateTime.parse(j['day'] as String),
        openingExpectedFils: (j['opening_expected_fils'] as num).toInt(),
        openingCashFils: (j['opening_cash_fils'] as num).toInt(),
        openingNote: j['opening_note'] as String?,
        closingExpectedFils: (j['closing_expected_fils'] as num?)?.toInt(),
        closingCashFils: (j['closing_cash_fils'] as num?)?.toInt(),
        closingNote: j['closing_note'] as String?,
        closedAt: j['closed_at'] == null
            ? null
            : DateTime.parse(j['closed_at'] as String).toLocal(),
      );

  final String id;
  final DateTime day;
  final int openingExpectedFils;
  final int openingCashFils;
  final String? openingNote;
  final int? closingExpectedFils;
  final int? closingCashFils;
  final String? closingNote;
  final DateTime? closedAt;

  bool get isClosed => closedAt != null;
  int get closingDiffFils =>
      (closingCashFils ?? 0) - (closingExpectedFils ?? 0);
}
