import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/portfolio_data.dart';
import '../../engine/particle_engine.dart';
import '../../engine/planet_system.dart';

/// Paints the Planetary Accretion era: banded procedural planets with
/// atmosphere glow, rings, orbiting tech moons, and the two pub.dev
/// comets with particle tails. Pure read of [PlanetSystem] state.
class PlanetaryLayer {
  final Map<String, TextPainter> _textCache = {};

  TextPainter _text(String text, double alpha,
      {double fontSize = 10.5, ui.Color color = const ui.Color(0xFFFFFFFF)}) {
    final int bucket = (alpha.clamp(0.0, 1.0) * 15).round();
    return _textCache.putIfAbsent('$text|$bucket|$fontSize', () {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: GoogleFonts.spaceGrotesk(
            fontSize: fontSize,
            letterSpacing: 0.8,
            color: color.withValues(alpha: color.a * bucket / 15),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  void paint(ui.Canvas canvas, ui.Size size, UniverseSimulation sim) {
    final PlanetSystem? ps = sim.planets;
    if (ps == null) return;
    final double a = PlanetSystem.eraAlpha(sim.clock.value);
    if (a <= 0.002) return;

    for (int k = 0; k < ps.states.length; k++) {
      final PlanetState s = ps.states[k];
      if (s.alpha <= 0.01) continue;
      _paintPlanet(canvas, ps.specs[k], s, sim.ambientTime,
          dimMoons: ps.zoomEase, zoomed: ps.zoomIndex == k);
    }

    for (int c = 0; c < ps.comets.length; c++) {
      final CometState comet = ps.comets[c];
      if (!comet.active) continue;
      _paintComet(canvas, comet, ps.packages[c], sim.ambientTime);
    }
  }

  void _paintPlanet(ui.Canvas canvas, PlanetSpec spec, PlanetState s,
      double time,
      {required double dimMoons, required bool zoomed}) {
    final ui.Offset c = ui.Offset(s.x, s.y);
    final double r = s.radius;
    final double alpha = s.alpha;

    // Tech moons behind the planet (z from orbit angle).
    _paintMoons(canvas, spec, s, time, behind: true, dim: dimMoons);

    // Ring, far half — drawn before the body so it passes behind.
    if (spec.hasRing) {
      _paintRingHalf(canvas, spec, c, r, alpha, far: true);
    }

    // Atmosphere glow.
    final Paint glow = Paint()
      ..blendMode = ui.BlendMode.plus
      ..shader = ui.Gradient.radial(c, r * 1.45, [
        spec.atmosphere.withValues(alpha: 0.0),
        spec.atmosphere.withValues(alpha: 0.22 * alpha),
        spec.atmosphere.withValues(alpha: 0.0),
      ], const [
        0.55,
        0.72,
        1.0,
      ]);
    canvas.drawCircle(c, r * 1.45, glow);

    // Body: clipped bands + sphere shading + terminator.
    canvas.save();
    canvas.clipPath(ui.Path()..addOval(ui.Rect.fromCircle(center: c, radius: r)));

    final ui.Rect body = ui.Rect.fromCircle(center: c, radius: r);
    final Paint fill = Paint()
      ..color = spec.bands[0].withValues(alpha: alpha);
    canvas.drawRect(body, fill);

    // Latitude bands with a gentle curve.
    final int nBands = spec.bands.length * 2;
    for (int b = 0; b < nBands; b++) {
      final ui.Color color = spec.bands[b % spec.bands.length];
      final double yTop = c.dy - r + (2 * r) * b / nBands;
      final double h = (2 * r) / nBands;
      final double bow = math.sin((b / nBands) * math.pi) * r * 0.07;
      final Paint band = Paint()
        ..color = color.withValues(alpha: (0.30 + 0.25 * (b % 3) / 2) * alpha);
      final ui.Path path = ui.Path()
        ..moveTo(c.dx - r, yTop)
        ..quadraticBezierTo(c.dx, yTop - bow, c.dx + r, yTop)
        ..lineTo(c.dx + r, yTop + h)
        ..quadraticBezierTo(c.dx, yTop + h - bow, c.dx - r, yTop + h)
        ..close();
      canvas.drawPath(path, band);
    }

    // Sphere shading: light from upper-left, deep limb shadow.
    final Paint shade = Paint()
      ..shader = ui.Gradient.radial(
        c.translate(-r * 0.35, -r * 0.4),
        r * 1.9,
        [
          const ui.Color(0x66FFFFFF).withValues(alpha: 0.32 * alpha),
          const ui.Color(0x00000000),
          spec.deep.withValues(alpha: 0.85 * alpha),
        ],
        const [0.0, 0.45, 1.0],
      );
    canvas.drawRect(body, shade);

    // Terminator: night side creeping in from the right.
    final Paint night = Paint()
      ..shader = ui.Gradient.linear(
        ui.Offset(c.dx, c.dy),
        ui.Offset(c.dx + r, c.dy),
        [
          const ui.Color(0x00000000),
          const ui.Color(0xE6000208).withValues(alpha: 0.62 * alpha),
        ],
      );
    canvas.drawRect(body, night);
    canvas.restore();

    // Ring, near half — over the body.
    if (spec.hasRing) {
      _paintRingHalf(canvas, spec, c, r, alpha, far: false);
    }

    _paintMoons(canvas, spec, s, time, behind: false, dim: dimMoons);
  }

  void _paintRingHalf(ui.Canvas canvas, PlanetSpec spec, ui.Offset c,
      double r, double alpha,
      {required bool far}) {
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(spec.ringTilt);
    final ui.Rect oval =
        ui.Rect.fromCenter(center: ui.Offset.zero, width: r * 4.0, height: r * 1.1);
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.13
      ..color = spec.atmosphere.withValues(alpha: 0.28 * alpha)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2);
    // Far half = top of the ellipse (π..2π), near half = bottom.
    canvas.drawArc(oval, far ? math.pi : 0, math.pi, false, ring);
    final Paint inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.04
      ..color = spec.atmosphere.withValues(alpha: 0.40 * alpha);
    canvas.drawArc(oval.deflate(r * 0.14), far ? math.pi : 0, math.pi, false, inner);
    canvas.restore();
  }

  /// Tech stack as orbiting moons. Flattened elliptical orbits; a
  /// moon is "behind" while on the upper half of its orbit.
  void _paintMoons(ui.Canvas canvas, PlanetSpec spec, PlanetState s,
      double time,
      {required bool behind, required double dim}) {
    final List<String> tech = spec.project.tech;
    final double labelGate = s.focus * (1 - dim);
    for (int i = 0; i < tech.length; i++) {
      final double orbR = s.radius * (1.55 + 0.30 * i);
      final double speed = 0.22 - 0.025 * i;
      final double angle = time * speed + i * 2.39996; // golden angle
      final double sinA = math.sin(angle);
      final bool isBehind = sinA < 0;
      if (isBehind != behind) continue;

      final double mx = s.x + math.cos(angle) * orbR;
      final double my = s.y + sinA * orbR * 0.30;
      final double depth = isBehind ? 0.55 : 1.0;
      final double moonR = (3.2 + (i % 3) * 0.8) * depth;
      final double mAlpha = s.alpha * depth * (1 - 0.6 * dim);

      final Paint moon = Paint()
        ..color = const ui.Color(0xFFE8EEF8).withValues(alpha: 0.9 * mAlpha);
      canvas.drawCircle(ui.Offset(mx, my), moonR, moon);
      final Paint moonGlow = Paint()
        ..blendMode = ui.BlendMode.plus
        ..shader = ui.Gradient.radial(ui.Offset(mx, my), moonR * 3.2, [
          spec.atmosphere.withValues(alpha: 0.35 * mAlpha),
          const ui.Color(0x00000000),
        ]);
      canvas.drawCircle(ui.Offset(mx, my), moonR * 3.2, moonGlow);

      final double la = mAlpha * labelGate;
      if (la > 0.04) {
        final tp = _text(tech[i], la * 0.85);
        tp.paint(canvas, ui.Offset(mx - tp.width / 2, my + moonR + 5));
      }
    }
  }

  void _paintComet(
      ui.Canvas canvas, CometState c, PubPackage package, double time) {
    final ui.Offset head = ui.Offset(c.x, c.y);

    // Particle tail: jittered points trailing the head.
    final Paint tail = Paint()..blendMode = ui.BlendMode.plus;
    const int n = 26;
    for (int i = 1; i <= n; i++) {
      final double f = i / n;
      final double px = c.x - c.dirX * i * 10.0 +
          math.sin(time * 3 + i * 0.7) * (1 + i * 0.16);
      final double py = c.y - c.dirY * i * 10.0 +
          math.cos(time * 2.6 + i * 0.9) * (1 + i * 0.13);
      tail.color = ui.Color.lerp(
        const ui.Color(0xFFBFE8FF),
        const ui.Color(0xFF4D6BFF),
        f,
      )!
          .withValues(alpha: (1 - f) * 0.55 * c.alpha);
      canvas.drawCircle(ui.Offset(px, py), (1 - f) * 3.2 + 0.6, tail);
    }

    // Head: bright core + halo.
    final Paint halo = Paint()
      ..blendMode = ui.BlendMode.plus
      ..shader = ui.Gradient.radial(head, 26, [
        const ui.Color(0xFFEAF6FF).withValues(alpha: 0.9 * c.alpha),
        const ui.Color(0xFF9CC8FF).withValues(alpha: 0.25 * c.alpha),
        const ui.Color(0x00000000),
      ], const [
        0.0,
        0.35,
        1.0,
      ]);
    canvas.drawCircle(head, 26, halo);
    canvas.drawCircle(
        head,
        2.6,
        Paint()
          ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: c.alpha));

    // The comet carries its package name — that's the tap invitation.
    final tp = _text(package.name, 0.78 * c.alpha, fontSize: 11);
    tp.paint(canvas, ui.Offset(c.x + 18, c.y + 10));
  }
}
