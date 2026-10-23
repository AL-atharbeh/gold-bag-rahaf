import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../app/theme.dart';
import '../../core/connectivity.dart';
import '../../core/units.dart';

/// لوحة مفاتيح رقمية تقبل الفاصلة العشرية والأرقام العربية الهندية.
const _numeric = TextInputType.numberWithOptions(decimal: true);

/// يحوّل ما يُكتب في حقول الأرقام إلى أرقام إنجليزية ونقطة عشرية،
/// مهما كانت لغة لوحة المفاتيح — التاجر لا يبدّل اللغة ليكتب وزناً.
///
/// • الأرقام العربية والفارسية → 0-9
/// • الفواصل ٫ ، , → نقطة
/// • زرّا النقطة والفاصلة في التخطيط العربي يكتبان "ز" و"و" → نقطة
///
/// التحويل حرف بحرف فلا يتحرك المؤشر.
class LatinNumberFormatter extends TextInputFormatter {
  const LatinNumberFormatter({this.decimal = true});

  final bool decimal;

  static String normalize(String s, {bool decimal = true}) =>
      String.fromCharCodes(s.runes.map((r) {
        if (r >= 0x0660 && r <= 0x0669) return r - 0x0660 + 0x30;
        if (r >= 0x06F0 && r <= 0x06F9) return r - 0x06F0 + 0x30;
        if (decimal &&
            (r == 0x066B ||
                r == 0x060C ||
                r == 0x2C ||
                r == 0x632 ||
                r == 0x648)) {
          return 0x2E; // ٫ ، , ز و → .
        }
        return r;
      }));

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = normalize(newValue.text, decimal: decimal);
    return text == newValue.text ? newValue : newValue.copyWith(text: text);
  }
}

final _numericFormatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'));

/// يمنع فاصلة عشرية ثانية.
///
/// بدونه يقبل الحقل "٥٥٫٥١٫٢٣" فيرفضه المدقّق عند الحفظ برسالة
/// "وزن غير صالح" — وصاحب المحل يكون قد كتب الوزن كاملاً قبل أن يعلم.
class _SingleSeparatorFormatter extends TextInputFormatter {
  const _SingleSeparatorFormatter();

  static final _separator = RegExp(r'\.');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      _separator.allMatches(newValue.text).length > 1 ? oldValue : newValue;
}

final _numericFormatters = <TextInputFormatter>[
  const LatinNumberFormatter(),
  _numericFormatter,
  const _SingleSeparatorFormatter(),
];

/// مرشّحات حقول الوزن والمبلغ — للشاشات التي تبني حقولها بنفسها.
List<TextInputFormatter> get decimalInputFormatters => _numericFormatters;

/// مرشّحات حقول الهاتف: أرقام إنجليزية، وعلامة + ومسافة فقط.
final phoneInputFormatters = <TextInputFormatter>[
  const LatinNumberFormatter(decimal: false),
  FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
  LengthLimitingTextInputFormatter(16),
];

/// مرشّحات حقول العدد الصحيح (عدد القطع).
final integerInputFormatters = <TextInputFormatter>[
  const LatinNumberFormatter(decimal: false),
  FilteringTextInputFormatter.digitsOnly,
];

/// حقل وزن بالجرام — يُخزَّن مليجراماً.
class GramsField extends StatelessWidget {
  const GramsField({
    super.key,
    required this.controller,
    this.label = 'الوزن القائم',
    this.autofocus = false,
    this.required = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final bool required;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: _numeric,
      inputFormatters: _numericFormatters,
      textAlign: TextAlign.left,
      // الأرقام تُكتب من اليسار — وإلا ظهرت النقطة قبل الرقم في الواجهة العربية
      textDirection: TextDirection.ltr,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.scale_rounded, size: 20),
        suffixText: 'غرام',
        suffixStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.goldDark,
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return required ? 'أدخل الوزن' : null;
        }
        final mg = parseGrams(v);
        if (mg == null) return 'وزن غير صالح';
        if (mg <= 0) return 'الوزن يجب أن يكون أكبر من صفر';
        return null;
      },
    );
  }
}

/// حقل مبلغ بالدينار — يُخزَّن فلساً.
class DinarsField extends StatelessWidget {
  const DinarsField({
    super.key,
    required this.controller,
    this.label = 'المبلغ',
    this.autofocus = false,
    this.required = true,
    this.allowZero = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool autofocus;
  final bool required;
  final bool allowZero;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: _numeric,
      inputFormatters: _numericFormatters,
      textAlign: TextAlign.left,
      // الأرقام تُكتب من اليسار — وإلا ظهرت النقطة قبل الرقم في الواجهة العربية
      textDirection: TextDirection.ltr,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.monetization_on_outlined, size: 20),
        suffixText: 'د.أ',
        suffixStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.goldDark,
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return required ? 'أدخل المبلغ' : null;
        }
        final fils = parseDinars(v);
        if (fils == null) return 'مبلغ غير صالح';
        if (fils < 0) return 'المبلغ لا يكون سالباً';
        if (fils == 0 && !allowZero) return 'المبلغ يجب أن يكون أكبر من صفر';
        return null;
      },
    );
  }
}

/// حقل عدد القطع.
class CountField extends StatelessWidget {
  const CountField({
    super.key,
    required this.controller,
    this.label = 'العدد',
  });

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: integerInputFormatters,
      textAlign: TextAlign.left,
      // الأرقام تُكتب من اليسار — وإلا ظهرت النقطة قبل الرقم في الواجهة العربية
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.tag_rounded, size: 20),
      ),
    );
  }
}

/// اختيار التاريخ — التاجر كثيراً ما يسجّل حركة الأمس.
class DateField extends StatelessWidget {
  const DateField({super.key, required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final t =
        '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: AppColors.goldPrimary,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'تاريخ الحركة',
          prefixIcon: Icon(Icons.calendar_today_rounded, size: 20),
        ),
        child: Text(
          t,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// شريط يعرض حصيلة العملية قبل الحفظ — بطاقة ذهبية فاخرة وواضحة.
class SummaryBar extends StatelessWidget {
  const SummaryBar(
      {super.key, required this.items, this.title = 'ملخص الحركة الحالية'});

  /// (العنوان، القيمة)
  final List<(String, String)> items;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.goldContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldBorder, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_rounded,
                  size: 16, color: AppColors.goldDark),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.goldDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 28,
            runSpacing: 12,
            children: [
              for (final (label, value) in items)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// عرض رسالة نجاح أو فشل بأسلوب موحّد.
void showResult(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            error
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      backgroundColor: error ? AppColors.error : AppColors.goldDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

/// ترجمة أخطاء السيرفر إلى لغة التاجر.
String readableError(Object e) {
  if (e is OfflineException) return e.toString();
  if (e is PostgrestException) {
    if (e.code == '42501' && !RegExp(r'[؀-ۿ]').hasMatch(e.message)) {
      return 'لا تملك صلاحية لهذه العملية';
    }
    return e.message;
  }
  if (e is AuthException) return e.message;
  final s = e.toString();
  if (s.contains('قيد غير متوازن')) return s;
  if (s.contains('SocketException') || s.contains('Failed host lookup')) {
    return 'لا يوجد اتصال بالإنترنت — لم تُحفظ الحركة';
  }
  if (s.contains('permission denied')) {
    return 'لا تملك صلاحية لهذه العملية';
  }
  final m = RegExp(r'message: ([^,}]+)').firstMatch(s);
  return m != null ? m.group(1)! : 'تعذّر الحفظ: $s';
}
