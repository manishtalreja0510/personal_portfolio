import 'dart:math' as math;
import 'dart:ui' as ui;

import 'eras.dart';

/// Shared math for the last two eras, used by the painter, the
/// overlays, and tests alike so geometry always agrees.

double presentAlpha(double t) =>
    smoothstep(phase(t, 0.855, 0.89)) *
    (1 - smoothstep(phase(t, 0.945, 0.975)));

double contactAlpha(double t) => smoothstep(phase(t, 0.952, 0.985));

/// Where the new universe waits to be born.
ui.Offset newSingularityCenter(ui.Size size) => ui.Offset(
    size.width / 2,
    size.height * (size.height > size.width ? 0.40 : 0.45));

/// Flattened orbital ellipse for the contact bodies.
({double rx, double ry}) contactOrbitRadii(ui.Size size) {
  final double rx = size.height > size.width
      ? size.width * 0.36
      : math.min(size.width * 0.17, 250.0);
  return (rx: rx, ry: rx * 0.42);
}

/// Position of contact body [index] of [count] at wall-time [time].
ui.Offset contactOrbitPosition({
  required int index,
  required int count,
  required double time,
  required ui.Offset center,
  required double rx,
  required double ry,
}) {
  final double angle = time * 0.26 + index * 2 * math.pi / count;
  return center.translate(math.cos(angle) * rx, math.sin(angle) * ry);
}

// ----------------------------------------------------------------
// The knight constellation — the chess flourish of the About era.
// Hand-authored points in a unit box (y down), traced as a chess
// knight's profile; edges chain them into a constellation.
// ----------------------------------------------------------------

const List<ui.Offset> kKnightPoints = [
  ui.Offset(0.25, 0.92), // 0  base left
  ui.Offset(0.75, 0.92), // 1  base right
  ui.Offset(0.70, 0.72), // 2  back
  ui.Offset(0.66, 0.50), // 3  neck
  ui.Offset(0.62, 0.30), // 4  ear base
  ui.Offset(0.55, 0.12), // 5  ear tip
  ui.Offset(0.45, 0.22), // 6  forehead
  ui.Offset(0.30, 0.30), // 7  brow
  ui.Offset(0.12, 0.42), // 8  nose
  ui.Offset(0.18, 0.53), // 9  mouth
  ui.Offset(0.32, 0.56), // 10 jaw
  ui.Offset(0.42, 0.70), // 11 chest
  ui.Offset(0.42, 0.38), // 12 eye
];

const List<(int, int)> kKnightEdges = [
  (0, 1),
  (1, 2),
  (2, 3),
  (3, 4),
  (4, 5),
  (5, 6),
  (6, 7),
  (7, 8),
  (8, 9),
  (9, 10),
  (10, 11),
  (11, 0),
  (6, 12), // the eye hangs off the forehead
];

/// Knight placement: tucked to the side on desktop, small in the
/// upper-right on phones.
({ui.Offset anchor, double scale}) knightLayout(ui.Size size) {
  if (size.height > size.width) {
    return (
      anchor: ui.Offset(size.width * 0.70, size.height * 0.10),
      scale: size.width * 0.24,
    );
  }
  return (
    anchor: ui.Offset(size.width * 0.74, size.height * 0.28),
    scale: math.min(size.height * 0.20, 170.0),
  );
}
