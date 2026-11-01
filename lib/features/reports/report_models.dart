import '../../domain/enums.dart';
import '../../domain/ledger.dart';
import '../../domain/models.dart';

/// مفتاح صنف + عيار، مع الاسمين للعرض.
class ItemKey {
  const ItemKey(this.itemId, this.karatId, this.itemName, this.karatName);

  final String? itemId;
  final String? karatId;
  final String? itemName;
  final String? karatName;

  bool get isScrap => itemId == null;
  String get id => '${itemId ?? '-'}|${karatId ?? '-'}';

  static ItemKey of(PeriodPosting p) =>
      ItemKey(p.itemId, p.karatId, p.itemName, p.karatName);
}

/// عدد ووزن قائم وصافٍ — يُجمع ويُطرح.
class Qty {
  int pieces = 0;
  int grossMg = 0;
  int netMg = 0;

  void add(int pcs, int gross, int net) {
    pieces += pcs;
    grossMg += gross;
    netMg += net;
  }
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

// ---------------------------------------------------------------------------
// تقرير المبيعات
// ---------------------------------------------------------------------------

class PartySales {
  PartySales(this.name);
  final String name;
  final sold = Qty();
  final returned = Qty();
  int makingFils = 0;
  int invoices = 0;
  int get netMg => sold.netMg - returned.netMg;
}

class DaySales {
  final sold = Qty();
  final returned = Qty();
  int makingFils = 0;
  int invoices = 0;
  int get netMg => sold.netMg - returned.netMg;
}

/// المبيعات من الشنطة في فترة: بالأيام، والمحلات، والأصناف.
///
/// المبيع = بضاعة خرجت من الشنطة بفاتورة بيع. المرتجع من المحلات يُطرح.
/// الحركات الملغاة وقيودها العكسية لا تدخل.
class SalesReport {
  SalesReport._(this.from, this.to);

  factory SalesReport.build({
    required DateTime from,
    required DateTime to,
    required List<PeriodPosting> postings,
    required String? bagId,
  }) {
    final r = SalesReport._(_day(from), _day(to));
    final invoicesPerDay = <DateTime, Set<String>>{};
    final invoicesPerParty = <String, Set<String>>{};

    for (final p in postings) {
      if (p.cancelled) continue;
      if (p.txType != TxType.sale && p.txType != TxType.goodsReturn) continue;
      final day = r.days.putIfAbsent(_day(p.occurredAt), DaySales.new);
      final partyKey = p.partyId ?? '-';
      final party =
          r.parties.putIfAbsent(partyKey, () => PartySales(p.partyName ?? '—'));

      // البضاعة من/إلى الشنطة
      if (p.accountId == bagId &&
          p.ledger == LedgerKind.gold &&
          p.itemId != null) {
        final pcs = (p.quantity ?? 0).abs();
        final gross = (p.grossWeightMg ?? 0).abs();
        final net = p.amount.abs();
        final key = ItemKey.of(p);
        r.itemKeys[key.id] = key;
        if (p.txType == TxType.sale && p.amount < 0) {
          r.sold.add(pcs, gross, net);
          day.sold.add(pcs, gross, net);
          party.sold.add(pcs, gross, net);
          r.byItem.putIfAbsent(key.id, Qty.new).add(pcs, gross, net);
          invoicesPerDay.putIfAbsent(_day(p.occurredAt), () => {}).add(p.txId);
          invoicesPerParty.putIfAbsent(partyKey, () => {}).add(p.txId);
        } else if ((p.txType == TxType.goodsReturn ||
                p.lineNote == noteRecovered) &&
            p.amount > 0) {
          // مرتجع من محل إلى الشنطة (المرتجع للمشغل يخرج منها فلا يُحسب)
          r.returned.add(pcs, gross, net);
          day.returned.add(pcs, gross, net);
          party.returned.add(pcs, gross, net);
          r.byItem.putIfAbsent(key.id, Qty.new).add(-pcs, -gross, -net);
        }
      }

      // المصنوعية المفوترة على الطرف (موجبة في البيع، سالبة في المرتجع)
      if (p.accountId == p.partyId &&
          p.ledger == LedgerKind.cash &&
          p.makingPerGramFils != null &&
          (p.partyKind == AccountKind.showroom ||
              p.partyKind == AccountKind.trader)) {
        r.makingFils += p.amount;
        day.makingFils += p.amount;
        party.makingFils += p.amount;
      }

      // خصم المصنوعية يُنقص ما فُوتر
      if (p.accountId == p.partyId &&
          p.ledger == LedgerKind.cash &&
          p.lineNote == noteMakingDiscount) {
        r.makingFils += p.amount;
        day.makingFils += p.amount;
        party.makingFils += p.amount;
      }

    }

    for (final e in invoicesPerDay.entries) {
      r.days[e.key]?.invoices = e.value.length;
    }
    for (final e in invoicesPerParty.entries) {
      r.parties[e.key]?.invoices = e.value.length;
    }
    r.invoices = invoicesPerParty.values
        .fold<Set<String>>({}, (a, s) => a..addAll(s)).length;
    // أيام وأطراف بلا مبيع ولا مرتجع (مثلاً حركة كسر فقط) لا تُعرض
    r.days.removeWhere((_, d) =>
        d.sold.netMg == 0 && d.returned.netMg == 0 && d.makingFils == 0);
    r.parties.removeWhere((_, d) =>
        d.sold.netMg == 0 && d.returned.netMg == 0 && d.makingFils == 0);
    return r;
  }

  final DateTime from;
  final DateTime to;
  final sold = Qty();
  final returned = Qty();
  int makingFils = 0;
  int invoices = 0;

  final days = <DateTime, DaySales>{};
  final parties = <String, PartySales>{};
  final byItem = <String, Qty>{};
  final itemKeys = <String, ItemKey>{};

  int get netMg => sold.netMg - returned.netMg;

  List<MapEntry<DateTime, DaySales>> get daysSorted =>
      days.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

  List<PartySales> get partiesSorted =>
      parties.values.toList()..sort((a, b) => b.netMg.compareTo(a.netMg));

  List<(ItemKey, Qty)> get itemsSorted => [
        for (final e in byItem.entries) (itemKeys[e.key]!, e.value),
      ]..sort((a, b) => b.$2.netMg.compareTo(a.$2.netMg));
}

// ---------------------------------------------------------------------------
// كشف الشنطة
// ---------------------------------------------------------------------------

/// حركة واحدة على الشنطة.
class BagMove {
  BagMove(this.first);
  final PeriodPosting first;
  int pieces = 0;
  int goodsNetMg = 0;
  int scrapNetMg = 0;
  int capitalFils = 0;
}

/// كشف الشنطة لفترة: الرصيد الافتتاحي لكل صنف وعيار، ثم كل حركة
/// دخلت أو خرجت، ثم الرصيد الختامي.
///
/// الافتتاحي = المخزون الآن − كل ما جرى منذ بداية الفترة؛ فلا يلزم
/// تحميل الحركات القديمة.
class BagStatement {
  BagStatement._(this.from, this.to);

  factory BagStatement.build({
    required DateTime from,
    required DateTime to,
    required List<PeriodPosting> sinceFrom,
    required List<ItemStock> stockNow,
    required int capitalNowFils,
  }) {
    final s = BagStatement._(_day(from), _day(to));
    final end = _day(to).add(const Duration(days: 1));

    // المخزون الآن لكل صنف وعيار
    for (final x in stockNow) {
      final k = ItemKey(x.itemId, x.karatId, x.itemName, x.karatName);
      s.keys[k.id] = k;
      s.opening.putIfAbsent(k.id, Qty.new).add(x.quantity, x.grossMg, x.netMg);
    }
    s.openingCapitalFils = capitalNowFils;

    final moves = <String, BagMove>{};
    for (final p in sinceFrom) {
      final inPeriod = p.occurredAt.isBefore(end);
      if (p.ledger == LedgerKind.gold) {
        final k = ItemKey.of(p);
        s.keys[k.id] = k;
        final pcs = p.quantity ?? 0;
        final gross = p.grossWeightMg ?? 0;
        // كل ما جرى منذ البداية يُطرح من المخزون الآن → الافتتاحي
        s.opening.putIfAbsent(k.id, Qty.new).add(-pcs, -gross, -p.amount);
        if (inPeriod) {
          final q = p.amount >= 0
              ? s.inQty.putIfAbsent(k.id, Qty.new)
              : s.outQty.putIfAbsent(k.id, Qty.new);
          q.add(pcs.abs(), gross.abs(), p.amount.abs());
        }
      } else {
        s.openingCapitalFils -= p.amount;
        if (inPeriod) s.capitalChangeFils += p.amount;
      }

      if (!inPeriod) continue;
      final m = moves.putIfAbsent(p.txId, () => BagMove(p));
      if (p.ledger == LedgerKind.gold) {
        if (p.itemId == null) {
          m.scrapNetMg += p.amount;
        } else {
          m.goodsNetMg += p.amount;
          m.pieces += p.quantity ?? 0;
        }
      } else {
        m.capitalFils += p.amount;
      }
    }
    s.moves.addAll(moves.values.toList()
      ..sort((a, b) {
        final c = a.first.occurredAt.compareTo(b.first.occurredAt);
        return c != 0 ? c : a.first.docNumber.compareTo(b.first.docNumber);
      }));
    // أصناف لا رصيد لها ولا حركة لا تُعرض
    s.keys.removeWhere((id, _) {
      final o = s.opening[id];
      return (o == null || (o.pieces == 0 && o.netMg == 0)) &&
          !s.inQty.containsKey(id) &&
          !s.outQty.containsKey(id);
    });
    return s;
  }

  final DateTime from;
  final DateTime to;
  final keys = <String, ItemKey>{};
  final opening = <String, Qty>{};
  final inQty = <String, Qty>{};
  final outQty = <String, Qty>{};
  final moves = <BagMove>[];
  int openingCapitalFils = 0;
  int capitalChangeFils = 0;

  int get closingCapitalFils => openingCapitalFils + capitalChangeFils;

  Qty closing(String id) {
    final q = Qty();
    final o = opening[id], i = inQty[id], x = outQty[id];
    if (o != null) q.add(o.pieces, o.grossMg, o.netMg);
    if (i != null) q.add(i.pieces, i.grossMg, i.netMg);
    if (x != null) q.add(-x.pieces, -x.grossMg, -x.netMg);
    return q;
  }

  /// البضاعة أولاً (بالاسم ثم العيار) ثم الكسر.
  List<ItemKey> get rows => keys.values.toList()
    ..sort((a, b) {
      if (a.isScrap != b.isScrap) return a.isScrap ? 1 : -1;
      final c = (a.itemName ?? '').compareTo(b.itemName ?? '');
      return c != 0 ? c : (a.karatName ?? '').compareTo(b.karatName ?? '');
    });

  Qty total(bool scrap, Qty Function(String id) pick) {
    final q = Qty();
    for (final k in keys.values.where((k) => k.isScrap == scrap)) {
      final v = pick(k.id);
      q.add(v.pieces, v.grossMg, v.netMg);
    }
    return q;
  }

  Qty openingOf(String id) => opening[id] ?? Qty();
  Qty inOf(String id) => inQty[id] ?? Qty();
  Qty outOf(String id) => outQty[id] ?? Qty();
}
