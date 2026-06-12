import 'dart:ui' as ui;

import 'eras.dart';

/// Flutter brand blue, applied to every particle while the egg runs.
const int kFlutterBlue = 0x54C5F8;

/// The Flutter logo as two polygons (the official 166 × 210.6
/// viewBox): the top chevron and the bottom Z-stroke. Constellation
/// points are sampled along their outlines.
const List<List<ui.Offset>> _logoPolygons = [
  [
    ui.Offset(100.4, 0),
    ui.Offset(166, 0),
    ui.Offset(30.9, 131.3),
    ui.Offset(0, 100.4),
  ],
  [
    ui.Offset(100.4, 100.4),
    ui.Offset(45.4, 155.4),
    ui.Offset(100.4, 210.6),
    ui.Offset(166, 210.6),
    ui.Offset(110.8, 155.4),
    ui.Offset(166, 100.4),
  ],
];

const double _logoW = 166;
const double _logoH = 210.6;

/// Egg envelope: 0.6s rise, hold to 3s, 0.6s fall. Negative elapsed
/// (not yet triggered) clamps to 0.
double eggBlendAt(double elapsed) =>
    smoothstep(phase(elapsed, 0.0, 0.6)) *
    (1 - smoothstep(phase(elapsed, 3.0, 3.6)));

/// [count] points evenly spaced along the logo outlines, scaled to
/// ~half the viewport's short side and centered slightly above mid.
List<ui.Offset> sampleFlutterLogo({required ui.Size size, int count = 150}) {
  final double scale = size.shortestSide * 0.5 / _logoH;
  final ui.Offset origin = ui.Offset(
    size.width / 2 - _logoW * scale / 2,
    size.height * 0.46 - _logoH * scale / 2,
  );

  final List<double> perimeters = [
    for (final poly in _logoPolygons) _perimeter(poly),
  ];
  final double total = perimeters.fold(0, (a, b) => a + b);

  final out = <ui.Offset>[];
  for (int p = 0; p < _logoPolygons.length; p++) {
    final int n = p == _logoPolygons.length - 1
        ? count - out.length
        : (count * perimeters[p] / total).round();
    _walk(_logoPolygons[p], n, scale, origin, out);
  }
  return out;
}

double _perimeter(List<ui.Offset> poly) {
  double sum = 0;
  for (int e = 0; e < poly.length; e++) {
    sum += (poly[(e + 1) % poly.length] - poly[e]).distance;
  }
  return sum;
}

void _walk(List<ui.Offset> poly, int n, double scale, ui.Offset origin,
    List<ui.Offset> out) {
  final double perimeter = _perimeter(poly);
  for (int j = 0; j < n; j++) {
    double d = perimeter * j / n;
    bool placed = false;
    for (int e = 0; e < poly.length && !placed; e++) {
      final ui.Offset a = poly[e];
      final ui.Offset b = poly[(e + 1) % poly.length];
      final double len = (b - a).distance;
      if (d <= len) {
        final ui.Offset p = a + (b - a) * (d / len);
        out.add(origin + p * scale);
        placed = true;
      } else {
        d -= len;
      }
    }
    if (!placed) out.add(origin + poly.first * scale);
  }
}
