/// وحدات القياس في النظام — كلها أعداد صحيحة (int).
///
/// لا تُستخدم `double` مطلقاً للأوزان أو المبالغ: أخطاء التقريب العشري
/// في تجارة الذهب تتحول إلى خسارة مال حقيقية بعد آلاف الحركات.
library;

/// الوزن يُخزَّن بالمليجرام. 1 جرام = 1000 مج (ميزان الذهب يعرض 3 خانات عشرية).
typedef WeightMg = int;

/// المبالغ تُخزَّن بالفلس. 1 دينار أردني = 1000 فلس.
typedef MoneyFils = int;

/// معامل العيار يُخزَّن مضروباً بمليون (ppm) ليبقى دقيقاً كعدد صحيح.
/// 0.885 → 885000 ، 0.740 → 740000 ، 1.000 → 1000000
typedef KaratPpm = int;

const int mgPerGram = 1000;
const int filsPerDinar = 1000;
const int karatPpmScale = 1000000;

/// الوزن الصافي (ما يعادله عيار 24) = الوزن القائم × معامل العيار.
///
/// التقريب لأقرب مليجرام بطريقة half-up على الموجب، وهي الطريقة التي
/// يتوقعها التاجر عند مطابقة الحساب يدوياً.
WeightMg netWeight(WeightMg gross, KaratPpm factor) =>
    (gross * factor + karatPpmScale ~/ 2) ~/ karatPpmScale;

/// قيمة وزن معيّن بسعر جرام معطى.
MoneyFils weightValue(WeightMg weight, MoneyFils pricePerGram) =>
    (weight * pricePerGram + mgPerGram ~/ 2) ~/ mgPerGram;

String formatGrams(WeightMg mg, {int decimals = 3}) {
  final negative = mg < 0;
  final v = mg.abs();
  final whole = v ~/ mgPerGram;
  final frac = (v % mgPerGram).toString().padLeft(3, '0');
  final tail = decimals == 0 ? '' : '.${frac.substring(0, decimals)}';
  return '${negative ? '-' : ''}$whole$tail';
}

String formatDinars(MoneyFils fils) {
  final negative = fils < 0;
  final v = fils.abs();
  final whole = v ~/ filsPerDinar;
  final frac = (v % filsPerDinar).toString().padLeft(3, '0');
  return '${negative ? '-' : ''}$whole.$frac';
}

/// تحويل نص يكتبه المستخدم ("12.345") إلى مليجرام دون المرور بـ double.
WeightMg? parseGrams(String input) => _parseScaled(input, 3);

/// تحويل نص يكتبه المستخدم ("45.500") إلى فلس دون المرور بـ double.
MoneyFils? parseDinars(String input) => _parseScaled(input, 3);

/// تحويل نص معامل عيار ("0.885") إلى ppm.
KaratPpm? parseKaratFactor(String input) => _parseScaled(input, 6);

int? _parseScaled(String input, int decimals) {
  // كل فواصل الكسر التي قد تُكتب تُعامل كنقطة عشرية: لوحة الأرقام العربية
  // تُخرج "٫" أو "،"، وبعض اللوحات تُخرج ",". لا أحد يكتب فاصلة الآلاف في وزن.
  var s = input.trim().replaceAll(RegExp(r'[٫،,]'), '.').replaceAll(' ', '');
  if (s.isEmpty) return null;
  var sign = 1;
  if (s.startsWith('-')) {
    sign = -1;
    s = s.substring(1);
  } else if (s.startsWith('+')) {
    s = s.substring(1);
  }
  // تحويل الأرقام العربية الهندية إلى لاتينية
  s = String.fromCharCodes(s.runes.map((r) {
    if (r >= 0x0660 && r <= 0x0669) return r - 0x0660 + 0x30;
    if (r >= 0x06f0 && r <= 0x06f9) return r - 0x06f0 + 0x30;
    return r;
  }));
  final parts = s.split('.');
  if (parts.length > 2) return null;
  final wholeText = parts[0].isEmpty ? '0' : parts[0];
  final fracText = (parts.length == 2 ? parts[1] : '')
      .padRight(decimals, '0')
      .substring(0, decimals);
  final whole = int.tryParse(wholeText);
  final frac = fracText.isEmpty ? 0 : int.tryParse(fracText);
  if (whole == null || frac == null) return null;
  final scale = List.filled(decimals, 10).fold<int>(1, (a, b) => a * b);
  return sign * (whole * scale + frac);
}
