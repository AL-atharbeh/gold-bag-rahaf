import 'package:flutter/material.dart';

import '../../domain/enums.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/platform_models.dart';
import '../accounts/accounts_page.dart';
import '../bag/bag_page.dart';
import '../expenses/expenses_tab.dart';
import '../home/home_page.dart';
import '../settings/bag_settings_page.dart';

/// تبويب في الشريط الرئيسي.
class ShellTab {
  const ShellTab({
    required this.id,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.page,
  });

  /// مفتاح ثابت — يحفظ التبويب المختار حين تتغيّر القائمة.
  final String id;
  final IconData icon;
  final IconData selectedIcon;
  final String Function(AppLocalizations) label;
  final Widget Function(AppLocalizations) page;
}

/// تبويبات نسخة تاجر الشنطة:
///
///   الرئيسية ← الشنطة ← المحلات ← التجار ← المصاريف والموظفون ← الإعدادات
///   التقارير والشيكات والأرصدة الافتتاحية داخل الإعدادات.
///
/// السيرفر يفرض الصلاحيات نفسها في RLS — إخفاء أي شيء هنا للوضوح لا للحماية.
List<ShellTab> tabsFor(Membership m) => [
      ShellTab(
        id: 'home',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: (l) => l.tabHome,
        page: (l) => const HomePage(),
      ),
      ShellTab(
        id: 'bag',
        icon: Icons.work_outline_rounded,
        selectedIcon: Icons.work_rounded,
        label: (l) => l.tabBag,
        page: (_) => const BagPage(),
      ),
      ShellTab(
        id: 'shops',
        icon: Icons.storefront_outlined,
        selectedIcon: Icons.storefront_rounded,
        label: (l) => l.tabShops,
        page: (l) => AccountsPage(
          kind: AccountKind.showroom,
          title: l.tabShops,
          addLabel: l.newShop,
          emptyTitle: l.noShops,
          emptyHint: l.noShopsHint,
        ),
      ),
      ShellTab(
        id: 'traders',
        icon: Icons.handshake_outlined,
        selectedIcon: Icons.handshake_rounded,
        label: (l) => l.tabTraders,
        page: (l) => AccountsPage(
          kind: AccountKind.trader,
          withWorkshops: true,
          title: l.tabTraders,
          addLabel: l.newTrader,
          emptyTitle: l.noTraders,
          emptyHint: l.noTradersHint,
        ),
      ),
      ShellTab(
        id: 'expenses',
        icon: Icons.receipt_long_outlined,
        selectedIcon: Icons.receipt_long_rounded,
        label: (l) => l.tabExpenses,
        page: (_) => const ExpensesTab(),
      ),
      ShellTab(
        id: 'settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        label: (l) => l.tabSettings,
        page: (l) => BagSettingsPage(title: l.tabSettings),
      ),
    ];
