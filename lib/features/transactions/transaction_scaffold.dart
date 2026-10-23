import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../common/inputs.dart';

/// هيكل موحّد لكل شاشات الحركات: نموذج قابل للتمرير مع شريط الحفظ الذهبي الأنيق
class TransactionScaffold extends StatelessWidget {
  const TransactionScaffold({
    super.key,
    required this.title,
    required this.formKey,
    required this.children,
    required this.onSubmit,
    required this.busy,
    this.submitLabel = 'حفظ الحركة',
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final VoidCallback onSubmit;
  final bool busy;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Form(
        key: formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
              children: [
                ...children,
                const SizedBox(height: 32),
                Container(
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: busy ? null : AppColors.goldGradient,
                    color: busy
                        ? AppColors.goldLight.withValues(alpha: 0.5)
                        : null,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      if (!busy)
                        const BoxShadow(
                          color: Color(0x25C5A059),
                          blurRadius: 14,
                          offset: Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: busy ? null : onSubmit,
                      borderRadius: BorderRadius.circular(14),
                      child: Center(
                        child: busy
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    submitLabel,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// عرض حالة التحميل/الخطأ لبيانات الشاشة قبل بناء النموذج.
class AsyncGate extends StatelessWidget {
  const AsyncGate({
    super.key,
    required this.title,
    required this.loading,
    required this.error,
  });

  final String title;
  final bool loading;
  final Object? error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: loading
                ? const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.goldPrimary),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'جاري جلب البيانات...',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.errorContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline_rounded,
                          color: AppColors.error,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        readableError(error!),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
