import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import 'bag_day_state.dart';
import 'day_pages.dart';

/// قبل الدخول لعمل اليوم: يُغلق اليوم السابق إن بقي مفتوحاً، ثم يُفتح
/// اليوم بتأكيد الكاش المحمول. غير حامل الشنطة يدخل مباشرة.
class DayGate extends ConsumerWidget {
  const DayGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(dayGateProvider);
    // إعادة التحميل (إضافة طرف تُحدّث الحسابات مثلاً) تُبقي الواجهة كما هي،
    // وإلا استُبدل الهيكل بمؤشر تحميل وضاع التبويب المفتوح.
    return gate.when(
      skipLoadingOnReload: true,
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.goldPrimary)),
      ),
      // جدول اليومية غير موجود بعد (لم يُنفَّذ 0014) أو انقطاع: لا نحجب العمل
      error: (_, __) => child,
      data: (s) => switch (s.$1) {
        DayGateState.ready => child,
        DayGateState.mustOpen => OpenDayPage(last: s.$2),
        DayGateState.mustCloseOld => CloseDayPage(day: s.$2!, mandatory: true),
      },
    );
  }
}
