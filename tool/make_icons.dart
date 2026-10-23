// توليد أصول الأيقونة والسبلاش من الشعار الأصلي.
//
// الشعار كما ورد فيه هوامش شفافة واسعة: التاج يشغل جزءاً صغيراً من
// المربع. لو استُعمل كما هو كأيقونة تطبيق لظهر التاج ضئيلاً وسط
// مربع فارغ. لذلك نقصّ الهوامش أولاً ثم نعيد التوسيط بهامش مضبوط.
//
// التشغيل:  dart run tool/make_icons.dart

import 'dart:io';

import 'package:image/image.dart' as img;

/// خلفية داكنة دافئة — الذهب يبرز عليها أكثر من الأبيض،
/// وتظل مميّزة على خلفيات الشاشات الفاتحة والداكنة معاً.
const bgR = 0x14, bgG = 0x12, bgB = 0x10;

void main() {
  final srcFile = File('assets/images/logo.png');
  if (!srcFile.existsSync()) {
    stderr.writeln('لم يُعثر على assets/images/logo.png');
    exit(1);
  }

  final src = img.decodePng(srcFile.readAsBytesSync())!;
  final box = _alphaBounds(src);
  if (box == null) {
    stderr.writeln('الصورة شفافة بالكامل');
    exit(1);
  }

  final (left, top, right, bottom) = box;
  final cropW = right - left + 1;
  final cropH = bottom - top + 1;
  stdout.writeln('الأصل: ${src.width}×${src.height}');
  stdout.writeln('التاج الفعلي: $cropW×$cropH  عند ($left, $top)');

  final trimmed = img.copyCrop(src, x: left, y: top, width: cropW, height: cropH);

  // ١) الشعار مقصوصاً — للسبلاش وشاشة الدخول
  File('assets/images/logo_trimmed.png')
      .writeAsBytesSync(img.encodePng(trimmed));

  // ٢) أيقونة التطبيق — خلفية صلبة، التاج بعرض ٧٠٪
  _write('assets/images/icon.png',
      _compose(trimmed, 1024, 0.80, opaque: true));

  // ٣) طبقة أمامية لأيقونة أندرويد التكيّفية.
  //    أندرويد يقصّ الأطراف بأشكال مختلفة، فالمحتوى يُحصر في ٥٠٪
  //    من المربع حتى لا يُقتطع التاج على أجهزة تقصّه دائرياً.
  _write('assets/images/icon_foreground.png',
      _compose(trimmed, 1024, 0.58, opaque: false));

  stdout.writeln('✅ تم التوليد');
}

/// أصغر مستطيل يحوي كل البكسلات غير الشفافة.
(int, int, int, int)? _alphaBounds(img.Image im) {
  var left = im.width, top = im.height, right = -1, bottom = -1;
  for (var y = 0; y < im.height; y++) {
    for (var x = 0; x < im.width; x++) {
      if (im.getPixel(x, y).a > 8) {
        if (x < left) left = x;
        if (x > right) right = x;
        if (y < top) top = y;
        if (y > bottom) bottom = y;
      }
    }
  }
  return right < 0 ? null : (left, top, right, bottom);
}

/// يضع الشعار وسط مربع، بحيث يشغل [fill] من عرضه.
img.Image _compose(img.Image logo, int size, double fill,
    {required bool opaque}) {
  final canvas = img.Image(width: size, height: size, numChannels: 4);
  if (opaque) {
    img.fill(canvas, color: img.ColorRgba8(bgR, bgG, bgB, 255));
  } else {
    img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));
  }

  // نقيس بالعرض أو بالارتفاع أيهما يبلغ الحد أولاً — التاج عريض ومنخفض،
  // فالقياس بالعرض وحده يجعله يبدو صغيراً جداً.
  final target = (size * fill).round();
  final scale = logo.width >= logo.height
      ? target / logo.width
      : target / logo.height;

  final w = (logo.width * scale).round();
  final h = (logo.height * scale).round();
  final resized = img.copyResize(logo,
      width: w, height: h, interpolation: img.Interpolation.cubic);

  img.compositeImage(canvas, resized,
      dstX: (size - w) ~/ 2, dstY: (size - h) ~/ 2);
  return canvas;
}

void _write(String path, img.Image im) {
  File(path).writeAsBytesSync(img.encodePng(im));
  stdout.writeln('  → $path  (${im.width}×${im.height})');
}
