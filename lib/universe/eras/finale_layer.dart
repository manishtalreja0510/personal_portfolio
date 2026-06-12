import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/portfolio_data.dart';
import '../../engine/eras.dart';
import '../../engine/finale.dart';
import '../../engine/particle_engine.dart';

/// Paints the last two eras: the knight constellation of the Present
/// Moment, and the new singularity of the finale — orbit guide,
/// pulsing point, and the mini big-bang fired when it's clicked.
class FinaleLayer {
  final Map<String, TextPainter> _textCache = {};

  TextPainter _text(String text, double alpha, {double fontSize = 10}) {
    final int bucket = (alpha.clamp(0.0, 1.0) * 15).round();
    return _textCache.putIfAbsent('$text|$bucket|$fontSize', () {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: GoogleFonts.spaceGrotesk(
            fontSize: fontSize,
            letterSpacing: 3,
            color: ui.Color.fromRGBO(255, 255, 255, bucket / 15 * 0.55),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  void paint(ui.Canvas canvas, ui.Size size, UniverseSimulation sim) {
    final double t = sim.clock.value;
    final double aPresent = presentAlpha(t);
    if (aPresent > 0.002) {
      _paintKnight(canvas, size, sim.time, t, aPresent);
    }
    final double aContact = contactAlpha(t);
    if (aContact > 0.002) {
      _paintNewUniverse(canvas, size, sim, aContact);
    }
  }

  // ---------------------------------------------------------------
  // The chess knight — stars first, then the lines find each other.
  // ---------------------------------------------------------------

  void _paintKnight(
      ui.Canvas canvas, ui.Size size, double time, double t, double a) {
    final layout = knightLayout(size);
    final double p = Era.present.progress(t);
    final bool tall = size.height > size.width;
    final double dim = tall ? 0.6 : 1.0;

    ui.Offset starAt(int i) => ui.Offset(
          layout.anchor.dx + kKnightPoints[i].dx * layout.scale,
          layout.anchor.dy + kKnightPoints[i].dy * layout.scale,
        );

    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..blendMode = ui.BlendMode.plus;
    for (int e = 0; e < kKnightEdges.length; e++) {
      final double draw =
          smoothstep(phase(p, 0.45 + e * 0.025, 0.58 + e * 0.025));
      if (draw <= 0.01) continue;
      final ui.Offset from = starAt(kKnightEdges[e].$1);
      final ui.Offset to = starAt(kKnightEdges[e].$2);
      line.color = const ui.Color(0xFFB9C8E8)
          .withValues(alpha: 0.18 * a * draw * dim);
      canvas.drawLine(
          from,
          ui.Offset(from.dx + (to.dx - from.dx) * draw,
              from.dy + (to.dy - from.dy) * draw),
          line);
    }

    final Paint halo = Paint()..blendMode = ui.BlendMode.plus;
    final Paint core = Paint();
    for (int i = 0; i < kKnightPoints.length; i++) {
      final double appear =
          smoothstep(phase(p, 0.22 + i * 0.018, 0.36 + i * 0.018));
      if (appear <= 0.01) continue;
      final ui.Offset c = starAt(i);
      final double twinkle = 0.8 + 0.2 * math.sin(time * 1.6 + i * 1.9);
      final double sa = a * appear * twinkle * dim;
      halo.shader = ui.Gradient.radial(c, 7, [
        const ui.Color(0xFFD8E4FF).withValues(alpha: 0.45 * sa),
        const ui.Color(0x00000000),
      ]);
      canvas.drawCircle(c, 7, halo);
      core.color = const ui.Color(0xFFFFFFFF).withValues(alpha: 0.85 * sa);
      canvas.drawCircle(c, 1.4, core);
    }

    final double captionA = a * smoothstep(phase(p, 0.62, 0.75)) * dim;
    if (captionA > 0.03) {
      final tp = _text(kHobbies.join(' · ').toUpperCase(), captionA);
      tp.paint(
          canvas,
          ui.Offset(
              layout.anchor.dx + layout.scale / 2 - tp.width / 2,
              layout.anchor.dy + layout.scale * 1.05));
    }
  }

  // ---------------------------------------------------------------
  // The new singularity
  // ---------------------------------------------------------------

  void _paintNewUniverse(
      ui.Canvas canvas, ui.Size size, UniverseSimulation sim, double a) {
    final ui.Offset c = newSingularityCenter(size);
    final double time = sim.time;
    final orbit = contactOrbitRadii(size);

    // Faint orbital guide the contact bodies ride on.
    final Paint guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: 0.07 * a);
    canvas.drawOval(
        ui.Rect.fromCenter(
            center: c, width: orbit.rx * 2, height: orbit.ry * 2),
        guide);

    // The point itself: pulsing, brightening under the pointer.
    final double pulse =
        0.78 + 0.16 * math.sin(time * 2.1) + 0.06 * math.sin(time * 5.3);
    final double hoverBoost = sim.contactHover ? 1.3 : 1.0;
    final double glow = (a * pulse * hoverBoost).clamp(0.0, 1.0);

    final double haloR = 40 * (0.92 + 0.08 * math.sin(time * 2.1));
    canvas.drawCircle(
      c,
      haloR,
      Paint()
        ..blendMode = ui.BlendMode.plus
        ..shader = ui.Gradient.radial(c, haloR, [
          const ui.Color(0xFFFFFFFF).withValues(alpha: 0.85 * glow),
          const ui.Color(0xFFBFD0FF).withValues(alpha: 0.18 * glow),
          const ui.Color(0x00000000),
        ], const [
          0.0,
          0.3,
          1.0,
        ]),
    );
    canvas.drawCircle(
        c,
        2.4,
        Paint()
          ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: glow));

    // Invitation ring breathing outward from the point.
    final double rr = (time * 0.5) % 1.0;
    canvas.drawCircle(
        c,
        14 + rr * 40,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..blendMode = ui.BlendMode.plus
          ..color = const ui.Color(0xFFBFD0FF)
              .withValues(alpha: (1 - rr) * 0.30 * a));

    _paintClickBurst(canvas, sim, c, a);
  }

  /// The mini big-bang: flash, chromatic-ish ring, and sparks for
  /// ~1.4s of wall-time after the singularity is clicked.
  void _paintClickBurst(
      ui.Canvas canvas, UniverseSimulation sim, ui.Offset c, double a) {
    final double elapsed = sim.time - sim.contactBurstStart;
    if (elapsed <= 0 || elapsed > 1.4) return;
    final double u = elapsed / 1.4;
    final double fade = (1 - u) * a;

    // Flash.
    final double flashA = math.exp(-elapsed * 4.5) * a;
    if (flashA > 0.01) {
      canvas.drawCircle(
        c,
        140,
        Paint()
          ..blendMode = ui.BlendMode.plus
          ..shader = ui.Gradient.radial(c, 140, [
            const ui.Color(0xFFFFF4E4).withValues(alpha: flashA),
            const ui.Color(0x00000000),
          ]),
      );
    }

    // Expanding ring.
    final double r = (1 - math.pow(1 - u, 2.2)) * 180;
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..blendMode = ui.BlendMode.plus
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4)
          ..color =
              const ui.Color(0xFFBFD0FF).withValues(alpha: 0.5 * fade));

    // Sparks on golden-angle rays.
    final Paint spark = Paint()..blendMode = ui.BlendMode.plus;
    for (int i = 0; i < 28; i++) {
      final double angle = i * 2.39996;
      final double speed = 0.45 + 0.55 * ((i * 37) % 11) / 10;
      final double d = r * speed;
      spark.color = const ui.Color(0xFFEAF2FF)
          .withValues(alpha: 0.7 * fade * (1 - 0.5 * speed));
      canvas.drawCircle(
          c.translate(math.cos(angle) * d, math.sin(angle) * d * 0.8),
          1.6,
          spark);
    }
  }
}
