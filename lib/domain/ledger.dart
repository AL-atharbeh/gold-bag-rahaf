import '../core/units.dart';
import 'enums.dart';
import 'models.dart';

/// خطأ يمنع إرسال قيد غير متوازن.
///
/// نفس القاعدة مفروضة داخل Postgres أيضاً — هذا الفحص هنا فقط ليعطي
/// المستخدم ردّاً فورياً بدل انتظار رحلة كاملة إلى سنغافورة.
class UnbalancedEntryException implements Exception {
  UnbalancedEntryException(this.ledger, this.difference);
  final LedgerKind ledger;
  final int difference;

  @override
  String toString() =>
      'قيد غير متوازن في دفتر ${ledger.label}: الفرق $difference';
}

/// سطر قيد قبل الإرسال.
class PostingDraft {
  const PostingDraft({
    required this.accountId,
    required this.ledger,
    required this.amount,
    this.karatId,
    this.karatPpm,
    this.grossWeightMg,
    this.itemId,
    this.quantity,
    this.makingPerGramFils,
    this.note,
  });

  /// سطر ذهبي: يحسب الوزن الصافي من الوزن القائم ومعامل العيار.
  factory PostingDraft.gold({
    required String accountId,
    required WeightMg grossWeightMg,
    required String karatId,
    required KaratPpm karatPpm,
    required bool debit,
    String? itemId,
    int? quantity,
    String? note,
  }) {
    final net = netWeight(grossWeightMg, karatPpm);
    return PostingDraft(
      accountId: accountId,
      ledger: LedgerKind.gold,
      amount: debit ? net : -net,
      karatId: karatId,
      karatPpm: karatPpm,
      grossWeightMg: debit ? grossWeightMg : -grossWeightMg,
      itemId: itemId,
      // العدد بإشارة كالوزن، فمجموعه على حساب = عدد القطع الموجودة فيه
      quantity: quantity == null ? null : (debit ? quantity : -quantity),
      note: note,
    );
  }

  factory PostingDraft.cash({
    required String accountId,
    required MoneyFils amountFils,
    required bool debit,
    int? makingPerGramFils,
    String? note,
  }) =>
      PostingDraft(
        accountId: accountId,
        ledger: LedgerKind.cash,
        amount: debit ? amountFils : -amountFils,
        makingPerGramFils: makingPerGramFils,
        note: note,
      );

  final String accountId;
  final LedgerKind ledger;
  final int amount;
  final String? karatId;
  final KaratPpm? karatPpm;
  final WeightMg? grossWeightMg;
  final String? itemId;
  final int? quantity;
  final MoneyFils? makingPerGramFils;
  final String? note;

  Map<String, dynamic> toJson() => {
        'account_id': accountId,
        'ledger': ledger.wire,
        'amount': amount,
        'karat_id': karatId,
        'karat_ppm': karatPpm,
        'gross_weight_mg': grossWeightMg,
        'item_id': itemId,
        'quantity': quantity,
        'making_per_gram_fils': makingPerGramFils,
        'note': note,
      };
}

/// كيف تُسوّى قيمة البضاعة: برصيد ذهب على الطرف الآخر، أم بمبلغ نقدي.
enum SettlementMode { gold, cash }

/// بند بضاعة داخل عملية بيع أو شراء.
class GoodsLine {
  /// يبني بنداً من عيار حُسم معامله سلفاً حسب الطرف والاتجاه.
  factory GoodsLine.of(
    KaratOption karat, {
    required WeightMg grossWeightMg,
    String? itemId,
    int? quantity,
    MoneyFils makingPerGramFils = 0,
  }) =>
      GoodsLine(
        grossWeightMg: grossWeightMg,
        karatId: karat.id,
        karatPpm: karat.ppm,
        itemId: itemId,
        quantity: quantity,
        makingPerGramFils: makingPerGramFils,
      );

  const GoodsLine({
    required this.grossWeightMg,
    required this.karatId,
    required this.karatPpm,
    this.itemId,
    this.quantity,
    this.makingPerGramFils = 0,
  });

  final WeightMg grossWeightMg;
  final String karatId;
  final KaratPpm karatPpm;
  final String? itemId;
  final int? quantity;
  final MoneyFils makingPerGramFils;

  WeightMg get netMg => netWeight(grossWeightMg, karatPpm);

  /// الأجرة تُحسب على الوزن القائم لا الصافي — هذا ما يفعله التاجر عملياً.
  MoneyFils get makingFils => weightValue(grossWeightMg, makingPerGramFils);
}

/// يبني سطور القيد لكل عملية. لا يتصل بالشبكة — قابل للاختبار وحده.
class LedgerBuilder {
  const LedgerBuilder();

  /// وارد بضاعة من المشغل إلى الشنطة.
  ///
  /// الذهب: يدخل الشنطة بالصافي (القائم × معامل البضاعة)، ويصير للمشغل
  /// علينا بنفس الصافي.
  /// المصنوعية: على الوزن القائم، نقداً — للمشغل علينا دنانير، وتُقيَّد
  /// على الشنطة في دفتر النقد كرأس مال مدفوع في البضاعة.
  /// كل بند يحمل صنفه وعدده، فيُعرف مخزون الشنطة قطعةً قطعة.
  List<PostingDraft> goodsIn({
    required String workshopId,
    required String bagAccountId,
    required List<GoodsLine> lines,
  }) {
    if (lines.isEmpty) {
      throw ArgumentError('الفاتورة تحتاج بنداً واحداً على الأقل');
    }

    final drafts = <PostingDraft>[];
    for (final l in lines) {
      if (l.grossWeightMg <= 0) {
        throw ArgumentError('الوزن يجب أن يكون أكبر من صفر');
      }
      drafts
        ..add(PostingDraft.gold(
          accountId: bagAccountId,
          grossWeightMg: l.grossWeightMg,
          karatId: l.karatId,
          karatPpm: l.karatPpm,
          debit: true, // يدخل الشنطة
          itemId: l.itemId,
          quantity: l.quantity,
        ))
        ..add(PostingDraft.gold(
          accountId: workshopId,
          grossWeightMg: l.grossWeightMg,
          karatId: l.karatId,
          karatPpm: l.karatPpm,
          debit: false, // له علينا ذهب
          itemId: l.itemId,
          quantity: l.quantity,
        ));

      if (l.makingFils != 0) {
        drafts
          ..add(PostingDraft.cash(
            accountId: bagAccountId,
            amountFils: l.makingFils,
            debit: true, // رأس مال مدفوع في البضاعة
            makingPerGramFils: l.makingPerGramFils,
            note: 'مصنوعية',
          ))
          ..add(PostingDraft.cash(
            accountId: workshopId,
            amountFils: l.makingFils,
            debit: false, // له علينا نقداً
            makingPerGramFils: l.makingPerGramFils,
            note: 'مصنوعية',
          ));
      }
    }
    return _checked(drafts);
  }

  /// بيع للمحل من الشنطة، مع استلام كسر و/أو نقد منه في نفس الحركة.
  ///
  /// البضاعة: تخرج من الشنطة بالصافي (معامل البضاعة) ويصير على المحل
  /// ذهب صافٍ بنفس القدر. مصنوعيتها (على القائم) دين نقدي على المحل
  /// وإيراد مصنوعية لنا.
  /// تكلفة البضاعة: [costOutFils] من رأس المال المقيّد على الشنطة يخرج
  /// منها ويُخصم من إيراد المصنوعية، فيبقى في الإيراد الربح الصافي.
  /// الكسر: يدخل الشنطة بمعامل الكسر (0.870 لعيار 21) وينقص به ذهب المحل.
  /// النقد: يدخل الصندوق وينقص به دين المحل النقدي.
  List<PostingDraft> shopSale({
    required String shopId,
    required String bagAccountId,
    required String cashboxId,
    required String makingIncomeId,
    List<GoodsLine> goods = const [],
    List<GoodsLine> scrap = const [],
    MoneyFils cashReceivedFils = 0,
    MoneyFils costOutFils = 0,
  }) {
    if (goods.isEmpty && scrap.isEmpty && cashReceivedFils <= 0) {
      throw ArgumentError('الحركة فارغة — أدخل بضاعة أو كسراً أو مبلغاً');
    }
    if (cashReceivedFils < 0 || costOutFils < 0) {
      throw ArgumentError('المبالغ لا تكون سالبة');
    }

    final drafts = <PostingDraft>[];

    for (final l in goods) {
      if (l.grossWeightMg <= 0)
        throw ArgumentError('الوزن يجب أن يكون أكبر من صفر');
      drafts
        ..add(PostingDraft.gold(
          accountId: bagAccountId,
          grossWeightMg: l.grossWeightMg,
          karatId: l.karatId,
          karatPpm: l.karatPpm,
          debit: false, // تخرج من الشنطة
          itemId: l.itemId,
          quantity: l.quantity,
        ))
        ..add(PostingDraft.gold(
          accountId: shopId,
          grossWeightMg: l.grossWeightMg,
          karatId: l.karatId,
          karatPpm: l.karatPpm,
          debit: true, // عليه ذهب
          itemId: l.itemId,
          quantity: l.quantity,
        ));
      if (l.makingFils != 0) {
        drafts
          ..add(PostingDraft.cash(
            accountId: shopId,
            amountFils: l.makingFils,
            debit: true, // عليه مصنوعية
            makingPerGramFils: l.makingPerGramFils,
            note: 'مصنوعية',
          ))
          ..add(PostingDraft.cash(
            accountId: makingIncomeId,
            amountFils: l.makingFils,
            debit: false,
            makingPerGramFils: l.makingPerGramFils,
            note: 'مصنوعية',
          ));
      }
    }

    if (costOutFils > 0) {
      drafts
        ..add(PostingDraft.cash(
          accountId: makingIncomeId,
          amountFils: costOutFils,
          debit: true, // تكلفة المصنوعية المباعة
          note: 'تكلفة مصنوعية البضاعة المباعة',
        ))
        ..add(PostingDraft.cash(
          accountId: bagAccountId,
          amountFils: costOutFils,
          debit: false, // يخرج من رأس مال الشنطة
          note: 'تكلفة مصنوعية البضاعة المباعة',
        ));
    }

    for (final l in scrap) {
      if (l.grossWeightMg <= 0)
        throw ArgumentError('الوزن يجب أن يكون أكبر من صفر');
      drafts
        ..add(PostingDraft.gold(
          accountId: bagAccountId,
          grossWeightMg: l.grossWeightMg,
          karatId: l.karatId,
          karatPpm: l.karatPpm,
          debit: true, // الكسر يدخل الشنطة
          note: 'كسر',
        ))
        ..add(PostingDraft.gold(
          accountId: shopId,
          grossWeightMg: l.grossWeightMg,
          karatId: l.karatId,
          karatPpm: l.karatPpm,
          debit: false, // ينقص ما عليه من ذهب
          note: 'كسر',
        ));
    }

    if (cashReceivedFils > 0) {
      drafts
        ..add(PostingDraft.cash(
            accountId: cashboxId, amountFils: cashReceivedFils, debit: true))
        ..add(PostingDraft.cash(
            accountId: shopId, amountFils: cashReceivedFils, debit: false));
    }

    return _checked(drafts);
  }

  /// مرتجع جزئي لبضاعة من فاتورة سابقة — بنفس معامل البند ومصنوعيته.
  ///
  /// [fromShop] صحيح: المحل يعيد قطعاً إلى الشنطة — ينقص ما عليه ذهباً
  /// ومصنوعيةً، ويعود إلى رأس مال الشنطة [costBackFils] (حصة القطع
  /// المرتجعة من تكلفة المصنوعية التي خرجت عند البيع).
  /// خطأ: نعيد بضاعة للمشغل — تخرج من الشنطة، وينقص ما له علينا ذهباً
  /// ومصنوعيةً، وتخرج مصنوعيتها من رأس مال الشنطة.
  List<PostingDraft> goodsReturn({
    required String partyId,
    required String bagAccountId,
    required String makingIncomeId,
    required List<GoodsLine> lines,
    required bool fromShop,
    MoneyFils costBackFils = 0,
  }) {
    if (lines.isEmpty) throw ArgumentError('اختر بنداً واحداً على الأقل');
    if (costBackFils < 0) throw ArgumentError('المبالغ لا تكون سالبة');

    final drafts = <PostingDraft>[];
    for (final l in lines) {
      if (l.grossWeightMg <= 0) {
        throw ArgumentError('الوزن يجب أن يكون أكبر من صفر');
      }
      drafts
        ..add(PostingDraft.gold(
          accountId: bagAccountId,
          grossWeightMg: l.grossWeightMg,
          karatId: l.karatId,
          karatPpm: l.karatPpm,
          debit: fromShop, // من المحل يدخل الشنطة، وللمشغل يخرج منها
          itemId: l.itemId,
          quantity: l.quantity,
          note: 'مرتجع',
        ))
        ..add(PostingDraft.gold(
          accountId: partyId,
          grossWeightMg: l.grossWeightMg,
          karatId: l.karatId,
          karatPpm: l.karatPpm,
          debit: !fromShop,
          itemId: l.itemId,
          quantity: l.quantity,
          note: 'مرتجع',
        ));
      if (l.makingFils != 0) {
        // المحل: ينقص ما عليه مصنوعيةً ويُعكس الإيراد.
        // المشغل: ينقص ما له علينا وتخرج المصنوعية من رأس مال الشنطة.
        drafts
          ..add(PostingDraft.cash(
            accountId: partyId,
            amountFils: l.makingFils,
            debit: !fromShop,
            makingPerGramFils: l.makingPerGramFils,
            note: 'مصنوعية مرتجع',
          ))
          ..add(PostingDraft.cash(
            accountId: fromShop ? makingIncomeId : bagAccountId,
            amountFils: l.makingFils,
            debit: fromShop,
            makingPerGramFils: l.makingPerGramFils,
            note: 'مصنوعية مرتجع',
          ));
      }
    }

    if (fromShop && costBackFils > 0) {
      drafts
        ..add(PostingDraft.cash(
          accountId: bagAccountId,
          amountFils: costBackFils,
          debit: true, // تعود تكلفة القطع إلى رأس مال الشنطة
          note: 'تكلفة مصنوعية المرتجع',
        ))
        ..add(PostingDraft.cash(
          accountId: makingIncomeId,
          amountFils: costBackFils,
          debit: false,
          note: 'تكلفة مصنوعية المرتجع',
        ));
    }
    return _checked(drafts);
  }

  /// تسليم كسر للطرف من الشنطة ([toParty] = true)، أو استلامه منه إليها.
  ///
  /// الكسر بمعامل الكسر (0.870 لعيار 21) ولا صنف له. تسليمه يُنقص ما
  /// علينا من ذهب للطرف، واستلامه يُنقص ما عليه لنا.
  List<PostingDraft> scrapMove({
    required String partyId,
    required String bagAccountId,
    required List<GoodsLine> lines,
    required bool toParty,
  }) {
    if (lines.isEmpty) throw ArgumentError('أدخل وزن الكسر');
    final drafts = <PostingDraft>[];
    for (final l in lines) {
      if (l.grossWeightMg <= 0)
        throw ArgumentError('الوزن يجب أن يكون أكبر من صفر');
      drafts
        ..add(PostingDraft.gold(
          accountId: bagAccountId,
          grossWeightMg: l.grossWeightMg,
          karatId: l.karatId,
          karatPpm: l.karatPpm,
          debit: !toParty, // يخرج من الشنطة عند التسليم، ويدخلها عند الاستلام
          note: 'كسر',
        ))
        ..add(PostingDraft.gold(
          accountId: partyId,
          grossWeightMg: l.grossWeightMg,
          karatId: l.karatId,
          karatPpm: l.karatPpm,
          debit: toParty,
          note: 'كسر',
        ));
    }
    return _checked(drafts);
  }

  /// دفعة نقدية من الطرف الآخر.
  List<PostingDraft> receiveCash({
    required String counterpartyId,
    required String cashboxId,
    required MoneyFils amountFils,
  }) =>
      _checked([
        PostingDraft.cash(
            accountId: cashboxId, amountFils: amountFils, debit: true),
        PostingDraft.cash(
            accountId: counterpartyId, amountFils: amountFils, debit: false),
      ]);

  /// دفعة نقدية صادرة — نحن ندفع للطرف الآخر.
  ///
  /// المورّد والمصنع نحن المدينون لهما غالباً، فالنقد يخرج لا يدخل.
  List<PostingDraft> payCash({
    required String counterpartyId,
    required String cashboxId,
    required MoneyFils amountFils,
  }) =>
      _checked([
        PostingDraft.cash(
            accountId: cashboxId, amountFils: amountFils, debit: false),
        PostingDraft.cash(
            accountId: counterpartyId, amountFils: amountFils, debit: true),
      ]);

  /// التسكير — تثبيت سعر لذهب في الذمة.
  ///
  /// لا يُسدَّد شيء: الدين يتحوّل من غرامات إلى دنانير بالسعر المتفق.
  /// بعده يتوقف الدين عن التأثر بحركة سعر الذهب، وهذا كل الغرض منه.
  ///
  /// [netWeightMg] وزن صافي موجب. [owedToUs] يحدّد أي الطرفين المدين:
  /// صحيح = عليه لنا ذهب، خطأ = علينا له.
  List<PostingDraft> price({
    required String counterpartyId,
    required String tradingIncomeId,
    required WeightMg netWeightMg,
    required MoneyFils pricePerGramFils,
    required bool owedToUs,
  }) {
    if (netWeightMg <= 0) {
      throw ArgumentError('وزن التسكير يجب أن يكون أكبر من صفر');
    }
    if (pricePerGramFils <= 0) {
      throw ArgumentError('سعر التسكير يجب أن يكون أكبر من صفر');
    }

    final sign = owedToUs ? 1 : -1;
    final value = weightValue(netWeightMg, pricePerGramFils);

    return _checked([
      // دين الذهب ينزل
      PostingDraft(
        accountId: counterpartyId,
        ledger: LedgerKind.gold,
        amount: -sign * netWeightMg,
      ),
      PostingDraft(
        accountId: tradingIncomeId,
        ledger: LedgerKind.gold,
        amount: sign * netWeightMg,
      ),
      // ويقوم مكانه دين نقدي بالقيمة المتفقة
      PostingDraft(
        accountId: counterpartyId,
        ledger: LedgerKind.cash,
        amount: sign * value,
      ),
      PostingDraft(
        accountId: tradingIncomeId,
        ledger: LedgerKind.cash,
        amount: -sign * value,
      ),
    ]);
  }

  List<PostingDraft> _checked(List<PostingDraft> drafts) {
    for (final ledger in LedgerKind.values) {
      final sum = drafts
          .where((p) => p.ledger == ledger)
          .fold<int>(0, (a, p) => a + p.amount);
      if (sum != 0) throw UnbalancedEntryException(ledger, sum);
    }
    return drafts;
  }
}
