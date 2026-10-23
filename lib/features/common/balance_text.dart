import '../../core/units.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';

/// وصف الرصيد بلغة التاجر.
///
/// الإشارة وحدها لا تكفي: رصيد موجب على *تاجر* يعني ديناً له عندنا،
/// بينما رصيد موجب في *الشنطة* يعني بضاعة موجودة. الخلط بينهما
/// يقلب معنى الشاشة كلها.
List<String> describeBalance(AccountBalance b) {
  final out = <String>[];
  if (b.goldMg != 0) {
    out.add(_phrase(b.kind, b.goldMg, '${formatGrams(b.goldMg.abs())} غ صافي'));
  }
  if (b.cashFils != 0) {
    out.add(
        _phrase(b.kind, b.cashFils, '${formatDinars(b.cashFils.abs())} د.أ'));
  }
  return out;
}

String _phrase(AccountKind kind, int amount, String value) => switch (kind) {
      AccountKind.inventoryLocation ||
      AccountKind.cashbox =>
        amount > 0 ? 'الرصيد: $value' : 'عجز: $value',
      AccountKind.showroom ||
      AccountKind.trader ||
      AccountKind.factory =>
        amount > 0 ? 'لنا عليه: $value' : 'له علينا: $value',
      _ => value,
    };

/// هل الرصيد في صالحنا؟ يُستخدم للّون فقط.
bool isFavourable(AccountKind kind, int amount) => switch (kind) {
      AccountKind.inventoryLocation || AccountKind.cashbox => amount >= 0,
      _ => amount >= 0,
    };
