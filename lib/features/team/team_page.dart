import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/locale.dart';
import '../../core/phone.dart';
import '../../platform/labels.dart';
import '../../platform/platform_models.dart';
import '../../platform/session.dart';
import '../common/inputs.dart';
import '../common/ui.dart';
import 'member_editor.dart';

/// فريق المنشأة النشطة. يتبع المنشأة: التبديل يعيد التحميل.
final teamProvider = FutureProvider.autoDispose<Team>((ref) {
  ref.watch(activeTenantIdProvider);
  return ref.watch(platformRepoProvider).team();
});

/// الفريق — للمالك وحده: إضافة بالهاتف، أدوار، صلاحيات، إيقاف.
class TeamPage extends ConsumerWidget {
  const TeamPage({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref,
      {TeamMember? member}) async {
    final saved = await showMemberEditor(context, member: member);
    if (saved == true) ref.invalidate(teamProvider);
  }

  Future<void> _cancelInvite(
      BuildContext context, WidgetRef ref, Invitation i) async {
    final l = context.l10n;
    final ok = await confirmDialog(
      context,
      title: l.cancelInvitation,
      body: displayPhone(i.phone),
      confirmLabel: l.cancelInvitation,
      destructive: true,
    );
    if (!ok || !context.mounted || !ensureOnline(context, ref)) return;
    try {
      await ref.read(platformRepoProvider).cancelInvitation(i.id);
      ref.invalidate(teamProvider);
    } catch (e) {
      if (context.mounted) showResult(context, readableError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final m = ref.watch(activeMembershipProvider);
    final me = ref.watch(sessionProvider).valueOrNull?.userId;
    final team = ref.watch(teamProvider);

    if (m == null || !m.isOwner) {
      return Scaffold(
        appBar: AppBar(title: Text(l.team)),
        body: CenteredMessage(
            icon: Icons.lock_outline_rounded, title: l.ownerOnly),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l.team),
        actions: [
          IconButton(
            tooltip: l.retry,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(teamProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      // الحسابات تُضاف من الدعم فقط — لا دعوات من التطبيق
      body: AsyncBody<Team>(
        value: team,
        onRetry: () => ref.invalidate(teamProvider),
        data: (t) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
          children: [
            if (m.maxUsers != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _Usage(
                    used: t.seatsUsed,
                    max: m.maxUsers!,
                    label: l.seatsUsed(t.seatsUsed, m.maxUsers!)),
              ),
            for (final member in t.members) ...[
              _MemberTile(
                member: member,
                isMe: member.userId == me,
                onTap: member.role == MemberRole.owner || !m.writable
                    ? null
                    : () => _open(context, ref, member: member),
              ),
              const SizedBox(height: 10),
            ],
            if (t.invitations.isNotEmpty) ...[
              SectionTitle(l.pendingInvitations),
              for (final i in t.invitations) ...[
                GoldCard(
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AppColors.surfaceMuted,
                        child: Icon(Icons.schedule_rounded,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              i.displayName.isEmpty
                                  ? displayPhone(i.phone)
                                  : i.displayName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${displayPhone(i.phone)}  ·  ${i.role.label(l)}',
                              textDirection: TextDirection.ltr,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 2),
                            Text(l.invitationHint,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: l.cancelInvitation,
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.error),
                        onPressed: () => _cancelInvite(context, ref, i),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({required this.member, required this.isMe, this.onTap});

  final TeamMember member;
  final bool isMe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final name = member.displayName.isEmpty
        ? displayPhone(member.phone)
        : member.displayName;

    return GoldCard(
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: member.isActive
                ? AppColors.goldContainer
                : AppColors.surfaceMuted,
            child: Text(
              name.isEmpty ? '?' : name.characters.first,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color:
                    member.isActive ? AppColors.goldDark : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? '$name ${l.you}' : name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: member.isActive
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayPhone(member.phone),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 6,
            children: [
              if (!member.isActive)
                Pill(l.inactive,
                    fg: AppColors.error, bg: AppColors.errorContainer),
              Pill(member.role.label(l)),
            ],
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _Usage extends StatelessWidget {
  const _Usage({required this.used, required this.max, required this.label});

  final int used;
  final int max;
  final String label;

  @override
  Widget build(BuildContext context) {
    final full = used >= max;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: full ? AppColors.error : AppColors.textSecondary,
            )),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: max == 0 ? 1 : (used / max).clamp(0, 1).toDouble(),
            minHeight: 6,
            color: full ? AppColors.error : AppColors.goldPrimary,
            backgroundColor: AppColors.surfaceMuted,
          ),
        ),
      ],
    );
  }
}
