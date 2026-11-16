/// نماذج المنصّة: المنشآت، العضويات، الصلاحيات، الشنط، الباقات.
///
/// قيم wire تطابق أنواع Postgres في 0008_platform.sql حرفياً.
library;

enum OrgType {
  distributor('distributor'),
  factory('factory'),
  shop('shop');

  const OrgType(this.wire);
  final String wire;

  static OrgType fromWire(String? w) =>
      OrgType.values.firstWhere((e) => e.wire == w, orElse: () => distributor);
}

enum OrgStatus {
  pending('pending'),
  active('active'),
  suspended('suspended'),
  rejected('rejected');

  const OrgStatus(this.wire);
  final String wire;

  static OrgStatus fromWire(String? w) =>
      OrgStatus.values.firstWhere((e) => e.wire == w, orElse: () => pending);
}

enum MemberRole {
  owner('owner'),
  manager('manager'),
  bagHolder('bag_holder'),
  assistant('assistant');

  const MemberRole(this.wire);
  final String wire;

  static MemberRole fromWire(String? w) =>
      MemberRole.values.firstWhere((e) => e.wire == w, orElse: () => assistant);

  /// الأدوار التي يستطيع المالك منحها — المالك واحد لا يُضاف.
  static const assignable = [manager, bagHolder, assistant];
}

/// مفاتيح الصلاحيات — المالك يملكها كلها ضمناً.
/// إدارة الفريق والشنط للمالك وحده ولا تُمنح لغيره.
enum Perm {
  ledgerWrite('ledger.write'),
  financeView('finance.view'),
  bagsViewAll('bags.view_all'),
  bagsIssue('bags.issue'),
  bagsConfirm('bags.confirm'),
  stockCount('stock.count'),
  chequesManage('cheques.manage');

  const Perm(this.wire);
  final String wire;

  static Perm? fromWire(String w) {
    for (final p in Perm.values) {
      if (p.wire == w) return p;
    }
    return null;
  }

  /// تطابق default_permissions في SQL.
  static Set<Perm> defaultsFor(MemberRole role) => switch (role) {
        MemberRole.owner => Perm.values.toSet(),
        MemberRole.manager => Perm.values.toSet(),
        MemberRole.bagHolder || MemberRole.assistant => {Perm.ledgerWrite},
      };

  /// الصلاحيات ذات المعنى لكل نوع منشأة — لا داعي لعرض الشنط على محل.
  static List<Perm> relevantFor(OrgType type) => switch (type) {
        OrgType.shop => [ledgerWrite, financeView, chequesManage],
        OrgType.distributor || OrgType.factory => Perm.values,
      };
}

Set<Perm> _perms(Object? raw) => {
      for (final w in (raw as List?) ?? const [])
        if (Perm.fromWire(w.toString()) case final p?) p,
    };

DateTime? _date(Object? raw) =>
    raw == null ? null : DateTime.tryParse(raw.toString())?.toLocal();

/// عضوية الشخص في منشأة واحدة.
class Membership {
  const Membership({
    required this.membershipId,
    required this.tenantId,
    required this.orgName,
    required this.orgType,
    required this.status,
    required this.role,
    required this.permissions,
    this.statusNote,
    this.displayName = '',
    this.maxUsers,
    this.maxBags,
  });

  factory Membership.fromJson(Map<String, dynamic> j) => Membership(
        membershipId: j['membership_id'] as String,
        tenantId: j['tenant_id'] as String,
        orgName: j['org_name'] as String? ?? '',
        orgType: OrgType.fromWire(j['org_type'] as String?),
        status: OrgStatus.fromWire(j['status'] as String?),
        statusNote: j['status_note'] as String?,
        role: MemberRole.fromWire(j['role'] as String?),
        permissions: _perms(j['permissions']),
        displayName: j['display_name'] as String? ?? '',
        maxUsers: (j['max_users'] as num?)?.toInt(),
        maxBags: (j['max_bags'] as num?)?.toInt(),
      );

  final String membershipId;
  final String tenantId;
  final String orgName;
  final OrgType orgType;
  final OrgStatus status;
  final String? statusNote;
  final MemberRole role;
  final Set<Perm> permissions;
  final String displayName;
  final int? maxUsers;
  final int? maxBags;

  bool get isOwner => role == MemberRole.owner;
  bool get isActive => status == OrgStatus.active;

  bool can(Perm p) => isOwner || permissions.contains(p);

  /// الكتابة مسموحة؟ نسخة الشنطة بترخيص دائم: يكفي أن تكون المنشأة مفعّلة.
  bool get writable => isActive;
}

/// كل ما يعرفه التطبيق عن المستخدم بعد الدخول.
class UserContext {
  const UserContext({
    required this.userId,
    required this.phone,
    required this.fullName,
    required this.isPlatformAdmin,
    required this.memberships,
    this.activeTenantId,
  });

  factory UserContext.fromJson(Map<String, dynamic> j) => UserContext(
        userId: j['user_id'] as String,
        phone: j['phone'] as String? ?? '',
        fullName: j['full_name'] as String? ?? '',
        isPlatformAdmin: j['is_platform_admin'] as bool? ?? false,
        activeTenantId: j['active_tenant_id'] as String?,
        memberships: [
          for (final m in (j['memberships'] as List?) ?? const [])
            Membership.fromJson(Map<String, dynamic>.from(m as Map)),
        ],
      );

  final String userId;
  final String phone;
  final String fullName;
  final bool isPlatformAdmin;
  final String? activeTenantId;
  final List<Membership> memberships;

  Membership? get active {
    for (final m in memberships) {
      if (m.tenantId == activeTenantId) return m;
    }
    return memberships.isEmpty ? null : memberships.first;
  }
}

class TeamMember {
  const TeamMember({
    required this.membershipId,
    required this.userId,
    required this.role,
    required this.permissions,
    required this.displayName,
    required this.isActive,
    this.phone,
  });

  factory TeamMember.fromJson(Map<String, dynamic> j) => TeamMember(
        membershipId: j['membership_id'] as String,
        userId: j['user_id'] as String,
        role: MemberRole.fromWire(j['role'] as String?),
        permissions: _perms(j['permissions']),
        displayName: j['display_name'] as String? ?? '',
        isActive: j['is_active'] as bool? ?? true,
        phone: j['phone'] as String?,
      );

  final String membershipId;
  final String userId;
  final MemberRole role;
  final Set<Perm> permissions;
  final String displayName;
  final bool isActive;
  final String? phone;
}

class Invitation {
  const Invitation({
    required this.id,
    required this.phone,
    required this.role,
    required this.displayName,
    this.permissions = const {},
    this.createdAt,
  });

  factory Invitation.fromJson(Map<String, dynamic> j) => Invitation(
        id: j['id'] as String,
        phone: j['phone'] as String? ?? '',
        role: MemberRole.fromWire(j['role'] as String?),
        permissions: _perms(j['permissions']),
        displayName: j['display_name'] as String? ?? '',
        createdAt: _date(j['created_at']),
      );

  final String id;
  final String phone;
  final MemberRole role;
  final Set<Perm> permissions;
  final String displayName;
  final DateTime? createdAt;
}

class Team {
  const Team({required this.members, required this.invitations});

  factory Team.fromJson(Map<String, dynamic> j) => Team(
        members: [
          for (final m in (j['members'] as List?) ?? const [])
            TeamMember.fromJson(Map<String, dynamic>.from(m as Map)),
        ],
        invitations: [
          for (final i in (j['invitations'] as List?) ?? const [])
            Invitation.fromJson(Map<String, dynamic>.from(i as Map)),
        ],
      );

  final List<TeamMember> members;
  final List<Invitation> invitations;

  int get seatsUsed =>
      members.where((m) => m.isActive).length + invitations.length;
}

class Bag {
  const Bag({
    required this.id,
    required this.name,
    required this.accountId,
    required this.isActive,
    this.holderUserId,
    this.holderName,
  });

  factory Bag.fromJson(Map<String, dynamic> j) => Bag(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        accountId: j['account_id'] as String,
        isActive: j['is_active'] as bool? ?? true,
        holderUserId: j['holder_user_id'] as String?,
        holderName: j['holder_name'] as String?,
      );

  final String id;
  final String name;
  final String accountId;
  final bool isActive;
  final String? holderUserId;
  final String? holderName;
}

/// بيانات المنشأة في ترويسة الكشوفات والفواتير.
class OrgProfile {
  const OrgProfile({required this.name, this.phone, this.city});

  factory OrgProfile.fromJson(Map<String, dynamic> j) => OrgProfile(
        name: j['name'] as String? ?? '',
        phone: j['phone'] as String?,
        city: j['city'] as String?,
      );

  final String name;
  final String? phone;
  final String? city;
}
