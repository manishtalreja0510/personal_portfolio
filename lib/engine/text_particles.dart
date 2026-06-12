import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Rasterizes [text] in [style] and samples its opaque pixels on a
/// grid, returning points relative to the text's center. These become
/// the assembly targets that Big Bang debris converges onto to spell
/// the hero name.
Future<List<ui.Offset>> sampleTextPoints(
  String text,
  TextStyle style, {
  double stride = 4.0,
  int maxPoints = 1200,
}) async {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  final int w = painter.width.ceil();
  final int h = painter.height.ceil();
  if (w == 0 || h == 0) return const [];

  final recorder = ui.PictureRecorder();
  painter.paint(ui.Canvas(recorder), ui.Offset.zero);
  final ui.Image image = await recorder.endRecording().toImage(w, h);
  final ByteData? data =
      await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  if (data == null) return const [];

  final points = <ui.Offset>[];
  for (double y = 0; y < h; y += stride) {
    final int rowBase = y.floor() * w;
    for (double x = 0; x < w; x += stride) {
      // Alpha channel of the RGBA pixel.
      if (data.getUint8((rowBase + x.floor()) * 4 + 3) > 96) {
        points.add(ui.Offset(x - w / 2, y - h / 2));
      }
    }
  }
  if (points.length <= maxPoints) return points;
  // Thin evenly rather than truncating, so all glyphs stay covered.
  final double step = points.length / maxPoints;
  return [
    for (double i = 0; i < points.length; i += step) points[i.floor()],
  ];
}
