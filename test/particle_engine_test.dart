import 'dart:typed_data';
import 'dart:ui';

import 'package:aiportfoliowebsite/engine/particle_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _viewport = Size(800, 600);
const double _half = kSpriteSize / 2;

/// Screen-space center of star [i] as written into the atlas buffers.
Offset _center(Float32List rst, int i) {
  final double s = rst[i * 4];
  return Offset(rst[i * 4 + 2] + s * _half, rst[i * 4 + 3] + s * _half);
}

void main() {
  group('StarField', () {
    test('generation is deterministic and stable across budget changes', () {
      final a = StarField(count: 200);
      final b = StarField(count: 200);
      final c = StarField(count: 80);
      for (final i in [0, 7, 79]) {
        expect(a.restX(i, _viewport, 1.5), b.restX(i, _viewport, 1.5));
        expect(a.restY(i, _viewport, 0.4), b.restY(i, _viewport, 0.4));
        // A smaller budget keeps the same leading stars, so resizes
        // never make the sky "jump".
        expect(a.restX(i, _viewport, 1.5), c.restX(i, _viewport, 1.5));
      }
    });

    test('rest positions stay within the wrap margin of the screen', () {
      final field = StarField(count: 300);
      for (double t = 0; t <= 1; t += 0.13) {
        for (int i = 0; i < field.count; i += 17) {
          final double x = field.restX(i, _viewport, t * 50);
          final double y = field.restY(i, _viewport, t);
          expect(x, inInclusiveRange(-0.06 * 800, 1.06 * 800));
          expect(y, inInclusiveRange(-0.06 * 600, 1.06 * 600));
        }
      }
    });

    test('without a pointer, stars sit exactly at rest', () {
      final field = StarField(count: 100);
      final rst = Float32List(100 * 4);
      final colors = Int32List(100);
      for (int frame = 0; frame < 10; frame++) {
        field.updateInto(rst, colors,
            size: _viewport, t: 0.3, time: 2.0, dt: 1 / 60, fieldAlpha: 1.0);
      }
      for (final i in [0, 33, 99]) {
        final Offset c = _center(rst, i);
        expect(c.dx, closeTo(field.restX(i, _viewport, 2.0), 1e-3));
        expect(c.dy, closeTo(field.restY(i, _viewport, 0.3), 1e-3));
      }
    });

    test('a nearby pointer attracts, and stars spring back after', () {
      final field = StarField(count: 100);
      final rst = Float32List(100 * 4);
      final colors = Int32List(100);
      final Offset rest = Offset(
          field.restX(0, _viewport, 2.0), field.restY(0, _viewport, 0.3));
      final Offset pull = rest + const Offset(60, 0);

      for (int frame = 0; frame < 40; frame++) {
        field.updateInto(rst, colors,
            size: _viewport,
            t: 0.3,
            time: 2.0,
            dt: 1 / 60,
            fieldAlpha: 1.0,
            pointer: pull);
      }
      final double pulled = _center(rst, 0).dx - rest.dx;
      expect(pulled, greaterThan(2.0), reason: 'gravity should displace');
      expect(pulled, lessThan(60.0), reason: 'but never reach the cursor');

      // Pointer leaves → displacement decays back to rest.
      for (int frame = 0; frame < 240; frame++) {
        field.updateInto(rst, colors,
            size: _viewport, t: 0.3, time: 2.0, dt: 1 / 60, fieldAlpha: 1.0);
      }
      expect(_center(rst, 0).dx, closeTo(rest.dx, 0.5));
    });

    test('fieldAlpha 0 writes fully transparent colors', () {
      final field = StarField(count: 50);
      final rst = Float32List(50 * 4);
      final colors = Int32List(50);
      field.updateInto(rst, colors,
          size: _viewport, t: 0.0, time: 0.0, dt: 1 / 60, fieldAlpha: 0.0);
      for (int i = 0; i < 50; i++) {
        expect(colors[i] >>> 24, 0);
      }
    });
  });
}
