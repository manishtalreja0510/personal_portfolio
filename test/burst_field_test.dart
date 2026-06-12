import 'dart:typed_data';
import 'dart:ui';

import 'package:aiportfoliowebsite/engine/particle_engine.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _viewport = Size(1200, 800);
const Offset _center = Offset(600, 336);
const double _half = kSpriteSize / 2;

Offset _pos(Float32List rst, int i) {
  final double s = rst[i * 4];
  return Offset(rst[i * 4 + 2] + s * _half, rst[i * 4 + 3] + s * _half);
}

int _alpha(Int32List colors, int i) => colors[i] >>> 24;

void main() {
  group('BurstField', () {
    final field = BurstField(count: 60);
    final rst = Float32List(60 * 4);
    final colors = Int32List(60);

    void update(double t, {List<Offset>? targets}) {
      field.updateInto(rst, colors,
          size: _viewport,
          t: t,
          time: 2.0,
          center: _center,
          nameTargets: targets);
    }

    test('invisible and gathered at the instant of detonation', () {
      update(0.05); // era progress 0
      for (int i = 0; i < 60; i += 7) {
        expect(_alpha(colors, i), 0);
        expect((_pos(rst, i) - _center).distance, lessThan(1.0));
      }
    });

    test('debris flies outward then fades by the era end', () {
      update(0.10); // mid-explosion
      double maxDist = 0;
      for (int i = 0; i < 60; i++) {
        final double d = (_pos(rst, i) - _center).distance;
        if (d > maxDist) maxDist = d;
      }
      expect(maxDist, greaterThan(100));

      update(0.15); // era end: pure debris is gone
      for (int i = 0; i < 60; i += 7) {
        expect(_alpha(colors, i), 0);
      }
    });

    test('name particles converge on their targets and glow', () {
      const targets = [Offset(-80, 0), Offset(80, 20)];
      update(0.15, targets: targets);
      for (int i = 0; i < targets.length; i++) {
        // Settled shimmer is ±0.6px around the exact target.
        expect((_pos(rst, i) - (_center + targets[i])).distance,
            lessThan(1.5));
        expect(_alpha(colors, i), greaterThan(200));
      }
      // Everyone else is still ordinary, faded debris.
      expect(_alpha(colors, 5), 0);
    });

    test('the name releases and disperses into the stellar era', () {
      const targets = [Offset(-80, 0), Offset(80, 20)];
      update(0.235, targets: targets);
      expect(_alpha(colors, 0), 0);
      expect(_alpha(colors, 1), 0);
    });

    test('pure function of t: rewinding reproduces frames exactly', () {
      const targets = [Offset(-80, 0)];
      update(0.12, targets: targets);
      final snapshotRst = Float32List.fromList(rst);
      final snapshotColors = Int32List.fromList(colors);

      update(0.07, targets: targets); // rewind
      update(0.12, targets: targets); // and forward again
      expect(rst, snapshotRst);
      expect(colors, snapshotColors);
    });
  });
}
