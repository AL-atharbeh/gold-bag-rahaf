/// أدوات نصية للبحث العربي.
library;

/// توحيد الحروف المتقاربة قبل المقارنة.
///
/// الاسم الواحد يُكتب بأكثر من صورة في الدفتر — "أم خالد" و"ام خالد"،
/// "قوقزة" و"قوقزه" — فبحث حرفي صارم يخفي الزبون عن صاحب المحل.
String arabicFold(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    // الأرقام العربية الهندية إلى لاتينية
    if (rune >= 0x0660 && rune <= 0x0669) {
      buffer.writeCharCode(rune - 0x0660 + 0x30);
      continue;
    }
    if (rune >= 0x06f0 && rune <= 0x06f9) {
      buffer.writeCharCode(rune - 0x06f0 + 0x30);
      continue;
    }
    // التشكيل والتطويل يُحذفان
    if ((rune >= 0x064b && rune <= 0x0652) || rune == 0x0640) continue;

    final ch = String.fromCharCode(rune);
    buffer.write(switch (ch) {
      'أ' || 'إ' || 'آ' || 'ٱ' => 'ا',
      'ة' => 'ه',
      'ى' => 'ي',
      'ؤ' => 'و',
      'ئ' => 'ي',
      _ => ch.toLowerCase(),
    });
  }
  return buffer.toString().trim();
}

/// هل يحتوي [haystack] على [needle] بعد توحيد الصور؟
bool arabicContains(String haystack, String needle) =>
    arabicFold(haystack).contains(arabicFold(needle));

/// هل النص أرقام فقط (بعد التوحيد)؟ يُستعمل لتمييز البحث بالمبلغ.
bool isNumericQuery(String input) {
  final folded = arabicFold(input).replaceAll(RegExp(r'[.,\s]'), '');
  return folded.isNotEmpty && RegExp(r'^\d+$').hasMatch(folded);
}

/// الأرقام وحدها من النص — للمطابقة على المبالغ وأرقام الهواتف.
String digitsOnly(String input) =>
    arabicFold(input).replaceAll(RegExp(r'\D'), '');
