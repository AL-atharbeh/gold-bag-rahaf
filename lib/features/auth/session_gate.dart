import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/locale.dart';
import '../../platform/session.dart';
import '../common/inputs.dart';
import '../common/ui.dart';
import '../shell/app_shell.dart';
import '../bagday/day_gate.dart';
import 'password_login_page.dart';
import 'pending_page.dart';

/// يقرر الشاشة الأولى — نسخة تاجر الشنطة:
///
///   غير مسجّل             → الدخول برقم الهاتف وكلمة المرور
///   بلا عضوية فعّالة      → رسالة "الحساب غير مفعّل" (الحسابات من الدعم فقط)
///   منشأته غير مفعّلة      → انتظار التفعيل / موقوف
///   حامل الشنطة           → فتح اليوم أولاً، ثم الواجهة
class SessionGate extends ConsumerWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);

    return session.when(
      loading: () => const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
            child: CircularProgressIndicator(color: AppColors.goldPrimary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: Colors.white,
        body: CenteredMessage(
          icon: Icons.cloud_off_rounded,
          title: readableError(e),
          action: Wrap(
            spacing: 10,
            children: [
              FilledButton(
                onPressed: () => ref.invalidate(sessionProvider),
                child: Text(context.l10n.retry),
              ),
              OutlinedButton(
                onPressed: () => ref.read(sessionProvider.notifier).signOut(),
                child: Text(context.l10n.signOut),
              ),
            ],
          ),
        ),
      ),
      data: (ctx) {
        if (ctx == null) return const PasswordLoginPage();
        final active = ctx.active;
        if (active == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: CenteredMessage(
              icon: Icons.lock_outline_rounded,
              title: context.l10n.accountNotEnabled,
              body: context.l10n.accountNotEnabledHint,
              action: OutlinedButton(
                onPressed: () =>
                    ref.read(sessionProvider.notifier).signOut(),
                child: Text(context.l10n.signOut),
              ),
            ),
          );
        }
        if (!active.isActive) return PendingPage(membership: active);
        // يومية الشنطة: فتح اليوم وإغلاقه إلزاميان لحاملها. المفتاح يعيد
        // بناء الهيكل كاملاً إن تغيّرت المنشأة.
        return DayGate(child: AppShell(key: ValueKey(active.tenantId)));
      },
    );
  }
}
