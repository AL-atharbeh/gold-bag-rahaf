import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/config.dart';
import '../../core/locale.dart';
import '../../platform/platform_models.dart';
import '../../platform/session.dart';
import '../common/ui.dart';
import '../shell/account_switcher.dart';

/// المنشأة النشطة غير مفعّلة: قيد المراجعة، أو مرفوضة، أو موقوفة.
class PendingPage extends ConsumerWidget {
  const PendingPage({super.key, required this.membership});

  final Membership membership;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final ctx = ref.watch(sessionProvider).valueOrNull;
    final m = membership;

    final (IconData icon, String title, String body) = switch (m.status) {
      OrgStatus.pending => (
          Icons.hourglass_top_rounded,
          l.statusPendingTitle,
          l.statusPendingBody(m.orgName)
        ),
      OrgStatus.rejected => (
          Icons.block_rounded,
          l.statusRejectedTitle,
          m.orgName
        ),
      _ => (
          Icons.pause_circle_outline_rounded,
          l.statusSuspendedTitle,
          l.statusSuspendedBody(m.orgName)
        ),
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l.appTitle),
        actions: [
          const LanguageButton(),
          IconButton(
            tooltip: l.signOut,
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => ref.read(sessionProvider.notifier).signOut(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: CenteredMessage(
        icon: icon,
        title: title,
        body: [
          body,
          if (m.statusNote != null && m.statusNote!.isNotEmpty)
            l.statusNote(m.statusNote!),
          if (AppConfig.supportPhone.isNotEmpty)
            l.contactUs(AppConfig.supportPhone),
        ].join('\n\n'),
        action: Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: () => ref.read(sessionProvider.notifier).reload(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(l.checkAgain),
            ),
            if ((ctx?.memberships.length ?? 0) > 1)
              OutlinedButton.icon(
                onPressed: () => showAccountSwitcher(context, ref),
                icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                label: Text(l.switchAccount),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.goldDark),
              ),
          ],
        ),
      ),
    );
  }
}
