import 'dart:ui';

import 'package:aiportfoliowebsite/engine/finale.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _desktop = Size(1440, 900);
const Size _phone = Size(390, 844);

void main() {
  group('finale era envelopes', () {
    test('the Present Moment rises after the stream and yields to the finale',
        () {
      expect(presentAlpha(0.80), 0);
      expect(presentAlpha(0.92), 1);
      expect(presentAlpha(0.99), 0);
    });

    test('the new universe owns the very end of time', () {
      expect(contactAlpha(0.90), 0);
      expect(contactAlpha(1.0), 1);
    });
  });

  group('knight constellation', () {
    test('points stay inside the unit box', () {
      for (final p in kKnightPoints) {
        expect(p.dx, inInclusiveRange(0, 1));
        expect(p.dy, inInclusiveRange(0, 1));
      }
    });

    test('edges reference valid stars', () {
      for (final (a, b) in kKnightEdges) {
        expect(a, inInclusiveRange(0, kKnightPoints.length - 1));
        expect(b, inInclusiveRange(0, kKnightPoints.length - 1));
        expect(a == b, isFalse);
      }
    });

    test('layout keeps the knight on screen for both aspects', () {
      for (final size in [_desktop, _phone]) {
        final layout = knightLayout(size);
        for (final p in kKnightPoints) {
          final double x = layout.anchor.dx + p.dx * layout.scale;
          final double y = layout.anchor.dy + p.dy * layout.scale;
          expect(x, inInclusiveRange(0, size.width), reason: 'on $size');
          expect(y, inInclusiveRange(0, size.height), reason: 'on $size');
        }
      }
    });
  });

  group('contact orbit', () {
    test('bodies sit on the ellipse, evenly phased', () {
      final Offset center = newSingularityCenter(_desktop);
      final orbit = contactOrbitRadii(_desktop);
      final positions = <Offset>[];
      for (int i = 0; i < 5; i++) {
        final Offset pos = contactOrbitPosition(
          index: i,
          count: 5,
          time: 3.0,
          center: center,
          rx: orbit.rx,
          ry: orbit.ry,
        );
        positions.add(pos);
        final double ex = (pos.dx - center.dx) / orbit.rx;
        final double ey = (pos.dy - center.dy) / orbit.ry;
        expect(ex * ex + ey * ey, closeTo(1.0, 1e-6));
      }
      // All five distinct.
      for (int i = 0; i < positions.length; i++) {
        for (int j = i + 1; j < positions.length; j++) {
          expect((positions[i] - positions[j]).distance, greaterThan(20));
        }
      }
    });
  });
}
