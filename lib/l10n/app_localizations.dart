import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'إدارة توزيع الذهب'**
  String get appTitle;

  /// No description provided for @otherLanguage.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get otherLanguage;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @close.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get close;

  /// No description provided for @done.
  ///
  /// In ar, this message translates to:
  /// **'تم'**
  String get done;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @saved.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ'**
  String get saved;

  /// No description provided for @requiredField.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get requiredField;

  /// No description provided for @invalidNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم غير صالح'**
  String get invalidNumber;

  /// No description provided for @genericError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ: {message}'**
  String genericError(String message);

  /// No description provided for @offlineBanner.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد اتصال بالإنترنت — اتصل بالإنترنت لتسجيل الحركات'**
  String get offlineBanner;

  /// No description provided for @offlineAction.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن الحفظ بدون اتصال بالإنترنت'**
  String get offlineAction;

  /// No description provided for @loginTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم هاتفك وسنرسل لك رمز التحقق برسالة نصية'**
  String get loginSubtitle;

  /// No description provided for @phoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phoneLabel;

  /// No description provided for @phoneHint.
  ///
  /// In ar, this message translates to:
  /// **'07XXXXXXXX'**
  String get phoneHint;

  /// No description provided for @invalidPhone.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم جوال أردنياً صحيحاً'**
  String get invalidPhone;

  /// No description provided for @sendCode.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الرمز'**
  String get sendCode;

  /// No description provided for @enterCode.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رمز التحقق'**
  String get enterCode;

  /// No description provided for @codeSentTo.
  ///
  /// In ar, this message translates to:
  /// **'أرسلنا رمزاً من 6 أرقام إلى {phone}'**
  String codeSentTo(String phone);

  /// No description provided for @codeLabel.
  ///
  /// In ar, this message translates to:
  /// **'الرمز'**
  String get codeLabel;

  /// No description provided for @invalidCode.
  ///
  /// In ar, this message translates to:
  /// **'الرمز يتكوّن من 6 أرقام'**
  String get invalidCode;

  /// No description provided for @verify.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get verify;

  /// No description provided for @resendCode.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إرسال الرمز'**
  String get resendCode;

  /// No description provided for @resendIn.
  ///
  /// In ar, this message translates to:
  /// **'إعادة الإرسال بعد {seconds} ثانية'**
  String resendIn(int seconds);

  /// No description provided for @wrongCode.
  ///
  /// In ar, this message translates to:
  /// **'الرمز غير صحيح أو انتهت صلاحيته'**
  String get wrongCode;

  /// No description provided for @signIn.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get signIn;

  /// No description provided for @loginSubtitleDev.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم هاتفك للدخول'**
  String get loginSubtitleDev;

  /// No description provided for @devModeBadge.
  ///
  /// In ar, this message translates to:
  /// **'وضع التجربة — الدخول بدون رمز'**
  String get devModeBadge;

  /// No description provided for @comingSoon.
  ///
  /// In ar, this message translates to:
  /// **'قريباً'**
  String get comingSoon;

  /// No description provided for @changeNumber.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الرقم'**
  String get changeNumber;

  /// No description provided for @signOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOut;

  /// No description provided for @signOutConfirm.
  ///
  /// In ar, this message translates to:
  /// **'هل تريد تسجيل الخروج من هذا الجهاز؟'**
  String get signOutConfirm;

  /// No description provided for @registerTitle.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب جديد'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر نوع حسابك ثم أكمل بياناتك. يُراجَع الطلب ويُفعَّل من إدارة التطبيق.'**
  String get registerSubtitle;

  /// No description provided for @accountType.
  ///
  /// In ar, this message translates to:
  /// **'نوع الحساب'**
  String get accountType;

  /// No description provided for @orgTypeDistributor.
  ///
  /// In ar, this message translates to:
  /// **'تاجر شنطة / موزّع'**
  String get orgTypeDistributor;

  /// No description provided for @orgTypeDistributorDesc.
  ///
  /// In ar, this message translates to:
  /// **'موزّع ذهب بشنطة أو أكثر، يتعامل مع المحلات والمشاغل'**
  String get orgTypeDistributorDesc;

  /// No description provided for @orgTypeFactory.
  ///
  /// In ar, this message translates to:
  /// **'مصنع / مشغل'**
  String get orgTypeFactory;

  /// No description provided for @orgTypeFactoryDesc.
  ///
  /// In ar, this message translates to:
  /// **'مشغل تشكيل ذهب بعدة شنط توزيع وموزّعين تابعين له'**
  String get orgTypeFactoryDesc;

  /// No description provided for @orgTypeShop.
  ///
  /// In ar, this message translates to:
  /// **'محل ذهب'**
  String get orgTypeShop;

  /// No description provided for @orgTypeShopDesc.
  ///
  /// In ar, this message translates to:
  /// **'محل بيع ذهب يتعامل مع الموزّعين والمصانع والزبائن'**
  String get orgTypeShopDesc;

  /// No description provided for @orgName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم التجاري'**
  String get orgName;

  /// No description provided for @ownerName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المالك'**
  String get ownerName;

  /// No description provided for @city.
  ///
  /// In ar, this message translates to:
  /// **'المحافظة'**
  String get city;

  /// No description provided for @submitRequest.
  ///
  /// In ar, this message translates to:
  /// **'إرسال طلب التسجيل'**
  String get submitRequest;

  /// No description provided for @chooseAccountType.
  ///
  /// In ar, this message translates to:
  /// **'اختر نوع الحساب أولاً'**
  String get chooseAccountType;

  /// No description provided for @statusPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد المراجعة'**
  String get statusPending;

  /// No description provided for @statusActive.
  ///
  /// In ar, this message translates to:
  /// **'مفعّل'**
  String get statusActive;

  /// No description provided for @statusSuspended.
  ///
  /// In ar, this message translates to:
  /// **'موقوف'**
  String get statusSuspended;

  /// No description provided for @statusRejected.
  ///
  /// In ar, this message translates to:
  /// **'مرفوض'**
  String get statusRejected;

  /// No description provided for @statusPendingTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلبك قيد المراجعة'**
  String get statusPendingTitle;

  /// No description provided for @statusPendingBody.
  ///
  /// In ar, this message translates to:
  /// **'استلمنا طلب تسجيل «{org}». سيتواصل معك فريقنا لتفعيل الحساب واختيار الباقة.'**
  String statusPendingBody(String org);

  /// No description provided for @statusRejectedTitle.
  ///
  /// In ar, this message translates to:
  /// **'لم تتم الموافقة على الطلب'**
  String get statusRejectedTitle;

  /// No description provided for @statusSuspendedTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحساب موقوف'**
  String get statusSuspendedTitle;

  /// No description provided for @statusSuspendedBody.
  ///
  /// In ar, this message translates to:
  /// **'تم إيقاف حساب «{org}». تواصل مع إدارة التطبيق.'**
  String statusSuspendedBody(String org);

  /// No description provided for @statusNote.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة: {note}'**
  String statusNote(String note);

  /// No description provided for @checkAgain.
  ///
  /// In ar, this message translates to:
  /// **'تحقّق مجدداً'**
  String get checkAgain;

  /// No description provided for @contactUs.
  ///
  /// In ar, this message translates to:
  /// **'للتواصل: {phone}'**
  String contactUs(String phone);

  /// No description provided for @roleOwner.
  ///
  /// In ar, this message translates to:
  /// **'المالك'**
  String get roleOwner;

  /// No description provided for @roleManager.
  ///
  /// In ar, this message translates to:
  /// **'مسؤول'**
  String get roleManager;

  /// No description provided for @roleBagHolder.
  ///
  /// In ar, this message translates to:
  /// **'حامل شنطة'**
  String get roleBagHolder;

  /// No description provided for @roleAssistant.
  ///
  /// In ar, this message translates to:
  /// **'مساعد'**
  String get roleAssistant;

  /// No description provided for @roleManagerDesc.
  ///
  /// In ar, this message translates to:
  /// **'يسلّم ويستلم ويعتمد الجرد حسب الصلاحيات الممنوحة'**
  String get roleManagerDesc;

  /// No description provided for @roleBagHolderDesc.
  ///
  /// In ar, this message translates to:
  /// **'يحمل شنطة ويؤكد ما يُسلَّم إليها'**
  String get roleBagHolderDesc;

  /// No description provided for @roleAssistantDesc.
  ///
  /// In ar, this message translates to:
  /// **'يسجّل الحركات فقط'**
  String get roleAssistantDesc;

  /// No description provided for @permLedgerWrite.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الحركات'**
  String get permLedgerWrite;

  /// No description provided for @permFinanceView.
  ///
  /// In ar, this message translates to:
  /// **'رؤية الأرصدة والتقارير المالية'**
  String get permFinanceView;

  /// No description provided for @permBagsViewAll.
  ///
  /// In ar, this message translates to:
  /// **'رؤية كل الشنط'**
  String get permBagsViewAll;

  /// No description provided for @permBagsIssue.
  ///
  /// In ar, this message translates to:
  /// **'تسليم بضاعة للشنط'**
  String get permBagsIssue;

  /// No description provided for @permBagsConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الاستلام والمرتجعات'**
  String get permBagsConfirm;

  /// No description provided for @permStockCount.
  ///
  /// In ar, this message translates to:
  /// **'طلب الجرد واعتماده'**
  String get permStockCount;

  /// No description provided for @permChequesManage.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الشيكات'**
  String get permChequesManage;

  /// No description provided for @tabBag.
  ///
  /// In ar, this message translates to:
  /// **'الشنطة'**
  String get tabBag;

  /// No description provided for @goodsIn.
  ///
  /// In ar, this message translates to:
  /// **'وارد بضاعة'**
  String get goodsIn;

  /// No description provided for @goodsInTitle.
  ///
  /// In ar, this message translates to:
  /// **'وارد بضاعة من مشغل'**
  String get goodsInTitle;

  /// No description provided for @workshop.
  ///
  /// In ar, this message translates to:
  /// **'المشغل'**
  String get workshop;

  /// No description provided for @newWorkshop.
  ///
  /// In ar, this message translates to:
  /// **'مشغل جديد'**
  String get newWorkshop;

  /// No description provided for @workshopName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المشغل'**
  String get workshopName;

  /// No description provided for @noWorkshops.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مشاغل بعد — أضف أول مشغل'**
  String get noWorkshops;

  /// No description provided for @item.
  ///
  /// In ar, this message translates to:
  /// **'الصنف'**
  String get item;

  /// No description provided for @newItem.
  ///
  /// In ar, this message translates to:
  /// **'صنف جديد'**
  String get newItem;

  /// No description provided for @itemName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الصنف'**
  String get itemName;

  /// No description provided for @count.
  ///
  /// In ar, this message translates to:
  /// **'العدد'**
  String get count;

  /// No description provided for @grossWeight.
  ///
  /// In ar, this message translates to:
  /// **'الوزن القائم'**
  String get grossWeight;

  /// No description provided for @karat.
  ///
  /// In ar, this message translates to:
  /// **'العيار'**
  String get karat;

  /// No description provided for @makingPerGram.
  ///
  /// In ar, this message translates to:
  /// **'المصنوعية / غرام'**
  String get makingPerGram;

  /// No description provided for @net24.
  ///
  /// In ar, this message translates to:
  /// **'الصافي (24)'**
  String get net24;

  /// No description provided for @making.
  ///
  /// In ar, this message translates to:
  /// **'المصنوعية'**
  String get making;

  /// No description provided for @addLine.
  ///
  /// In ar, this message translates to:
  /// **'إضافة صنف آخر'**
  String get addLine;

  /// No description provided for @lineNumber.
  ///
  /// In ar, this message translates to:
  /// **'بند {n}'**
  String lineNumber(int n);

  /// No description provided for @summary.
  ///
  /// In ar, this message translates to:
  /// **'الملخص'**
  String get summary;

  /// No description provided for @totalPieces.
  ///
  /// In ar, this message translates to:
  /// **'عدد القطع'**
  String get totalPieces;

  /// No description provided for @totalGross.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي القائم'**
  String get totalGross;

  /// No description provided for @totalNet.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الصافي عيار 24'**
  String get totalNet;

  /// No description provided for @totalMaking.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المصنوعية'**
  String get totalMaking;

  /// No description provided for @effectWorkshop.
  ///
  /// In ar, this message translates to:
  /// **'يصبح للمشغل علينا: {gold} غ صافي و {cash} د.أ مصنوعية'**
  String effectWorkshop(String gold, String cash);

  /// No description provided for @saveInvoice.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الفاتورة'**
  String get saveInvoice;

  /// No description provided for @invoiceSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ الفاتورة — رقم {doc}'**
  String invoiceSaved(String doc);

  /// No description provided for @fillLines.
  ///
  /// In ar, this message translates to:
  /// **'أكمل الصنف والوزن في كل بند'**
  String get fillLines;

  /// No description provided for @noteOptional.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات (اختياري)'**
  String get noteOptional;

  /// No description provided for @date.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get date;

  /// No description provided for @gramsUnit.
  ///
  /// In ar, this message translates to:
  /// **'غ'**
  String get gramsUnit;

  /// No description provided for @dinarUnit.
  ///
  /// In ar, this message translates to:
  /// **'د.أ'**
  String get dinarUnit;

  /// No description provided for @bagEmpty.
  ///
  /// In ar, this message translates to:
  /// **'الشنطة فارغة'**
  String get bagEmpty;

  /// No description provided for @bagEmptyHint.
  ///
  /// In ar, this message translates to:
  /// **'سجّل وارد بضاعة من مشغل لتظهر هنا بالعدد والوزن.'**
  String get bagEmptyHint;

  /// No description provided for @bagCapital.
  ///
  /// In ar, this message translates to:
  /// **'رأس المال (مصنوعية)'**
  String get bagCapital;

  /// No description provided for @piecesCount.
  ///
  /// In ar, this message translates to:
  /// **'{n} قطعة'**
  String piecesCount(int n);

  /// No description provided for @unknownItem.
  ///
  /// In ar, this message translates to:
  /// **'كسر'**
  String get unknownItem;

  /// No description provided for @invalidWeight.
  ///
  /// In ar, this message translates to:
  /// **'وزن غير صالح'**
  String get invalidWeight;

  /// No description provided for @invalidAmount.
  ///
  /// In ar, this message translates to:
  /// **'مبلغ غير صالح'**
  String get invalidAmount;

  /// No description provided for @remove.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get remove;

  /// No description provided for @tabShops.
  ///
  /// In ar, this message translates to:
  /// **'المحلات'**
  String get tabShops;

  /// No description provided for @tabTraders.
  ///
  /// In ar, this message translates to:
  /// **'التجار'**
  String get tabTraders;

  /// No description provided for @tabSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get tabSettings;

  /// No description provided for @phDistributorHome.
  ///
  /// In ar, this message translates to:
  /// **'ملخص يومك: رصيد الشنطة، ما لك على المحلات والتجار، وما عليك للمشاغل.'**
  String get phDistributorHome;

  /// No description provided for @bagStock.
  ///
  /// In ar, this message translates to:
  /// **'المخزون'**
  String get bagStock;

  /// No description provided for @bagWorkshops.
  ///
  /// In ar, this message translates to:
  /// **'المشاغل'**
  String get bagWorkshops;

  /// No description provided for @newShop.
  ///
  /// In ar, this message translates to:
  /// **'محل جديد'**
  String get newShop;

  /// No description provided for @newTrader.
  ///
  /// In ar, this message translates to:
  /// **'تاجر جديد'**
  String get newTrader;

  /// No description provided for @noShops.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد محلات بعد'**
  String get noShops;

  /// No description provided for @noShopsHint.
  ///
  /// In ar, this message translates to:
  /// **'أضف المحلات التي تبيعها البضاعة.'**
  String get noShopsHint;

  /// No description provided for @noTraders.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد تجار بعد'**
  String get noTraders;

  /// No description provided for @noTradersHint.
  ///
  /// In ar, this message translates to:
  /// **'أضف التجار الذين تبيعهم الكسر أو تشتريه منهم أو تسكّر معهم.'**
  String get noTradersHint;

  /// No description provided for @noWorkshopsHint.
  ///
  /// In ar, this message translates to:
  /// **'أضف المشاغل التي تأخذ منها البضاعة.'**
  String get noWorkshopsHint;

  /// No description provided for @otherLedgers.
  ///
  /// In ar, this message translates to:
  /// **'دفاتر أخرى'**
  String get otherLedgers;

  /// No description provided for @shopSaleTitle.
  ///
  /// In ar, this message translates to:
  /// **'بيع للمحل'**
  String get shopSaleTitle;

  /// No description provided for @shop.
  ///
  /// In ar, this message translates to:
  /// **'المحل'**
  String get shop;

  /// No description provided for @soldGoods.
  ///
  /// In ar, this message translates to:
  /// **'البضاعة المباعة'**
  String get soldGoods;

  /// No description provided for @receivedScrap.
  ///
  /// In ar, this message translates to:
  /// **'الكسر المستلم'**
  String get receivedScrap;

  /// No description provided for @receivedCash.
  ///
  /// In ar, this message translates to:
  /// **'النقد المستلم'**
  String get receivedCash;

  /// No description provided for @addScrap.
  ///
  /// In ar, this message translates to:
  /// **'إضافة كسر'**
  String get addScrap;

  /// No description provided for @scrapLine.
  ///
  /// In ar, this message translates to:
  /// **'كسر {n}'**
  String scrapLine(int n);

  /// No description provided for @cashAmount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get cashAmount;

  /// No description provided for @accountEffect.
  ///
  /// In ar, this message translates to:
  /// **'الأثر على الحساب'**
  String get accountEffect;

  /// No description provided for @goldBalance.
  ///
  /// In ar, this message translates to:
  /// **'رصيد الذهب'**
  String get goldBalance;

  /// No description provided for @cashBalance.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد النقدي'**
  String get cashBalance;

  /// No description provided for @balanceBefore.
  ///
  /// In ar, this message translates to:
  /// **'قبل'**
  String get balanceBefore;

  /// No description provided for @balanceAfter.
  ///
  /// In ar, this message translates to:
  /// **'بعد'**
  String get balanceAfter;

  /// No description provided for @owedToUs.
  ///
  /// In ar, this message translates to:
  /// **'لنا {v}'**
  String owedToUs(String v);

  /// No description provided for @owedByUs.
  ///
  /// In ar, this message translates to:
  /// **'له {v}'**
  String owedByUs(String v);

  /// No description provided for @settledZero.
  ///
  /// In ar, this message translates to:
  /// **'صفر'**
  String get settledZero;

  /// No description provided for @emptyTx.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بضاعة أو كسراً أو مبلغاً'**
  String get emptyTx;

  /// No description provided for @saveTx.
  ///
  /// In ar, this message translates to:
  /// **'حفظ الحركة'**
  String get saveTx;

  /// No description provided for @sell.
  ///
  /// In ar, this message translates to:
  /// **'بيع'**
  String get sell;

  /// No description provided for @movements.
  ///
  /// In ar, this message translates to:
  /// **'الحركات'**
  String get movements;

  /// No description provided for @noMovements.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد حركات بعد'**
  String get noMovements;

  /// No description provided for @goldChange.
  ///
  /// In ar, this message translates to:
  /// **'ذهب'**
  String get goldChange;

  /// No description provided for @cashChange.
  ///
  /// In ar, this message translates to:
  /// **'نقد'**
  String get cashChange;

  /// No description provided for @bagNotEnough.
  ///
  /// In ar, this message translates to:
  /// **'{item} {karat}: في الشنطة {have} غ فقط'**
  String bagNotEnough(String item, String karat, String have);

  /// No description provided for @bagNotEnoughCount.
  ///
  /// In ar, this message translates to:
  /// **'{item} {karat}: في الشنطة {have} قطعة فقط'**
  String bagNotEnoughCount(String item, String karat, int have);

  /// No description provided for @saleExceedsBag.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن بيع أكثر مما في الشنطة:'**
  String get saleExceedsBag;

  /// No description provided for @onlyHolderSells.
  ///
  /// In ar, this message translates to:
  /// **'هذه الشنطة يبيع منها حاملها فقط'**
  String get onlyHolderSells;

  /// No description provided for @product.
  ///
  /// In ar, this message translates to:
  /// **'المنتج'**
  String get product;

  /// No description provided for @pickFromBag.
  ///
  /// In ar, this message translates to:
  /// **'اختر من الشنطة — اضغط على المنتج لإضافته'**
  String get pickFromBag;

  /// No description provided for @txDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الحركة'**
  String get txDetails;

  /// No description provided for @docNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الفاتورة'**
  String get docNumber;

  /// No description provided for @reversedTx.
  ///
  /// In ar, this message translates to:
  /// **'ملغاة'**
  String get reversedTx;

  /// No description provided for @receivedGoods.
  ///
  /// In ar, this message translates to:
  /// **'البضاعة الواردة'**
  String get receivedGoods;

  /// No description provided for @deliveredScrap.
  ///
  /// In ar, this message translates to:
  /// **'الكسر المسلَّم'**
  String get deliveredScrap;

  /// No description provided for @paidCash.
  ///
  /// In ar, this message translates to:
  /// **'النقد المدفوع'**
  String get paidCash;

  /// No description provided for @total.
  ///
  /// In ar, this message translates to:
  /// **'المجموع'**
  String get total;

  /// No description provided for @traderOps.
  ///
  /// In ar, this message translates to:
  /// **'حركة مع التاجر'**
  String get traderOps;

  /// No description provided for @opSellGold.
  ///
  /// In ar, this message translates to:
  /// **'بيع ذهب / كسر للتاجر'**
  String get opSellGold;

  /// No description provided for @opSellGoldDesc.
  ///
  /// In ar, this message translates to:
  /// **'بالهاتف غالباً: يصير علينا ذهب ولنا نقد بسعر الحلة'**
  String get opSellGoldDesc;

  /// No description provided for @opBuyGold.
  ///
  /// In ar, this message translates to:
  /// **'شراء ذهب / كسر من التاجر'**
  String get opBuyGold;

  /// No description provided for @opBuyGoldDesc.
  ///
  /// In ar, this message translates to:
  /// **'يصير لنا ذهب وعلينا نقد بسعر الحلة'**
  String get opBuyGoldDesc;

  /// No description provided for @opFix.
  ///
  /// In ar, this message translates to:
  /// **'تسكير'**
  String get opFix;

  /// No description provided for @opFixDesc.
  ///
  /// In ar, this message translates to:
  /// **'تحويل رصيد الذهب إلى نقد بسعر الحلة اليوم'**
  String get opFixDesc;

  /// No description provided for @opDeliverScrap.
  ///
  /// In ar, this message translates to:
  /// **'تسليم كسر للتاجر'**
  String get opDeliverScrap;

  /// No description provided for @opDeliverScrapDesc.
  ///
  /// In ar, this message translates to:
  /// **'يخرج من الشنطة ويُنقص ما علينا من ذهب'**
  String get opDeliverScrapDesc;

  /// No description provided for @opReceiveScrap.
  ///
  /// In ar, this message translates to:
  /// **'استلام كسر من التاجر'**
  String get opReceiveScrap;

  /// No description provided for @opReceiveScrapDesc.
  ///
  /// In ar, this message translates to:
  /// **'يدخل الشنطة ويُنقص ما عليه من ذهب'**
  String get opReceiveScrapDesc;

  /// No description provided for @opReceiveCash.
  ///
  /// In ar, this message translates to:
  /// **'قبض نقد / شيك'**
  String get opReceiveCash;

  /// No description provided for @opReceiveCashDesc.
  ///
  /// In ar, this message translates to:
  /// **'الشيك يُحسب نقداً ويُسجَّل في دفتر الشيكات'**
  String get opReceiveCashDesc;

  /// No description provided for @opPayCash.
  ///
  /// In ar, this message translates to:
  /// **'دفع نقد / شيك'**
  String get opPayCash;

  /// No description provided for @opPayCashDesc.
  ///
  /// In ar, this message translates to:
  /// **'الشيك يُحسب نقداً ويُسجَّل في دفتر الشيكات'**
  String get opPayCashDesc;

  /// No description provided for @opGoodsInvoice.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة بضاعة + أجور'**
  String get opGoodsInvoice;

  /// No description provided for @opGoodsInvoiceDesc.
  ///
  /// In ar, this message translates to:
  /// **'بضاعة واردة من التاجر إلى الشنطة'**
  String get opGoodsInvoiceDesc;

  /// No description provided for @netGrams24.
  ///
  /// In ar, this message translates to:
  /// **'الوزن صافي 24'**
  String get netGrams24;

  /// No description provided for @pricePerGram24.
  ///
  /// In ar, this message translates to:
  /// **'سعر غرام الحلة'**
  String get pricePerGram24;

  /// No description provided for @totalValue.
  ///
  /// In ar, this message translates to:
  /// **'القيمة'**
  String get totalValue;

  /// No description provided for @fixDirection.
  ///
  /// In ar, this message translates to:
  /// **'اتجاه التسكير'**
  String get fixDirection;

  /// No description provided for @fixWeOwe.
  ///
  /// In ar, this message translates to:
  /// **'ذهب علينا ← نقد علينا'**
  String get fixWeOwe;

  /// No description provided for @fixTheyOwe.
  ///
  /// In ar, this message translates to:
  /// **'ذهب لنا ← نقد لنا'**
  String get fixTheyOwe;

  /// No description provided for @byCheque.
  ///
  /// In ar, this message translates to:
  /// **'بشيك'**
  String get byCheque;

  /// No description provided for @byChequeHint.
  ///
  /// In ar, this message translates to:
  /// **'يُحسب نقداً الآن، ويُتابَع استحقاقه في دفتر الشيكات'**
  String get byChequeHint;

  /// No description provided for @chequeNumber.
  ///
  /// In ar, this message translates to:
  /// **'رقم الشيك'**
  String get chequeNumber;

  /// No description provided for @bank.
  ///
  /// In ar, this message translates to:
  /// **'البنك'**
  String get bank;

  /// No description provided for @dueDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الاستحقاق'**
  String get dueDate;

  /// No description provided for @bagScrapNotEnough.
  ///
  /// In ar, this message translates to:
  /// **'{karat}: في الشنطة {have} غ كسر فقط'**
  String bagScrapNotEnough(String karat, String have);

  /// No description provided for @scrapExceedsBag.
  ///
  /// In ar, this message translates to:
  /// **'لا يمكن تسليم كسر أكثر مما في الشنطة:'**
  String get scrapExceedsBag;

  /// No description provided for @supplier.
  ///
  /// In ar, this message translates to:
  /// **'المورّد (مشغل / تاجر)'**
  String get supplier;

  /// No description provided for @newKarat.
  ///
  /// In ar, this message translates to:
  /// **'عيار جديد'**
  String get newKarat;

  /// No description provided for @karatNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم العيار (مثال: عيار 22 أو سبائك 9999)'**
  String get karatNameLabel;

  /// No description provided for @factorLabel.
  ///
  /// In ar, this message translates to:
  /// **'المعامل'**
  String get factorLabel;

  /// No description provided for @invalidFactor.
  ///
  /// In ar, this message translates to:
  /// **'معامل غير صالح — بين 0.001 و 1.000'**
  String get invalidFactor;

  /// No description provided for @karatAdded.
  ///
  /// In ar, this message translates to:
  /// **'أُضيف العيار'**
  String get karatAdded;

  /// No description provided for @partialPricing.
  ///
  /// In ar, this message translates to:
  /// **'شراء جزء منه نقداً'**
  String get partialPricing;

  /// No description provided for @partialPricingHint.
  ///
  /// In ar, this message translates to:
  /// **'جزء من الكسر يُحسب كاشاً علينا بسعر الحلة، والباقي يُضاف لرصيد الذهب'**
  String get partialPricingHint;

  /// No description provided for @partGrams.
  ///
  /// In ar, this message translates to:
  /// **'الوزن المشترى (حلة)'**
  String get partGrams;

  /// No description provided for @partExceeds.
  ///
  /// In ar, this message translates to:
  /// **'الجزء المشترى أكبر من صافي الكسر المستلم'**
  String get partExceeds;

  /// No description provided for @wholeBalance.
  ///
  /// In ar, this message translates to:
  /// **'كامل الرصيد'**
  String get wholeBalance;

  /// No description provided for @goldLines.
  ///
  /// In ar, this message translates to:
  /// **'الذهب / الكسر'**
  String get goldLines;

  /// No description provided for @netTotal.
  ///
  /// In ar, this message translates to:
  /// **'الصافي (حلة)'**
  String get netTotal;

  /// No description provided for @karatAndFactor.
  ///
  /// In ar, this message translates to:
  /// **'العيار والمعامل'**
  String get karatAndFactor;

  /// No description provided for @otherFactor.
  ///
  /// In ar, this message translates to:
  /// **'عيار لحظي (لهذه العملية فقط)…'**
  String get otherFactor;

  /// No description provided for @tabDistributors.
  ///
  /// In ar, this message translates to:
  /// **'الموزّعون'**
  String get tabDistributors;

  /// No description provided for @tabReceivables.
  ///
  /// In ar, this message translates to:
  /// **'الذمم'**
  String get tabReceivables;

  /// No description provided for @tabCompany.
  ///
  /// In ar, this message translates to:
  /// **'الشركة الدولية'**
  String get tabCompany;

  /// No description provided for @tabEmployees.
  ///
  /// In ar, this message translates to:
  /// **'الموظفون'**
  String get tabEmployees;

  /// No description provided for @tabCheques.
  ///
  /// In ar, this message translates to:
  /// **'الشيكات'**
  String get tabCheques;

  /// No description provided for @tabMore.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get tabMore;

  /// No description provided for @tabHome.
  ///
  /// In ar, this message translates to:
  /// **'الرئيسية'**
  String get tabHome;

  /// No description provided for @tabBags.
  ///
  /// In ar, this message translates to:
  /// **'الشنط'**
  String get tabBags;

  /// No description provided for @tabMyBag.
  ///
  /// In ar, this message translates to:
  /// **'شنطتي'**
  String get tabMyBag;

  /// No description provided for @tabTransfers.
  ///
  /// In ar, this message translates to:
  /// **'التسليم والاستلام'**
  String get tabTransfers;

  /// No description provided for @tabConfirmations.
  ///
  /// In ar, this message translates to:
  /// **'التأكيدات'**
  String get tabConfirmations;

  /// No description provided for @tabStockCount.
  ///
  /// In ar, this message translates to:
  /// **'الجرد'**
  String get tabStockCount;

  /// No description provided for @tabSuppliers.
  ///
  /// In ar, this message translates to:
  /// **'الموردون'**
  String get tabSuppliers;

  /// No description provided for @tabShowcase.
  ///
  /// In ar, this message translates to:
  /// **'الفترينة'**
  String get tabShowcase;

  /// No description provided for @tabCustomers.
  ///
  /// In ar, this message translates to:
  /// **'الزبائن'**
  String get tabCustomers;

  /// No description provided for @nextPhaseTitle.
  ///
  /// In ar, this message translates to:
  /// **'قيد البناء — المرحلة التالية'**
  String get nextPhaseTitle;

  /// No description provided for @phFactoryHome.
  ///
  /// In ar, this message translates to:
  /// **'ملخص المصنع: رصيد كل شنطة، الحركات بانتظار التأكيد، وآخر جرد.'**
  String get phFactoryHome;

  /// No description provided for @phTransfers.
  ///
  /// In ar, this message translates to:
  /// **'تسليم البضاعة للشنط واستلام الكسر والمرتجعات. كل حركة تنتظر تأكيد الطرف الآخر قبل أن تدخل الأرصدة.'**
  String get phTransfers;

  /// No description provided for @phConfirmations.
  ///
  /// In ar, this message translates to:
  /// **'ما سلّمه المصنع لشنطتك بانتظار تأكيدك أو اعتراضك.'**
  String get phConfirmations;

  /// No description provided for @phStockCount.
  ///
  /// In ar, this message translates to:
  /// **'جرد مشترك بين المسؤول وحامل الشنطة، مع مقارنة الموجود فعلياً بالرصيد الدفتري.'**
  String get phStockCount;

  /// No description provided for @phMyBag.
  ///
  /// In ar, this message translates to:
  /// **'رصيد شنطتك وحركاتها مع المحلات.'**
  String get phMyBag;

  /// No description provided for @phSuppliers.
  ///
  /// In ar, this message translates to:
  /// **'دفاتر الموزّعين والمصانع الذين تتعامل معهم.'**
  String get phSuppliers;

  /// No description provided for @phShowcase.
  ///
  /// In ar, this message translates to:
  /// **'الذهب المعروض في الفترينة والعهدة لكل مورّد.'**
  String get phShowcase;

  /// No description provided for @myAccount.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get myAccount;

  /// No description provided for @currentAccount.
  ///
  /// In ar, this message translates to:
  /// **'الحساب الحالي'**
  String get currentAccount;

  /// No description provided for @switchAccount.
  ///
  /// In ar, this message translates to:
  /// **'تبديل الحساب'**
  String get switchAccount;

  /// No description provided for @team.
  ///
  /// In ar, this message translates to:
  /// **'الفريق'**
  String get team;

  /// No description provided for @teamDesc.
  ///
  /// In ar, this message translates to:
  /// **'إضافة الموظفين وتحديد صلاحياتهم'**
  String get teamDesc;

  /// No description provided for @bags.
  ///
  /// In ar, this message translates to:
  /// **'الشنط'**
  String get bags;

  /// No description provided for @bagsDesc.
  ///
  /// In ar, this message translates to:
  /// **'الشنط وحاملوها'**
  String get bagsDesc;

  /// No description provided for @subscription.
  ///
  /// In ar, this message translates to:
  /// **'الاشتراك'**
  String get subscription;

  /// No description provided for @adminDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة الإدارة'**
  String get adminDashboard;

  /// No description provided for @registerAnotherOrg.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل حساب آخر'**
  String get registerAnotherOrg;

  /// No description provided for @registerAnotherOrgDesc.
  ///
  /// In ar, this message translates to:
  /// **'مثلاً حساب مستقل إلى جانب عضويتك في مصنع'**
  String get registerAnotherOrgDesc;

  /// No description provided for @planLabel.
  ///
  /// In ar, this message translates to:
  /// **'الباقة'**
  String get planLabel;

  /// No description provided for @endsOn.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي في'**
  String get endsOn;

  /// No description provided for @noExpiry.
  ///
  /// In ar, this message translates to:
  /// **'بلا تاريخ انتهاء'**
  String get noExpiry;

  /// No description provided for @daysLeft.
  ///
  /// In ar, this message translates to:
  /// **'متبقٍّ {days} يوم'**
  String daysLeft(int days);

  /// No description provided for @usersLimit.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمون'**
  String get usersLimit;

  /// No description provided for @bagsLimit.
  ///
  /// In ar, this message translates to:
  /// **'الشنط'**
  String get bagsLimit;

  /// No description provided for @renewHint.
  ///
  /// In ar, this message translates to:
  /// **'للتجديد أو تغيير الباقة تواصل مع إدارة التطبيق.'**
  String get renewHint;

  /// No description provided for @subscriptionExpiring.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي اشتراكك خلال {days} يوم'**
  String subscriptionExpiring(int days);

  /// No description provided for @subscriptionExpired.
  ///
  /// In ar, this message translates to:
  /// **'انتهى الاشتراك — الحساب للقراءة فقط حتى التجديد'**
  String get subscriptionExpired;

  /// No description provided for @seatsUsed.
  ///
  /// In ar, this message translates to:
  /// **'{used} من {max} مستخدمين'**
  String seatsUsed(int used, int max);

  /// No description provided for @inviteMember.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عضو'**
  String get inviteMember;

  /// No description provided for @pendingInvitations.
  ///
  /// In ar, this message translates to:
  /// **'دعوات بانتظار أول دخول'**
  String get pendingInvitations;

  /// No description provided for @invitationHint.
  ///
  /// In ar, this message translates to:
  /// **'ينضم تلقائياً عند أول دخول برقمه'**
  String get invitationHint;

  /// No description provided for @cancelInvitation.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الدعوة'**
  String get cancelInvitation;

  /// No description provided for @memberName.
  ///
  /// In ar, this message translates to:
  /// **'اسم العضو'**
  String get memberName;

  /// No description provided for @role.
  ///
  /// In ar, this message translates to:
  /// **'الدور'**
  String get role;

  /// No description provided for @permissions.
  ///
  /// In ar, this message translates to:
  /// **'الصلاحيات'**
  String get permissions;

  /// No description provided for @memberActive.
  ///
  /// In ar, this message translates to:
  /// **'العضوية سارية'**
  String get memberActive;

  /// No description provided for @inactive.
  ///
  /// In ar, this message translates to:
  /// **'موقوف'**
  String get inactive;

  /// No description provided for @editMember.
  ///
  /// In ar, this message translates to:
  /// **'تعديل العضو'**
  String get editMember;

  /// No description provided for @memberAdded.
  ///
  /// In ar, this message translates to:
  /// **'تمت إضافة العضو'**
  String get memberAdded;

  /// No description provided for @invitationCreated.
  ///
  /// In ar, this message translates to:
  /// **'حُفظت الدعوة — ينضم عند أول دخول برقمه'**
  String get invitationCreated;

  /// No description provided for @you.
  ///
  /// In ar, this message translates to:
  /// **'(أنت)'**
  String get you;

  /// No description provided for @ownerOnly.
  ///
  /// In ar, this message translates to:
  /// **'هذه الصفحة للمالك فقط'**
  String get ownerOnly;

  /// No description provided for @ownerHasAll.
  ///
  /// In ar, this message translates to:
  /// **'المالك يملك كل الصلاحيات'**
  String get ownerHasAll;

  /// No description provided for @bagsUsed.
  ///
  /// In ar, this message translates to:
  /// **'{used} من {max} شنط'**
  String bagsUsed(int used, int max);

  /// No description provided for @newBag.
  ///
  /// In ar, this message translates to:
  /// **'شنطة جديدة'**
  String get newBag;

  /// No description provided for @bagName.
  ///
  /// In ar, this message translates to:
  /// **'اسم الشنطة'**
  String get bagName;

  /// No description provided for @bagHolder.
  ///
  /// In ar, this message translates to:
  /// **'حامل الشنطة'**
  String get bagHolder;

  /// No description provided for @noHolder.
  ///
  /// In ar, this message translates to:
  /// **'بدون حامل'**
  String get noHolder;

  /// No description provided for @bagActive.
  ///
  /// In ar, this message translates to:
  /// **'الشنطة فعّالة'**
  String get bagActive;

  /// No description provided for @editBag.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الشنطة'**
  String get editBag;

  /// No description provided for @noBags.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد شنط'**
  String get noBags;

  /// No description provided for @adminOverview.
  ///
  /// In ar, this message translates to:
  /// **'نظرة عامة'**
  String get adminOverview;

  /// No description provided for @adminOrgs.
  ///
  /// In ar, this message translates to:
  /// **'المنشآت'**
  String get adminOrgs;

  /// No description provided for @adminPlans.
  ///
  /// In ar, this message translates to:
  /// **'الباقات'**
  String get adminPlans;

  /// No description provided for @statPending.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار التفعيل'**
  String get statPending;

  /// No description provided for @statActive.
  ///
  /// In ar, this message translates to:
  /// **'مفعّلة'**
  String get statActive;

  /// No description provided for @statExpiring.
  ///
  /// In ar, this message translates to:
  /// **'تنتهي خلال 14 يوماً'**
  String get statExpiring;

  /// No description provided for @statExpired.
  ///
  /// In ar, this message translates to:
  /// **'اشتراك منتهٍ'**
  String get statExpired;

  /// No description provided for @statSuspended.
  ///
  /// In ar, this message translates to:
  /// **'موقوفة'**
  String get statSuspended;

  /// No description provided for @statUsers.
  ///
  /// In ar, this message translates to:
  /// **'المستخدمون'**
  String get statUsers;

  /// No description provided for @pendingRequests.
  ///
  /// In ar, this message translates to:
  /// **'طلبات بانتظار المراجعة'**
  String get pendingRequests;

  /// No description provided for @noPending.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات جديدة'**
  String get noPending;

  /// No description provided for @searchOrgs.
  ///
  /// In ar, this message translates to:
  /// **'ابحث بالاسم أو الهاتف'**
  String get searchOrgs;

  /// No description provided for @all.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get all;

  /// No description provided for @membersCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} أعضاء'**
  String membersCount(int count);

  /// No description provided for @activate.
  ///
  /// In ar, this message translates to:
  /// **'تفعيل'**
  String get activate;

  /// No description provided for @renew.
  ///
  /// In ar, this message translates to:
  /// **'تجديد'**
  String get renew;

  /// No description provided for @suspend.
  ///
  /// In ar, this message translates to:
  /// **'إيقاف'**
  String get suspend;

  /// No description provided for @reject.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get reject;

  /// No description provided for @reactivate.
  ///
  /// In ar, this message translates to:
  /// **'إعادة التفعيل'**
  String get reactivate;

  /// No description provided for @months.
  ///
  /// In ar, this message translates to:
  /// **'المدة'**
  String get months;

  /// No description provided for @monthsCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} شهر'**
  String monthsCount(int count);

  /// No description provided for @note.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة'**
  String get note;

  /// No description provided for @addMemberByPhone.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عضو برقم الهاتف'**
  String get addMemberByPhone;

  /// No description provided for @createdAt.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ التسجيل'**
  String get createdAt;

  /// No description provided for @owner.
  ///
  /// In ar, this message translates to:
  /// **'المالك'**
  String get owner;

  /// No description provided for @phone.
  ///
  /// In ar, this message translates to:
  /// **'الهاتف'**
  String get phone;

  /// No description provided for @activityLog.
  ///
  /// In ar, this message translates to:
  /// **'سجل النشاط'**
  String get activityLog;

  /// No description provided for @editPlan.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الباقة'**
  String get editPlan;

  /// No description provided for @newPlan.
  ///
  /// In ar, this message translates to:
  /// **'باقة جديدة'**
  String get newPlan;

  /// No description provided for @planCode.
  ///
  /// In ar, this message translates to:
  /// **'الرمز'**
  String get planCode;

  /// No description provided for @nameAr.
  ///
  /// In ar, this message translates to:
  /// **'الاسم بالعربية'**
  String get nameAr;

  /// No description provided for @nameEn.
  ///
  /// In ar, this message translates to:
  /// **'الاسم بالإنجليزية'**
  String get nameEn;

  /// No description provided for @price.
  ///
  /// In ar, this message translates to:
  /// **'السعر (د.أ)'**
  String get price;

  /// No description provided for @periodMonths.
  ///
  /// In ar, this message translates to:
  /// **'مدة الاشتراك (أشهر)'**
  String get periodMonths;

  /// No description provided for @maxUsers.
  ///
  /// In ar, this message translates to:
  /// **'الحد الأقصى للمستخدمين'**
  String get maxUsers;

  /// No description provided for @maxBags.
  ///
  /// In ar, this message translates to:
  /// **'الحد الأقصى للشنط'**
  String get maxBags;

  /// No description provided for @extraBagPrice.
  ///
  /// In ar, this message translates to:
  /// **'سعر الشنطة الإضافية (د.أ)'**
  String get extraBagPrice;

  /// No description provided for @planActive.
  ///
  /// In ar, this message translates to:
  /// **'الباقة متاحة'**
  String get planActive;

  /// No description provided for @perPeriod.
  ///
  /// In ar, this message translates to:
  /// **'{price} د.أ / {months} شهر'**
  String perPeriod(String price, int months);

  /// No description provided for @priceNotSet.
  ///
  /// In ar, this message translates to:
  /// **'السعر غير محدد'**
  String get priceNotSet;

  /// No description provided for @noResults.
  ///
  /// In ar, this message translates to:
  /// **'لا نتائج'**
  String get noResults;

  /// No description provided for @accountStatement.
  ///
  /// In ar, this message translates to:
  /// **'كشف حساب'**
  String get accountStatement;

  /// No description provided for @statementPeriod.
  ///
  /// In ar, this message translates to:
  /// **'الفترة'**
  String get statementPeriod;

  /// No description provided for @thisMonth.
  ///
  /// In ar, this message translates to:
  /// **'هذا الشهر'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In ar, this message translates to:
  /// **'الشهر الماضي'**
  String get lastMonth;

  /// No description provided for @last3Months.
  ///
  /// In ar, this message translates to:
  /// **'آخر 3 أشهر'**
  String get last3Months;

  /// No description provided for @thisYear.
  ///
  /// In ar, this message translates to:
  /// **'هذه السنة'**
  String get thisYear;

  /// No description provided for @fromDate.
  ///
  /// In ar, this message translates to:
  /// **'من تاريخ'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In ar, this message translates to:
  /// **'إلى تاريخ'**
  String get toDate;

  /// No description provided for @statementLanguage.
  ///
  /// In ar, this message translates to:
  /// **'لغة الكشف'**
  String get statementLanguage;

  /// No description provided for @openingBalance.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد السابق'**
  String get openingBalance;

  /// No description provided for @closingBalance.
  ///
  /// In ar, this message translates to:
  /// **'الرصيد الختامي'**
  String get closingBalance;

  /// No description provided for @periodMovements.
  ///
  /// In ar, this message translates to:
  /// **'حركات الفترة'**
  String get periodMovements;

  /// No description provided for @previewPdf.
  ///
  /// In ar, this message translates to:
  /// **'معاينة ومشاركة PDF'**
  String get previewPdf;

  /// No description provided for @statementHint.
  ///
  /// In ar, this message translates to:
  /// **'يبدأ الكشف بالرصيد السابق لبداية الفترة، ثم حركات الفترة، ولا تظهر فيه الملاحظات.'**
  String get statementHint;

  /// No description provided for @invalidRange.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ البداية بعد تاريخ النهاية'**
  String get invalidRange;

  /// No description provided for @cancelTx.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الحركة'**
  String get cancelTx;

  /// No description provided for @cancelTxBody.
  ///
  /// In ar, this message translates to:
  /// **'لن تُحذف الحركة؛ سيُسجَّل قيد عكسي يعيد الأرصدة والمخزون كما كانت، وتبقى الحركتان ظاهرتين في الدفتر. الشيكات المعلّقة المرتبطة بها تُلغى أيضاً.'**
  String get cancelTxBody;

  /// No description provided for @cancelReason.
  ///
  /// In ar, this message translates to:
  /// **'سبب الإلغاء'**
  String get cancelReason;

  /// No description provided for @cancelConfirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الإلغاء'**
  String get cancelConfirm;

  /// No description provided for @txCancelledDoc.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء الحركة — القيد العكسي رقم {doc}'**
  String txCancelledDoc(String doc);

  /// No description provided for @txIsReversed.
  ///
  /// In ar, this message translates to:
  /// **'هذه الحركة ملغاة بقيد عكسي، ولا أثر لها على الأرصدة.'**
  String get txIsReversed;

  /// No description provided for @txIsReversal.
  ///
  /// In ar, this message translates to:
  /// **'هذا قيد عكسي ألغى حركة سابقة.'**
  String get txIsReversal;

  /// No description provided for @needMigration12.
  ///
  /// In ar, this message translates to:
  /// **'يلزم تنفيذ ملف 0012_void_cheque.sql في Supabase أولاً'**
  String get needMigration12;

  /// No description provided for @partialReturn.
  ///
  /// In ar, this message translates to:
  /// **'مرتجع جزئي'**
  String get partialReturn;

  /// No description provided for @returnFromShopHint.
  ///
  /// In ar, this message translates to:
  /// **'القطع المرتجعة تعود إلى الشنطة، وينقص عن المحل ذهبها الصافي ومصنوعيتها بنفس سعر الفاتورة.'**
  String get returnFromShopHint;

  /// No description provided for @returnToWorkshopHint.
  ///
  /// In ar, this message translates to:
  /// **'القطع المرتجعة تخرج من الشنطة إلى المشغل، وينقص ما له علينا ذهباً ومصنوعيةً بنفس سعر الفاتورة.'**
  String get returnToWorkshopHint;

  /// No description provided for @returnAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get returnAll;

  /// No description provided for @returnedCount.
  ///
  /// In ar, this message translates to:
  /// **'العدد المرتجع'**
  String get returnedCount;

  /// No description provided for @returnedGross.
  ///
  /// In ar, this message translates to:
  /// **'الوزن المرتجع'**
  String get returnedGross;

  /// No description provided for @maxReturn.
  ///
  /// In ar, this message translates to:
  /// **'المتاح للإرجاع: {count} قطعة · {grams} غ'**
  String maxReturn(String count, String grams);

  /// No description provided for @returnExceeds.
  ///
  /// In ar, this message translates to:
  /// **'أكبر من المتاح للإرجاع'**
  String get returnExceeds;

  /// No description provided for @nothingToReturn.
  ///
  /// In ar, this message translates to:
  /// **'أدخل وزن قطعة واحدة على الأقل'**
  String get nothingToReturn;

  /// No description provided for @returnSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ المرتجع — رقم {doc}'**
  String returnSaved(String doc);

  /// No description provided for @returnedGoods.
  ///
  /// In ar, this message translates to:
  /// **'البضاعة المرتجعة'**
  String get returnedGoods;

  /// No description provided for @saveReturn.
  ///
  /// In ar, this message translates to:
  /// **'حفظ المرتجع'**
  String get saveReturn;

  /// No description provided for @invoiceLines.
  ///
  /// In ar, this message translates to:
  /// **'بنود الفاتورة'**
  String get invoiceLines;

  /// No description provided for @bagEditionSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'نسخة تاجر الشنطة — ادخل برقم هاتفك وكلمة المرور'**
  String get bagEditionSubtitle;

  /// No description provided for @passwordLabel.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get passwordLabel;

  /// No description provided for @showPassword.
  ///
  /// In ar, this message translates to:
  /// **'إظهار كلمة المرور'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء كلمة المرور'**
  String get hidePassword;

  /// No description provided for @wrongPhoneOrPassword.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف أو كلمة المرور غير صحيحة'**
  String get wrongPhoneOrPassword;

  /// No description provided for @forgotPasswordHint.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور أو تحتاج حساباً جديداً؟ تواصل مع الدعم'**
  String get forgotPasswordHint;

  /// No description provided for @accountNotEnabled.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحساب غير مفعّل في هذه النسخة'**
  String get accountNotEnabled;

  /// No description provided for @accountNotEnabledHint.
  ///
  /// In ar, this message translates to:
  /// **'الحسابات تُضاف أو تُفعَّل من الدعم فقط. تواصل معنا لتفعيل حسابك.'**
  String get accountNotEnabledHint;

  /// No description provided for @letterheadTitle.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الكشوفات والفواتير'**
  String get letterheadTitle;

  /// No description provided for @letterheadHint.
  ///
  /// In ar, this message translates to:
  /// **'تظهر في رأس كل كشف حساب وفاتورة وتقرير PDF.'**
  String get letterheadHint;

  /// No description provided for @businessName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المنشأة'**
  String get businessName;

  /// No description provided for @businessPhone.
  ///
  /// In ar, this message translates to:
  /// **'هاتف المنشأة'**
  String get businessPhone;

  /// No description provided for @businessCity.
  ///
  /// In ar, this message translates to:
  /// **'المدينة / العنوان'**
  String get businessCity;

  /// No description provided for @editionAccounts.
  ///
  /// In ar, this message translates to:
  /// **'الحسابات'**
  String get editionAccounts;

  /// No description provided for @accountsUsed.
  ///
  /// In ar, this message translates to:
  /// **'{count} من {max} حسابات مستخدمة'**
  String accountsUsed(int count, int max);

  /// No description provided for @accountsBySupport.
  ///
  /// In ar, this message translates to:
  /// **'إضافة حساب أو تغيير كلمة مرور أو إيقاف حساب يتم من الدعم. اضغط على حساب لتعديل صلاحياته.'**
  String get accountsBySupport;

  /// No description provided for @appSection.
  ///
  /// In ar, this message translates to:
  /// **'التطبيق'**
  String get appSection;

  /// No description provided for @aboutEdition.
  ///
  /// In ar, this message translates to:
  /// **'عن النسخة'**
  String get aboutEdition;

  /// No description provided for @editionVersion.
  ///
  /// In ar, this message translates to:
  /// **'نسخة تاجر الشنطة · 1.2.0'**
  String get editionVersion;

  /// No description provided for @support.
  ///
  /// In ar, this message translates to:
  /// **'الدعم'**
  String get support;

  /// No description provided for @edit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get edit;

  /// No description provided for @needMigration13.
  ///
  /// In ar, this message translates to:
  /// **'يلزم تنفيذ ملف 0013_bag_edition.sql في Supabase أولاً'**
  String get needMigration13;

  /// No description provided for @welcome.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك'**
  String get welcome;

  /// No description provided for @welcomeName.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً، {name}'**
  String welcomeName(String name);

  /// No description provided for @noTradersYet.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد تجار بعد — أضف تاجراً من تبويب التجار'**
  String get noTradersYet;

  /// No description provided for @chooseTrader.
  ///
  /// In ar, this message translates to:
  /// **'اختر التاجر'**
  String get chooseTrader;

  /// No description provided for @quickSellShop.
  ///
  /// In ar, this message translates to:
  /// **'بيع لمحل'**
  String get quickSellShop;

  /// No description provided for @today.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get today;

  /// No description provided for @noMovesToday.
  ///
  /// In ar, this message translates to:
  /// **'لا حركات اليوم بعد'**
  String get noMovesToday;

  /// No description provided for @todaySales.
  ///
  /// In ar, this message translates to:
  /// **'مبيعات اليوم (صافي)'**
  String get todaySales;

  /// No description provided for @makingProfit.
  ///
  /// In ar, this message translates to:
  /// **'ربح المصنوعية'**
  String get makingProfit;

  /// No description provided for @cashIn.
  ///
  /// In ar, this message translates to:
  /// **'نقد مقبوض'**
  String get cashIn;

  /// No description provided for @cashOut.
  ///
  /// In ar, this message translates to:
  /// **'نقد مدفوع'**
  String get cashOut;

  /// No description provided for @movementsToday.
  ///
  /// In ar, this message translates to:
  /// **'عدد الحركات'**
  String get movementsToday;

  /// No description provided for @scrapInBag.
  ///
  /// In ar, this message translates to:
  /// **'كسر في الشنطة'**
  String get scrapInBag;

  /// No description provided for @receivablesSummary.
  ///
  /// In ar, this message translates to:
  /// **'الذمم'**
  String get receivablesSummary;

  /// No description provided for @topDebtors.
  ///
  /// In ar, this message translates to:
  /// **'أكبر الذمم بالذهب'**
  String get topDebtors;

  /// No description provided for @chequesOverdue.
  ///
  /// In ar, this message translates to:
  /// **'شيكات متأخرة'**
  String get chequesOverdue;

  /// No description provided for @chequesThisWeek.
  ///
  /// In ar, this message translates to:
  /// **'تستحق هذا الأسبوع'**
  String get chequesThisWeek;

  /// No description provided for @recentMovements.
  ///
  /// In ar, this message translates to:
  /// **'آخر الحركات'**
  String get recentMovements;

  /// No description provided for @reports.
  ///
  /// In ar, this message translates to:
  /// **'التقارير'**
  String get reports;

  /// No description provided for @accountStatements.
  ///
  /// In ar, this message translates to:
  /// **'كشوفات الحسابات'**
  String get accountStatements;

  /// No description provided for @shopStatement.
  ///
  /// In ar, this message translates to:
  /// **'كشف حساب محل'**
  String get shopStatement;

  /// No description provided for @traderStatement.
  ///
  /// In ar, this message translates to:
  /// **'كشف حساب تاجر'**
  String get traderStatement;

  /// No description provided for @workshopStatement.
  ///
  /// In ar, this message translates to:
  /// **'كشف حساب مشغل'**
  String get workshopStatement;

  /// No description provided for @statementTileHint.
  ///
  /// In ar, this message translates to:
  /// **'اختر الحساب والفترة — يبدأ بالرصيد السابق'**
  String get statementTileHint;

  /// No description provided for @salesAndBag.
  ///
  /// In ar, this message translates to:
  /// **'المبيعات والشنطة'**
  String get salesAndBag;

  /// No description provided for @salesReport.
  ///
  /// In ar, this message translates to:
  /// **'تقرير المبيعات'**
  String get salesReport;

  /// No description provided for @salesReportHint.
  ///
  /// In ar, this message translates to:
  /// **'يومي، أسبوعي، شهري — بالأيام والمحلات والأصناف'**
  String get salesReportHint;

  /// No description provided for @bagStatement.
  ///
  /// In ar, this message translates to:
  /// **'كشف الشنطة'**
  String get bagStatement;

  /// No description provided for @bagStatementHint.
  ///
  /// In ar, this message translates to:
  /// **'الافتتاحي والداخل والخارج والختامي لكل صنف، وكل الحركات'**
  String get bagStatementHint;

  /// No description provided for @bagInventoryNow.
  ///
  /// In ar, this message translates to:
  /// **'جرد الشنطة الآن'**
  String get bagInventoryNow;

  /// No description provided for @bagInventoryHint.
  ///
  /// In ar, this message translates to:
  /// **'ما في الشنطة الآن صنفاً صنفاً'**
  String get bagInventoryHint;

  /// No description provided for @shopsBalances.
  ///
  /// In ar, this message translates to:
  /// **'ذمم المحلات'**
  String get shopsBalances;

  /// No description provided for @tradersBalances.
  ///
  /// In ar, this message translates to:
  /// **'ذمم التجار'**
  String get tradersBalances;

  /// No description provided for @chequesReportHint.
  ///
  /// In ar, this message translates to:
  /// **'المعلّقة والمنتهية — ومنها تقرير PDF'**
  String get chequesReportHint;

  /// No description provided for @noAccountsOfKind.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد حسابات من هذا النوع بعد'**
  String get noAccountsOfKind;

  /// No description provided for @chooseAccount.
  ///
  /// In ar, this message translates to:
  /// **'اختر الحساب'**
  String get chooseAccount;

  /// No description provided for @thisWeek.
  ///
  /// In ar, this message translates to:
  /// **'هذا الأسبوع'**
  String get thisWeek;

  /// No description provided for @soldNet.
  ///
  /// In ar, this message translates to:
  /// **'المبيع (صافي)'**
  String get soldNet;

  /// No description provided for @netSales.
  ///
  /// In ar, this message translates to:
  /// **'صافي المبيعات'**
  String get netSales;

  /// No description provided for @makingCharges.
  ///
  /// In ar, this message translates to:
  /// **'المصنوعية'**
  String get makingCharges;

  /// No description provided for @invoicesCount.
  ///
  /// In ar, this message translates to:
  /// **'الفواتير'**
  String get invoicesCount;

  /// No description provided for @byShop.
  ///
  /// In ar, this message translates to:
  /// **'حسب المحل'**
  String get byShop;

  /// No description provided for @byDay.
  ///
  /// In ar, this message translates to:
  /// **'حسب اليوم'**
  String get byDay;

  /// No description provided for @noSalesInPeriod.
  ///
  /// In ar, this message translates to:
  /// **'لا مبيعات في هذه الفترة'**
  String get noSalesInPeriod;

  /// No description provided for @goodsInPeriod.
  ///
  /// In ar, this message translates to:
  /// **'داخل في الفترة'**
  String get goodsInPeriod;

  /// No description provided for @goodsOutPeriod.
  ///
  /// In ar, this message translates to:
  /// **'خارج في الفترة'**
  String get goodsOutPeriod;

  /// No description provided for @stockByItem.
  ///
  /// In ar, this message translates to:
  /// **'المخزون حسب الصنف'**
  String get stockByItem;

  /// No description provided for @scrap.
  ///
  /// In ar, this message translates to:
  /// **'كسر'**
  String get scrap;

  /// No description provided for @openingShort.
  ///
  /// In ar, this message translates to:
  /// **'افتتاحي'**
  String get openingShort;

  /// No description provided for @inShort.
  ///
  /// In ar, this message translates to:
  /// **'داخل'**
  String get inShort;

  /// No description provided for @outShort.
  ///
  /// In ar, this message translates to:
  /// **'خارج'**
  String get outShort;

  /// No description provided for @reportsHint.
  ///
  /// In ar, this message translates to:
  /// **'كشوفات الحسابات، المبيعات، كشف الشنطة، الذمم'**
  String get reportsHint;

  /// No description provided for @shopOps.
  ///
  /// In ar, this message translates to:
  /// **'حركة مع المحل'**
  String get shopOps;

  /// No description provided for @shopSellDesc.
  ///
  /// In ar, this message translates to:
  /// **'بضاعة من الشنطة، مع استلام كسر أو نقد'**
  String get shopSellDesc;

  /// No description provided for @shopFixDesc.
  ///
  /// In ar, this message translates to:
  /// **'يدفع نقداً بدل الذهب الذي عليه — بسعر غرام الحلة اليوم'**
  String get shopFixDesc;

  /// No description provided for @movement.
  ///
  /// In ar, this message translates to:
  /// **'حركة'**
  String get movement;

  /// No description provided for @goodsInBag.
  ///
  /// In ar, this message translates to:
  /// **'البضاعة في الشنطة'**
  String get goodsInBag;

  /// No description provided for @totalGoldNet.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الذهب (صافي)'**
  String get totalGoldNet;

  /// No description provided for @cashInBag.
  ///
  /// In ar, this message translates to:
  /// **'الكاش في الشنطة'**
  String get cashInBag;

  /// No description provided for @chequesInHand.
  ///
  /// In ar, this message translates to:
  /// **'شيكات بحوزتك'**
  String get chequesInHand;

  /// No description provided for @cashboxBalance.
  ///
  /// In ar, this message translates to:
  /// **'رصيد الصندوق'**
  String get cashboxBalance;

  /// No description provided for @chequesInPending.
  ///
  /// In ar, this message translates to:
  /// **'شيكات واردة لم تُصرف'**
  String get chequesInPending;

  /// No description provided for @chequesOutPending.
  ///
  /// In ar, this message translates to:
  /// **'شيكات صادرة لم تُصرف'**
  String get chequesOutPending;

  /// No description provided for @cashInBagHint.
  ///
  /// In ar, this message translates to:
  /// **'النقد الفعلي الذي يجب أن يكون معك الآن.'**
  String get cashInBagHint;

  /// No description provided for @expensesToday.
  ///
  /// In ar, this message translates to:
  /// **'مصاريف اليوم'**
  String get expensesToday;

  /// No description provided for @newExpense.
  ///
  /// In ar, this message translates to:
  /// **'مصروف'**
  String get newExpense;

  /// No description provided for @closeDay.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق اليوم'**
  String get closeDay;

  /// No description provided for @openDay.
  ///
  /// In ar, this message translates to:
  /// **'فتح اليوم'**
  String get openDay;

  /// No description provided for @goodMorning.
  ///
  /// In ar, this message translates to:
  /// **'صباح الخير'**
  String get goodMorning;

  /// No description provided for @goodMorningName.
  ///
  /// In ar, this message translates to:
  /// **'صباح الخير، {name}'**
  String goodMorningName(String name);

  /// No description provided for @openDayFor.
  ///
  /// In ar, this message translates to:
  /// **'بداية يوم'**
  String get openDayFor;

  /// No description provided for @cashYouCarry.
  ///
  /// In ar, this message translates to:
  /// **'الكاش المحمول معك'**
  String get cashYouCarry;

  /// No description provided for @cashLeftYesterday.
  ///
  /// In ar, this message translates to:
  /// **'ما بقي من آخر يوم'**
  String get cashLeftYesterday;

  /// No description provided for @cashAddedNote.
  ///
  /// In ar, this message translates to:
  /// **'ستُضيف {amount} د.أ إلى كاش الشنطة'**
  String cashAddedNote(String amount);

  /// No description provided for @cashTakenNote.
  ///
  /// In ar, this message translates to:
  /// **'ستُنقص {amount} د.أ من كاش الشنطة'**
  String cashTakenNote(String amount);

  /// No description provided for @reasonRequired.
  ///
  /// In ar, this message translates to:
  /// **'السبب (إلزامي)'**
  String get reasonRequired;

  /// No description provided for @startDay.
  ///
  /// In ar, this message translates to:
  /// **'بدء اليوم'**
  String get startDay;

  /// No description provided for @confirmGoodsFirst.
  ///
  /// In ar, this message translates to:
  /// **'أكّد البضاعة والكسر أولاً'**
  String get confirmGoodsFirst;

  /// No description provided for @dayReport.
  ///
  /// In ar, this message translates to:
  /// **'يومية الشنطة PDF'**
  String get dayReport;

  /// No description provided for @closeOldDayFirst.
  ///
  /// In ar, this message translates to:
  /// **'يوجد يوم سابق لم يُغلق. أغلقه أولاً لتبدأ يومك الجديد.'**
  String get closeOldDayFirst;

  /// No description provided for @daySummary.
  ///
  /// In ar, this message translates to:
  /// **'ملخص اليوم'**
  String get daySummary;

  /// No description provided for @chequesReceived.
  ///
  /// In ar, this message translates to:
  /// **'شيكات مستلمة'**
  String get chequesReceived;

  /// No description provided for @cashPaidParties.
  ///
  /// In ar, this message translates to:
  /// **'نقد مدفوع للأطراف'**
  String get cashPaidParties;

  /// No description provided for @afterExpenses.
  ///
  /// In ar, this message translates to:
  /// **'بعد المصاريف'**
  String get afterExpenses;

  /// No description provided for @bagCount.
  ///
  /// In ar, this message translates to:
  /// **'جرد الشنطة'**
  String get bagCount;

  /// No description provided for @confirmGoodsScrap.
  ///
  /// In ar, this message translates to:
  /// **'تأكدت أن البضاعة والكسر في الشنطة مطابقة'**
  String get confirmGoodsScrap;

  /// No description provided for @countCash.
  ///
  /// In ar, this message translates to:
  /// **'عدّ الكاش'**
  String get countCash;

  /// No description provided for @cashExpected.
  ///
  /// In ar, this message translates to:
  /// **'الكاش المتوقع حسب الحركات'**
  String get cashExpected;

  /// No description provided for @cashCounted.
  ///
  /// In ar, this message translates to:
  /// **'الكاش المعدود فعلاً'**
  String get cashCounted;

  /// No description provided for @matches.
  ///
  /// In ar, this message translates to:
  /// **'مطابق'**
  String get matches;

  /// No description provided for @cashShortage.
  ///
  /// In ar, this message translates to:
  /// **'عجز {amount} د.أ'**
  String cashShortage(String amount);

  /// No description provided for @cashSurplus.
  ///
  /// In ar, this message translates to:
  /// **'زيادة {amount} د.أ'**
  String cashSurplus(String amount);

  /// No description provided for @dayClosed.
  ///
  /// In ar, this message translates to:
  /// **'تم إغلاق اليوم ✓'**
  String get dayClosed;

  /// No description provided for @continueLabel.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get continueLabel;

  /// No description provided for @expFuel.
  ///
  /// In ar, this message translates to:
  /// **'بنزين'**
  String get expFuel;

  /// No description provided for @expFood.
  ///
  /// In ar, this message translates to:
  /// **'أكل'**
  String get expFood;

  /// No description provided for @expTransport.
  ///
  /// In ar, this message translates to:
  /// **'مواصلات'**
  String get expTransport;

  /// No description provided for @expMaintenance.
  ///
  /// In ar, this message translates to:
  /// **'صيانة'**
  String get expMaintenance;

  /// No description provided for @expPersonal.
  ///
  /// In ar, this message translates to:
  /// **'سحب شخصي'**
  String get expPersonal;

  /// No description provided for @expOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get expOther;

  /// No description provided for @needMigration14.
  ///
  /// In ar, this message translates to:
  /// **'يلزم تنفيذ ملف 0014_bag_day.sql في Supabase أولاً'**
  String get needMigration14;

  /// No description provided for @expenseSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم حفظ المصروف'**
  String get expenseSaved;

  /// No description provided for @expenseCategory.
  ///
  /// In ar, this message translates to:
  /// **'البند'**
  String get expenseCategory;

  /// No description provided for @expenseNoteRequired.
  ///
  /// In ar, this message translates to:
  /// **'الوصف (إلزامي)'**
  String get expenseNoteRequired;

  /// No description provided for @expenseHint.
  ///
  /// In ar, this message translates to:
  /// **'يُخصم المبلغ من كاش الشنطة ويظهر في مصاريف اليوم وتقاريره.'**
  String get expenseHint;

  /// No description provided for @instantKarat.
  ///
  /// In ar, this message translates to:
  /// **'عيار لحظي'**
  String get instantKarat;

  /// No description provided for @makingPerPiece.
  ///
  /// In ar, this message translates to:
  /// **'المصنوعية / قطعة'**
  String get makingPerPiece;

  /// No description provided for @perGram.
  ///
  /// In ar, this message translates to:
  /// **'على الغرام'**
  String get perGram;

  /// No description provided for @perPiece.
  ///
  /// In ar, this message translates to:
  /// **'على القطعة'**
  String get perPiece;

  /// No description provided for @makingDiscount.
  ///
  /// In ar, this message translates to:
  /// **'خصم المصنوعية'**
  String get makingDiscount;

  /// No description provided for @noDiscount.
  ///
  /// In ar, this message translates to:
  /// **'بلا خصم'**
  String get noDiscount;

  /// No description provided for @dropFraction.
  ///
  /// In ar, this message translates to:
  /// **'حذف الكسر'**
  String get dropFraction;

  /// No description provided for @extraDiscount.
  ///
  /// In ar, this message translates to:
  /// **'خصم إضافي'**
  String get extraDiscount;

  /// No description provided for @finalMaking.
  ///
  /// In ar, this message translates to:
  /// **'المصنوعية النهائية'**
  String get finalMaking;

  /// No description provided for @recoveredGoods.
  ///
  /// In ar, this message translates to:
  /// **'المسترد من المحل'**
  String get recoveredGoods;

  /// No description provided for @recoveredMaking.
  ///
  /// In ar, this message translates to:
  /// **'مصنوعية المسترد'**
  String get recoveredMaking;

  /// No description provided for @addRecovered.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مسترد'**
  String get addRecovered;

  /// No description provided for @dailyCashTotal.
  ///
  /// In ar, this message translates to:
  /// **'مجموع الكاش اليومي'**
  String get dailyCashTotal;

  /// No description provided for @dailyCashHint.
  ///
  /// In ar, this message translates to:
  /// **'كاش بداية اليوم + المقبوض'**
  String get dailyCashHint;

  /// No description provided for @netCash.
  ///
  /// In ar, this message translates to:
  /// **'الكاش الصافي'**
  String get netCash;

  /// No description provided for @fixClass.
  ///
  /// In ar, this message translates to:
  /// **'تصنيف التسكير'**
  String get fixClass;

  /// No description provided for @fixClassGold.
  ///
  /// In ar, this message translates to:
  /// **'حلة'**
  String get fixClassGold;

  /// No description provided for @fixClassScrap.
  ///
  /// In ar, this message translates to:
  /// **'كسر'**
  String get fixClassScrap;

  /// No description provided for @fixCashNow.
  ///
  /// In ar, this message translates to:
  /// **'نقد الآن (اختياري)'**
  String get fixCashNow;

  /// No description provided for @fixCashHint.
  ///
  /// In ar, this message translates to:
  /// **'كله أو جزء منه أو صفر — والباقي يبقى ذمة.'**
  String get fixCashHint;

  /// No description provided for @fixWithTrader.
  ///
  /// In ar, this message translates to:
  /// **'تسكير مع تاجر (اختياري)'**
  String get fixWithTrader;

  /// No description provided for @noTrader.
  ///
  /// In ar, this message translates to:
  /// **'بدون تاجر'**
  String get noTrader;

  /// No description provided for @traderGrams.
  ///
  /// In ar, this message translates to:
  /// **'غرامات التاجر'**
  String get traderGrams;

  /// No description provided for @traderFixHint.
  ///
  /// In ar, this message translates to:
  /// **'فارغة = نفس غرامات المحل وسعره.'**
  String get traderFixHint;

  /// No description provided for @opReceiveGold.
  ///
  /// In ar, this message translates to:
  /// **'استلام ذهب'**
  String get opReceiveGold;

  /// No description provided for @opReceiveGoldDesc.
  ///
  /// In ar, this message translates to:
  /// **'يدخل الشنطة بأي عيار، ومعامله 1.000 ويمكن تعديله'**
  String get opReceiveGoldDesc;

  /// No description provided for @opDeliverGold.
  ///
  /// In ar, this message translates to:
  /// **'تسليم ذهب'**
  String get opDeliverGold;

  /// No description provided for @opDeliverGoldDesc.
  ///
  /// In ar, this message translates to:
  /// **'يخرج من الشنطة بأي عيار، ومعامله 1.000 ويمكن تعديله'**
  String get opDeliverGoldDesc;

  /// No description provided for @opLira.
  ///
  /// In ar, this message translates to:
  /// **'بيع ليرة مع الأجور'**
  String get opLira;

  /// No description provided for @opLiraDesc.
  ///
  /// In ar, this message translates to:
  /// **'وزن قائم، والأجور على القطعة لنا'**
  String get opLiraDesc;

  /// No description provided for @opExchange.
  ///
  /// In ar, this message translates to:
  /// **'بدل ذهب'**
  String get opExchange;

  /// No description provided for @opExchangeDesc.
  ///
  /// In ar, this message translates to:
  /// **'استلام وتسليم بأجور على الغرام، لنا أو علينا'**
  String get opExchangeDesc;

  /// No description provided for @liraFromBag.
  ///
  /// In ar, this message translates to:
  /// **'تخرج من الشنطة'**
  String get liraFromBag;

  /// No description provided for @liraFromBagHint.
  ///
  /// In ar, this message translates to:
  /// **'فعّله إذا كانت الليرة من مخزون الشنطة.'**
  String get liraFromBagHint;

  /// No description provided for @liraFee.
  ///
  /// In ar, this message translates to:
  /// **'الأجور / قطعة'**
  String get liraFee;

  /// No description provided for @liraCountNeeded.
  ///
  /// In ar, this message translates to:
  /// **'أدخل العدد لحساب الأجور.'**
  String get liraCountNeeded;

  /// No description provided for @exchangeReceived.
  ///
  /// In ar, this message translates to:
  /// **'الذهب المستلم'**
  String get exchangeReceived;

  /// No description provided for @exchangeDelivered.
  ///
  /// In ar, this message translates to:
  /// **'الذهب المسلَّم (اختياري)'**
  String get exchangeDelivered;

  /// No description provided for @exchangeDeliveredHint.
  ///
  /// In ar, this message translates to:
  /// **'ما لا يُسلَّم الآن يبقى في الرصيد.'**
  String get exchangeDeliveredHint;

  /// No description provided for @exchangeFee.
  ///
  /// In ar, this message translates to:
  /// **'أجور البدل'**
  String get exchangeFee;

  /// No description provided for @exchangeFeePerGram.
  ///
  /// In ar, this message translates to:
  /// **'الأجور / غرام'**
  String get exchangeFeePerGram;

  /// No description provided for @feeForUs.
  ///
  /// In ar, this message translates to:
  /// **'لنا'**
  String get feeForUs;

  /// No description provided for @feeOnUs.
  ///
  /// In ar, this message translates to:
  /// **'علينا'**
  String get feeOnUs;

  /// No description provided for @openingBalances.
  ///
  /// In ar, this message translates to:
  /// **'الأرصدة الافتتاحية'**
  String get openingBalances;

  /// No description provided for @openingBalancesHint.
  ///
  /// In ar, this message translates to:
  /// **'حسابات سابقة للمحلات والتجار والمشاغل، ومحتوى الشنطة'**
  String get openingBalancesHint;

  /// No description provided for @openingBag.
  ///
  /// In ar, this message translates to:
  /// **'محتوى الشنطة عند البدء'**
  String get openingBag;

  /// No description provided for @openingBagHint.
  ///
  /// In ar, this message translates to:
  /// **'البضاعة والكسر والكاش الموجود الآن'**
  String get openingBagHint;

  /// No description provided for @openingGold.
  ///
  /// In ar, this message translates to:
  /// **'رصيد الذهب (صافي 24)'**
  String get openingGold;

  /// No description provided for @openingCash.
  ///
  /// In ar, this message translates to:
  /// **'رصيد النقد'**
  String get openingCash;

  /// No description provided for @openingForUs.
  ///
  /// In ar, this message translates to:
  /// **'لنا عليه'**
  String get openingForUs;

  /// No description provided for @openingForHim.
  ///
  /// In ar, this message translates to:
  /// **'له علينا'**
  String get openingForHim;

  /// No description provided for @openingSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الرصيد — {doc}'**
  String openingSaved(String doc);

  /// No description provided for @bagMovements.
  ///
  /// In ar, this message translates to:
  /// **'الحركات'**
  String get bagMovements;

  /// No description provided for @allMovements.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get allMovements;

  /// No description provided for @movementsIn.
  ///
  /// In ar, this message translates to:
  /// **'وارد للشنطة'**
  String get movementsIn;

  /// No description provided for @movementsOut.
  ///
  /// In ar, this message translates to:
  /// **'صادر من الشنطة'**
  String get movementsOut;

  /// No description provided for @noBagMovements.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد حركات في هذه الفترة'**
  String get noBagMovements;

  /// No description provided for @lastMakingHint.
  ///
  /// In ar, this message translates to:
  /// **'آخر مصنوعية لهذا المحل: {rate} {unit} — يمكن تعديلها'**
  String lastMakingHint(String rate, String unit);

  /// No description provided for @recoveredLine.
  ///
  /// In ar, this message translates to:
  /// **'مسترد {n}'**
  String recoveredLine(int n);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
