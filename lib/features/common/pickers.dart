import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/units.dart';
import '../../domain/models.dart';

class AccountPicker extends StatelessWidget {
  const AccountPicker({
    super.key,
    required this.accounts,
    required this.value,
    required this.onChanged,
    this.label = 'الطرف',
  });

  final List<Account> accounts;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.person_search_rounded, size: 22),
      ),
      items: [
        for (final a in accounts)
          DropdownMenuItem(
            value: a.id,
            child: Row(
              children: [
                Text(
                  a.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.goldContainer,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.goldBorder, width: 0.8),
                  ),
                  child: Text(
                    a.kind.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.goldDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
      onChanged: onChanged,
      validator: (v) => v == null ? 'اختر $label' : null,
    );
  }
}

/// العيارات — أزرار متجاورة أنيقة أو قائمة منسدلة.
///
/// المعامل مكتوب تحت اسم العيار لأن الدفتر الورقي يعنون أعمدته به لا
/// بالاسم: "بضاعة ٨٨٥" و"تسليم كسر ١٨". وهو يتغيّر بتغيّر الاتجاه —
/// عيار ٢١ يخرج بـ ٨٨٥ ويعود بـ ٨٧٠ — فإخفاؤه يخفي هامش المحل نفسه.
class KaratPicker extends StatelessWidget {
  const KaratPicker({
    super.key,
    required this.karats,
    required this.value,
    required this.onChanged,
  });

  final List<KaratOption> karats;
  final String? value;
  final ValueChanged<String> onChanged;

  /// ٨٨٥٠٠٠ → "٨٨٥" كما يكتبها التاجر في رأس العمود، و١٠٠٠٠٠٠ → "حلة".
  static String factorLabel(int ppm) =>
      ppm == karatPpmScale ? 'حلة صافية' : (ppm ~/ 1000).toString();

  @override
  Widget build(BuildContext context) {
    if (karats.length > 4) {
      return DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        dropdownColor: Colors.white,
        decoration: const InputDecoration(
          labelText: 'العيار',
          prefixIcon: Icon(Icons.workspace_premium_rounded, size: 20),
        ),
        items: [
          for (final k in karats)
            DropdownMenuItem(
              value: k.id,
              child: Row(
                children: [
                  Text(
                    k.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    factorLabel(k.ppm),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldDark,
                    ),
                  ),
                ],
              ),
            ),
        ],
        onChanged: (v) => v == null ? null : onChanged(v),
      );
    }

    return SegmentedButton<String>(
      segments: [
        for (final k in karats)
          ButtonSegment(
            value: k.id,
            label: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  k.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                Text(
                  factorLabel(k.ppm),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
      ],
      selected: value == null ? {} : {value!},
      emptySelectionAllowed: true,
      showSelectedIcon: false,
      onSelectionChanged: (s) => s.isEmpty ? null : onChanged(s.first),
    );
  }
}
