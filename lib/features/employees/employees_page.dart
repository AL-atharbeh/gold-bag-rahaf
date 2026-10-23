import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/dates.dart';
import '../../core/units.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';
import 'employee_sheet_page.dart';
import 'new_employee_dialog.dart';

/// قائمة الموظفين — لكل واحد راتبه وما سحبه في الشهر الجاري.
class EmployeesPage extends ConsumerWidget {
  const EmployeesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employees = ref.watch(employeesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('الموظفون'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(accountsProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-employees',
        onPressed: () => showDialog<bool>(
          context: context,
          builder: (_) => const NewEmployeeDialog(),
        ),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'موظف جديد',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: employees.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.goldPrimary),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('خطأ: $e'),
          ),
        ),
        data: (list) {
          if (list.isEmpty) return const _EmptyState();

          return RefreshIndicator(
            color: AppColors.goldPrimary,
            backgroundColor: Colors.white,
            onRefresh: () async => ref.invalidate(accountsProvider),
            child: ListView(
              key: const PageStorageKey('employees-list'),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'شهر ${monthLabel(DateTime.now())}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                for (final e in list) _EmployeeTile(employee: e),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// بطاقة موظف — تحسب سحوبات الشهر الجاري من كشف حسابه.
class _EmployeeTile extends ConsumerWidget {
  const _EmployeeTile({required this.employee});

  final Account employee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statement = ref.watch(statementProvider(employee.id));
    final now = DateTime.now();

    final withdrawn = statement.valueOrNull
            ?.where((l) =>
                l.ledger == LedgerKind.cash &&
                !l.isReversed &&
                inSameMonth(l.occurredAt, now))
            .fold<int>(0, (a, l) => a + l.amount) ??
        0;

    final salary = employee.monthlySalaryFils;
    final remaining = salary - withdrawn;
    final overdrawn = salary > 0 && remaining < 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x05000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EmployeeSheetPage(employee: employee),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.goldContainer,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.goldBorder, width: 1.2),
                    ),
                    child: const Icon(Icons.badge_outlined,
                        color: AppColors.goldDark, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          employee.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          salary == 0
                              ? 'الراتب غير محدَّد'
                              : 'الراتب ${formatDinars(salary)} د.أ  ·  '
                                  'المسحوب ${formatDinars(withdrawn)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (salary > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: overdrawn
                            ? AppColors.errorContainer
                            : AppColors.successContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        overdrawn
                            ? 'زيادة ${formatDinars(remaining.abs())}'
                            : 'باقٍ ${formatDinars(remaining)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color:
                              overdrawn ? AppColors.error : AppColors.success,
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: 'تعديل البيانات',
                    icon: const Icon(Icons.more_vert_rounded,
                        size: 20, color: AppColors.textMuted),
                    onPressed: () => showDialog<bool>(
                      context: context,
                      builder: (_) => NewEmployeeDialog(employee: employee),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.goldBorder),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: AppColors.goldContainer,
                child: Icon(Icons.badge_outlined,
                    size: 36, color: AppColors.goldDark),
              ),
              SizedBox(height: 16),
              Text(
                'لا يوجد موظفون بعد',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'أضف موظفاً وحدّد راتبه الشهري لتتابع سحوباته شهراً بشهر.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
