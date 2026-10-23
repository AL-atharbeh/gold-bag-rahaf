/// الأنواع تطابق حرفياً أنواع Postgres — أي تغيير هنا يلزمه تغيير في SQL.
library;

enum AccountKind {
  showroom('showroom', 'محل عرض'),
  trader('trader', 'تاجر'),
  factory('factory', 'مشغل / مصنع'),
  inventoryLocation('inventory_location', 'موقع مخزون'),
  cashbox('cashbox', 'صندوق نقد'),
  customer('customer', 'زبون تجزئة'),
  employee('employee', 'موظف'),
  income('income', 'إيرادات'),
  expense('expense', 'مصاريف'),
  owner('owner', 'رأس المال');

  const AccountKind(this.wire, this.label);
  final String wire;
  final String label;

  static AccountKind fromWire(String w) =>
      AccountKind.values.firstWhere((e) => e.wire == w);
}

/// دفتران منفصلان تماماً: الذهب بالمليجرام الصافي، والنقد بالفلس.
enum LedgerKind {
  gold('gold', 'ذهب'),
  cash('cash', 'نقد');

  const LedgerKind(this.wire, this.label);
  final String wire;
  final String label;

  static LedgerKind fromWire(String w) =>
      LedgerKind.values.firstWhere((e) => e.wire == w);
}

enum TxType {
  openingBalance('opening_balance', 'رصيد افتتاحي'),
  sale('sale', 'بيع'),
  purchase('purchase', 'شراء'),
  goodsIn('goods_in', 'وارد بضاعة'),
  consignmentOut('consignment_out', 'تسليم عرض'),
  consignmentReturn('consignment_return', 'إرجاع عرض'),
  consignmentSold('consignment_sold', 'تحويل عرض إلى بيع'),
  cashPayment('cash_payment', 'دفعة نقدية'),
  goldPayment('gold_payment', 'دفعة ذهب'),
  pricing('pricing', 'تسكير'),
  transfer('transfer', 'نقل مخزون'),
  goodsReturn('goods_return', 'مرتجع بضاعة'),
  cashReturn('cash_return', 'مرتجع نقد'),
  adjustment('adjustment', 'تسوية'),
  reversal('reversal', 'قيد عكسي'),
  expense('expense', 'مصروف'),
  cashAdjust('cash_adjust', 'تسوية كاش'),
  chequeClear('cheque_clear', 'صرف شيك');

  const TxType(this.wire, this.label);
  final String wire;
  final String label;

  static TxType fromWire(String w) =>
      TxType.values.firstWhere((e) => e.wire == w);
}

/// أي معامل عيار يُطبَّق على الحركة.
///
/// المعامل تابع لصورة الذهب لا لاتجاه انتقاله: البضاعة المشغولة
/// تُقيَّم بالمعامل الأعلى، والكسر بالمعامل الأدنى. مع الموزّعين تصلنا
/// البضاعة منهم بـ ٨٨٥ ونردّ إليهم كسراً بـ ٨٧٠، فنعيد وزناً قائماً
/// أكبر مما استلمنا — الفارق عليهم لنا لا العكس.
///
/// الخلط بين المعاملين يقلب الرصيد في كل حركة.
enum GoldDirection {
  /// بضاعة مشغولة — المعامل الأعلى (٠٫٨٨٥ لعيار ٢١).
  out('بضاعة'),

  /// كسر أو ذهب خام — المعامل الأدنى (٠٫٨٧٠ لعيار ٢١).
  incoming('كسر');

  const GoldDirection(this.label);
  final String label;
}

enum ChequeDirection {
  incoming('incoming', 'شيك وارد'),
  outgoing('outgoing', 'شيك صادر');

  const ChequeDirection(this.wire, this.label);
  final String wire;
  final String label;

  static ChequeDirection fromWire(String w) =>
      ChequeDirection.values.firstWhere((e) => e.wire == w);
}

enum ChequeStatus {
  pending('pending', 'معلّق'),
  cleared('cleared', 'محصَّل'),
  bounced('bounced', 'مرتجع'),
  cancelled('cancelled', 'ملغى');

  const ChequeStatus(this.wire, this.label);
  final String wire;
  final String label;

  static ChequeStatus fromWire(String w) =>
      ChequeStatus.values.firstWhere((e) => e.wire == w);
}

/// مفاتيح حسابات النظام كما زُرعت في bootstrap_tenant.
class SystemAccount {
  static const shanta = 'shanta';
  static const vault = 'vault';
  static const cashbox = 'cashbox';
  static const makingIncome = 'making_income';
  static const tradingIncome = 'trading_income';
  static const capital = 'capital';
  static const cheques = 'cheques';
  static const expenses = 'expenses';
}

/// بنود المصاريف اليومية — المفتاح يُحفظ في سطر القيد.
enum ExpenseCategory {
  fuel('fuel'),
  food('food'),
  transport('transport'),
  maintenance('maintenance'),
  personal('personal'),
  other('other');

  const ExpenseCategory(this.key);
  final String key;

  static ExpenseCategory? fromKey(String? k) =>
      ExpenseCategory.values.where((e) => e.key == k).firstOrNull;
}
