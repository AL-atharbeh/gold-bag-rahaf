import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/enums.dart';
import '../../domain/models.dart';

/// جرد كل ما في الشنطة: البضاعة، والكسر، والكاش، والشيكات، ورأس المال.
class BagInventory {
  BagInventory({
    required List<ItemStock> stock,
    required this.cashboxFils,
    required this.chequesInFils,
    required this.chequesOutFils,
    required this.capitalFils,
  })  : goods = stock.where((r) => r.itemId != null && !r.isEmpty).toList(),
        scrap = stock.where((r) => r.itemId == null && !r.isEmpty).toList();

  final List<ItemStock> goods;
  final List<ItemStock> scrap;

  /// الكاش النقدي في الشنطة (الصندوق).
  final int cashboxFils;

  /// شيكات بحوزة حامل الشنطة لم تُصرف بعد (حساب الشيكات).
  final int chequesInFils;

  /// شيكات صادرة لم تُصرف بعد — موجبة.
  final int chequesOutFils;

  /// تكلفة المصنوعية المدفوعة في البضاعة الموجودة.
  final int capitalFils;

  /// النقد الفعلي في الشنطة.
  int get cashFils => cashboxFils;

  int get goodsPieces => goods.fold(0, (a, r) => a + r.quantity);
  int get goodsGrossMg => goods.fold(0, (a, r) => a + r.grossMg);
  int get goodsNetMg => goods.fold(0, (a, r) => a + r.netMg);
  int get scrapGrossMg => scrap.fold(0, (a, r) => a + r.grossMg);
  int get scrapNetMg => scrap.fold(0, (a, r) => a + r.netMg);
  int get totalNetMg => goodsNetMg + scrapNetMg;

  bool get isEmpty =>
      goods.isEmpty && scrap.isEmpty && cashboxFils == 0 && capitalFils == 0;

  /// البضاعة مجمّعة حسب الصنف، ثم العيارات داخله.
  Map<String, List<ItemStock>> goodsByItem(String unknown) {
    final m = <String, List<ItemStock>>{};
    for (final r in goods) {
      m.putIfAbsent(r.itemName ?? unknown, () => []).add(r);
    }
    return m;
  }
}

/// يجمع الجرد من المخزون والأرصدة والشيكات المعلّقة.
final bagInventoryProvider =
    FutureProvider.autoDispose<BagInventory?>((ref) async {
  final sys = await ref.watch(systemAccountsProvider.future);
  final bagId = sys[SystemAccount.shanta];
  final cashboxId = sys[SystemAccount.cashbox];
  if (bagId == null) return null;

  final stock = await ref.watch(itemStockProvider(bagId).future);
  final balances = await ref.watch(balancesProvider.future);

  int cashOf(String? id) =>
      balances.where((b) => b.accountId == id).firstOrNull?.cashFils ?? 0;
  final cheques = cashOf(sys[SystemAccount.cheques]);

  return BagInventory(
    stock: stock,
    cashboxFils: cashOf(cashboxId),
    chequesInFils: cheques > 0 ? cheques : 0,
    chequesOutFils: cheques < 0 ? -cheques : 0,
    capitalFils: cashOf(bagId),
  );
});
