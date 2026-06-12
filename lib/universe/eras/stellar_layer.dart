import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../engine/eras.dart';
import '../../engine/particle_engine.dart';
import '../../engine/skill_stars.dart';

/// Paints the Stellar Formation era: constellation lines that draw
/// themselves in, skill stars whose size/brightness map to mass,
/// hover flares with diffraction spikes, and star name labels.
///
/// Text is drawn via [TextPainter]s cached by (text, alpha-bucket),
/// so steady frames lay out zero text.
class StellarLayer {
  final Map<String, TextPainter> _textCache = {};

  TextPainter _text(String text, double alpha,
      {required double fontSize,
      required ui.Color color,
      double letterSpacing = 0.4,
      FontWeight weight = FontWeight.w400}) {
    // Quantize alpha into 16 buckets to keep the cache tiny.
    final int bucket = (alpha.clamp(0.0, 1.0) * 15).round();
    final String key = '$text|$bucket|$fontSize';
    return _textCache.putIfAbsent(key, () {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: GoogleFonts.spaceGrotesk(
            fontSize: fontSize,
            fontWeight: weight,
            letterSpacing: letterSpacing,
            color: color.withValues(alpha: color.a * bucket / 15),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  void paint(ui.Canvas canvas, ui.Size size, UniverseSimulation sim) {
    final SkillStars? skills = sim.skills;
    if (skills == null) return;
    final double t = sim.clock.value;
    final double a = SkillStars.eraAlpha(t);
    if (a <= 0.002) return;
    final double p = Era.stellar.progress(t);

    // --- constellation lines ---
    final Paint line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..blendMode = ui.BlendMode.plus;
    for (final edge in skills.edges) {
      final double draw = smoothstep(
          phase(p, 0.40 + edge.stagger * 0.12, 0.52 + edge.stagger * 0.12));
      if (draw <= 0.01) continue;
      final SkillStar sa = skills.stars[edge.a];
      final SkillStar sb = skills.stars[edge.b];
      final double glowBoost =
          0.5 * math.max(sa.flare, sb.flare); // hovered lines brighten
      line.color = sa.color
          .withValues(alpha: (0.20 + glowBoost) * a * draw);
      canvas.drawLine(
        ui.Offset(sa.x, sa.y),
        ui.Offset(sa.x + (sb.x - sa.x) * draw, sa.y + (sb.y - sa.y) * draw),
        line,
      );
    }

    // --- stars ---
    final Paint halo = Paint()..blendMode = ui.BlendMode.plus;
    final Paint core = Paint();
    final Paint spike = Paint()
      ..strokeWidth = 1.1
      ..blendMode = ui.BlendMode.plus
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2);
    for (final s in skills.stars) {
      if (s.alpha <= 0.01) continue;
      final ui.Offset c = ui.Offset(s.x, s.y);
      final double haloR = s.haloRadius * (1 + 0.6 * s.flare);
      halo.shader = ui.Gradient.radial(c, haloR, [
        s.color.withValues(alpha: 0.50 * s.alpha),
        s.color.withValues(alpha: 0.10 * s.alpha),
        const ui.Color(0x00000000),
      ], const [
        0.0,
        0.35,
        1.0,
      ]);
      canvas.drawCircle(c, haloR, halo);

      core.color = const ui.Color(0xFFFFFFFF)
          .withValues(alpha: (0.85 + 0.15 * s.flare) * s.alpha);
      canvas.drawCircle(c, s.coreRadius * (1 + 0.25 * s.flare), core);

      if (s.flare > 0.02) {
        final double len = (18 + 30 * s.mass) * s.flare;
        spike.color = const ui.Color(0xFFFFFFFF)
            .withValues(alpha: 0.65 * s.flare * s.alpha);
        canvas.drawLine(
            c.translate(-len, 0), c.translate(len, 0), spike);
        canvas.drawLine(
            c.translate(0, -len), c.translate(0, len), spike);
      }

      // --- name label beneath the star ---
      final double labelAlpha = s.alpha * (0.42 + 0.55 * s.flare);
      if (labelAlpha > 0.03) {
        final tp = _text(s.skill.name, labelAlpha,
            fontSize: 11.5, color: const ui.Color(0xFFFFFFFF));
        tp.paint(
            canvas,
            ui.Offset(
                s.x - tp.width / 2, s.y + s.haloRadius * 0.5 + 8));
      }
    }
  }
}
