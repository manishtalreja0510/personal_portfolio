import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../engine/eras.dart';
import '../engine/particle_engine.dart';
import 'eras/civilizations_layer.dart';
import 'eras/finale_layer.dart';
import 'eras/planetary_layer.dart';
import 'eras/stellar_layer.dart';

/// Paints the whole universe in one pass, in narrative order: black
/// base, nebula tints, starfield, Big Bang debris, the flash shader,
/// and the singularity point — all under one screen-shake transform.
/// Repaints are driven by the simulation's frame tick via `repaint`.
class UniversePainter extends CustomPainter {
  UniversePainter(this.sim) : super(repaint: sim);

  final UniverseSimulation sim;
  final StellarLayer _stellar = StellarLayer();
  final PlanetaryLayer _planetary = PlanetaryLayer();
  final CivilizationsLayer _civilizations = CivilizationsLayer();
  final FinaleLayer _finale = FinaleLayer();

  static final Paint _basePaint = Paint()..color = const Color(0xFF000000);
  static final Paint _atlasPaint = Paint()
    ..blendMode = BlendMode.plus
    ..filterQuality = FilterQuality.low;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect bounds = Offset.zero & size;
    canvas.drawRect(bounds, _basePaint);

    canvas.save();
    canvas.translate(sim.shakeX, sim.shakeY);

    final double t = sim.clock.value;
    final double fieldA = sim.fieldAlpha;
    final ui.Image? sprite = sim.sprite;

    if (fieldA > 0) {
      _paintNebula(canvas, size, t, fieldA);
      if (sprite != null && sim.field != null) {
        canvas.drawRawAtlas(sprite, sim.rstTransforms, sim.spriteRects,
            sim.spriteColors, BlendMode.modulate, bounds, _atlasPaint);
      }
    }

    _stellar.paint(canvas, size, sim);
    _planetary.paint(canvas, size, sim);
    _civilizations.paint(canvas, size, sim);
    _finale.paint(canvas, size, sim);

    if (sim.burstLive && sprite != null) {
      canvas.drawRawAtlas(sprite, sim.burstRst, sim.burstRects,
          sim.burstColors, BlendMode.modulate, bounds, _atlasPaint);
    }

    final double bp = Era.bigBang.progress(t);
    if (t > Era.bigBang.start && bp < 1) {
      _paintFlash(canvas, size, bp);
    }

    _paintSingularity(canvas, size, t);

    canvas.restore();
  }

  /// Two vast, very faint radial tints that drift upward with scroll
  /// at sub-star parallax — depth for free, no shader required yet.
  void _paintNebula(Canvas canvas, Size size, double t, double a) {
    final Paint paint = Paint()..blendMode = BlendMode.plus;

    paint.shader = ui.Gradient.radial(
      Offset(size.width * 0.26, size.height * (0.34 - 0.18 * t)),
      size.shortestSide * 0.9,
      [
        const Color(0xFF4956C4).withValues(alpha: 0.07 * a),
        const Color(0x00000000),
      ],
    );
    canvas.drawRect(Offset.zero & size, paint);

    paint.shader = ui.Gradient.radial(
      Offset(size.width * 0.76, size.height * (0.72 - 0.30 * t)),
      size.shortestSide * 0.8,
      [
        const Color(0xFF7A3FA0).withValues(alpha: 0.05 * a),
        const Color(0x00000000),
      ],
    );
    canvas.drawRect(Offset.zero & size, paint);
  }

  /// The detonation flash: fragment shader when available, otherwise
  /// an equivalent gradient flash with three chromatic rings.
  void _paintFlash(Canvas canvas, Size size, double bp) {
    final Rect bounds = Offset.zero & size;
    final ui.Offset center = sim.bangCenter;
    final ui.FragmentShader? shader = sim.flashShader;

    if (shader != null) {
      shader
        ..setFloat(0, size.width)
        ..setFloat(1, size.height)
        ..setFloat(2, center.dx)
        ..setFloat(3, center.dy)
        ..setFloat(4, bp)
        ..setFloat(5, sim.time);
      canvas.drawRect(
          bounds,
          Paint()
            ..shader = shader
            ..blendMode = BlendMode.plus);
      return;
    }

    // Fallback: same envelopes as the shader, painter primitives.
    final double born = smoothstep(phase(bp, 0.0, 0.02));
    final double flashA =
        (math.exp(-bp * 5.0) * born).clamp(0.0, 1.0);
    if (flashA > 0.003) {
      final Paint flash = Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(
          center,
          size.shortestSide * (0.22 + 0.55 * bp),
          [
            const Color(0xFFFFF4E4).withValues(alpha: flashA),
            const Color(0xFFFF9D54).withValues(alpha: 0.35 * flashA),
            const Color(0x00000000),
          ],
          const [0.0, 0.3, 1.0],
        );
      canvas.drawRect(bounds, flash);
    }

    final double r =
        1.3 * (1 - math.pow(1 - bp, 2.2)) * size.shortestSide;
    final double ringA = (0.5 * math.exp(-bp * 2.5) * born).clamp(0.0, 1.0);
    if (ringA > 0.01 && r > 1) {
      final Paint ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..blendMode = BlendMode.plus
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      // R/G/B at slightly different radii — chromatic fringe.
      ring.color = const Color(0xFFFF2040).withValues(alpha: ringA);
      canvas.drawCircle(center, r * 1.03, ring);
      ring.color = const Color(0xFF30FF50).withValues(alpha: ringA);
      canvas.drawCircle(center, r, ring);
      ring.color = const Color(0xFF4060FF).withValues(alpha: ringA);
      canvas.drawCircle(center, r * 0.97, ring);
    }
  }

  /// The lone pulsing point before time begins. Builds up as the
  /// reader approaches the bang, then is swallowed by the flash.
  void _paintSingularity(Canvas canvas, Size size, double t) {
    final double swallow = 1 -
        smoothstep(phase(t, Era.bigBang.start, Era.bigBang.start + 0.012));
    if (swallow <= 0) return;

    final ui.Offset c = sim.bangCenter;
    final double time = sim.time;
    final double buildup = smoothstep(Era.singularity.progress(t));
    final double pulse =
        0.78 + 0.16 * math.sin(time * 2.1) + 0.06 * math.sin(time * 5.3);
    final double glow = ((0.5 + 0.5 * buildup) * pulse * swallow).clamp(0.0, 1.0);

    final double haloR =
        (34 + 30 * buildup) * (0.92 + 0.08 * math.sin(time * 2.1));
    canvas.drawCircle(
      c,
      haloR,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(c, haloR, [
          const Color(0xFFFFFFFF).withValues(alpha: 0.85 * glow),
          const Color(0xFFBFD0FF).withValues(alpha: 0.16 * glow),
          const Color(0x00000000),
        ], const [
          0.0,
          0.3,
          1.0,
        ]),
    );
    canvas.drawCircle(
      c,
      1.6 + 1.8 * buildup + 0.3 * math.sin(time * 2.1),
      Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: glow),
    );
  }

  @override
  bool shouldRepaint(UniversePainter oldDelegate) => oldDelegate.sim != sim;
}
