import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/config.dart';
import '../../core/locale.dart';
import '../../core/phone.dart';
import '../../platform/labels.dart';
import '../../platform/platform_models.dart';
import '../../platform/session.dart';
import '../cheques/cheques_page.dart';
import '../common/inputs.dart';
import '../common/ui.dart';
import '../employees/employees_page.dart';
import '../opening/opening_balances_page.dart';
import '../reports/reports_page.dart';
import '../team/member_editor.dart';
import '../team/team_page.dart';

/// إعدادات نسخة تاجر الشنطة: الحساب، بيانات الترويسة، الدفاتر،
/// الحسابات الثلاثة، اللغة، والخروج. بلا اشتراك ولا شنط متعددة ولا تسجيل.
class BagSettingsPage extends ConsumerWidget {
  const BagSettingsPage({super.key, this.title});

  final String? title;

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l.signOut,
      body: l.signOutConfirm,
      confirmLabel: l.signOut,
      destructive: true,
    );
    if (ok) await ref.read(sessionProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ctx = ref.watch(sessionProvider).valueOrNull;
    final m = ref.watch(activeMembershipProvider);
    if (ctx == null || m == null) return const SizedBox.shrink();
    final org = ref.watch(orgProfileProvider).valueOrNull;

    void push(Widget page) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(title ?? l.tabSettings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── حسابي ──
                  _ProfileCard(
                    business: org?.name ?? m.orgName,
                    name:
                        m.displayName.isNotEmpty ? m.displayName : ctx.fullName,
                    phone: ctx.phone,
                    role: m.role.label(l),
                  ),

                  // ── بيانات الكشوفات والفواتير ──
                  SectionTitle(l.letterheadTitle),
                  _LetterheadCard(
                      org: org, fallbackName: m.orgName, canEdit: m.isOwner),

                  // ── الدفاتر ──
                  SectionTitle(l.otherLedgers),
                  _Tile(
                    icon: Icons.summarize_outlined,
                    title: l.reports,
                    subtitle: l.reportsHint,
                    onTap: () => push(const ReportsPage()),
                  ),
                  _Tile(
                    icon: Icons.playlist_add_check_rounded,
                    title: l.openingBalances,
                    subtitle: l.openingBalancesHint,
                    onTap: () => push(const OpeningBalancesPage()),
                  ),
                  if (m.can(Perm.chequesManage))
                    _Tile(
                      icon: Icons.receipt_long_outlined,
                      title: l.tabCheques,
                      onTap: () => push(const ChequesPage()),
                    ),
                  if (m.can(Perm.financeView))
                    _Tile(
                      icon: Icons.badge_outlined,
                      title: l.tabEmployees,
                      onTap: () => push(const EmployeesPage()),
                    ),

                  // ── الحسابات ──
                  if (m.isOwner) ...[
                    SectionTitle(l.editionAccounts),
                    const _AccountsCard(),
                  ],

                  // ── التطبيق ──
                  SectionTitle(l.appSection),
                  _Tile(
                    icon: Icons.translate_rounded,
                    title: l.language,
                    subtitle: context.isArabic ? 'العربية' : 'English',
                    trailing: const LanguageButton(),
                  ),
                  _Tile(
                    icon: Icons.info_outline_rounded,
                    title: l.aboutEdition,
                    subtitle: AppConfig.supportPhone.isEmpty
                        ? l.editionVersion
                        : '${l.editionVersion} · ${l.support}: ${ltrIsolate(displayPhone(AppConfig.supportPhone))}',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => _signOut(context, ref),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: Text(l.signOut),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                          color: AppColors.error.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard(
      {required this.business,
      required this.name,
      required this.phone,
      required this.role});

  final String business;
  final String name;
  final String phone;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBF8F1), Color(0xFFFAF3E3)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.goldBorder, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.goldBorder),
            ),
            child: Image.asset('assets/images/logo_trimmed.png',
                fit: BoxFit.contain),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(business,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.goldDark)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(ltrIsolate(displayPhone(phone)),
                        style: const TextStyle(color: AppColors.textSecondary)),
                    Pill(role, fg: AppColors.textSecondary, bg: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// اسم المنشأة وهاتفها ومدينتها كما تظهر في رأس كل ملف PDF.
class _LetterheadCard extends ConsumerWidget {
  const _LetterheadCard(
      {required this.org, required this.fallbackName, required this.canEdit});

  final OrgProfile? org;
  final String fallbackName;
  final bool canEdit;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final l = context.l10n;
    final name = TextEditingController(text: org?.name ?? fallbackName);
    final phone = TextEditingController(text: org?.phone ?? '');
    final city = TextEditingController(text: org?.city ?? '');
    final form = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.letterheadTitle),
        content: SizedBox(
          width: 420,
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: name,
                  decoration: InputDecoration(labelText: l.businessName),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? l.requiredField : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: phoneInputFormatters,
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(labelText: l.businessPhone),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: city,
                  decoration: InputDecoration(labelText: l.businessCity),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel)),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(ctx, true);
            },
            child: Text(l.save),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(platformRepoProvider).updateOrgProfile(
            name: name.text.trim(),
            phone: phone.text.trim(),
            city: city.text.trim(),
          );
      ref.invalidate(orgProfileProvider);
      ref.invalidate(sessionProvider);
      messenger.showSnackBar(SnackBar(
          content: Text(l.saved), backgroundColor: AppColors.goldDark));
    } catch (e) {
      final missing = e.toString().contains('update_org_profile');
      messenger.showSnackBar(SnackBar(
        content: Text(missing ? l.needMigration13 : readableError(e)),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final name = (org?.name.isNotEmpty ?? false) ? org!.name : fallbackName;

    Widget row(IconData icon, String label, String? value,
            {bool ltr = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Icon(icon, size: 18, color: AppColors.goldDark),
            const SizedBox(width: 10),
            Text('$label: ',
                style: const TextStyle(color: AppColors.textSecondary)),
            Expanded(
              child: Text(
                (value == null || value.isEmpty)
                    ? '—'
                    : (ltr ? ltrIsolate(value) : value),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ]),
        );

    return GoldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row(Icons.storefront_outlined, l.businessName, name),
          row(Icons.phone_outlined, l.businessPhone,
              org?.phone == null ? null : displayPhone(org!.phone),
              ltr: true),
          row(Icons.location_on_outlined, l.businessCity, org?.city),
          const SizedBox(height: 6),
          Text(l.letterheadHint,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          if (canEdit) ...[
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton.icon(
                onPressed: () => _edit(context, ref),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(l.edit),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// الحسابات المسموح لها بالدخول (3 كحد أقصى) — للعرض وتعديل الصلاحيات.
/// الإضافة وتغيير كلمة المرور من الدعم فقط.
class _AccountsCard extends ConsumerWidget {
  const _AccountsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final team = ref.watch(teamProvider);
    final me = ref.watch(sessionProvider).valueOrNull?.userId;

    return GoldCard(
      child: AsyncBody<Team>(
        value: team,
        onRetry: () => ref.invalidate(teamProvider),
        data: (t) {
          final active = t.members.where((x) => x.isActive).length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(
                  child: Text(
                    l.accountsUsed(active, AppConfig.bagEditionMaxUsers),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                for (var i = 0; i < AppConfig.bagEditionMaxUsers; i++)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(start: 4),
                    child: Icon(
                      i < active
                          ? Icons.person_rounded
                          : Icons.person_outline_rounded,
                      size: 20,
                      color:
                          i < active ? AppColors.goldDark : AppColors.textMuted,
                    ),
                  ),
              ]),
              const SizedBox(height: 8),
              for (final x in t.members) ...[
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: x.isActive
                        ? AppColors.goldContainer
                        : AppColors.surfaceMuted,
                    child: Icon(Icons.person_rounded,
                        color: x.isActive
                            ? AppColors.goldDark
                            : AppColors.textMuted),
                  ),
                  title: Text(
                    x.displayName.isEmpty ? '—' : x.displayName,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        decoration:
                            x.isActive ? null : TextDecoration.lineThrough),
                  ),
                  subtitle: Text(
                      '${ltrIsolate(displayPhone(x.phone))} · ${x.role.label(l)}'),
                  trailing: x.userId == me || x.role == MemberRole.owner
                      ? null
                      : const Icon(Icons.tune_rounded,
                          color: AppColors.textMuted),
                  // صلاحيات الأعضاء الآخرين — المالك لا تُعدَّل صلاحياته
                  onTap: x.userId == me || x.role == MemberRole.owner
                      ? null
                      : () async {
                          final saved =
                              await showMemberEditor(context, member: x);
                          if (saved == true) ref.invalidate(teamProvider);
                        },
                ),
              ],
              const SizedBox(height: 6),
              Text(l.accountsBySupport,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(
      {required this.icon,
      required this.title,
      this.subtitle,
      this.onTap,
      this.trailing});

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GoldCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.goldDark),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
            trailing ??
                (onTap == null
                    ? const SizedBox.shrink()
                    : const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
