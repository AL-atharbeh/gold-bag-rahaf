import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

const _key = 'app_locale';

/// لغة الواجهة — العربية افتراضياً، وتُحفظ على الجهاز.
class LocaleController extends StateNotifier<Locale> {
  LocaleController() : super(const Locale('ar')) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_key);
      if (code != null && code != state.languageCode) state = Locale(code);
    } catch (_) {
      // التخزين غير متاح (اختبارات مثلاً) — نبقى على الافتراضي
    }
  }

  Future<void> set(Locale locale) async {
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, locale.languageCode);
    } catch (_) {}
  }

  Future<void> toggle() =>
      set(Locale(state.languageCode == 'ar' ? 'en' : 'ar'));
}

final localeProvider = StateNotifierProvider<LocaleController, Locale>(
    (ref) => LocaleController());

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';
}

/// يعزل نصاً لاتينياً أو رقمياً (مثل 2026-00004) فلا يقلبه اتجاه العربية.
String ltrIsolate(String s) =>
    '${String.fromCharCode(0x2066)}$s${String.fromCharCode(0x2069)}';
