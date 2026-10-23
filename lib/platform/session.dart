import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'platform_models.dart';
import 'platform_repository.dart';

final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

final platformRepoProvider = Provider<PlatformRepository>(
  (ref) => PlatformRepository(ref.watch(supabaseClientProvider)),
);

/// الجلسة: null = غير مسجّل الدخول.
///
/// تُعاد قراءتها عند تغيّر الشخص (دخول / خروج) فقط — تجديد التوكن كل
/// ساعة لا يعيد بناء الواجهة ولا يُضيع الشاشة المفتوحة.
class SessionController extends AsyncNotifier<UserContext?> {
  PlatformRepository get _repo => ref.read(platformRepoProvider);

  @override
  Future<UserContext?> build() async {
    final repo = ref.watch(platformRepoProvider);
    final uid = repo.session?.user.id;

    final sub = repo.auth.onAuthStateChange.listen((s) {
      if (s.session?.user.id != uid) ref.invalidateSelf();
    });
    ref.onDispose(sub.cancel);

    if (uid == null) return null;
    return repo.loadContext();
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> switchTenant(String tenantId) async {
    await _repo.switchTenant(tenantId);
    await reload();
  }

  Future<void> signOut() => _repo.signOut();
}

final sessionProvider = AsyncNotifierProvider<SessionController, UserContext?>(
    SessionController.new);

/// العضوية النشطة — مصدر الحقيقة لكل ما يظهر في الواجهة.
final activeMembershipProvider = Provider<Membership?>(
  (ref) => ref.watch(sessionProvider).valueOrNull?.active,
);

/// معرّف المنشأة النشطة المفعّلة فقط. select يجعل التبعيات لا تُعاد
/// إلا إن تغيّرت المنشأة فعلاً، لا عند كل تحديث للجلسة.
final activeTenantIdProvider = Provider<String?>((ref) => ref.watch(
      sessionProvider.select((s) {
        final m = s.valueOrNull?.active;
        return m != null && m.isActive ? m.tenantId : null;
      }),
    ));

/// بيانات المنشأة النشطة — للترويسة وشاشة الإعدادات.
final orgProfileProvider = FutureProvider<OrgProfile?>((ref) async {
  final tenant = ref.watch(activeTenantIdProvider);
  if (tenant == null) return null;
  return ref.watch(platformRepoProvider).orgProfile(tenant);
});
