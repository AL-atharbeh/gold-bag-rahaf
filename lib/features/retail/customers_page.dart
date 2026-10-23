import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/text.dart';
import '../../core/units.dart';
import '../../domain/models.dart';
import '../statement/statement_page.dart';
import 'customer_payment_dialog.dart';
import 'new_customer_dialog.dart';
import 'retail_sale_page.dart';

/// دفتر الذمم — نظير ورقة "الذمم" في الإكسل.
///
/// بحث بالاسم أو بالمبلغ، وتسجيل الدفعات من القائمة مباشرة.
class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  final _search = TextEditingController();

  /// إخفاء المسدَّدين — الدفتر الورقي يمتلئ بأسماء انتهت ذممها.
  bool _onlyIndebted = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// المطابقة: الاسم أو الملاحظة أو الهاتف نصّياً، والمبلغ رقمياً.
  bool _matches(Account c, MoneyFils due, String query) {
    if (query.trim().isEmpty) return true;

    if (arabicContains(c.name, query)) return true;
    if (c.note != null && arabicContains(c.note!, query)) return true;

    final digits = digitsOnly(query);
    if (digits.isEmpty) return false;

    if (c.phone != null && digitsOnly(c.phone!).contains(digits)) return true;

    // البحث بالمبلغ يطابق الدين كاملاً وبالدينار الصحيح معاً، حتى يجد
    // صاحب المحل "٨٤٦" سواء كتبها بفواصلها أو بلا.
    if (isNumericQuery(query)) {
      final whole = (due ~/ filsPerDinar).toString();
      if (whole.contains(digits)) return true;
      if (digitsOnly(formatDinars(due)).contains(digits)) return true;
    }
    return false;
  }

  Future<void> _collect(Account customer, MoneyFils due) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => CustomerPaymentDialog(customer: customer, dueFils: due),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = ref.watch(customersProvider);
    final balances = ref.watch(balancesProvider);
    final query = _search.text;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('الذمم'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(customersProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-customers',
        onPressed: () => showDialog<bool>(
          context: context,
          builder: (_) => const NewCustomerDialog(),
        ),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(
          'زبون جديد',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: customers.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.goldPrimary),
        ),
        error: (e, _) => Center(child: Text('خطأ: $e')),
        data: (list) {
          if (list.isEmpty) return const _EmptyState();

          final byId = {
            for (final b in balances.valueOrNull ?? const <AccountBalance>[])
              b.accountId: b,
          };

          MoneyFils dueOf(Account c) => byId[c.id]?.cashFils ?? 0;

          final all = [...list]..sort((a, b) => dueOf(b).compareTo(dueOf(a)));

          final visible = all
              .where((c) => !_onlyIndebted || dueOf(c) > 0)
              .where((c) => _matches(c, dueOf(c), query))
              .toList();

          // الإجماليات تخص الدفتر كله لا نتيجة البحث — وإلا تغيّر
          // "إجمالي الذمم" كلما كتب المستخدم حرفاً.
          final totalDue =
              all.fold<int>(0, (a, c) => a + (dueOf(c) > 0 ? dueOf(c) : 0));
          final indebted = all.where((c) => dueOf(c) > 0).length;

          return RefreshIndicator(
            color: AppColors.goldPrimary,
            backgroundColor: Colors.white,
            onRefresh: () async {
              ref.invalidate(customersProvider);
              ref.invalidate(balancesProvider);
            },
            child: ListView(
              key: const PageStorageKey('customers-list-storage-key'),
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
              children: [
                _SummaryCard(
                  totalDue: totalDue,
                  indebted: indebted,
                  total: all.length,
                  onSale: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RetailSalePage()),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'ابحث بالاسم أو المبلغ أو رقم الهاتف',
                    prefixIcon: const Icon(Icons.search_rounded, size: 22),
                    suffixIcon: query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'مسح البحث',
                            icon: const Icon(Icons.close_rounded, size: 20),
                            onPressed: () => setState(_search.clear),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilterChip(
                      selected: _onlyIndebted,
                      onSelected: (v) => setState(() => _onlyIndebted = v),
                      label: const Text('المدينون فقط'),
                      showCheckmark: false,
                      avatar: Icon(
                        _onlyIndebted
                            ? Icons.filter_alt_rounded
                            : Icons.filter_alt_outlined,
                        size: 16,
                        color: _onlyIndebted
                            ? AppColors.goldDark
                            : AppColors.textSecondary,
                      ),
                      selectedColor: AppColors.goldContainer,
                      side: BorderSide(
                        color: _onlyIndebted
                            ? AppColors.goldBorder
                            : AppColors.border,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'ظاهر ${visible.length} من ${all.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (visible.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 36, color: AppColors.textMuted),
                        SizedBox(height: 10),
                        Text(
                          'لا نتائج مطابقة',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final c in visible)
                    _CustomerTile(
                      customer: c,
                      due: dueOf(c),
                      onCollect: () => _collect(c, dueOf(c)),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalDue,
    required this.indebted,
    required this.total,
    required this.onSale,
  });

  final MoneyFils totalDue;
  final int indebted;
  final int total;
  final VoidCallback onSale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBF8F1), Color(0xFFFAF3E3)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.goldBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'إجمالي الذمم',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatDinars(totalDue)} د.أ',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.goldDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'موزعة على $indebted من أصل $total زبوناً',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: onSale,
            icon: const Icon(Icons.shopping_bag_outlined, size: 18),
            label: const Text('بيع تجزئة'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              minimumSize: const Size(0, 44),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.customer,
    required this.due,
    required this.onCollect,
  });

  final Account customer;
  final MoneyFils due;
  final VoidCallback onCollect;

  @override
  Widget build(BuildContext context) {
    final c = customer;
    final subtitle = [
      if (c.phone != null && c.phone!.isNotEmpty) c.phone!,
      if (c.note != null && c.note!.isNotEmpty) c.note!,
    ].join('  ·  ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: due > 0 ? AppColors.border : AppColors.borderSubtle,
            width: 1.2,
          ),
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
                builder: (_) => StatementPage(accountId: c.id, title: c.name),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: due > 0
                          ? AppColors.goldContainer
                          : AppColors.surfaceMuted,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: due > 0
                            ? AppColors.goldBorder
                            : AppColors.borderSubtle,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        c.name.characters.first,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: due > 0
                              ? AppColors.goldDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: due > 0
                              ? AppColors.errorContainer
                              : AppColors.successContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          due > 0 ? '${formatDinars(due)} د.أ' : 'مسدَّد',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color:
                                due > 0 ? AppColors.error : AppColors.success,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 30,
                        child: TextButton.icon(
                          onPressed: onCollect,
                          icon: const Icon(Icons.add_card_rounded, size: 15),
                          label: const Text('دفعة'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.goldDark,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                child: Icon(Icons.groups_rounded,
                    size: 36, color: AppColors.goldDark),
              ),
              SizedBox(height: 16),
              Text(
                'لا يوجد زبائن في دفتر الذمم بعد',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'أضف زبوناً وسجّل عليه المبلغ، ثم دوّن دفعاته أولاً بأول.',
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
