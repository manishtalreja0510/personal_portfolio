import 'dart:math' as math;
import 'dart:ui' as ui;

import '../data/portfolio_data.dart';
import 'eras.dart';

/// Identity colors for the four constellations, in data order.
const List<ui.Color> kConstellationColors = [
  ui.Color(0xFF66C4FF), // Flutter blue
  ui.Color(0xFFFFD9A0), // data gold
  ui.Color(0xFF7FE8D0), // integration teal
  ui.Color(0xFFB9A8FF), // outer violet
];

/// What the UI needs to know about the star under the pointer.
class SkillHover {
  const SkillHover({
    required this.index,
    required this.skill,
    required this.constellationName,
    required this.color,
    required this.position,
  });

  final int index;
  final Skill skill;
  final String constellationName;
  final ui.Color color;
  final ui.Offset position;
}

class SkillStar {
  SkillStar({
    required this.skill,
    required this.constellation,
    required this.color,
    required this.baseX,
    required this.baseY,
    required this.scatterX,
    required this.scatterY,
    required this.stagger,
  });

  final Skill skill;
  final int constellation;
  final ui.Color color;

  /// Final layout position in pixels (for the size given at build).
  final double baseX, baseY;

  /// Where this star condenses in from, relative to its base.
  final double scatterX, scatterY;

  /// Formation order within the era, 0..1.
  final double stagger;

  // Per-frame state, written by [SkillStars.update].
  double x = 0, y = 0;
  double alpha = 0;
  double flare = 0;

  double get mass => skill.mass;
  double get coreRadius => 2.2 + 3.2 * mass;
  double get haloRadius => 16 + 26 * mass;
}

class ConstellationEdge {
  ConstellationEdge(this.a, this.b, this.stagger);

  /// Global star indices.
  final int a, b;

  /// Lines draw only after both endpoint stars have formed.
  final double stagger;
}

/// Layout and per-frame state for the skills era. Positions are a
/// pure function of `t` (formation reverses on rewind); only the
/// hover flare runs on dt-easing, like cursor gravity.
class SkillStars {
  SkillStars({
    required List<Constellation> constellations,
    required ui.Size size,
    int seed = 271,
  }) : _size = size {
    final rnd = math.Random(seed);
    final bool tall = size.height > size.width;
    final List<ui.Offset> anchors = tall
        ? const [
            ui.Offset(0.30, 0.22),
            ui.Offset(0.70, 0.38),
            ui.Offset(0.30, 0.56),
            ui.Offset(0.70, 0.72),
          ]
        : const [
            ui.Offset(0.24, 0.34),
            ui.Offset(0.74, 0.30),
            ui.Offset(0.27, 0.71),
            ui.Offset(0.76, 0.72),
          ];
    final double radius = (size.shortestSide * 0.17)
        .clamp(64.0, 175.0)
        .toDouble();

    for (int c = 0; c < constellations.length; c++) {
      final constellation = constellations[c];
      final ui.Offset anchor = anchors[c % anchors.length];
      final double ax = anchor.dx * size.width;
      final double ay = anchor.dy * size.height;
      final int firstIndex = stars.length;

      // Heaviest star becomes the hub; the rest ring around it.
      final ordered = [...constellation.stars]
        ..sort((a, b) => b.mass.compareTo(a.mass));
      for (int j = 0; j < ordered.length; j++) {
        final double angle =
            rnd.nextDouble() * math.pi * 2 + j * 2 * math.pi / ordered.length;
        final double dist = j == 0
            ? radius * 0.18 * rnd.nextDouble()
            : radius * (0.55 + 0.45 * rnd.nextDouble());
        final double scatterAngle = rnd.nextDouble() * math.pi * 2;
        final double scatterDist = 140 + 260 * rnd.nextDouble();
        stars.add(
          SkillStar(
            skill: ordered[j],
            constellation: c,
            color: kConstellationColors[c % kConstellationColors.length],
            baseX: ax + math.cos(angle) * dist,
            baseY: ay + math.sin(angle) * dist,
            scatterX: math.cos(scatterAngle) * scatterDist,
            scatterY: math.sin(scatterAngle) * scatterDist,
            stagger: (c * 0.12 + j * 0.045).clamp(0.0, 1.0),
          ),
        );
      }
      _addMstEdges(firstIndex, stars.length);
    }
  }

  final ui.Size _size;
  final List<SkillStar> stars = [];
  final List<ConstellationEdge> edges = [];

  /// Global visibility of the era: condenses in while the hero name
  /// is still dispersing (debris becomes stars), gone before planets.
  static double eraAlpha(double t) =>
      smoothstep(phase(t, 0.19, 0.25)) *
      (1 - smoothstep(phase(t, 0.345, 0.39)));

  /// Minimum spanning tree over one constellation's stars — organic
  /// constellation lines without hand-authoring.
  void _addMstEdges(int from, int to) {
    final int n = to - from;
    if (n < 2) return;
    final inTree = <int>{from};
    while (inTree.length < n) {
      double best = double.infinity;
      int bestA = from, bestB = from;
      for (final a in inTree) {
        for (int b = from; b < to; b++) {
          if (inTree.contains(b)) continue;
          final double dx = stars[a].baseX - stars[b].baseX;
          final double dy = stars[a].baseY - stars[b].baseY;
          final double d2 = dx * dx + dy * dy;
          if (d2 < best) {
            best = d2;
            bestA = a;
            bestB = b;
          }
        }
      }
      inTree.add(bestB);
      edges.add(
        ConstellationEdge(
          bestA,
          bestB,
          math.max(stars[bestA].stagger, stars[bestB].stagger),
        ),
      );
    }
  }

  /// Advances flares by [dt], recomputes positions for scroll-time
  /// [t], and returns the index of the star under [pointer] (if any).
  /// [highlight] is the star currently flaring (hovered or pinned).
  int? update({
    required double dt,
    required double t,
    ui.Offset? pointer,
    int? highlight,
  }) {
    final double a = eraAlpha(t);
    final double p = Era.stellar.progress(t);
    // The whole field drifts up slightly as the era passes, and
    // spreads outward as the camera flies through it on exit.
    final double drift = (0.5 - p) * _size.height * 0.10;
    final double spread = 1 + 0.25 * smoothstep(phase(t, 0.34, 0.39));
    final double cx = _size.width / 2;
    final double cy = _size.height / 2;
    final double ease = 1 - math.exp(-10 * dt);

    int? hovered;
    double bestDist = double.infinity;
    for (int i = 0; i < stars.length; i++) {
      final SkillStar s = stars[i];
      final double form = smoothstep(
        phase(p, 0.18 + s.stagger * 0.16, 0.34 + s.stagger * 0.16),
      );
      final double bx = cx + (s.baseX - cx) * spread;
      final double by = cy + (s.baseY - cy) * spread + drift;
      s.x = bx + s.scatterX * (1 - form);
      s.y = by + s.scatterY * (1 - form);
      s.alpha = form * a * (0.55 + 0.45 * s.mass);
      s.flare += ((i == highlight ? 1.0 : 0.0) - s.flare) * ease;

      if (pointer != null && a > 0.4 && form > 0.8) {
        final double dx = pointer.dx - s.x;
        final double dy = pointer.dy - s.y;
        final double d2 = dx * dx + dy * dy;
        final double r = math.max(26.0, s.haloRadius * 0.8);
        if (d2 < r * r && d2 < bestDist) {
          bestDist = d2;
          hovered = i;
        }
      }
    }
    return hovered;
  }

  SkillHover hoverInfo(int index, List<Constellation> constellations) {
    final SkillStar s = stars[index];
    return SkillHover(
      index: index,
      skill: s.skill,
      constellationName: constellations[s.constellation].name,
      color: s.color,
      position: ui.Offset(s.x, s.y),
    );
  }
}
