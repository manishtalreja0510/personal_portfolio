import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../engine/career_stream.dart';
import '../../engine/particle_engine.dart';

/// Paints the Age of Civilizations: the career light-stream (a
/// layered glowing path color-graded from warm past to blue-white
/// present), light particles flowing along it, pulsar nodes with
/// expanding rings and rotating beams, and the NOW terminus.
class CivilizationsLayer {
  final Map<String, TextPainter> _textCache = {};

  TextPainter _text(String text, double alpha, {double fontSize = 10.5}) {
    final int bucket = (alpha.clamp(0.0, 1.0) * 15).round();
    return _textCache.putIfAbsent('$text|$bucket|$fontSize', () {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: GoogleFonts.spaceGrotesk(
            fontSize: fontSize,
            letterSpacing: 2.4,
            color: ui.Color.fromRGBO(255, 255, 255, bucket / 15 * 0.7),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    });
  }

  void paint(ui.Canvas canvas, ui.Size size, UniverseSimulation sim) {
    final CareerStream? stream = sim.career;
    if (stream == null) return;
    final double a = CareerStream.eraAlpha(sim.clock.value);
    if (a <= 0.002) return;
    final double time = sim.time;

    canvas.save();
    canvas.translate(-stream.cameraX, stream.driftY);

    // --- the stream itself: three strokes, wide to fine ---
    final ui.Offset gradFrom = stream.pointAt(0.1);
    final ui.Offset gradTo = stream.pointAt(0.9);
    final ui.Color past = stream.nodes.first.color;
    final ui.Color present = stream.nodes.last.color;
    ui.Shader flowGradient(double alpha) => ui.Gradient.linear(
          gradFrom,
          gradTo,
          [
            past.withValues(alpha: alpha * a),
            present.withValues(alpha: alpha * a),
          ],
        );

    final Paint wide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26
      ..blendMode = ui.BlendMode.plus
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 16)
      ..shader = flowGradient(0.06);
    canvas.drawPath(stream.path, wide);

    final Paint mid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..blendMode = ui.BlendMode.plus
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5)
      ..shader = flowGradient(0.14);
    canvas.drawPath(stream.path, mid);

    final Paint core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..blendMode = ui.BlendMode.plus
      ..shader = flowGradient(0.40);
    canvas.drawPath(stream.path, core);

    // --- light flowing along the path, past → present ---
    final Paint mote = Paint()..blendMode = ui.BlendMode.plus;
    const int motes = 56;
    for (int i = 0; i < motes; i++) {
      final double u = (i / motes + time * 0.022) % 1.0;
      final ui.Offset pos = stream.pointAt(u);
      final double twinkle =
          0.55 + 0.45 * math.sin(time * 2.0 + i * 1.7);
      mote.color = ui.Color.lerp(past, present, u)!
          .withValues(alpha: 0.5 * a * twinkle);
      canvas.drawCircle(pos, 1.2 + 1.4 * twinkle, mote);
    }

    // --- start and end markers ---
    final ui.Offset origin = stream.pointAt(0.04);
    final tpStart = _text(
        stream.nodes.first.role.period.split('–').first.trim(), 0.5 * a);
    tpStart.paint(
        canvas, origin.translate(-tpStart.width / 2, 14));

    final ui.Offset terminus = stream.pointAt(0.96);
    final Paint nowGlow = Paint()
      ..blendMode = ui.BlendMode.plus
      ..shader = ui.Gradient.radial(terminus, 30, [
        present.withValues(alpha: 0.5 * a),
        const ui.Color(0x00000000),
      ]);
    canvas.drawCircle(terminus, 30, nowGlow);
    canvas.drawCircle(
        terminus,
        3,
        Paint()
          ..color = const ui.Color(0xFFFFFFFF).withValues(alpha: 0.9 * a));
    final tpNow = _text('NOW', 0.8 * a, fontSize: 11.5);
    tpNow.paint(canvas, terminus.translate(-tpNow.width / 2, 14));

    canvas.restore();

    // --- pulsars (already in screen space) ---
    for (int k = 0; k < stream.nodes.length; k++) {
      _paintPulsar(canvas, stream.nodes[k], k, time, a);
    }
  }

  void _paintPulsar(
      ui.Canvas canvas, PulsarNode node, int k, double time, double a) {
    final ui.Offset c = ui.Offset(node.x, node.y);
    final double presence = a * (0.45 + 0.55 * node.focus);
    final double pulse = 0.8 + 0.2 * math.sin(time * 2.6 + k * 2.1);

    // Rotating beams — the lighthouse signature of a pulsar.
    final double beamLen = 60 + 30 * node.focus;
    final double beamAngle = time * 0.35 + k * 1.3;
    final Paint beam = Paint()
      ..strokeWidth = 1.4
      ..blendMode = ui.BlendMode.plus
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3)
      ..color = node.color.withValues(alpha: 0.20 * presence);
    for (final double phaseOffset in const [0.0, math.pi]) {
      final double dx = math.cos(beamAngle + phaseOffset) * beamLen;
      final double dy = math.sin(beamAngle + phaseOffset) * beamLen;
      canvas.drawLine(c, c.translate(dx, dy), beam);
    }

    // Expanding rings, breathing out from the core.
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..blendMode = ui.BlendMode.plus;
    for (int j = 0; j < 2; j++) {
      final double rr = (time * 0.45 + j * 0.5) % 1.0;
      ring.color = node.color
          .withValues(alpha: (1 - rr) * 0.35 * presence * node.focus);
      canvas.drawCircle(c, 12 + rr * 46, ring);
    }

    // Halo + core.
    final double haloR = (26 + 14 * node.focus) * pulse;
    final Paint halo = Paint()
      ..blendMode = ui.BlendMode.plus
      ..shader = ui.Gradient.radial(c, haloR, [
        node.color.withValues(alpha: 0.75 * presence * pulse),
        node.color.withValues(alpha: 0.15 * presence),
        const ui.Color(0x00000000),
      ], const [
        0.0,
        0.4,
        1.0,
      ]);
    canvas.drawCircle(c, haloR, halo);
    canvas.drawCircle(
        c,
        3.4 + 1.6 * node.focus,
        Paint()
          ..color =
              const ui.Color(0xFFFFFFFF).withValues(alpha: presence));

    // Company name rides with the node even when its card is away.
    final tp = _text(node.role.company.toUpperCase(),
        presence * (0.35 + 0.3 * node.focus));
    tp.paint(canvas, c.translate(-tp.width / 2, haloR + 10));
  }
}
