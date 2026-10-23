import 'package:flutter_test/flutter_test.dart';
import 'package:gold_bashar/core/phone.dart';
import 'package:gold_bashar/features/shell/tab_specs.dart';
import 'package:gold_bashar/platform/platform_models.dart';

Membership _m(OrgType type, MemberRole role, {Set<Perm>? perms, DateTime? endsAt}) => Membership(
      membershipId: 'm',
      tenantId: 't',
      orgName: 'org',
      orgType: type,
      status: OrgStatus.active,
      role: role,
      permissions: perms ?? Perm.defaultsFor(role),
      subscriptionEndsAt: endsAt,
    );

List<String> _tabs(Membership m) => [for (final t in tabsFor(m)) t.id];

void main() {
  group('رقم الهاتف', () {
    test('يقبل الصيغ الشائعة ويوحّدها', () {
      for (final input in [
        '0791234567',
        '791234567',
        '+962791234567',
        '00962791234567',
        '+962 79 123 4567',
        '٠٧٩١٢٣٤٥٦٧',
      ]) {
        expect(normalizeJordanMobile(input), '+962791234567', reason: input);
      }
    });

    test('يرفض غير جوالات الأردن', () {
      expect(normalizeJordanMobile('0761234567'), isNull); // ليس 77/78/79
      expect(normalizeJordanMobile('079123456'), isNull); // ناقص رقم
      expect(normalizeJordanMobile('065123456'), isNull); // أرضي
      expect(normalizeJordanMobile(''), isNull);
    });

    test('العرض يعيد الصفر في البداية', () {
      expect(displayPhone('962791234567'), '0791234567');
      expect(displayPhone('+962791234567'), '0791234567');
    });
  });

  group('الصلاحيات', () {
    test('المالك يملك كل شيء ولو كانت قائمته فارغة', () {
      final m = _m(OrgType.factory, MemberRole.owner, perms: {});
      expect(Perm.values.every(m.can), isTrue);
    });

    test('حامل الشنطة يسجّل فقط افتراضياً', () {
      final m = _m(OrgType.factory, MemberRole.bagHolder);
      expect(m.can(Perm.ledgerWrite), isTrue);
      expect(m.can(Perm.bagsViewAll), isFalse);
      expect(m.can(Perm.financeView), isFalse);
    });

    test('الاشتراك المنتهي يجعل الحساب للقراءة فقط', () {
      final expired = _m(OrgType.distributor, MemberRole.owner,
          endsAt: DateTime.now().subtract(const Duration(days: 1)));
      final soon = _m(OrgType.distributor, MemberRole.owner,
          endsAt: DateTime.now().add(const Duration(days: 5)));
      expect(expired.writable, isFalse);
      expect(expired.isExpired, isTrue);
      expect(soon.writable, isTrue);
      expect(soon.isExpiringSoon, isTrue);
    });
  });

  group('تقسيم الواجهات — نسخة تاجر الشنطة', () {
    test('المالك يرى الرئيسية والشنطة والمحلات والتجار والإعدادات', () {
      expect(_tabs(_m(OrgType.distributor, MemberRole.owner)),
          ['home', 'bag', 'shops', 'traders', 'settings']);
    });

    test('المساعد يرى نفس التبويبات — الدفاتر المالية تُخفى داخل الإعدادات', () {
      expect(_tabs(_m(OrgType.distributor, MemberRole.assistant)),
          ['home', 'bag', 'shops', 'traders', 'settings']);
    });

    test('الإعدادات آخر تبويب دائماً — منها الخروج', () {
      for (final role in MemberRole.values) {
        expect(_tabs(_m(OrgType.distributor, role)).last, 'settings',
            reason: '$role');
      }
    });
  });
}
