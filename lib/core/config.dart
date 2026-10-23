/// إعدادات الاتصال — تُمرَّر عند البناء وتبقى القيم الحالية افتراضية:
///
///   flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// المفتاح العام (publishable) ليس سرّاً: الحماية الفعلية في سياسات RLS
/// داخل قاعدة البيانات، لا في إخفاء المفتاح.
class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ykopzrugkbrxbsyvizfb.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_34zhaEWMXjWLg6T5O_GpKw_u9KTev61',
  );

  /// رقم الدعم الذي يظهر في شاشة انتظار التفعيل والاشتراك. فارغ = لا يظهر.
  static const supportPhone = String.fromEnvironment('SUPPORT_PHONE');

  /// أقصى عدد حسابات في نسخة الشنطة — مفروض أيضاً في قاعدة البيانات.
  static const bagEditionMaxUsers = 3;
}
