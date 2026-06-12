import 'dart:ui';

import 'package:aiportfoliowebsite/data/portfolio_data.dart';
import 'package:aiportfoliowebsite/engine/career_stream.dart';
import 'package:aiportfoliowebsite/engine/eras.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _desktop = Size(1440, 900);
const Size _phone = Size(390, 844);

/// Global t at which node [k] of [stream] is centered.
double _focusT(CareerStream stream, int k) =>
    Era.civilizations.start +
    stream.nodes[k].focusCenter * Era.civilizations.span;

void main() {
  group('CareerStream', () {
    test('one pulsar per role, ordered past to present', () {
      final stream = CareerStream(roles: kRoles, size: _desktop);
      expect(stream.nodes.length, kRoles.length);
      for (int i = 1; i < stream.nodes.length; i++) {
        expect(stream.nodes[i].pathFraction,
            greaterThan(stream.nodes[i - 1].pathFraction));
      }
      expect(stream.length, greaterThan(_desktop.width * 2));
    });

    test('era envelope gates the stream', () {
      expect(CareerStream.eraAlpha(0.50), 0);
      expect(CareerStream.eraAlpha(0.75), 1);
      expect(CareerStream.eraAlpha(0.95), 0);
    });

    test('the camera centers each node in turn', () {
      for (final size in [_desktop, _phone]) {
        final stream = CareerStream(roles: kRoles, size: size);
        for (int k = 0; k < stream.nodes.length; k++) {
          stream.update(t: _focusT(stream, k));
          expect(stream.nodes[k].focus, greaterThan(0.95),
              reason: 'node $k focused on $size');
          // Focused node sits near the focal column.
          expect((stream.nodes[k].x - stream.focalX).abs(),
              lessThan(size.width * 0.12),
              reason: 'node $k near focal on $size');
        }
      }
    });

    test('focus is exclusive between the two roles', () {
      final stream = CareerStream(roles: kRoles, size: _desktop);
      stream.update(t: _focusT(stream, 0));
      expect(stream.nodes[1].focus, lessThan(0.05));
      stream.update(t: _focusT(stream, 1));
      expect(stream.nodes[0].focus, lessThan(0.05));
    });

    test('approach ramps before focus and feeds the bullet stagger', () {
      final stream = CareerStream(roles: kRoles, size: _desktop);
      final double tFocus = _focusT(stream, 1);
      final double span = Era.civilizations.span;
      // Windows scale with node spacing; probe relative to it.
      final double spacing =
          stream.nodes[1].focusCenter - stream.nodes[0].focusCenter;
      stream.update(t: tFocus - 0.30 * spacing * span);
      final double early = stream.nodes[1].approach;
      stream.update(t: tFocus - 0.10 * spacing * span);
      final double later = stream.nodes[1].approach;
      expect(early, greaterThan(0));
      expect(later, greaterThanOrEqualTo(early));
      stream.update(t: tFocus);
      expect(stream.nodes[1].approach, 1);
    });

    test('pure function of t: rewinding reproduces poses', () {
      final stream = CareerStream(roles: kRoles, size: _desktop);
      stream.update(t: 0.75);
      final double x = stream.nodes[0].x;
      final double cam = stream.cameraX;
      stream.update(t: 0.68);
      stream.update(t: 0.75);
      expect(stream.nodes[0].x, x);
      expect(stream.cameraX, cam);
    });
  });
}
