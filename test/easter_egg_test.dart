import 'dart:typed_data';
import 'dart:ui';

import 'package:aiportfoliowebsite/engine/easter_egg.dart';
import 'package:aiportfoliowebsite/engine/eras.dart';
import 'package:aiportfoliowebsite/engine/particle_engine.dart';
import 'package:aiportfoliowebsite/ui/cosmic_scrubber.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _viewport = Size(1440, 900);

void main() {
  group('easter egg', () {
    test('blend envelope: rise, hold, fall, gone', () {
      expect(eggBlendAt(-1), 0);
      expect(eggBlendAt(0), 0);
      expect(eggBlendAt(0.6), 1);
      expect(eggBlendAt(2.0), 1);
      expect(eggBlendAt(3.6), 0);
      expect(eggBlendAt(100), 0);
    });

    test('logo sampling returns the requested count, centered', () {
      final points = sampleFlutterLogo(size: _viewport, count: 150);
      expect(points.length, 150);
      final double half = _viewport.shortestSide * 0.5;
      for (final p in points) {
        expect((p.dx - _viewport.width / 2).abs(), lessThan(half));
        expect((p.dy - _viewport.height * 0.46).abs(), lessThan(half));
      }
      // Two distinct strokes — points are not all collinear.
      final double minY =
          points.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
      final double maxY =
          points.map((p) => p.dy).reduce((a, b) => a > b ? a : b);
      expect(maxY - minY, greaterThan(100));
    });

    test('full blend pins chosen stars to targets and turns them blue', () {
      final field = StarField(count: 50);
      final rst = Float32List(50 * 4);
      final colors = Int32List(50);
      final targets = Float32List.fromList([300.0, 400.0, 500.0, 200.0]);

      field.updateInto(rst, colors,
          size: _viewport,
          t: 0.0, // pre-bang: egg must still show
          time: 1.0,
          dt: 1 / 60,
          fieldAlpha: 0.9,
          eggBlend: 1.0,
          eggTargets: targets,
          eggCount: 2);

      for (int i = 0; i < 2; i++) {
        final double s = rst[i * 4];
        final double cx = rst[i * 4 + 2] + s * kSpriteSize / 2;
        final double cy = rst[i * 4 + 3] + s * kSpriteSize / 2;
        expect(cx, closeTo(targets[i * 2], 0.001));
        expect(cy, closeTo(targets[i * 2 + 1], 0.001));
        // Tinted 90% toward Flutter blue, fully bright.
        expect(colors[i] & 0xFF, greaterThan(0xB0),
            reason: 'chosen star should lean Flutter blue');
        expect(colors[i] >>> 24, greaterThan(200));
      }
      // Unchosen stars are tinted too.
      final int rgb = colors[10] & 0xFFFFFF;
      final int blue = rgb & 0xFF;
      expect(blue, greaterThan(0xB0), reason: 'should lean Flutter blue');
    });
  });

  group('cosmic scrubber', () {
    test('every era has a date on the ruler', () {
      for (final era in Era.values) {
        expect(kEraDates[era], isNotNull, reason: era.name);
        expect(kEraDates[era], isNotEmpty);
      }
    });
  });
}
