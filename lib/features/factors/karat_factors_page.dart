import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/units.dart';
import '../../domain/models.dart';
import '../common/inputs.dart';

/// تعديل معاملات العيار لطرف معيّن — خروج بضاعة ودخول ذهب/كسر.
class KaratFactorsPage extends ConsumerStatefulWidget {
  const KaratFactorsPage({
    super.key,
    required this.accountId,
    required this.accountName,
  });

  final String accountId;
  final String accountName;

  @override
  ConsumerState<KaratFactorsPage> createState() => _KaratFactorsPageState();
}

class _KaratFactorsPageState extends ConsumerState<KaratFactorsPage> {
  final _formKey = GlobalKey<FormState>();
  final _out = <String, TextEditingController>{};
  final _in = <String, TextEditingController>{};
  bool _busy = false;
  bool _seeded = false;

  @override
  void dispose() {
    for (final c in _out.values) {
      c.dispose();
    }
    for (final c in _in.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _seed(List<KaratFactor> factors) {
    if (_seeded) return;
    _seeded = true;
    for (final f in factors) {
      _out[f.karatId] = TextEditingController(
        text: f.outIsCustom ? _fmt(f.outFactorPpm) : '',
      );
      _in[f.karatId] = TextEditingController(
        text: f.inIsCustom ? _fmt(f.inFactorPpm) : '',
      );
    }
  }

  String _fmt(int ppm) => (ppm / 1000000.0).toStringAsFixed(3);

  Future<void> _save(List<KaratFactor> factors) async {
    if (!_formKey.currentState!.validate()) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      final repo = ref.read(repositoryProvider);
      for (final f in factors) {
        final outText = _out[f.karatId]?.text.trim() ?? '';
        final inText = _in[f.karatId]?.text.trim() ?? '';

        final outPpm = outText.isEmpty ? null : parseKaratFactor(outText);
        final inPpm = inText.isEmpty ? null : parseKaratFactor(inText);

        await repo.setKaratFactor(
          accountId: widget.accountId,
          karatId: f.karatId,
          outFactorPpm: outPpm,
          inFactorPpm: inPpm,
        );
      }
      ref.invalidate(karatFactorsProvider(widget.accountId));
      if (mounted) {
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('تم حفظ معاملات العيار بنجاح'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(readableError(e)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final factors = ref.watch(karatFactorsProvider(widget.accountId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('معاملات عيار: ${widget.accountName}'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: factors.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.goldPrimary),
        ),
        error: (e, _) => Center(child: Text(readableError(e))),
        data: (list) {
          _seed(list);
          return Form(
            key: _formKey,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.goldContainer,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.goldBorder),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: AppColors.goldDark, size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'اترك الحقل فارغاً ليتبع المعامل العام للنظام. الفارق بين معامل خروج البضاعة ومعامل دخول الذهب يمثل هامش ربحك على كل حركة.',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final f in list) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: AppColors.border, width: 1.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x06000000),
                              blurRadius: 12,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.karatName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _FactorField(
                                    controller: _out[f.karatId]!,
                                    label: 'خروج بضاعة',
                                    fallback: _fmt(f.outFactorPpm),
                                    isCustom: f.outIsCustom,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _FactorField(
                                    controller: _in[f.karatId]!,
                                    label: 'دخول ذهب / كسر',
                                    fallback: _fmt(f.inFactorPpm),
                                    isCustom: f.inIsCustom,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: _busy ? null : AppColors.goldGradient,
                        color: _busy
                            ? AppColors.goldLight.withValues(alpha: 0.5)
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          if (!_busy)
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
                          onTap: _busy ? null : () => _save(list),
                          borderRadius: BorderRadius.circular(14),
                          child: Center(
                            child: _busy
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'حفظ معاملات العيار',
                                        style: TextStyle(
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FactorField extends StatelessWidget {
  const _FactorField({
    required this.controller,
    required this.label,
    required this.fallback,
    required this.isCustom,
  });

  final TextEditingController controller;
  final String label;
  final String fallback;
  final bool isCustom;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: decimalInputFormatters,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      decoration: InputDecoration(
        labelText: label,
        hintText: isCustom ? null : 'العام: $fallback',
        helperText: isCustom ? 'معامل خاص بهذا الطرف' : 'يتبع المعامل العام',
        helperStyle: TextStyle(
          color: isCustom ? AppColors.goldDark : AppColors.textMuted,
          fontWeight: isCustom ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        final ppm = parseKaratFactor(v);
        if (ppm == null || ppm < 1 || ppm > 1000000) {
          return 'بين 0.001 و 1.000';
        }
        return null;
      },
    );
  }
}
