import 'dart:ui' as ui;

import '../data/portfolio_data.dart';
import 'eras.dart';

/// Node colors along the stream: the past glows warm, the middle of
/// the journey is neutral white, the present burns blue-white.
/// Sampled evenly across however many roles the resume holds.
const List<ui.Color> kPulsarColors = [
  ui.Color(0xFFFFD9A0),
  ui.Color(0xFFEDEFF2),
  ui.Color(0xFF9CC8FF),
];

ui.Color _pulsarColor(int index, int count) {
  if (count <= 1) return kPulsarColors.last;
  final double u = index / (count - 1) * (kPulsarColors.length - 1);
  final int lo = u.floor().clamp(0, kPulsarColors.length - 2);
  return ui.Color.lerp(kPulsarColors[lo], kPulsarColors[lo + 1], u - lo)!;
}

class PulsarNode {
  PulsarNode({
    required this.role,
    required this.color,
    required this.pathFraction,
    required this.focusCenter,
  });

  final Role role;
  final ui.Color color;

  /// Position along the stream, as a fraction of its length.
  final double pathFraction;

  /// Era-progress at which this node owns the camera.
  final double focusCenter;

  // Per-frame state, written by [CareerStream.update].
  double x = 0, y = 0;
  double focus = 0;

  /// Rising edge of the approach — drives the bullet stagger.
  double approach = 0;
}

/// The career light-stream: a fixed path in "stream space" (about
/// 2.3 viewports wide) that the camera pans along as the era
/// progresses. Node poses are pure functions of `t`; only the
/// flowing light rides on wall-time.
class CareerStream {
  CareerStream({required List<Role> roles, required ui.Size size})
      : _size = size {
    final double w = size.width;
    final double h = size.height;
    final bool tall = size.height > size.width;

    path = ui.Path();
    if (tall) {
      path.moveTo(-0.15 * w, 0.34 * h);
      path.cubicTo(0.40 * w, 0.24 * h, 0.80 * w, 0.40 * h, 1.20 * w, 0.30 * h);
      path.cubicTo(1.60 * w, 0.22 * h, 1.90 * w, 0.36 * h, 2.30 * w, 0.28 * h);
    } else {
      path.moveTo(-0.15 * w, 0.62 * h);
      path.cubicTo(0.20 * w, 0.70 * h, 0.35 * w, 0.38 * h, 0.62 * w, 0.44 * h);
      path.cubicTo(0.95 * w, 0.52 * h, 1.15 * w, 0.60 * h, 1.45 * w, 0.42 * h);
      path.cubicTo(1.70 * w, 0.28 * h, 1.95 * w, 0.40 * h, 2.15 * w, 0.34 * h);
    }
    metric = path.computeMetrics().first;
    length = metric.length;

    // Nodes spread between 28% and 72% of the stream, however many
    // roles the resume holds.
    nodes = [
      for (int i = 0; i < roles.length; i++)
        PulsarNode(
          role: roles[i],
          color: _pulsarColor(i, roles.length),
          pathFraction: roles.length == 1
              ? 0.5
              : 0.28 + 0.44 * i / (roles.length - 1),
          focusCenter: roles.length == 1
              ? 0.5
              : 0.28 + 0.44 * i / (roles.length - 1),
        ),
    ];
    // Focus/approach windows scale with node spacing so neighbouring
    // role cards never overlap, no matter how many roles there are.
    _spacing = roles.length > 1
        ? nodes[1].focusCenter - nodes[0].focusCenter
        : 0.44;
  }

  final ui.Size _size;
  late final ui.Path path;
  late final ui.PathMetric metric;
  late final double length;
  late final List<PulsarNode> nodes;
  late final double _spacing;

  /// Camera offset in stream space; painter translates by -cameraX.
  double cameraX = 0;
  double driftY = 0;

  double get focalX =>
      _size.height > _size.width ? _size.width * 0.50 : _size.width * 0.40;

  static double eraAlpha(double t) =>
      smoothstep(phase(t, 0.655, 0.70)) *
      (1 - smoothstep(phase(t, 0.835, 0.875)));

  ui.Offset pointAt(double fraction) {
    final ui.Tangent? tangent =
        metric.getTangentForOffset(fraction.clamp(0.0, 1.0) * length);
    return tangent?.position ?? ui.Offset.zero;
  }

  void update({required double t}) {
    final double p = Era.civilizations.progress(t);
    driftY = (0.5 - p) * _size.height * 0.04;

    // Camera travels node to node — piecewise, so it dwells on every
    // role in turn — with a slow constant drift on top so the stream
    // never sits entirely still.
    double anchorX = pointAt(nodes.first.pathFraction).dx;
    for (int i = 0; i + 1 < nodes.length; i++) {
      final double seg = smoothstep(phase(
        p,
        nodes[i].focusCenter + _spacing * 0.1,
        nodes[i + 1].focusCenter - _spacing * 0.1,
      ));
      anchorX += (pointAt(nodes[i + 1].pathFraction).dx -
              pointAt(nodes[i].pathFraction).dx) *
          seg;
    }
    cameraX = anchorX + (p - 0.5) * _size.width * 0.18 - focalX;

    for (final node in nodes) {
      final ui.Offset pos = pointAt(node.pathFraction);
      node.x = pos.dx - cameraX;
      node.y = pos.dy + driftY;
      final double d = (p - node.focusCenter).abs();
      node.focus =
          1 - smoothstep(phase(d, _spacing * 0.23, _spacing * 0.50));
      node.approach = smoothstep(phase(
              p,
              node.focusCenter - _spacing * 0.45,
              node.focusCenter - _spacing * 0.05)) *
          (1 -
              smoothstep(phase(
                  p,
                  node.focusCenter + _spacing * 0.27,
                  node.focusCenter + _spacing * 0.50)));
    }
  }
}
