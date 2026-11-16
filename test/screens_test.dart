import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gold_bashar/app/providers.dart';
import 'package:gold_bashar/domain/enums.dart';
import 'package:gold_bashar/domain/models.dart';
import 'package:gold_bashar/features/expenses/expenses_tab.dart';
import 'package:gold_bashar/features/accounts/accounts_page.dart';
import 'package:gold_bashar/features/shell/app_shell.dart';
import 'package:gold_bashar/l10n/app_localizations.dart';
import 'package:gold_bashar/platform/platform_models.dart';
import 'package:gold_bashar/platform/session.dart';

/// بيانات ثابتة تحاكي منشأة مهيّأة — لا شبكة ولا Supabase.
const _karats = [
  Karat(id: 'k24', name: 'عيار 24',
      outFactorPpm: 1000000, inFactorPpm: 1000000, sortOrder: 0),
  Karat(id: 'k21', name: 'عيار 21',
      outFactorPpm: 885000, inFactorPpm: 870000, sortOrder: 1),
  Karat(id: 'k18', name: 'عيار 18',
      outFactorPpm: 790000, inFactorPpm: 740000, sortOrder: 2),
];

const _customer = Account(
  id: 'a-customer',
  name: 'أم سليمان',
  kind: AccountKind.customer,
);

const _showroom = Account(
  id: 'a-showroom',
  name: 'محل الأمانة',
  kind: AccountKind.showroom,
  consignmentAccountId: 'a-consign',
);

const _trader = Account(
  id: 'a-trader',
  name: 'أبو محمد',
  kind: AccountKind.trader,
);

const _system = {
  SystemAccount.shanta: 'a-shanta',
  SystemAccount.cashbox: 'a-cashbox',
  SystemAccount.tradingIncome: 'a-trading',
  SystemAccount.makingIncome: 'a-making',
};

final _balances = [
  const AccountBalance(
    accountId: 'a-showroom',
    name: 'محل الأمانة',
    kind: AccountKind.showroom,
    goldMg: 87500, // لنا عليه
    cashFils: 0,
    consignmentAccountId: 'a-consign',
  ),
  const AccountBalance(
    accountId: 'a-trader',
    name: 'أبو محمد',
    kind: AccountKind.trader,
    goldMg: -20000, // له علينا
    cashFils: 0,
  ),
  const AccountBalance(
    accountId: 'a-shanta',
    name: 'الشنطة',
    kind: AccountKind.inventoryLocation,
    goldMg: 500000,
    cashFils: 0,
    systemKey: SystemAccount.shanta,
  ),
];

/// مالك موزّع مفعّل — يرى كل تبويبات الموزّع.
const _owner = Membership(
  membershipId: 'm1',
  tenantId: 't1',
  orgName: 'منشأة تجريبية',
  orgType: OrgType.distributor,
  status: OrgStatus.active,
  role: MemberRole.owner,
  permissions: {},
);

Widget _wrap(Widget child) => ProviderScope(
      overrides: [
        karatsProvider.overrideWith((ref) => _karats),
        // المعامل يُحسم حسب الاتجاه — هذا ما تراه الشاشة فعلاً
        karatOptionsProvider.overrideWith((ref, q) => _karats
            .map((k) => KaratOption(
                id: k.id, name: k.name, ppm: k.factorFor(q.direction)))
            .toList()),
        customersProvider.overrideWith((ref) => [_customer]),
        accountsProvider.overrideWith((ref) => [_showroom, _trader, _customer]),
        counterpartiesProvider.overrideWith((ref) => [_showroom, _trader]),
        showroomsProvider.overrideWith((ref) => [_showroom]),
        systemAccountsProvider.overrideWith((ref) => _system),
        balancesProvider.overrideWith((ref) => Stream.value(_balances)),
        statementProvider.overrideWith((ref, id) => <StatementLine>[]),
        cashboxPostingsProvider.overrideWith((ref, r) => <PeriodPosting>[]),
        employeesProvider.overrideWith((ref) => <Account>[]),
        allChequesProvider.overrideWith((ref) => <Cheque>[]),
        pendingChequesProvider.overrideWith((ref) => <Cheque>[]),
        activeMembershipProvider.overrideWithValue(_owner),
      ],
      child: MaterialApp(
        locale: const Locale('ar', 'JO'),
        supportedLocales: const [Locale('ar', 'JO'), Locale('en')],
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    );

void main() {
  setUp(() {
    // شاشة تابلت — الأصل الذي صُمم له التطبيق.
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Future<void> pump(WidgetTester t, Widget page) async {
    t.view.physicalSize = const Size(1400, 1000);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    await t.pumpWidget(_wrap(page));
    await t.pumpAndSettle();
  }

  testWidgets('شاشة الأطراف تعرض اتجاه الدين صحيحاً', (t) async {
    await pump(t, const AccountsPage());
    // موجب = الطرف مدين لنا
    expect(find.textContaining('لنا عليه: 87.500'), findsOneWidget);
    // سالب = نحن مدينون له
    expect(find.textContaining('له علينا: 20.000'), findsOneWidget);
  });

  testWidgets('أزرار الإضافة العائمة لا تتشارك وسم Hero', (t) async {
    // IndexedStack يبقي كل الصفحات حيّة معاً، فأزرارها العائمة تجتمع
    // في الشجرة نفسها. اشتراكها في الوسم الافتراضي يُسقط التطبيق عند
    // أول انتقال بين الشاشات — وهو ما لا تكشفه اختبارات الشاشة المفردة.
    await pump(t, const AppShell());

    // الصفحات غير المعروضة offstage، لكنها في شجرة العناصر — وهذا
    // بالضبط ما يجعل Hero يراها ويصطدم. فالبحث يجب ألا يتخطاها.
    final fabs = t
        .widgetList<FloatingActionButton>(
            find.byType(FloatingActionButton, skipOffstage: false))
        .toList();

    expect(fabs.length, greaterThan(1),
        reason: 'يُفترض وجود أكثر من زر عائم حيّ في آن واحد');

    final tags = fabs.map((f) => f.heroTag).toList();

    // الوسم الافتراضي ليس null بل كائن ثابت مشترك، فوجوده مرتين
    // يعني تصادماً. نطلب وسماً صريحاً من كل زر بدل تتبّع التكرار.
    final usingDefault = tags
        .where((tag) =>
            tag.toString().contains('default FloatingActionButton tag'))
        .toList();
    expect(usingDefault, isEmpty,
        reason: 'كل زر عائم يحتاج وسماً صريحاً — وجدت ${usingDefault.length} '
            'بالوسم الافتراضي');

    expect(tags.toSet().length, tags.length,
        reason: 'الوسوم يجب أن تكون فريدة: $tags');
  });
}
