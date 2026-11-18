// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'إدارة توزيع الذهب';

  @override
  String get otherLanguage => 'English';

  @override
  String get language => 'اللغة';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get close => 'إغلاق';

  @override
  String get done => 'تم';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get saved => 'تم الحفظ';

  @override
  String get requiredField => 'هذا الحقل مطلوب';

  @override
  String get invalidNumber => 'رقم غير صالح';

  @override
  String genericError(String message) {
    return 'حدث خطأ: $message';
  }

  @override
  String get offlineBanner =>
      'لا يوجد اتصال بالإنترنت — اتصل بالإنترنت لتسجيل الحركات';

  @override
  String get offlineAction => 'لا يمكن الحفظ بدون اتصال بالإنترنت';

  @override
  String get loginTitle => 'تسجيل الدخول';

  @override
  String get loginSubtitle => 'أدخل رقم هاتفك وسنرسل لك رمز التحقق برسالة نصية';

  @override
  String get phoneLabel => 'رقم الهاتف';

  @override
  String get phoneHint => '07XXXXXXXX';

  @override
  String get invalidPhone => 'أدخل رقم جوال أردنياً صحيحاً';

  @override
  String get sendCode => 'إرسال الرمز';

  @override
  String get enterCode => 'أدخل رمز التحقق';

  @override
  String codeSentTo(String phone) {
    return 'أرسلنا رمزاً من 6 أرقام إلى $phone';
  }

  @override
  String get codeLabel => 'الرمز';

  @override
  String get invalidCode => 'الرمز يتكوّن من 6 أرقام';

  @override
  String get verify => 'تأكيد';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String resendIn(int seconds) {
    return 'إعادة الإرسال بعد $seconds ثانية';
  }

  @override
  String get wrongCode => 'الرمز غير صحيح أو انتهت صلاحيته';

  @override
  String get signIn => 'دخول';

  @override
  String get loginSubtitleDev => 'أدخل رقم هاتفك للدخول';

  @override
  String get devModeBadge => 'وضع التجربة — الدخول بدون رمز';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get changeNumber => 'تغيير الرقم';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get signOutConfirm => 'هل تريد تسجيل الخروج من هذا الجهاز؟';

  @override
  String get registerTitle => 'إنشاء حساب جديد';

  @override
  String get registerSubtitle =>
      'اختر نوع حسابك ثم أكمل بياناتك. يُراجَع الطلب ويُفعَّل من إدارة التطبيق.';

  @override
  String get accountType => 'نوع الحساب';

  @override
  String get orgTypeDistributor => 'تاجر شنطة / موزّع';

  @override
  String get orgTypeDistributorDesc =>
      'موزّع ذهب بشنطة أو أكثر، يتعامل مع المحلات والمشاغل';

  @override
  String get orgTypeFactory => 'مصنع / مشغل';

  @override
  String get orgTypeFactoryDesc =>
      'مشغل تشكيل ذهب بعدة شنط توزيع وموزّعين تابعين له';

  @override
  String get orgTypeShop => 'محل ذهب';

  @override
  String get orgTypeShopDesc =>
      'محل بيع ذهب يتعامل مع الموزّعين والمصانع والزبائن';

  @override
  String get orgName => 'الاسم التجاري';

  @override
  String get ownerName => 'اسم المالك';

  @override
  String get city => 'المحافظة';

  @override
  String get submitRequest => 'إرسال طلب التسجيل';

  @override
  String get chooseAccountType => 'اختر نوع الحساب أولاً';

  @override
  String get statusPending => 'قيد المراجعة';

  @override
  String get statusActive => 'مفعّل';

  @override
  String get statusSuspended => 'موقوف';

  @override
  String get statusRejected => 'مرفوض';

  @override
  String get statusPendingTitle => 'طلبك قيد المراجعة';

  @override
  String statusPendingBody(String org) {
    return 'استلمنا طلب تسجيل «$org». سيتواصل معك فريقنا لتفعيل الحساب واختيار الباقة.';
  }

  @override
  String get statusRejectedTitle => 'لم تتم الموافقة على الطلب';

  @override
  String get statusSuspendedTitle => 'الحساب موقوف';

  @override
  String statusSuspendedBody(String org) {
    return 'تم إيقاف حساب «$org». تواصل مع إدارة التطبيق.';
  }

  @override
  String statusNote(String note) {
    return 'ملاحظة: $note';
  }

  @override
  String get checkAgain => 'تحقّق مجدداً';

  @override
  String contactUs(String phone) {
    return 'للتواصل: $phone';
  }

  @override
  String get roleOwner => 'المالك';

  @override
  String get roleManager => 'مسؤول';

  @override
  String get roleBagHolder => 'حامل شنطة';

  @override
  String get roleAssistant => 'مساعد';

  @override
  String get roleManagerDesc =>
      'يسلّم ويستلم ويعتمد الجرد حسب الصلاحيات الممنوحة';

  @override
  String get roleBagHolderDesc => 'يحمل شنطة ويؤكد ما يُسلَّم إليها';

  @override
  String get roleAssistantDesc => 'يسجّل الحركات فقط';

  @override
  String get permLedgerWrite => 'تسجيل الحركات';

  @override
  String get permFinanceView => 'رؤية الأرصدة والتقارير المالية';

  @override
  String get permBagsViewAll => 'رؤية كل الشنط';

  @override
  String get permBagsIssue => 'تسليم بضاعة للشنط';

  @override
  String get permBagsConfirm => 'تأكيد الاستلام والمرتجعات';

  @override
  String get permStockCount => 'طلب الجرد واعتماده';

  @override
  String get permChequesManage => 'إدارة الشيكات';

  @override
  String get tabBag => 'الشنطة';

  @override
  String get goodsIn => 'وارد بضاعة';

  @override
  String get goodsInTitle => 'وارد بضاعة من مشغل';

  @override
  String get workshop => 'المشغل';

  @override
  String get newWorkshop => 'مشغل جديد';

  @override
  String get workshopName => 'اسم المشغل';

  @override
  String get noWorkshops => 'لا يوجد مشاغل بعد — أضف أول مشغل';

  @override
  String get item => 'الصنف';

  @override
  String get newItem => 'صنف جديد';

  @override
  String get itemName => 'اسم الصنف';

  @override
  String get count => 'العدد';

  @override
  String get grossWeight => 'الوزن القائم';

  @override
  String get karat => 'العيار';

  @override
  String get makingPerGram => 'المصنوعية / غرام';

  @override
  String get net24 => 'الصافي (24)';

  @override
  String get making => 'المصنوعية';

  @override
  String get addLine => 'إضافة صنف آخر';

  @override
  String lineNumber(int n) {
    return 'بند $n';
  }

  @override
  String get summary => 'الملخص';

  @override
  String get totalPieces => 'عدد القطع';

  @override
  String get totalGross => 'إجمالي القائم';

  @override
  String get totalNet => 'إجمالي الصافي عيار 24';

  @override
  String get totalMaking => 'إجمالي المصنوعية';

  @override
  String effectWorkshop(String gold, String cash) {
    return 'يصبح للمشغل علينا: $gold غ صافي و $cash د.أ مصنوعية';
  }

  @override
  String get saveInvoice => 'حفظ الفاتورة';

  @override
  String invoiceSaved(String doc) {
    return 'تم حفظ الفاتورة — رقم $doc';
  }

  @override
  String get fillLines => 'أكمل الصنف والوزن في كل بند';

  @override
  String get noteOptional => 'ملاحظات (اختياري)';

  @override
  String get date => 'التاريخ';

  @override
  String get gramsUnit => 'غ';

  @override
  String get dinarUnit => 'د.أ';

  @override
  String get bagEmpty => 'الشنطة فارغة';

  @override
  String get bagEmptyHint => 'سجّل وارد بضاعة من مشغل لتظهر هنا بالعدد والوزن.';

  @override
  String get bagCapital => 'رأس المال (مصنوعية)';

  @override
  String piecesCount(int n) {
    return '$n قطعة';
  }

  @override
  String get unknownItem => 'كسر';

  @override
  String get invalidWeight => 'وزن غير صالح';

  @override
  String get invalidAmount => 'مبلغ غير صالح';

  @override
  String get remove => 'حذف';

  @override
  String get tabShops => 'المحلات';

  @override
  String get tabTraders => 'التجار';

  @override
  String get tabSettings => 'الإعدادات';

  @override
  String get phDistributorHome =>
      'ملخص يومك: رصيد الشنطة، ما لك على المحلات والتجار، وما عليك للمشاغل.';

  @override
  String get bagStock => 'المخزون';

  @override
  String get bagWorkshops => 'المشاغل';

  @override
  String get newShop => 'محل جديد';

  @override
  String get newTrader => 'تاجر جديد';

  @override
  String get noShops => 'لا يوجد محلات بعد';

  @override
  String get noShopsHint => 'أضف المحلات التي تبيعها البضاعة.';

  @override
  String get noTraders => 'لا يوجد تجار بعد';

  @override
  String get noTradersHint =>
      'أضف التجار الذين تبيعهم الكسر أو تشتريه منهم أو تسكّر معهم.';

  @override
  String get noWorkshopsHint => 'أضف المشاغل التي تأخذ منها البضاعة.';

  @override
  String get otherLedgers => 'دفاتر أخرى';

  @override
  String get shopSaleTitle => 'بيع للمحل';

  @override
  String get shop => 'المحل';

  @override
  String get soldGoods => 'البضاعة المباعة';

  @override
  String get receivedScrap => 'الكسر المستلم';

  @override
  String get receivedCash => 'النقد المستلم';

  @override
  String get addScrap => 'إضافة كسر';

  @override
  String scrapLine(int n) {
    return 'كسر $n';
  }

  @override
  String get cashAmount => 'المبلغ';

  @override
  String get accountEffect => 'الأثر على الحساب';

  @override
  String get goldBalance => 'رصيد الذهب';

  @override
  String get cashBalance => 'الرصيد النقدي';

  @override
  String get balanceBefore => 'قبل';

  @override
  String get balanceAfter => 'بعد';

  @override
  String owedToUs(String v) {
    return 'لنا $v';
  }

  @override
  String owedByUs(String v) {
    return 'له $v';
  }

  @override
  String get settledZero => 'صفر';

  @override
  String get emptyTx => 'أدخل بضاعة أو كسراً أو مبلغاً';

  @override
  String get saveTx => 'حفظ الحركة';

  @override
  String get sell => 'بيع';

  @override
  String get movements => 'الحركات';

  @override
  String get noMovements => 'لا توجد حركات بعد';

  @override
  String get goldChange => 'ذهب';

  @override
  String get cashChange => 'نقد';

  @override
  String bagNotEnough(String item, String karat, String have) {
    return '$item $karat: في الشنطة $have غ فقط';
  }

  @override
  String bagNotEnoughCount(String item, String karat, int have) {
    return '$item $karat: في الشنطة $have قطعة فقط';
  }

  @override
  String get saleExceedsBag => 'لا يمكن بيع أكثر مما في الشنطة:';

  @override
  String get onlyHolderSells => 'هذه الشنطة يبيع منها حاملها فقط';

  @override
  String get product => 'المنتج';

  @override
  String get pickFromBag => 'اختر من الشنطة — اضغط على المنتج لإضافته';

  @override
  String get txDetails => 'تفاصيل الحركة';

  @override
  String get docNumber => 'رقم الفاتورة';

  @override
  String get reversedTx => 'ملغاة';

  @override
  String get receivedGoods => 'البضاعة الواردة';

  @override
  String get deliveredScrap => 'الكسر المسلَّم';

  @override
  String get paidCash => 'النقد المدفوع';

  @override
  String get total => 'المجموع';

  @override
  String get traderOps => 'حركة مع التاجر';

  @override
  String get opSellGold => 'بيع ذهب / كسر للتاجر';

  @override
  String get opSellGoldDesc =>
      'بالهاتف غالباً: يصير علينا ذهب ولنا نقد بسعر الحلة';

  @override
  String get opBuyGold => 'شراء ذهب / كسر من التاجر';

  @override
  String get opBuyGoldDesc => 'يصير لنا ذهب وعلينا نقد بسعر الحلة';

  @override
  String get opFix => 'تسكير';

  @override
  String get opFixDesc => 'تحويل رصيد الذهب إلى نقد بسعر الحلة اليوم';

  @override
  String get opDeliverScrap => 'تسليم كسر للتاجر';

  @override
  String get opDeliverScrapDesc => 'يخرج من الشنطة ويُنقص ما علينا من ذهب';

  @override
  String get opReceiveScrap => 'استلام كسر من التاجر';

  @override
  String get opReceiveScrapDesc => 'يدخل الشنطة ويُنقص ما عليه من ذهب';

  @override
  String get opReceiveCash => 'قبض نقد / شيك';

  @override
  String get opReceiveCashDesc => 'الشيك يُحسب نقداً ويُسجَّل في دفتر الشيكات';

  @override
  String get opPayCash => 'دفع نقد / شيك';

  @override
  String get opPayCashDesc => 'الشيك يُحسب نقداً ويُسجَّل في دفتر الشيكات';

  @override
  String get opGoodsInvoice => 'فاتورة بضاعة + أجور';

  @override
  String get opGoodsInvoiceDesc => 'بضاعة واردة من التاجر إلى الشنطة';

  @override
  String get netGrams24 => 'الوزن صافي 24';

  @override
  String get pricePerGram24 => 'سعر غرام الحلة';

  @override
  String get totalValue => 'القيمة';

  @override
  String get fixDirection => 'اتجاه التسكير';

  @override
  String get fixWeOwe => 'ذهب علينا ← نقد علينا';

  @override
  String get fixTheyOwe => 'ذهب لنا ← نقد لنا';

  @override
  String get byCheque => 'بشيك';

  @override
  String get byChequeHint =>
      'يُحسب نقداً الآن، ويُتابَع استحقاقه في دفتر الشيكات';

  @override
  String get chequeNumber => 'رقم الشيك';

  @override
  String get bank => 'البنك';

  @override
  String get dueDate => 'تاريخ الاستحقاق';

  @override
  String bagScrapNotEnough(String karat, String have) {
    return '$karat: في الشنطة $have غ كسر فقط';
  }

  @override
  String get scrapExceedsBag => 'لا يمكن تسليم كسر أكثر مما في الشنطة:';

  @override
  String get supplier => 'المورّد (مشغل / تاجر)';

  @override
  String get newKarat => 'عيار جديد';

  @override
  String get karatNameLabel => 'اسم العيار (مثال: عيار 22 أو سبائك 9999)';

  @override
  String get factorLabel => 'المعامل';

  @override
  String get invalidFactor => 'معامل غير صالح — بين 0.001 و 1.000';

  @override
  String get karatAdded => 'أُضيف العيار';

  @override
  String get partialPricing => 'شراء جزء منه نقداً';

  @override
  String get partialPricingHint =>
      'جزء من الكسر يُحسب كاشاً علينا بسعر الحلة، والباقي يُضاف لرصيد الذهب';

  @override
  String get partGrams => 'الوزن المشترى (حلة)';

  @override
  String get partExceeds => 'الجزء المشترى أكبر من صافي الكسر المستلم';

  @override
  String get wholeBalance => 'كامل الرصيد';

  @override
  String get goldLines => 'الذهب / الكسر';

  @override
  String get netTotal => 'الصافي (حلة)';

  @override
  String get karatAndFactor => 'العيار والمعامل';

  @override
  String get otherFactor => 'عيار لحظي (لهذه العملية فقط)…';

  @override
  String get tabDistributors => 'الموزّعون';

  @override
  String get tabReceivables => 'الذمم';

  @override
  String get tabCompany => 'الشركة الدولية';

  @override
  String get tabEmployees => 'الموظفون';

  @override
  String get tabCheques => 'الشيكات';

  @override
  String get tabMore => 'المزيد';

  @override
  String get tabHome => 'الرئيسية';

  @override
  String get tabBags => 'الشنط';

  @override
  String get tabMyBag => 'شنطتي';

  @override
  String get tabTransfers => 'التسليم والاستلام';

  @override
  String get tabConfirmations => 'التأكيدات';

  @override
  String get tabStockCount => 'الجرد';

  @override
  String get tabSuppliers => 'الموردون';

  @override
  String get tabShowcase => 'الفترينة';

  @override
  String get tabCustomers => 'الزبائن';

  @override
  String get nextPhaseTitle => 'قيد البناء — المرحلة التالية';

  @override
  String get phFactoryHome =>
      'ملخص المصنع: رصيد كل شنطة، الحركات بانتظار التأكيد، وآخر جرد.';

  @override
  String get phTransfers =>
      'تسليم البضاعة للشنط واستلام الكسر والمرتجعات. كل حركة تنتظر تأكيد الطرف الآخر قبل أن تدخل الأرصدة.';

  @override
  String get phConfirmations =>
      'ما سلّمه المصنع لشنطتك بانتظار تأكيدك أو اعتراضك.';

  @override
  String get phStockCount =>
      'جرد مشترك بين المسؤول وحامل الشنطة، مع مقارنة الموجود فعلياً بالرصيد الدفتري.';

  @override
  String get phMyBag => 'رصيد شنطتك وحركاتها مع المحلات.';

  @override
  String get phSuppliers => 'دفاتر الموزّعين والمصانع الذين تتعامل معهم.';

  @override
  String get phShowcase => 'الذهب المعروض في الفترينة والعهدة لكل مورّد.';

  @override
  String get myAccount => 'حسابي';

  @override
  String get currentAccount => 'الحساب الحالي';

  @override
  String get switchAccount => 'تبديل الحساب';

  @override
  String get team => 'الفريق';

  @override
  String get teamDesc => 'إضافة الموظفين وتحديد صلاحياتهم';

  @override
  String get bags => 'الشنط';

  @override
  String get bagsDesc => 'الشنط وحاملوها';

  @override
  String get adminDashboard => 'لوحة الإدارة';

  @override
  String get registerAnotherOrg => 'تسجيل حساب آخر';

  @override
  String get registerAnotherOrgDesc =>
      'مثلاً حساب مستقل إلى جانب عضويتك في مصنع';

  @override
  String get endsOn => 'ينتهي في';

  @override
  String get noExpiry => 'بلا تاريخ انتهاء';

  @override
  String daysLeft(int days) {
    return 'متبقٍّ $days يوم';
  }

  @override
  String seatsUsed(int used, int max) {
    return '$used من $max مستخدمين';
  }

  @override
  String get inviteMember => 'إضافة عضو';

  @override
  String get pendingInvitations => 'دعوات بانتظار أول دخول';

  @override
  String get invitationHint => 'ينضم تلقائياً عند أول دخول برقمه';

  @override
  String get cancelInvitation => 'إلغاء الدعوة';

  @override
  String get memberName => 'اسم العضو';

  @override
  String get role => 'الدور';

  @override
  String get permissions => 'الصلاحيات';

  @override
  String get memberActive => 'العضوية سارية';

  @override
  String get inactive => 'موقوف';

  @override
  String get editMember => 'تعديل العضو';

  @override
  String get memberAdded => 'تمت إضافة العضو';

  @override
  String get invitationCreated => 'حُفظت الدعوة — ينضم عند أول دخول برقمه';

  @override
  String get you => '(أنت)';

  @override
  String get ownerOnly => 'هذه الصفحة للمالك فقط';

  @override
  String get ownerHasAll => 'المالك يملك كل الصلاحيات';

  @override
  String bagsUsed(int used, int max) {
    return '$used من $max شنط';
  }

  @override
  String get newBag => 'شنطة جديدة';

  @override
  String get bagName => 'اسم الشنطة';

  @override
  String get bagHolder => 'حامل الشنطة';

  @override
  String get noHolder => 'بدون حامل';

  @override
  String get bagActive => 'الشنطة فعّالة';

  @override
  String get editBag => 'تعديل الشنطة';

  @override
  String get noBags => 'لا توجد شنط';

  @override
  String get adminOverview => 'نظرة عامة';

  @override
  String get adminOrgs => 'المنشآت';

  @override
  String get statPending => 'بانتظار التفعيل';

  @override
  String get statActive => 'مفعّلة';

  @override
  String get statExpiring => 'تنتهي خلال 14 يوماً';

  @override
  String get statSuspended => 'موقوفة';

  @override
  String get statUsers => 'المستخدمون';

  @override
  String get pendingRequests => 'طلبات بانتظار المراجعة';

  @override
  String get noPending => 'لا توجد طلبات جديدة';

  @override
  String get searchOrgs => 'ابحث بالاسم أو الهاتف';

  @override
  String get all => 'الكل';

  @override
  String membersCount(int count) {
    return '$count أعضاء';
  }

  @override
  String get activate => 'تفعيل';

  @override
  String get renew => 'تجديد';

  @override
  String get suspend => 'إيقاف';

  @override
  String get reject => 'رفض';

  @override
  String get reactivate => 'إعادة التفعيل';

  @override
  String get months => 'المدة';

  @override
  String monthsCount(int count) {
    return '$count شهر';
  }

  @override
  String get note => 'ملاحظة';

  @override
  String get addMemberByPhone => 'إضافة عضو برقم الهاتف';

  @override
  String get createdAt => 'تاريخ التسجيل';

  @override
  String get owner => 'المالك';

  @override
  String get phone => 'الهاتف';

  @override
  String get activityLog => 'سجل النشاط';

  @override
  String get nameAr => 'الاسم بالعربية';

  @override
  String get nameEn => 'الاسم بالإنجليزية';

  @override
  String get price => 'السعر (د.أ)';

  @override
  String get maxUsers => 'الحد الأقصى للمستخدمين';

  @override
  String get maxBags => 'الحد الأقصى للشنط';

  @override
  String get extraBagPrice => 'سعر الشنطة الإضافية (د.أ)';

  @override
  String perPeriod(String price, int months) {
    return '$price د.أ / $months شهر';
  }

  @override
  String get priceNotSet => 'السعر غير محدد';

  @override
  String get noResults => 'لا نتائج';

  @override
  String get accountStatement => 'كشف حساب';

  @override
  String get statementPeriod => 'الفترة';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get lastMonth => 'الشهر الماضي';

  @override
  String get last3Months => 'آخر 3 أشهر';

  @override
  String get thisYear => 'هذه السنة';

  @override
  String get fromDate => 'من تاريخ';

  @override
  String get toDate => 'إلى تاريخ';

  @override
  String get statementLanguage => 'لغة الكشف';

  @override
  String get openingBalance => 'الرصيد السابق';

  @override
  String get closingBalance => 'الرصيد الختامي';

  @override
  String get periodMovements => 'حركات الفترة';

  @override
  String get previewPdf => 'معاينة ومشاركة PDF';

  @override
  String get statementHint =>
      'يبدأ الكشف بالرصيد السابق لبداية الفترة، ثم حركات الفترة، ولا تظهر فيه الملاحظات.';

  @override
  String get invalidRange => 'تاريخ البداية بعد تاريخ النهاية';

  @override
  String get cancelTx => 'إلغاء الحركة';

  @override
  String get cancelTxBody =>
      'لن تُحذف الحركة؛ سيُسجَّل قيد عكسي يعيد الأرصدة والمخزون كما كانت، وتبقى الحركتان ظاهرتين في الدفتر. الشيكات المعلّقة المرتبطة بها تُلغى أيضاً.';

  @override
  String get cancelReason => 'سبب الإلغاء';

  @override
  String get cancelConfirm => 'تأكيد الإلغاء';

  @override
  String txCancelledDoc(String doc) {
    return 'تم إلغاء الحركة — القيد العكسي رقم $doc';
  }

  @override
  String get txIsReversed =>
      'هذه الحركة ملغاة بقيد عكسي، ولا أثر لها على الأرصدة.';

  @override
  String get txIsReversal => 'هذا قيد عكسي ألغى حركة سابقة.';

  @override
  String get needMigration12 =>
      'يلزم تنفيذ ملف 0012_void_cheque.sql في Supabase أولاً';

  @override
  String get partialReturn => 'مرتجع جزئي';

  @override
  String get returnFromShopHint =>
      'القطع المرتجعة تعود إلى الشنطة، وينقص عن المحل ذهبها الصافي ومصنوعيتها بنفس سعر الفاتورة.';

  @override
  String get returnToWorkshopHint =>
      'القطع المرتجعة تخرج من الشنطة إلى المشغل، وينقص ما له علينا ذهباً ومصنوعيةً بنفس سعر الفاتورة.';

  @override
  String get returnAll => 'الكل';

  @override
  String get returnedCount => 'العدد المرتجع';

  @override
  String get returnedGross => 'الوزن المرتجع';

  @override
  String maxReturn(String count, String grams) {
    return 'المتاح للإرجاع: $count قطعة · $grams غ';
  }

  @override
  String get returnExceeds => 'أكبر من المتاح للإرجاع';

  @override
  String get nothingToReturn => 'أدخل وزن قطعة واحدة على الأقل';

  @override
  String returnSaved(String doc) {
    return 'تم حفظ المرتجع — رقم $doc';
  }

  @override
  String get returnedGoods => 'البضاعة المرتجعة';

  @override
  String get saveReturn => 'حفظ المرتجع';

  @override
  String get invoiceLines => 'بنود الفاتورة';

  @override
  String get bagEditionSubtitle =>
      'نسخة تاجر الشنطة — ادخل برقم هاتفك وكلمة المرور';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get wrongPhoneOrPassword => 'رقم الهاتف أو كلمة المرور غير صحيحة';

  @override
  String get forgotPasswordHint =>
      'نسيت كلمة المرور أو تحتاج حساباً جديداً؟ تواصل مع الدعم';

  @override
  String get accountNotEnabled => 'هذا الحساب غير مفعّل في هذه النسخة';

  @override
  String get accountNotEnabledHint =>
      'الحسابات تُضاف أو تُفعَّل من الدعم فقط. تواصل معنا لتفعيل حسابك.';

  @override
  String get letterheadTitle => 'بيانات الكشوفات والفواتير';

  @override
  String get letterheadHint => 'تظهر في رأس كل كشف حساب وفاتورة وتقرير PDF.';

  @override
  String get businessName => 'اسم المنشأة';

  @override
  String get businessPhone => 'هاتف المنشأة';

  @override
  String get businessCity => 'المدينة / العنوان';

  @override
  String get editionAccounts => 'الحسابات';

  @override
  String accountsUsed(int count, int max) {
    return '$count من $max حسابات مستخدمة';
  }

  @override
  String get accountsBySupport =>
      'إضافة حساب أو تغيير كلمة مرور أو إيقاف حساب يتم من الدعم. اضغط على حساب لتعديل صلاحياته.';

  @override
  String get appSection => 'التطبيق';

  @override
  String get aboutEdition => 'عن النسخة';

  @override
  String get editionVersion => 'نسخة تاجر الشنطة · 1.3.0';

  @override
  String get support => 'الدعم';

  @override
  String get edit => 'تعديل';

  @override
  String get needMigration13 =>
      'يلزم تنفيذ ملف 0013_bag_edition.sql في Supabase أولاً';

  @override
  String get welcome => 'أهلاً بك';

  @override
  String welcomeName(String name) {
    return 'أهلاً، $name';
  }

  @override
  String get noTradersYet => 'لا يوجد تجار بعد — أضف تاجراً من تبويب التجار';

  @override
  String get chooseTrader => 'اختر التاجر';

  @override
  String get quickSellShop => 'بيع لمحل';

  @override
  String get today => 'اليوم';

  @override
  String get noMovesToday => 'لا حركات اليوم بعد';

  @override
  String get todaySales => 'مبيعات اليوم (صافي)';

  @override
  String get makingProfit => 'ربح المصنوعية';

  @override
  String get cashIn => 'نقد مقبوض';

  @override
  String get cashOut => 'نقد مدفوع';

  @override
  String get movementsToday => 'عدد الحركات';

  @override
  String get scrapInBag => 'كسر في الشنطة';

  @override
  String get receivablesSummary => 'الذمم';

  @override
  String get topDebtors => 'أكبر الذمم بالذهب';

  @override
  String get chequesOverdue => 'شيكات متأخرة';

  @override
  String get chequesThisWeek => 'تستحق هذا الأسبوع';

  @override
  String get recentMovements => 'آخر الحركات';

  @override
  String get reports => 'التقارير';

  @override
  String get accountStatements => 'كشوفات الحسابات';

  @override
  String get shopStatement => 'كشف حساب محل';

  @override
  String get traderStatement => 'كشف حساب تاجر';

  @override
  String get workshopStatement => 'كشف حساب مشغل';

  @override
  String get statementTileHint => 'اختر الحساب والفترة — يبدأ بالرصيد السابق';

  @override
  String get salesAndBag => 'المبيعات والشنطة';

  @override
  String get salesReport => 'تقرير المبيعات';

  @override
  String get salesReportHint =>
      'يومي، أسبوعي، شهري — بالأيام والمحلات والأصناف';

  @override
  String get bagStatement => 'كشف الشنطة';

  @override
  String get bagStatementHint =>
      'الافتتاحي والداخل والخارج والختامي لكل صنف، وكل الحركات';

  @override
  String get bagInventoryNow => 'جرد الشنطة الآن';

  @override
  String get bagInventoryHint => 'ما في الشنطة الآن صنفاً صنفاً';

  @override
  String get shopsBalances => 'ذمم المحلات';

  @override
  String get tradersBalances => 'ذمم التجار';

  @override
  String get chequesReportHint => 'المعلّقة والمنتهية — ومنها تقرير PDF';

  @override
  String get noAccountsOfKind => 'لا توجد حسابات من هذا النوع بعد';

  @override
  String get chooseAccount => 'اختر الحساب';

  @override
  String get thisWeek => 'هذا الأسبوع';

  @override
  String get soldNet => 'المبيع (صافي)';

  @override
  String get netSales => 'صافي المبيعات';

  @override
  String get makingCharges => 'المصنوعية';

  @override
  String get invoicesCount => 'الفواتير';

  @override
  String get byShop => 'حسب المحل';

  @override
  String get byDay => 'حسب اليوم';

  @override
  String get noSalesInPeriod => 'لا مبيعات في هذه الفترة';

  @override
  String get goodsInPeriod => 'داخل في الفترة';

  @override
  String get goodsOutPeriod => 'خارج في الفترة';

  @override
  String get stockByItem => 'المخزون حسب الصنف';

  @override
  String get scrap => 'كسر';

  @override
  String get openingShort => 'افتتاحي';

  @override
  String get inShort => 'داخل';

  @override
  String get outShort => 'خارج';

  @override
  String get reportsHint => 'كشوفات الحسابات، المبيعات، كشف الشنطة، الذمم';

  @override
  String get shopOps => 'حركة مع المحل';

  @override
  String get shopSellDesc => 'بضاعة من الشنطة، مع استلام كسر أو نقد';

  @override
  String get shopFixDesc =>
      'يدفع نقداً بدل الذهب الذي عليه — بسعر غرام الحلة اليوم';

  @override
  String get movement => 'حركة';

  @override
  String get goodsInBag => 'البضاعة في الشنطة';

  @override
  String get totalGoldNet => 'إجمالي الذهب (صافي)';

  @override
  String get cashInBag => 'الكاش في الشنطة';

  @override
  String get chequesInHand => 'شيكات بحوزتك';

  @override
  String get cashboxBalance => 'رصيد الصندوق';

  @override
  String get chequesInPending => 'شيكات واردة لم تُصرف';

  @override
  String get chequesOutPending => 'شيكات صادرة لم تُصرف';

  @override
  String get cashInBagHint => 'النقد الفعلي الذي يجب أن يكون معك الآن.';

  @override
  String get expensesToday => 'مصاريف اليوم';

  @override
  String get newExpense => 'مصروف';

  @override
  String get closeDay => 'إغلاق اليوم';

  @override
  String get openDay => 'فتح اليوم';

  @override
  String get goodMorning => 'صباح الخير';

  @override
  String goodMorningName(String name) {
    return 'صباح الخير، $name';
  }

  @override
  String get openDayFor => 'بداية يوم';

  @override
  String get cashYouCarry => 'الكاش المحمول معك';

  @override
  String get cashLeftYesterday => 'ما بقي من آخر يوم';

  @override
  String cashAddedNote(String amount) {
    return 'ستُضيف $amount د.أ إلى كاش الشنطة';
  }

  @override
  String cashTakenNote(String amount) {
    return 'ستُنقص $amount د.أ من كاش الشنطة';
  }

  @override
  String get reasonRequired => 'السبب (إلزامي)';

  @override
  String get startDay => 'بدء اليوم';

  @override
  String get confirmGoodsFirst => 'أكّد البضاعة والكسر أولاً';

  @override
  String get dayReport => 'يومية الشنطة PDF';

  @override
  String get closeOldDayFirst =>
      'يوجد يوم سابق لم يُغلق. أغلقه أولاً لتبدأ يومك الجديد.';

  @override
  String get daySummary => 'ملخص اليوم';

  @override
  String get chequesReceived => 'شيكات مستلمة';

  @override
  String get cashPaidParties => 'نقد مدفوع للأطراف';

  @override
  String get afterExpenses => 'بعد المصاريف';

  @override
  String get bagCount => 'جرد الشنطة';

  @override
  String get confirmGoodsScrap => 'تأكدت أن البضاعة والكسر في الشنطة مطابقة';

  @override
  String get countCash => 'عدّ الكاش';

  @override
  String get cashExpected => 'الكاش المتوقع حسب الحركات';

  @override
  String get cashCounted => 'الكاش المعدود فعلاً';

  @override
  String get matches => 'مطابق';

  @override
  String cashShortage(String amount) {
    return 'عجز $amount د.أ';
  }

  @override
  String cashSurplus(String amount) {
    return 'زيادة $amount د.أ';
  }

  @override
  String get dayClosed => 'تم إغلاق اليوم ✓';

  @override
  String get continueLabel => 'متابعة';

  @override
  String get expFuel => 'بنزين';

  @override
  String get expFood => 'أكل';

  @override
  String get expTransport => 'مواصلات';

  @override
  String get expMaintenance => 'صيانة';

  @override
  String get expPersonal => 'سحب شخصي';

  @override
  String get expOther => 'أخرى';

  @override
  String get needMigration14 =>
      'يلزم تنفيذ ملف 0014_bag_day.sql في Supabase أولاً';

  @override
  String get expenseSaved => 'تم حفظ المصروف';

  @override
  String get expenseCategory => 'البند';

  @override
  String get expenseNoteRequired => 'الوصف (إلزامي)';

  @override
  String get expenseHint =>
      'يُخصم المبلغ من كاش الشنطة ويظهر في مصاريف اليوم وتقاريره.';

  @override
  String get instantKarat => 'عيار لحظي';

  @override
  String get makingPerPiece => 'المصنوعية / قطعة';

  @override
  String get perGram => 'على الغرام';

  @override
  String get perPiece => 'على القطعة';

  @override
  String get makingDiscount => 'خصم المصنوعية';

  @override
  String get noDiscount => 'بلا خصم';

  @override
  String get dropFraction => 'حذف الكسر';

  @override
  String get extraDiscount => 'خصم إضافي';

  @override
  String get finalMaking => 'المصنوعية النهائية';

  @override
  String get recoveredGoods => 'المسترد من المحل';

  @override
  String get recoveredMaking => 'مصنوعية المسترد';

  @override
  String get addRecovered => 'إضافة مسترد';

  @override
  String get dailyCashTotal => 'مجموع الكاش اليومي';

  @override
  String get dailyCashHint => 'كاش بداية اليوم + المقبوض';

  @override
  String get netCash => 'الكاش الصافي';

  @override
  String get fixClass => 'تصنيف التسكير';

  @override
  String get fixClassGold => 'حلة';

  @override
  String get fixClassScrap => 'كسر';

  @override
  String get fixCashNow => 'نقد الآن (اختياري)';

  @override
  String get fixCashHint => 'كله أو جزء منه أو صفر — والباقي يبقى ذمة.';

  @override
  String get fixWithTrader => 'تسكير مع تاجر أو مشغل (اختياري)';

  @override
  String get noTrader => 'بدون تاجر أو مشغل';

  @override
  String get traderGrams => 'غرامات التاجر';

  @override
  String get traderFixHint => 'فارغة = نفس غرامات المحل وسعره.';

  @override
  String get opReceiveGold => 'استلام ذهب';

  @override
  String get opReceiveGoldDesc =>
      'يدخل الشنطة بأي عيار، ومعامله 1.000 ويمكن تعديله';

  @override
  String get opDeliverGold => 'تسليم ذهب';

  @override
  String get opDeliverGoldDesc =>
      'يخرج من الشنطة بأي عيار، ومعامله 1.000 ويمكن تعديله';

  @override
  String get opLira => 'بيع ليرة مع الأجور';

  @override
  String get opLiraDesc => 'وزن قائم، والأجور على القطعة لنا';

  @override
  String get opExchange => 'بدل ذهب';

  @override
  String get opExchangeDesc => 'استلام وتسليم بأجور على الغرام، لنا أو علينا';

  @override
  String get liraFromBag => 'تخرج من الشنطة';

  @override
  String get liraFromBagHint => 'فعّله إذا كانت الليرة من مخزون الشنطة.';

  @override
  String get liraFee => 'الأجور / قطعة';

  @override
  String get liraCountNeeded => 'أدخل العدد لحساب الأجور.';

  @override
  String get exchangeReceived => 'الذهب المستلم';

  @override
  String get exchangeDelivered => 'الذهب المسلَّم (اختياري)';

  @override
  String get exchangeDeliveredHint => 'ما لا يُسلَّم الآن يبقى في الرصيد.';

  @override
  String get exchangeFee => 'أجور البدل';

  @override
  String get exchangeFeePerGram => 'الأجور / غرام';

  @override
  String get feeForUs => 'لنا';

  @override
  String get feeOnUs => 'علينا';

  @override
  String get openingBalances => 'الأرصدة الافتتاحية';

  @override
  String get openingBalancesHint =>
      'حسابات سابقة للمحلات والتجار والمشاغل، ومحتوى الشنطة';

  @override
  String get openingBag => 'محتوى الشنطة عند البدء';

  @override
  String get openingBagHint => 'البضاعة والكسر والكاش الموجود الآن';

  @override
  String get openingGold => 'رصيد الذهب (صافي 24)';

  @override
  String get openingCash => 'رصيد النقد';

  @override
  String get openingForUs => 'لنا عليه';

  @override
  String get openingForHim => 'له علينا';

  @override
  String openingSaved(String doc) {
    return 'تم تسجيل الرصيد — $doc';
  }

  @override
  String get bagMovements => 'الحركات';

  @override
  String get allMovements => 'الكل';

  @override
  String get movementsIn => 'وارد للشنطة';

  @override
  String get movementsOut => 'صادر من الشنطة';

  @override
  String get noBagMovements => 'لا توجد حركات في هذه الفترة';

  @override
  String lastMakingHint(String rate, String unit) {
    return 'آخر مصنوعية لهذا المحل: $rate $unit — يمكن تعديلها';
  }

  @override
  String recoveredLine(int n) {
    return 'مسترد $n';
  }

  @override
  String get tabExpenses => 'المصاريف';

  @override
  String get expensesTitle => 'المصاريف';

  @override
  String get noExpenses => 'لا مصاريف في هذه الفترة';

  @override
  String get expensesTotal => 'مجموع المصاريف';

  @override
  String get expensesOnEmployees => 'منها باسم الموظفين';

  @override
  String get expenseOnEmployee => 'على حساب موظف (اختياري)';

  @override
  String get noEmployee => 'بدون موظف';

  @override
  String get expenseEmployeeHint =>
      'يخرج من كاش الشنطة ويُخصم من راتب الموظف، ويظهر في مصاريف اليوم.';

  @override
  String get fixInSale => 'تسكير مع البيع (اختياري)';

  @override
  String get fixInSaleHint =>
      'تسكير غرامات المحل في نفس الفاتورة، ومعه تاجر أو مشغل إن أردت.';

  @override
  String get fixGrams => 'غرامات التسكير (صافي)';

  @override
  String get fixNeedsGramsPrice =>
      'أدخل غرامات التسكير وسعره، أو أطفئ التسكير.';

  @override
  String get fixSpread => 'فرق السعر';

  @override
  String get reopenDay => 'إعادة فتح اليوم';

  @override
  String get reopenDayConfirm =>
      'اليوم مغلق بجرده. أعد فتحه لتسجيل حركة نُسيت، ثم أغلقه من جديد بعدّ الكاش.';

  @override
  String get dayClosedHint =>
      'اليوم مغلق — لا تُسجَّل حركة بتاريخه حتى يُعاد فتحه.';

  @override
  String get goodsNet24 => 'صافي البضاعة عيار 24';
}
