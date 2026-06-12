import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Generates the site's brand images straight from the bundled fonts
/// and the universe's visual language, writing them into web/:
/// og-image.png (link previews), favicon.png, and the PWA icons.
/// Deterministic, so re-runs are idempotent; doubles as a regression
/// check that the bundled fonts actually load.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final orbitron = FontLoader('Orbitron')
      ..addFont(rootBundle.load('google_fonts/Orbitron-Bold.ttf'));
    final spaceGrotesk = FontLoader('SpaceGrotesk')
      ..addFont(rootBundle.load('google_fonts/SpaceGrotesk-Regular.ttf'))
      ..addFont(rootBundle.load('google_fonts/SpaceGrotesk-Light.ttf'));
    await orbitron.load();
    await spaceGrotesk.load();
  });

  Future<void> savePng(ui.Image image, String path) async {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(data!.buffer.asUint8List());
    expect(File(path).existsSync(), isTrue, reason: path);
  }

  void centeredText(ui.Canvas canvas, String text, TextStyle style,
      double centerX, double y) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, ui.Offset(centerX - tp.width / 2, y));
  }

  test('generate og-image.png', () async {
    const double w = 1200, h = 630;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, w, h),
        ui.Paint()..color = const ui.Color(0xFF000000));

    // Nebula tints, same hues as the live site.
    final nebula = ui.Paint()..blendMode = ui.BlendMode.plus;
    nebula.shader = ui.Gradient.radial(const ui.Offset(260, 160), 520, [
      const ui.Color(0xFF4956C4).withValues(alpha: 0.12),
      const ui.Color(0x00000000),
    ]);
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, w, h), nebula);
    nebula.shader = ui.Gradient.radial(const ui.Offset(960, 520), 460, [
      const ui.Color(0xFF7A3FA0).withValues(alpha: 0.10),
      const ui.Color(0x00000000),
    ]);
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, w, h), nebula);

    // Seeded starfield.
    final rnd = math.Random(1380);
    final star = ui.Paint();
    for (int i = 0; i < 240; i++) {
      final bool warm = rnd.nextDouble() < 0.12;
      star.color = (warm
              ? const ui.Color(0xFFFFE2BE)
              : const ui.Color(0xFFCDD8FF))
          .withValues(alpha: 0.12 + 0.6 * rnd.nextDouble());
      canvas.drawCircle(
        ui.Offset(rnd.nextDouble() * w, rnd.nextDouble() * h),
        0.5 + 1.5 * rnd.nextDouble(),
        star,
      );
    }

    // The singularity above the name.
    const ui.Offset point = ui.Offset(w / 2, 150);
    canvas.drawCircle(
      point,
      46,
      ui.Paint()
        ..blendMode = ui.BlendMode.plus
        ..shader = ui.Gradient.radial(point, 46, [
          const ui.Color(0xFFFFFFFF).withValues(alpha: 0.9),
          const ui.Color(0xFFBFD0FF).withValues(alpha: 0.2),
          const ui.Color(0x00000000),
        ], const [
          0.0,
          0.3,
          1.0,
        ]),
    );
    canvas.drawCircle(point, 3, ui.Paint()..color = const ui.Color(0xFFFFFFFF));

    centeredText(
      canvas,
      'MANISH TALREJA',
      const TextStyle(
        fontFamily: 'Orbitron',
        fontWeight: FontWeight.w700,
        fontSize: 68,
        letterSpacing: 10,
        color: ui.Color(0xF2FFFFFF),
      ),
      w / 2,
      236,
    );
    canvas.drawRect(
      const ui.Rect.fromLTWH(w / 2 - 260, 348, 520, 1),
      ui.Paint()..color = const ui.Color(0x40FFFFFF),
    );
    centeredText(
      canvas,
      'MOBILE APPLICATION DEVELOPER · FLUTTER',
      const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontSize: 24,
        letterSpacing: 6,
        color: ui.Color(0xB3FFFFFF),
      ),
      w / 2,
      382,
    );
    centeredText(
      canvas,
      '4+ YEARS  ·  50+ PROJECTS  ·  20+ LIVE APPS',
      const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w300,
        fontSize: 17,
        letterSpacing: 4,
        color: ui.Color(0x73FFFFFF),
      ),
      w / 2,
      452,
    );
    centeredText(
      canvas,
      'THE BIG BANG PORTFOLIO',
      const TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontWeight: FontWeight.w300,
        fontSize: 12,
        letterSpacing: 5,
        color: ui.Color(0x59FFFFFF),
      ),
      w / 2,
      560,
    );

    final image =
        await recorder.endRecording().toImage(w.toInt(), h.toInt());
    await savePng(image, 'web/og-image.png');
  });

  test('generate favicon and PWA icons', () async {
    Future<ui.Image> drawIcon(int size, {required bool maskable}) async {
      final double s = size.toDouble();
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final center = ui.Offset(s / 2, s / 2);

      canvas.drawRect(ui.Rect.fromLTWH(0, 0, s, s),
          ui.Paint()..color = const ui.Color(0xFF000000));

      // Maskable icons keep the singularity inside the 80% safe zone.
      final double reach = maskable ? 0.30 : 0.38;

      // Orbit ring with one small body — the contact era, condensed.
      canvas.drawOval(
        ui.Rect.fromCenter(
            center: center, width: s * reach * 2.3, height: s * reach * 0.95),
        ui.Paint()
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = math.max(1, s * 0.012)
          ..color = const ui.Color(0x40FFFFFF),
      );
      canvas.drawCircle(
        center.translate(s * reach * 0.92, s * reach * 0.19),
        math.max(1.5, s * 0.022),
        ui.Paint()..color = const ui.Color(0xCCFFFFFF),
      );

      // The singularity.
      final double glowR = s * reach;
      canvas.drawCircle(
        center,
        glowR,
        ui.Paint()
          ..blendMode = ui.BlendMode.plus
          ..shader = ui.Gradient.radial(center, glowR, [
            const ui.Color(0xFFFFFFFF).withValues(alpha: 0.95),
            const ui.Color(0xFFBFD0FF).withValues(alpha: 0.25),
            const ui.Color(0x00000000),
          ], const [
            0.0,
            0.32,
            1.0,
          ]),
      );
      canvas.drawCircle(center, math.max(1.5, s * 0.05),
          ui.Paint()..color = const ui.Color(0xFFFFFFFF));

      return recorder.endRecording().toImage(size, size);
    }

    await savePng(await drawIcon(64, maskable: false), 'web/favicon.png');
    await savePng(
        await drawIcon(192, maskable: false), 'web/icons/Icon-192.png');
    await savePng(
        await drawIcon(512, maskable: false), 'web/icons/Icon-512.png');
    await savePng(await drawIcon(192, maskable: true),
        'web/icons/Icon-maskable-192.png');
    await savePng(await drawIcon(512, maskable: true),
        'web/icons/Icon-maskable-512.png');
  });
}
