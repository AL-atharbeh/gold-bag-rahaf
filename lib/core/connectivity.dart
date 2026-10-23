import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// التطبيق يعمل متصلاً فقط — لا تخزين محلي ولا مزامنة لاحقة.
/// عند الانقطاع يظهر شريط تنبيه وتُمنع عمليات الحفظ.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final c = Connectivity();
  bool online(List<ConnectivityResult> r) =>
      r.any((x) => x != ConnectivityResult.none);

  yield online(await c.checkConnectivity());
  yield* c.onConnectivityChanged.map(online);
});

/// القيمة الحالية. غير المعروف بعد يُعامل كمتصل حتى لا يومض الشريط عند الإقلاع.
final isOnlineProvider = Provider<bool>(
  (ref) => ref.watch(connectivityProvider).valueOrNull ?? true,
);

class OfflineException implements Exception {
  const OfflineException();

  @override
  String toString() => 'لا يوجد اتصال بالإنترنت — لم يُحفظ شيء';
}
