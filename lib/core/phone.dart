/// أرقام الهاتف الأردنية.
///
/// المستخدم يكتب الرقم كما اعتاد: "0791234567" أو "791234567" أو
/// "+962 79 123 4567" أو بأرقام عربية. Supabase يحتاجه بصيغة E.164.
library;

/// يُرجع "+9627XXXXXXXX" أو null إن لم يكن رقم جوال أردنياً صالحاً.
String? normalizeJordanMobile(String input) {
  var d = String.fromCharCodes(input.runes.map((r) {
    if (r >= 0x0660 && r <= 0x0669) return r - 0x0660 + 0x30;
    if (r >= 0x06f0 && r <= 0x06f9) return r - 0x06f0 + 0x30;
    return r;
  })).replaceAll(RegExp(r'\D'), '');

  if (d.startsWith('00')) d = d.substring(2);
  if (d.startsWith('962')) d = d.substring(3);
  if (d.startsWith('0')) d = d.substring(1);

  // جوالات الأردن: 77 / 78 / 79 ثم سبعة أرقام
  if (!RegExp(r'^7[789]\d{7}$').hasMatch(d)) return null;
  return '+962$d';
}

/// "+962791234567" أو "962791234567" → "0791234567" للعرض.
String displayPhone(String? phone) {
  if (phone == null || phone.isEmpty) return '';
  final d = phone.replaceAll(RegExp(r'\D'), '');
  if (d.startsWith('962') && d.length == 12) return '0${d.substring(3)}';
  return phone;
}

/// البريد الداخلي للدخول: "+962791234567" → "962791234567@phone.goldbashar.app".
/// نظير edition_login_email في قاعدة البيانات (0017).
String phoneLoginEmail(String phone) =>
    '${phone.replaceAll(RegExp(r'\D'), '')}@phone.goldbashar.app';
