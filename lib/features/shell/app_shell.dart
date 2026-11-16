import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/locale.dart';
import '../../platform/session.dart';
import 'tab_specs.dart';

/// الهيكل الرئيسي لمنشأة مفعّلة. التبويبات تأتي من [tabsFor] حسب نوع
/// الحساب والصلاحيات. شريط جانبي على التابلت، وسفلي على الشاشات الضيقة.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(activeMembershipProvider);
    if (m == null) return const SizedBox.shrink();

    final l = context.l10n;
    final tabs = tabsFor(m);
    final index =
        tabs.indexWhere((t) => t.id == _selectedId).clamp(0, tabs.length - 1);
    void select(int i) => setState(() => _selectedId = tabs[i].id);

    final body = IndexedStack(
      index: index,
      children: [for (final t in tabs) t.page(l)],
    );

    final wide = MediaQuery.sizeOf(context).width >= 700;

    if (!wide) {
      return Scaffold(
        body: body,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: select,
            labelBehavior: tabs.length > 5
                ? NavigationDestinationLabelBehavior.onlyShowSelected
                : NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              for (final t in tabs)
                NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.selectedIcon, color: AppColors.goldDark),
                  label: t.label(l),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: BorderDirectional(
                  end: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: NavigationRail(
              selectedIndex: index,
              onDestinationSelected: select,
              labelType: NavigationRailLabelType.all,
              minWidth: 88,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.goldContainer,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.goldBorder, width: 1.5),
                  ),
                  child:
                      Image.asset('assets/images/logo_trimmed.png', width: 36),
                ),
              ),
              destinations: [
                for (final t in tabs)
                  NavigationRailDestination(
                    icon: Icon(t.icon),
                    selectedIcon:
                        Icon(t.selectedIcon, color: AppColors.goldDark),
                    label: Text(t.label(l), textAlign: TextAlign.center),
                  ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
