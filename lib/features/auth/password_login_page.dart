import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/theme.dart';
import '../../core/config.dart';
import '../../core/locale.dart';
import '../../core/phone.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/session.dart';
import '../common/inputs.dart';
import '../common/ui.dart';

/// دخول نسخة تاجر الشنطة: رقم الهاتف وكلمة المرور فقط.
///
/// لا يوجد إنشاء حساب ولا استعادة كلمة مرور من التطبيق — الحسابات
/// الثلاثة نُنشئها نحن، ومن نسي كلمة مروره يتواصل مع الدعم.
class PasswordLoginPage extends ConsumerStatefulWidget {
  const PasswordLoginPage({super.key});

  @override
  ConsumerState<PasswordLoginPage> createState() => _PasswordLoginPageState();
}

class _PasswordLoginPageState extends ConsumerState<PasswordLoginPage> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _hidden = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_form.currentState!.validate()) return;
    if (!ensureOnline(context, ref)) return;
    final l = context.l10n;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(platformRepoProvider)
          .passwordSignIn(normalizeJordanMobile(_phone.text)!, _password.text);
      // الجلسة تتغيّر فيعيد SessionGate البناء وحده
    } on AuthException catch (e) {
      final m = e.message.toLowerCase();
      final wrong = m.contains('invalid') || m.contains('credentials');
      final banned = m.contains('banned');
      if (mounted) {
        setState(() => _error = banned
            ? l.accountNotEnabled
            : wrong
                ? l.wrongPhoneOrPassword
                : readableError(e));
      }
    } catch (e) {
      if (mounted) setState(() => _error = readableError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.3),
                  radius: 1.2,
                  colors: [Color(0xFFFDFBF7), Colors.white],
                ),
              ),
            ),
          ),
          const SafeArea(
            child: Align(
              alignment: AlignmentDirectional.topEnd,
              child:
                  Padding(padding: EdgeInsets.all(12), child: LanguageButton()),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border, width: 1.2),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x0A000000),
                          blurRadius: 24,
                          offset: Offset(0, 8)),
                    ],
                  ),
                  child: Form(
                    key: _form,
                    child: AutofillGroup(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const AuthLogo(),
                          const SizedBox(height: 20),
                          Text(
                            l.appTitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l.bagEditionSubtitle,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 28),
                          TextFormField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            inputFormatters: phoneInputFormatters,
                            textDirection: TextDirection.ltr,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.telephoneNumber
                            ],
                            style: const TextStyle(
                                fontSize: 18,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              labelText: l.phoneLabel,
                              hintText: l.phoneHint,
                              prefixIcon:
                                  const Icon(Icons.phone_iphone_rounded),
                            ),
                            validator: (v) =>
                                normalizeJordanMobile(v ?? '') == null
                                    ? l.invalidPhone
                                    : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _password,
                            obscureText: _hidden,
                            textDirection: TextDirection.ltr,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _busy ? null : _signIn(),
                            decoration: InputDecoration(
                              labelText: l.passwordLabel,
                              prefixIcon:
                                  const Icon(Icons.lock_outline_rounded),
                              suffixIcon: IconButton(
                                tooltip:
                                    _hidden ? l.showPassword : l.hidePassword,
                                icon: Icon(_hidden
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () =>
                                    setState(() => _hidden = !_hidden),
                              ),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                ? l.requiredField
                                : null,
                          ),
                          const SizedBox(height: 24),
                          AuthPrimaryButton(
                              label: l.signIn, busy: _busy, onPressed: _signIn),
                          if (_error != null) ...[
                            const SizedBox(height: 16),
                            AuthErrorBox(_error!),
                          ],
                          const SizedBox(height: 18),
                          _SupportNote(l: l),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportNote extends StatelessWidget {
  const _SupportNote({required this.l});

  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final support = AppConfig.supportPhone;
    return Text(
      support.isEmpty
          ? l.forgotPasswordHint
          : '${l.forgotPasswordHint} ${ltrIsolate(displayPhone(support))}',
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
    );
  }
}

class AuthLogo extends StatelessWidget {
  const AuthLogo();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 88,
        height: 88,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.goldContainer,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.goldBorder, width: 1.5),
        ),
        child:
            Image.asset('assets/images/logo_trimmed.png', fit: BoxFit.contain),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton(
      {required this.label, required this.busy, required this.onPressed});

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.goldPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: busy
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : Text(label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}

class AuthErrorBox extends StatelessWidget {
  const AuthErrorBox(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
