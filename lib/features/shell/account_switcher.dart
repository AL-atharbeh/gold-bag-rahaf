import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/locale.dart';
import '../../platform/labels.dart';
import '../../platform/session.dart';
import '../common/inputs.dart';
import '../common/ui.dart';

/// قائمة المنشآت التي ينتمي إليها الشخص — مثل تبديل الحسابات في واتساب للأعمال.
Future<void> showAccountSwitcher(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _Switcher(),
  );
}

class _Switcher extends ConsumerStatefulWidget {
  const _Switcher();

  @override
  ConsumerState<_Switcher> createState() => _SwitcherState();
}

class _SwitcherState extends ConsumerState<_Switcher> {
  String? _switching;

  Future<void> _switch(String tenantId) async {
    if (!ensureOnline(context, ref)) return;
    final navigator = Navigator.of(context);
    setState(() => _switching = tenantId);
    try {
      await ref.read(sessionProvider.notifier).switchTenant(tenantId);
      navigator.pop();
    } catch (e) {
      if (mounted) showResult(context, readableError(e), error: true);
    } finally {
      if (mounted) setState(() => _switching = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ctx = ref.watch(sessionProvider).valueOrNull;
    if (ctx == null) return const SizedBox.shrink();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l.switchAccount,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final m in ctx.memberships) ...[
              GoldCard(
                onTap: _switching != null ? null : () => _switch(m.tenantId),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.goldContainer,
                      child: Icon(m.orgType.icon, color: AppColors.goldDark),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.orgName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              Pill(m.orgType.label(l)),
                              Pill(m.role.label(l),
                                  fg: AppColors.textSecondary,
                                  bg: AppColors.surfaceMuted),
                              if (!m.isActive)
                                Pill(m.status.label(l),
                                    fg: m.status.colors.$1,
                                    bg: m.status.colors.$2),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_switching == m.tenantId)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (m.tenantId == ctx.activeTenantId)
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.success),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}
