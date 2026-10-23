import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/connectivity.dart';
import '../../core/locale.dart';
import 'inputs.dart';

/// شريط أحمر ثابت أعلى التطبيق عند انقطاع الإنترنت.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider);
    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: online
              ? const SizedBox(width: double.infinity)
              : Material(
                  color: AppColors.error,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              context.l10n.offlineBanner,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: !online,
            child: child,
          ),
        ),
      ],
    );
  }
}

/// يمنع الحفظ بدون اتصال ويُظهر السبب. يُرجع true إن كان متصلاً.
bool ensureOnline(BuildContext context, WidgetRef ref) {
  if (ref.read(isOnlineProvider)) return true;
  showResult(context, context.l10n.offlineAction, error: true);
  return false;
}

/// زر تبديل اللغة — يظهر اسم اللغة الأخرى.
class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () => ref.read(localeProvider.notifier).toggle(),
      icon: const Icon(Icons.translate_rounded, size: 18),
      label: Text(context.l10n.otherLanguage),
      style: TextButton.styleFrom(foregroundColor: AppColors.goldDark),
    );
  }
}

/// شارة صغيرة ملوّنة (حالة، دور…).
class Pill extends StatelessWidget {
  const Pill(this.text,
      {super.key,
      this.fg = AppColors.goldDark,
      this.bg = AppColors.goldContainer});

  final String text;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

/// بطاقة بيضاء بحدود ذهبية خفيفة — العنصر المتكرر في كل الشاشات.
class GoldCard extends StatelessWidget {
  const GoldCard(
      {super.key,
      required this.child,
      this.onTap,
      this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
              color: Color(0x05000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// رسالة مركزية: فراغ، أو خطأ مع إعادة محاولة.
class CenteredMessage extends StatelessWidget {
  const CenteredMessage({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 440),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.goldBorder),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: AppColors.goldContainer,
                child: Icon(icon, size: 34, color: AppColors.goldDark),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              if (body != null) ...[
                const SizedBox(height: 10),
                Text(
                  body!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ),
    );
  }
}

/// غلاف موحّد لحالات AsyncValue في الشاشات الجديدة.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody(
      {super.key, required this.value, required this.data, this.onRetry});

  final AsyncValue<T> value;
  final Widget Function(T) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.goldPrimary),
      ),
      error: (e, _) => CenteredMessage(
        icon: Icons.error_outline_rounded,
        title: readableError(e),
        action: onRetry == null
            ? null
            : OutlinedButton(
                onPressed: onRetry, child: Text(context.l10n.retry)),
      ),
      data: data,
    );
  }
}

/// عنوان قسم داخل قائمة.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// نافذة تأكيد بسيطة.
Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  String? body,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: body == null ? null : Text(body),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: AppColors.error)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// عرض خانة يتكيّف مع الجهاز.
///
/// على التابلت (عرض الشاشة 600 فأكثر) تأخذ الخانة عرضها [width] وتصطف
/// بجانب أخواتها. على الهاتف تملأ السطر كله، أو نصفه إن كانت [half]
/// (للخانات القصيرة كالعدد والوزن، فتتجاور اثنتان في السطر).
class AdaptiveBox extends StatelessWidget {
  const AdaptiveBox({
    super.key,
    required this.width,
    required this.child,
    this.half = false,
    this.spacing = 12,
  });

  final double width;
  final Widget child;
  final bool half;

  /// المسافة بين الخانتين المتجاورتين على الهاتف — نفس spacing في Wrap.
  final double spacing;

  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  @override
  Widget build(BuildContext context) {
    if (!isPhone(context)) return SizedBox(width: width, child: child);
    if (!half) return SizedBox(width: double.infinity, child: child);
    return LayoutBuilder(
      builder: (context, c) => SizedBox(
        width: c.maxWidth.isFinite ? (c.maxWidth - spacing) / 2 : width,
        child: child,
      ),
    );
  }
}
