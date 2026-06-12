import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart' show HSVColor;

import '../data/portfolio_data.dart';
import 'eras.dart';

/// Procedural identity of one project planet, derived entirely from
/// the project name so every build of the site grows the same worlds.
class PlanetSpec {
  PlanetSpec({
    required this.project,
    required this.bands,
    required this.atmosphere,
    required this.deep,
    required this.hasRing,
    required this.ringTilt,
    required this.sizeFactor,
  });

  factory PlanetSpec.fromProject(Project project) {
    final int seed =
        project.name.codeUnits.fold(7, (a, c) => (a * 31 + c) & 0x7fffffff);
    final rnd = math.Random(seed);
    final double hue = rnd.nextDouble() * 360;
    final double sat = 0.40 + 0.25 * rnd.nextDouble();
    final double val = 0.50 + 0.20 * rnd.nextDouble();

    ui.Color band(double dh, double dv) => HSVColor.fromAHSV(
          1,
          (hue + dh) % 360,
          (sat + rnd.nextDouble() * 0.16 - 0.08).clamp(0.15, 0.9),
          (val + dv).clamp(0.22, 0.85),
        ).toColor();

    return PlanetSpec(
      project: project,
      bands: [
        band(0, 0.10),
        band(-14 + 10 * rnd.nextDouble(), -0.06),
        band(10 + 12 * rnd.nextDouble(), 0.02),
        band(-8 + 18 * rnd.nextDouble(), -0.14),
      ],
      atmosphere: HSVColor.fromAHSV(1, (hue + 24) % 360, 0.5, 0.85).toColor(),
      deep: HSVColor.fromAHSV(1, hue, sat * 0.9, 0.16).toColor(),
      hasRing: rnd.nextDouble() > 0.5,
      ringTilt: -0.38 + 0.3 * rnd.nextDouble(),
      sizeFactor: 0.85 + 0.3 * rnd.nextDouble(),
    );
  }

  final Project project;
  final List<ui.Color> bands;
  final ui.Color atmosphere;
  final ui.Color deep;
  final bool hasRing;
  final double ringTilt;
  final double sizeFactor;
}

/// Per-frame pose of a planet, written by [PlanetSystem.update].
class PlanetState {
  double x = 0, y = 0;
  double radius = 0;

  /// 1 when this planet owns the camera, 0 when off-stage.
  double focus = 0;

  /// Signed distance from the focus window center, in windows.
  double offset = 0;
  double alpha = 0;
}

class CometState {
  CometState(this.startX, this.startY, this.endX, this.endY, this.phase) {
    final double len =
        math.sqrt(math.pow(endX - startX, 2) + math.pow(endY - startY, 2));
    dirX = (endX - startX) / len;
    dirY = (endY - startY) / len;
  }

  final double startX, startY, endX, endY;

  /// Offset into the shared period, seconds.
  final double phase;

  /// Flight direction — constant per trajectory.
  late final double dirX, dirY;

  bool active = false;
  double x = 0, y = 0;
  double alpha = 0;
}

/// The Planetary Accretion era: a camera pan across four project
/// planets (poses are pure functions of `t`), a dt-eased zoom state
/// for the case-study view, and two pub.dev comets that cruise
/// through on wall-time while the era is active.
class PlanetSystem {
  PlanetSystem({
    required List<Project> projects,
    required this.packages,
    required this._size,
  })  : specs = [for (final p in projects) PlanetSpec.fromProject(p)],
        states = [for (final _ in projects) PlanetState()],
        comets = [
          CometState(-0.08, 0.22, 1.08, 0.50, 0.0),
          CometState(1.08, 0.14, -0.08, 0.58, 9.5),
        ];

  final ui.Size _size;
  final List<PlanetSpec> specs;
  final List<PlanetState> states;
  final List<PubPackage> packages;
  final List<CometState> comets;

  static const double _cometPeriod = 19.0;
  static const double _windowSpan = 0.225;

  /// Case-study zoom: which planet, how far along the ease.
  int? zoomIndex;
  double zoomEase = 0;
  double _zoomStartT = 0;

  /// Comet card pinned by tap.
  int? pinnedComet;

  bool get tall => _size.height > _size.width;

  /// Where the focused planet sits.
  ui.Offset get focal => tall
      ? ui.Offset(_size.width * 0.50, _size.height * 0.30)
      : ui.Offset(_size.width * 0.34, _size.height * 0.50);

  double get baseRadius => tall
      ? _size.width * 0.24
      : (_size.height * 0.20).clamp(90.0, 185.0).toDouble();

  static double eraAlpha(double t) =>
      smoothstep(phase(t, 0.355, 0.40)) *
      (1 - smoothstep(phase(t, 0.635, 0.675)));

  /// Era-progress at which planet [k] is centered on the camera.
  static double focusCenter(int k) => 0.16 + _windowSpan * k;

  void update({
    required double dt,
    required double t,
    required double time,
    bool reduceMotion = false,
  }) {
    final double a = eraAlpha(t);
    if (a <= 0) {
      zoomIndex = null;
      zoomEase = 0;
      pinnedComet = null;
      for (final s in states) {
        s.alpha = 0;
        s.focus = 0;
      }
      for (final c in comets) {
        c.active = false;
      }
      return;
    }

    // Scrolling away from a zoomed planet closes the case study.
    if (zoomIndex != null && (t - _zoomStartT).abs() > 0.03) {
      zoomIndex = null;
    }
    zoomEase += ((zoomIndex != null ? 1 : 0) - zoomEase) *
        (1 - math.exp(-8 * dt));
    if (zoomEase < 0.001 && zoomIndex == null) zoomEase = 0;

    final double p = Era.planetary.progress(t);
    for (int k = 0; k < states.length; k++) {
      final PlanetState s = states[k];
      s.offset = (p - focusCenter(k)) / _windowSpan;
      s.focus = 1 - smoothstep(phase(s.offset.abs(), 0.20, 0.50));
      // The camera pans: planets slide opposite to scroll direction.
      double x = focal.dx - s.offset * _size.width * 1.45;
      double y = focal.dy + (k.isEven ? -1 : 1) * _size.height * 0.03;
      double radius = baseRadius * specs[k].sizeFactor;
      if (k == zoomIndex || zoomEase > 0) {
        final double z = (k == zoomIndex) ? zoomEase : 0;
        final ui.Offset zoomedAt = tall
            ? ui.Offset(_size.width * 0.50, _size.height * 0.24)
            : ui.Offset(_size.width * 0.28, _size.height * 0.46);
        x += (zoomedAt.dx - x) * z;
        y += (zoomedAt.dy - y) * z;
        radius *= 1 + 0.55 * z;
      }
      s.x = x;
      s.y = y;
      s.radius = radius;
      s.alpha = a * (1 - smoothstep(phase(s.offset.abs(), 0.55, 0.85)));
    }

    if (reduceMotion) {
      // No streaking under reduced motion: the comets park as
      // steady glowing bodies, still labeled and tappable.
      const List<ui.Offset> parked = [
        ui.Offset(0.18, 0.16),
        ui.Offset(0.82, 0.13),
      ];
      for (int i = 0; i < comets.length; i++) {
        final CometState c = comets[i];
        final ui.Offset spot = parked[i % parked.length];
        c.x = spot.dx * _size.width;
        c.y = spot.dy * _size.height;
        c.alpha = a * 0.9;
        c.active = true;
      }
      return;
    }

    for (final c in comets) {
      final double u =
          ((time + c.phase) % _cometPeriod) / _cometPeriod;
      if (u >= 0.5) {
        c.active = false;
        continue;
      }
      final double along = u / 0.5;
      c.x = (c.startX + (c.endX - c.startX) * along) * _size.width;
      c.y = (c.startY + (c.endY - c.startY) * along) * _size.height +
          math.sin(time * 1.3 + c.phase) * 6;
      c.alpha = a *
          smoothstep(phase(along, 0.0, 0.12)) *
          (1 - smoothstep(phase(along, 0.88, 1.0)));
      c.active = c.alpha > 0.01;
    }
  }

  /// Returns true if the tap hit something in this era.
  bool tapAt(ui.Offset pos, double t) {
    if (eraAlpha(t) < 0.4) {
      zoomIndex = null;
      pinnedComet = null;
      return false;
    }
    // Comets first: smaller, rarer, on top.
    for (int c = 0; c < comets.length; c++) {
      if (!comets[c].active) continue;
      final double dx = pos.dx - comets[c].x;
      final double dy = pos.dy - comets[c].y;
      if (dx * dx + dy * dy < 48 * 48) {
        pinnedComet = (pinnedComet == c) ? null : c;
        return true;
      }
    }
    for (int k = 0; k < states.length; k++) {
      final PlanetState s = states[k];
      if (s.focus < 0.35) continue;
      final double dx = pos.dx - s.x;
      final double dy = pos.dy - s.y;
      final double r = s.radius * 1.15;
      if (dx * dx + dy * dy < r * r) {
        if (zoomIndex == k) {
          zoomIndex = null;
        } else {
          zoomIndex = k;
          _zoomStartT = t;
        }
        return true;
      }
    }
    final bool consumed = zoomIndex != null || pinnedComet != null;
    zoomIndex = null;
    pinnedComet = null;
    return consumed;
  }
}
