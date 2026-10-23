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

/// إضافة عضو ([member] = null) أو تعديله. يُرجع true عند الحفظ.
Future<bool?> showMemberEditor(BuildContext context, {TeamMember? member}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _MemberEditor(member: member),
  );
}

class _MemberEditor extends ConsumerStatefulWidget {
  const _MemberEditor({this.member});

  final TeamMember? member;

  @override
  ConsumerState<_MemberEditor> createState() => _MemberEditorState();
}

class _MemberEditorState extends ConsumerState<_MemberEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _phone;
  late final TextEditingController _name;
  late MemberRole _role;
  late Set<Perm> _perms;
  late bool _active;
  bool _busy = false;

  bool get _isNew => widget.member == null;

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    _phone = TextEditingController(text: displayPhone(m?.phone));
    _name = TextEditingController(text: m?.displayName ?? '');
    _role = m?.role ?? MemberRole.bagHolder;
    _perms = m == null ? Perm.defaultsFor(_role) : {...m.permissions};
    _active = m?.isActive ?? true;
  }

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!ensureOnline(context, ref)) return;

    final l = context.l10n;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(platformRepoProvider);
    setState(() => _busy = true);

    try {
      String message = l.saved;
      if (_isNew) {
        final kind = await repo.inviteMember(
          phone: normalizeJordanMobile(_phone.text)!,
          role: _role,
          permissions: _perms,
          displayName: _name.text.trim(),
        );
        message = kind == 'invitation' ? l.invitationCreated : l.memberAdded;
      } else {
        await repo.updateMember(
          membershipId: widget.member!.membershipId,
          role: _role,
          permissions: _perms,
          displayName: _name.text.trim(),
          isActive: _active,
        );
      }
      navigator.pop(true);
      messenger.showSnackBar(SnackBar(
          content: Text(message), backgroundColor: AppColors.goldDark));
    } catch (e) {
      if (mounted) showResult(context, readableError(e), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final orgType =
        ref.watch(activeMembershipProvider)?.orgType ?? OrgType.distributor;
    final perms = Perm.relevantFor(orgType);
    final roles = [
      for (final r in MemberRole.assignable)
        // حامل الشنطة لا معنى له في محل
        if (!(orgType == OrgType.shop && r == MemberRole.bagHolder)) r,
    ];

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isNew ? l.inviteMember : l.editMember,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: TextFormField(
                    controller: _phone,
                    enabled: _isNew,
                    keyboardType: TextInputType.phone,
                    inputFormatters: phoneInputFormatters,
                    decoration: InputDecoration(
                      labelText: l.phoneLabel,
                      hintText: l.phoneHint,
                      prefixIcon: const Icon(Icons.phone_iphone_rounded),
                    ),
                    validator: (v) =>
                        _isNew && normalizeJordanMobile(v ?? '') == null
                            ? l.invalidPhone
                            : null,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: l.memberName,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? l.requiredField : null,
                ),
                const SizedBox(height: 18),
                SectionTitle(l.role),
                for (final r in roles)
                  RadioListTile<MemberRole>(
                    value: r,
                    // ignore: deprecated_member_use
                    groupValue: _role,
                    // ignore: deprecated_member_use
                    onChanged: (v) => setState(() {
                      _role = v!;
                      // تغيير الدور يعيد الصلاحيات الافتراضية — يمكن تعديلها بعده
                      _perms = Perm.defaultsFor(_role);
                    }),
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.goldDark,
                    title: Text(r.label(l),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(r.description(l),
                        style: const TextStyle(fontSize: 12)),
                  ),
                const SizedBox(height: 8),
                SectionTitle(l.permissions),
                for (final p in perms)
                  CheckboxListTile(
                    value: _perms.contains(p),
                    onChanged: (v) =>
                        setState(() => v! ? _perms.add(p) : _perms.remove(p)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: AppColors.goldDark,
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(p.label(l)),
                  ),
                if (!_isNew) ...[
                  const Divider(height: 24),
                  SwitchListTile(
                    value: _active,
                    onChanged: (v) => setState(() => _active = v),
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.goldDark,
                    title: Text(l.memberActive,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _save,
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(l.save,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
