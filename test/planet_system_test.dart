import 'dart:ui';

import 'package:aiportfoliowebsite/data/portfolio_data.dart';
import 'package:aiportfoliowebsite/engine/eras.dart';
import 'package:aiportfoliowebsite/engine/planet_system.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _desktop = Size(1440, 900);

/// Global t at which planet [k] is centered.
double _focusT(int k) =>
    Era.planetary.start + PlanetSystem.focusCenter(k) * Era.planetary.span;

PlanetSystem _system() => PlanetSystem(
    projects: kProjects, packages: kPackages, size: _desktop);

void main() {
  group('PlanetSpec', () {
    test('procedural looks are deterministic per project name', () {
      final a = PlanetSpec.fromProject(kProjects[0]);
      final b = PlanetSpec.fromProject(kProjects[0]);
      expect(a.bands, b.bands);
      expect(a.hasRing, b.hasRing);
      expect(a.sizeFactor, b.sizeFactor);
    });

    test('different projects grow different worlds', () {
      final a = PlanetSpec.fromProject(kProjects[0]);
      final b = PlanetSpec.fromProject(kProjects[1]);
      expect(a.bands[0] != b.bands[0] || a.bands[1] != b.bands[1], isTrue);
    });
  });

  group('PlanetSystem', () {
    test('era envelope gates everything', () {
      final ps = _system();
      ps.update(dt: 1 / 60, t: 0.30, time: 1);
      expect(PlanetSystem.eraAlpha(0.30), 0);
      for (final s in ps.states) {
        expect(s.alpha, 0);
      }
    });

    test('the camera focuses one planet at a time', () {
      final ps = _system();
      ps.update(dt: 1 / 60, t: _focusT(1), time: 1);
      expect(ps.states[1].focus, greaterThan(0.95));
      expect(ps.states[0].focus, lessThan(0.05));
      expect(ps.states[2].focus, lessThan(0.05));
      // The focused planet sits at the focal point.
      expect(ps.states[1].x, closeTo(ps.focal.dx, 1.0));
    });

    test('tap on the focused planet toggles the case-study zoom', () {
      final ps = _system();
      final double t = _focusT(2);
      ps.update(dt: 1 / 60, t: t, time: 1);
      final tapPos = Offset(ps.states[2].x, ps.states[2].y);

      expect(ps.tapAt(tapPos, t), isTrue);
      expect(ps.zoomIndex, 2);
      for (int i = 0; i < 60; i++) {
        ps.update(dt: 1 / 60, t: t, time: 1.0 + i / 60);
      }
      expect(ps.zoomEase, greaterThan(0.9));

      expect(ps.tapAt(tapPos, t), isTrue);
      expect(ps.zoomIndex, isNull);
    });

    test('scrolling away closes the zoom; empty tap clears state', () {
      final ps = _system();
      final double t = _focusT(0);
      ps.update(dt: 1 / 60, t: t, time: 1);
      ps.tapAt(Offset(ps.states[0].x, ps.states[0].y), t);
      expect(ps.zoomIndex, 0);

      ps.update(dt: 1 / 60, t: t + 0.05, time: 1.1);
      expect(ps.zoomIndex, isNull);

      ps.update(dt: 1 / 60, t: t, time: 1.2);
      expect(ps.tapAt(const Offset(5, 5), t), isFalse);
    });

    test('comets cruise through on wall-time and can be pinned', () {
      final ps = _system();
      final double t = _focusT(1);
      // Find a moment when comet 0 is active and well on screen.
      double? when;
      for (double time = 0; time < 19; time += 0.25) {
        ps.update(dt: 1 / 60, t: t, time: time);
        final c = ps.comets[0];
        if (c.active &&
            c.alpha > 0.5 &&
            c.x > 100 &&
            c.x < _desktop.width - 100) {
          when = time;
          break;
        }
      }
      expect(when, isNotNull, reason: 'comet 0 never crossed the screen');

      final c = ps.comets[0];
      expect(ps.tapAt(Offset(c.x, c.y), t), isTrue);
      expect(ps.pinnedComet, 0);
      expect(ps.tapAt(Offset(c.x, c.y), t), isTrue);
      expect(ps.pinnedComet, isNull);
    });
  });
}
