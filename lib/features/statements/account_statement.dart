import '../../core/units.dart';
import '../../domain/enums.dart';
import '../../domain/ledger.dart';
import '../../domain/models.dart';

/// حركة واحدة في كشف الحساب — مجموع سطورها في الدفترين، والرصيد بعدها.
class StatementRow {
  StatementRow(this.first);

  final StatementLine first;
  int gold = 0;
  int cash = 0;
  int goldAfter = 0;
  int cashAfter = 0;

  /// وزن الذهب القائم لكل عيار في الحركة — لعمود البيان.
  final Map<String, int> grossByKarat = {};

  DateTime get date => first.occurredAt;
  String get docNumber => first.docNumber;
  TxType get type => first.txType;
  bool get isReversed => first.isReversed;

  /// تصنيف التسكير إن وُجد: حلة أو كسر — من أي سطر في الحركة.
  String? fixClass;
}

/// كشف حساب طرف لفترة: الرصيد السابق أولاً، ثم حركات الفترة، ثم الرصيد الختامي.
class AccountStatement {
  AccountStatement._({
    required this.from,
    required this.to,
    required this.openingGold,
    required this.openingCash,
    required this.rows,
  });

  /// يبني الكشف من:
  /// - [since]: كل سطور الطرف من بداية الفترة حتى اليوم.
  /// - [goldNow] و[cashNow]: رصيده الحالي الفعلي.
  ///
  /// الرصيد السابق = الرصيد الحالي − كل ما جرى منذ بداية الفترة؛
  /// فيصح مهما كان عدد الحركات القديمة، بلا تحميلها.
  factory AccountStatement.build({
    required DateTime from,
    required DateTime to,
    required List<StatementLine> since,
    required int goldNow,
    required int cashNow,
  }) {
    final start = DateTime(from.year, from.month, from.day);
    final end =
        DateTime(to.year, to.month, to.day).add(const Duration(days: 1));

    var gold = goldNow;
    var cash = cashNow;
    final byTx = <String, StatementRow>{};
    for (final s in since) {
      if (s.occurredAt.isBefore(start)) continue;
      if (s.ledger == LedgerKind.gold) {
        gold -= s.amount;
      } else {
        cash -= s.amount;
      }
      if (!s.occurredAt.isBefore(end)) continue;
      final r = byTx.putIfAbsent(s.txId, () => StatementRow(s));
      if (s.note == noteFixGold || s.note == noteFixScrap) r.fixClass = s.note;
      if (s.ledger == LedgerKind.gold) {
        r.gold += s.amount;
        final g = s.grossWeightMg;
        if (g != null && g != 0) {
          final k = s.karatName ?? '';
          r.grossByKarat[k] = (r.grossByKarat[k] ?? 0) + g.abs();
        }
      } else {
        r.cash += s.amount;
      }
    }

    final rows = byTx.values.toList()
      ..sort((a, b) {
        final c = a.date.compareTo(b.date);
        return c != 0 ? c : a.docNumber.compareTo(b.docNumber);
      });
    var g = gold;
    var c = cash;
    for (final r in rows) {
      g += r.gold;
      c += r.cash;
      r.goldAfter = g;
      r.cashAfter = c;
    }
    return AccountStatement._(
      from: start,
      to: DateTime(to.year, to.month, to.day),
      openingGold: gold,
      openingCash: cash,
      rows: rows,
    );
  }

  final DateTime from;
  final DateTime to;
  final int openingGold;
  final int openingCash;
  final List<StatementRow> rows;

  int get goldTotal => rows.fold(0, (a, r) => a + r.gold);
  int get cashTotal => rows.fold(0, (a, r) => a + r.cash);
  int get closingGold => openingGold + goldTotal;
  int get closingCash => openingCash + cashTotal;

  /// مجموع ما دخل حسابه (عليه) وما خرج (له) في الفترة — لكل دفتر.
  int get goldDebit => rows.fold(0, (a, r) => a + (r.gold > 0 ? r.gold : 0));
  int get goldCredit => rows.fold(0, (a, r) => a + (r.gold < 0 ? -r.gold : 0));
  int get cashDebit => rows.fold(0, (a, r) => a + (r.cash > 0 ? r.cash : 0));
  int get cashCredit => rows.fold(0, (a, r) => a + (r.cash < 0 ? -r.cash : 0));
}

/// وصف قصير للأوزان: «عيار 21: 40.000 · عيار 18: 12.500».
String grossSummary(StatementRow r, String gramsUnit) => [
      for (final e in r.grossByKarat.entries)
        '${e.key.isEmpty ? '' : '${e.key}: '}${formatGrams(e.value)} $gramsUnit',
    ].join(' · ');
