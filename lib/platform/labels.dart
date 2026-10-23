import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../l10n/app_localizations.dart';
import 'platform_models.dart';

/// أسماء الأنواع بلغة الواجهة الحالية.
extension OrgTypeL10n on OrgType {
  String label(AppLocalizations l) => switch (this) {
        OrgType.distributor => l.orgTypeDistributor,
        OrgType.factory => l.orgTypeFactory,
        OrgType.shop => l.orgTypeShop,
      };

  String description(AppLocalizations l) => switch (this) {
        OrgType.distributor => l.orgTypeDistributorDesc,
        OrgType.factory => l.orgTypeFactoryDesc,
        OrgType.shop => l.orgTypeShopDesc,
      };

  IconData get icon => switch (this) {
        OrgType.distributor => Icons.work_outline_rounded,
        OrgType.factory => Icons.precision_manufacturing_outlined,
        OrgType.shop => Icons.storefront_outlined,
      };
}

extension OrgStatusL10n on OrgStatus {
  String label(AppLocalizations l) => switch (this) {
        OrgStatus.pending => l.statusPending,
        OrgStatus.active => l.statusActive,
        OrgStatus.suspended => l.statusSuspended,
        OrgStatus.rejected => l.statusRejected,
      };

  (Color fg, Color bg) get colors => switch (this) {
        OrgStatus.pending => (AppColors.goldDark, AppColors.goldContainer),
        OrgStatus.active => (AppColors.success, AppColors.successContainer),
        OrgStatus.suspended || OrgStatus.rejected => (
            AppColors.error,
            AppColors.errorContainer
          ),
      };
}

extension MemberRoleL10n on MemberRole {
  String label(AppLocalizations l) => switch (this) {
        MemberRole.owner => l.roleOwner,
        MemberRole.manager => l.roleManager,
        MemberRole.bagHolder => l.roleBagHolder,
        MemberRole.assistant => l.roleAssistant,
      };

  String description(AppLocalizations l) => switch (this) {
        MemberRole.owner => l.ownerHasAll,
        MemberRole.manager => l.roleManagerDesc,
        MemberRole.bagHolder => l.roleBagHolderDesc,
        MemberRole.assistant => l.roleAssistantDesc,
      };
}

extension PermL10n on Perm {
  String label(AppLocalizations l) => switch (this) {
        Perm.ledgerWrite => l.permLedgerWrite,
        Perm.financeView => l.permFinanceView,
        Perm.bagsViewAll => l.permBagsViewAll,
        Perm.bagsIssue => l.permBagsIssue,
        Perm.bagsConfirm => l.permBagsConfirm,
        Perm.stockCount => l.permStockCount,
        Perm.chequesManage => l.permChequesManage,
      };
}

/// محافظات الأردن — تُحفظ بالعربية وتُعرض بلغة الواجهة.
const jordanGovernorates = <(String ar, String en)>[
  ('عمّان', 'Amman'),
  ('إربد', 'Irbid'),
  ('الزرقاء', 'Zarqa'),
  ('البلقاء', 'Balqa'),
  ('مادبا', 'Madaba'),
  ('جرش', 'Jerash'),
  ('عجلون', 'Ajloun'),
  ('المفرق', 'Mafraq'),
  ('الكرك', 'Karak'),
  ('الطفيلة', 'Tafilah'),
  ('معان', "Ma'an"),
  ('العقبة', 'Aqaba'),
];

String governorateLabel(String? stored, bool arabic) {
  if (stored == null) return '';
  for (final (ar, en) in jordanGovernorates) {
    if (ar == stored) return arabic ? ar : en;
  }
  return stored;
}

String formatDate(DateTime? d) => d == null
    ? '—'
    : '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
