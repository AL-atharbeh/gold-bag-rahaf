import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/locale.dart';
import '../../platform/platform_models.dart';
import '../../platform/session.dart';
import '../common/inputs.dart';
import '../common/ui.dart';
import '../team/team_page.dart';

final bagsProvider = FutureProvider.autoDispose<List<Bag>>((ref) {
  ref.watch(activeTenantIdProvider);
  return ref.watch(platformRepoProvider).bags();
});

/// الشنط وحاملوها. المالك ينشئ ويعدّل؛ غيره يرى ما تسمح به صلاحيته.
///
/// المحتوى (رصيد كل شنطة وحركاتها) في المرحلة التالية.
class BagsPage extends ConsumerWidget {
  const BagsPage({super.key, this.pushed = false});

  /// مفتوحة من "المزيد" لا تبويباً رئيسياً.
  final bool pushed;

  Future<void> _edit(BuildContext context, WidgetRef ref, {Bag? bag}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _BagDialog(bag: bag),
    );
    if (saved == true) ref.invalidate(bagsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final m = ref.watch(activeMembershipProvider);
    final bags = ref.watch(bagsProvider);
    final canEdit = (m?.isOwner ?? false) && (m?.writable ?? false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(l.bags),
        automaticallyImplyLeading: pushed,
        actions: [
          IconButton(
            tooltip: l.retry,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(bagsProvider),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              heroTag: pushed ? 'fab-bags-pushed' : 'fab-bags',
              onPressed: () => _edit(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: Text(l.newBag,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
      body: AsyncBody<List<Bag>>(
        value: bags,
        onRetry: () => ref.invalidate(bagsProvider),
        data: (list) {
          if (list.isEmpty) {
            return CenteredMessage(
                icon: Icons.inventory_2_outlined, title: l.noBags);
          }
          final active = list.where((b) => b.isActive).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
            children: [
              if (m?.maxBags != null && m!.maxBags! > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    l.bagsUsed(active, m.maxBags!),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active >= m.maxBags!
                          ? AppColors.error
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              for (final b in list) ...[
                GoldCard(
                  onTap: canEdit ? () => _edit(context, ref, bag: b) : null,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: b.isActive
                            ? AppColors.goldContainer
                            : AppColors.surfaceMuted,
                        child: Icon(
                          Icons.work_rounded,
                          color: b.isActive
                              ? AppColors.goldDark
                              : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Text(
                              b.holderUserId == null
                                  ? l.noHolder
                                  : (b.holderName ?? ''),
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (!b.isActive)
                        Pill(l.inactive,
                            fg: AppColors.error, bg: AppColors.errorContainer),
                      if (canEdit)
                        const Icon(Icons.chevron_right_rounded,
                            color: AppColors.textMuted),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _BagDialog extends ConsumerStatefulWidget {
  const _BagDialog({this.bag});

  final Bag? bag;

  @override
  ConsumerState<_BagDialog> createState() => _BagDialogState();
}

class _BagDialogState extends ConsumerState<_BagDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  String? _holder;
  late bool _active;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.bag?.name ?? '');
    _holder = widget.bag?.holderUserId;
    _active = widget.bag?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!ensureOnline(context, ref)) return;
    final navigator = Navigator.of(context);
    final repo = ref.read(platformRepoProvider);
    setState(() => _busy = true);
    try {
      if (widget.bag == null) {
        await repo.createBag(_name.text.trim(), holderUserId: _holder);
      } else {
        await repo.updateBag(
          bagId: widget.bag!.id,
          name: _name.text.trim(),
          holderUserId: _holder,
          isActive: _active,
        );
      }
      navigator.pop(true);
    } catch (e) {
      if (mounted) showResult(context, readableError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final team = ref.watch(teamProvider);
    final members = [
      for (final m in team.valueOrNull?.members ?? const <TeamMember>[])
        if (m.isActive) m,
    ];

    return AlertDialog(
      title: Text(widget.bag == null ? l.newBag : l.editBag),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                autofocus: widget.bag == null,
                decoration: InputDecoration(
                  labelText: l.bagName,
                  prefixIcon: const Icon(Icons.work_outline_rounded),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? l.requiredField : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                initialValue:
                    members.any((m) => m.userId == _holder) ? _holder : null,
                decoration: InputDecoration(
                  labelText: l.bagHolder,
                  prefixIcon: const Icon(Icons.person_pin_outlined),
                ),
                items: [
                  DropdownMenuItem<String?>(
                      value: null, child: Text(l.noHolder)),
                  for (final m in members)
                    DropdownMenuItem<String?>(
                      value: m.userId,
                      child: Text(m.displayName.isEmpty
                          ? (m.phone ?? '')
                          : m.displayName),
                    ),
                ],
                onChanged: (v) => setState(() => _holder = v),
              ),
              if (widget.bag != null) ...[
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.goldDark,
                  title: Text(l.bagActive),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(l.save),
        ),
      ],
    );
  }
}
