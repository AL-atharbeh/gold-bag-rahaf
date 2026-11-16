import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/phone.dart';
import 'platform_models.dart';

/// الدخول والمنشآت والفريق والشنط ولوحة الإدارة.
///
/// كل عملية حساسة دالة في Postgres (security definer) تفحص الصلاحية
/// بنفسها — التطبيق لا يقرر شيئاً، يعرض فقط.
class PlatformRepository {
  PlatformRepository(this._client);

  final SupabaseClient _client;

  GoTrueClient get auth => _client.auth;
  Session? get session => _client.auth.currentSession;

  Future<Map<String, dynamic>> _rpcMap(String fn,
      [Map<String, dynamic>? params]) async {
    final r = await _client.rpc(fn, params: params);
    return Map<String, dynamic>.from(r as Map);
  }

  Future<List<Map<String, dynamic>>> _rpcList(String fn,
      [Map<String, dynamic>? params]) async {
    final r = await _client.rpc(fn, params: params);
    return [
      for (final e in (r as List?) ?? const [])
        Map<String, dynamic>.from(e as Map)
    ];
  }

  // ---------------------------------------------------------------------------
  // الدخول برقم الهاتف
  // ---------------------------------------------------------------------------

  /// دخول نسخة الشنطة: رقم وكلمة مرور لحساب أنشأناه مسبقاً.
  /// لا يُنشئ حساباً أبداً — الرقم غير الموجود يفشل كأي كلمة مرور خاطئة.
  ///
  /// يدخل بالبريد الداخلي المشتق من الرقم (0017) لا بالهاتف: دخول الهاتف
  /// في Supabase يتطلب مزوّد رسائل، والنسخة لا ترسل رسائل أبداً.
  Future<void> passwordSignIn(String phone, String password) =>
      _client.auth.signInWithPassword(
          email: phoneLoginEmail(phone), password: password);

  Future<void> signOut() => _client.auth.signOut();

  /// بيانات المنشأة النشطة كما تظهر في ترويسة الملفات.
  Future<OrgProfile> orgProfile(String tenantId) async =>
      OrgProfile.fromJson(await _client
          .from('tenants')
          .select('name, phone, city')
          .eq('id', tenantId)
          .single());

  Future<void> updateOrgProfile(
          {required String name, String? phone, String? city}) =>
      _client.rpc('update_org_profile',
          params: {'p_name': name, 'p_phone': phone, 'p_city': city});

  // ---------------------------------------------------------------------------
  // الجلسة والمنشأة
  // ---------------------------------------------------------------------------

  Future<UserContext> loadContext() async =>
      UserContext.fromJson(await _rpcMap('load_my_context'));

  Future<void> switchTenant(String tenantId) =>
      _client.rpc('switch_tenant', params: {'p_tenant': tenantId});

  // ---------------------------------------------------------------------------
  // الفريق
  // ---------------------------------------------------------------------------

  Future<Team> team() async => Team.fromJson(await _rpcMap('list_team'));

  /// يُرجع 'member' إن انضم فوراً، أو 'invitation' إن كان لم يسجّل بعد.
  Future<String> inviteMember({
    required String phone,
    required MemberRole role,
    required Set<Perm> permissions,
    required String displayName,
  }) async {
    final r = await _rpcMap('invite_member', {
      'p_phone': phone,
      'p_role': role.wire,
      'p_permissions': [for (final p in permissions) p.wire],
      'p_display_name': displayName,
    });
    return r['kind'] as String? ?? 'member';
  }

  Future<void> updateMember({
    required String membershipId,
    required MemberRole role,
    required Set<Perm> permissions,
    required String displayName,
    required bool isActive,
  }) =>
      _client.rpc('update_member', params: {
        'p_membership_id': membershipId,
        'p_role': role.wire,
        'p_permissions': [for (final p in permissions) p.wire],
        'p_display_name': displayName,
        'p_is_active': isActive,
      });

  Future<void> cancelInvitation(String id) =>
      _client.rpc('cancel_invitation', params: {'p_invitation_id': id});

  // ---------------------------------------------------------------------------
  // الشنط
  // ---------------------------------------------------------------------------

  Future<List<Bag>> bags() async =>
      [for (final b in await _rpcList('list_bags')) Bag.fromJson(b)];

  Future<void> createBag(String name, {String? holderUserId}) =>
      _client.rpc('create_bag', params: {
        'p_name': name,
        'p_holder_user_id': holderUserId,
      });

  Future<void> updateBag({
    required String bagId,
    required String name,
    required String? holderUserId,
    required bool isActive,
  }) =>
      _client.rpc('update_bag', params: {
        'p_bag_id': bagId,
        'p_name': name,
        'p_holder_user_id': holderUserId,
        'p_is_active': isActive,
      });

  // ---------------------------------------------------------------------------
  // الباقات
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // لوحة الإدارة
  // ---------------------------------------------------------------------------

}
