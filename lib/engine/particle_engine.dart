import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../data/portfolio_data.dart';
import 'career_stream.dart';
import 'eras.dart';
import 'planet_system.dart';
import 'quality.dart';
import 'scroll_engine.dart';
import 'skill_stars.dart';

/// Side length of the shared glow sprite. Every particle on the site
/// is an instance of this one texture via [ui.Canvas.drawRawAtlas],
/// so a whole field costs a single draw call.
const int kSpriteSize = 64;

/// Vertical position of the Big Bang epicenter as a fraction of the
/// viewport height. The singularity pulses here, the explosion
/// detonates here, and the hero name assembles here — one continuous
/// place in space across all three beats.
const double kBangCenterYFraction = 0.42;

/// A soft-glow disc: hard bright core easing into a wide halo.
/// Tinted per-particle at draw time (atlas colors + additive paint).
Future<ui.Image> createGlowSprite({int size = kSpriteSize}) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  final center = ui.Offset(size / 2, size / 2);
  canvas.drawCircle(
    center,
    size / 2,
    ui.Paint()
      ..shader = ui.Gradient.radial(center, size / 2, const [
        ui.Color(0xFFFFFFFF),
        ui.Color(0xE6FFFFFF),
        ui.Color(0x33FFFFFF),
        ui.Color(0x00FFFFFF),
      ], const [
        0.0,
        0.15,
        0.45,
        1.0,
      ]),
  );
  return recorder.endRecording().toImage(size, size);
}

/// The background starfield: stars live at fixed positions in a unit
/// "world" space with a depth coordinate; scroll-time `t` moves the
/// camera through them with per-depth parallax (rewindable, since the
/// rest position is a pure function of `t`). On top of that rest
/// position sits a small displacement integrated with semi-implicit
/// Euler — that's the cursor-gravity wobble, which springs back to
/// zero when the cursor leaves.
///
/// Storage is structure-of-arrays in typed lists: cache-friendly and
/// garbage-free in the per-frame hot loop.
class StarField {
  StarField({required this.count, this.seed = 1380})
      : _x = Float32List(count),
        _y = Float32List(count),
        _z = Float32List(count),
        _radius = Float32List(count),
        _alpha = Float32List(count),
        _twFreq = Float32List(count),
        _twPhase = Float32List(count),
        _dx = Float32List(count),
        _dy = Float32List(count),
        _vx = Float32List(count),
        _vy = Float32List(count),
        _rgb = Int32List(count) {
    final rnd = math.Random(seed);
    for (int i = 0; i < count; i++) {
      _x[i] = rnd.nextDouble();
      _y[i] = rnd.nextDouble();
      final double z = rnd.nextDouble();
      _z[i] = z * z; // quadratic bias: most stars far away and small
      _radius[i] = (0.7 + 1.9 * _z[i]) * (0.7 + 0.6 * rnd.nextDouble());
      _alpha[i] = (0.35 + 0.65 * _z[i]) * (0.8 + 0.2 * rnd.nextDouble());
      _twFreq[i] = 0.5 + 1.5 * rnd.nextDouble();
      _twPhase[i] = rnd.nextDouble() * math.pi * 2;
      if (rnd.nextDouble() < 0.12) {
        _rgb[i] = 0xFFE2BE; // rare warm star
      } else {
        // cool white→blue-white range
        final double c = rnd.nextDouble();
        final int r = (200 + 55 * c).round();
        final int g = (214 + 41 * c).round();
        _rgb[i] = (r << 16) | (g << 8) | 0xFF;
      }
    }
  }

  final int count;
  final int seed;

  /// How far the nearest stars travel over the full scroll, in
  /// viewport heights. The knob for "speed of flight through space".
  static const double _travel = 5.0;

  /// Wrap margin in unit space so stars leave the screen before
  /// teleporting to the other edge.
  static const double _margin = 0.06;

  // Cursor-gravity feel. Equilibrium displacement is roughly
  // strength/spring ≈ a couple dozen pixels: present, not distracting.
  static const double _spring = 30.0;
  static const double _dampRate = 5.0;
  static const double _gravityRadius = 140.0;
  static const double _gravityStrength = 1300.0;

  final Float32List _x, _y, _z, _radius, _alpha, _twFreq, _twPhase;
  final Float32List _dx, _dy, _vx, _vy;
  final Int32List _rgb;

  static double _parallax(double z) => 0.15 + 0.85 * z;

  static double _wrap(double v) {
    const double span = 1.0 + 2 * _margin;
    double w = (v + _margin) % span;
    if (w < 0) w += span;
    return w - _margin;
  }

  /// Rest position of star [i] — pure function of scroll-time and
  /// wall-time (slow sideways drift keeps the field alive when idle).
  double restX(int i, ui.Size size, double time) =>
      _wrap(_x[i] + time * 0.004 * _parallax(_z[i])) * size.width;

  double restY(int i, ui.Size size, double t) =>
      _wrap(_y[i] - t * _travel * _parallax(_z[i])) * size.height;

  /// Advances physics by [dt] and writes draw data for
  /// [ui.Canvas.drawRawAtlas]: RSTransforms into [rst] (4 floats per
  /// star) and tint colors into [colors] (1 ARGB int per star).
  void updateInto(
    Float32List rst,
    Int32List colors, {
    required ui.Size size,
    required double t,
    required double time,
    required double dt,
    required double fieldAlpha,
    ui.Offset? pointer,
  }) {
    final bool hasPointer = pointer != null;
    final double damp = math.exp(-_dampRate * dt);
    final double px = pointer?.dx ?? 0;
    final double py = pointer?.dy ?? 0;
    const double r2max = _gravityRadius * _gravityRadius;
    const double half = kSpriteSize / 2;

    for (int i = 0; i < count; i++) {
      final double rx = restX(i, size, time);
      final double ry = restY(i, size, t);

      double dx = _dx[i], dy = _dy[i], vx = _vx[i], vy = _vy[i];
      if (hasPointer || dx != 0 || dy != 0 || vx != 0 || vy != 0) {
        double ax = -_spring * dx;
        double ay = -_spring * dy;
        if (hasPointer) {
          final double gx = px - (rx + dx);
          final double gy = py - (ry + dy);
          final double d2 = gx * gx + gy * gy;
          if (d2 < r2max && d2 > 1) {
            final double d = math.sqrt(d2);
            final double f = _gravityStrength * (1 - d / _gravityRadius) / d;
            ax += gx * f;
            ay += gy * f;
          }
        }
        vx = (vx + ax * dt) * damp;
        vy = (vy + ay * dt) * damp;
        dx += vx * dt;
        dy += vy * dt;
        // Settled and unprovoked → snap to rest so the fast path
        // (skip all physics) takes over next frame.
        if (!hasPointer &&
            vx.abs() < 0.01 &&
            vy.abs() < 0.01 &&
            dx.abs() < 0.05 &&
            dy.abs() < 0.05) {
          vx = 0;
          vy = 0;
          dx = 0;
          dy = 0;
        }
        _dx[i] = dx;
        _dy[i] = dy;
        _vx[i] = vx;
        _vy[i] = vy;
      }

      final double s = _radius[i] * 5.0 / kSpriteSize;
      final int j = i * 4;
      rst[j] = s;
      rst[j + 1] = 0;
      rst[j + 2] = rx + dx - s * half;
      rst[j + 3] = ry + dy - s * half;

      final double tw = 0.75 + 0.25 * math.sin(time * _twFreq[i] + _twPhase[i]);
      final int a = (255 * _alpha[i] * tw * fieldAlpha).round().clamp(0, 255);
      colors[i] = (a << 24) | _rgb[i];
    }
  }
}

/// The Big Bang debris field. Every position is a pure function of
/// scroll-time: the explosion radius decelerates as the era
/// progresses, and the first `nameTargets.length` particles peel off
/// mid-era to assemble the hero name from the chaos. Scrolling
/// backward runs it all in reverse, gathering the universe back into
/// the singularity.
class BurstField {
  BurstField({required this.count, this.seed = 96})
      : _dirX = Float32List(count),
        _dirY = Float32List(count),
        _speed = Float32List(count),
        _radius = Float32List(count),
        _twFreq = Float32List(count),
        _twPhase = Float32List(count),
        _rgb = Int32List(count) {
    final rnd = math.Random(seed);
    for (int i = 0; i < count; i++) {
      final double angle = rnd.nextDouble() * math.pi * 2;
      _dirX[i] = math.cos(angle);
      _dirY[i] = math.sin(angle);
      // Many slow embers, a few screamers that clear the screen.
      _speed[i] =
          0.22 + 0.78 * math.pow(rnd.nextDouble(), 1.6).toDouble();
      final double r = rnd.nextDouble();
      _radius[i] = 0.9 + 2.0 * r * r;
      _twFreq[i] = 0.8 + 2.2 * rnd.nextDouble();
      _twPhase[i] = rnd.nextDouble() * math.pi * 2;
      final double heat = rnd.nextDouble();
      if (heat < 0.55) {
        _rgb[i] = 0xFFF3E2; // white-hot
      } else if (heat < 0.85) {
        _rgb[i] = 0xFFB36B; // ember orange
      } else {
        _rgb[i] = 0xBFD0FF; // blue-shifted
      }
    }
  }

  final int count;
  final int seed;

  final Float32List _dirX, _dirY, _speed, _radius, _twFreq, _twPhase;
  final Int32List _rgb;

  static int _lerpRgb(int a, int b, double t) {
    final int r =
        (((a >> 16) & 0xFF) + (((b >> 16) & 0xFF) - ((a >> 16) & 0xFF)) * t)
            .round();
    final int g =
        (((a >> 8) & 0xFF) + (((b >> 8) & 0xFF) - ((a >> 8) & 0xFF)) * t)
            .round();
    final int bl = ((a & 0xFF) + ((b & 0xFF) - (a & 0xFF)) * t).round();
    return (r << 16) | (g << 8) | bl;
  }

  /// Writes atlas draw data for scroll-time [t]. [nameTargets] are
  /// offsets relative to [center] (from [sampleTextPoints]); null or
  /// short lists simply leave more particles as plain debris.
  void updateInto(
    Float32List rst,
    Int32List colors, {
    required ui.Size size,
    required double t,
    required double time,
    required ui.Offset center,
    List<ui.Offset>? nameTargets,
  }) {
    final double p = Era.bigBang.progress(t);
    // Nothing exists the instant before detonation.
    final double born = smoothstep(phase(p, 0.0, 0.04));
    final double decel = 1 - math.pow(1 - p, 2.4).toDouble();
    final double maxR = size.longestSide * 0.75;
    // The assembled name holds through the hero beat, then releases
    // its particles as the stellar era takes over.
    final double nameHold = 1 - smoothstep(phase(t, 0.165, 0.235));
    final int nameCount = nameTargets?.length ?? 0;
    const double half = kSpriteSize / 2;

    for (int i = 0; i < count; i++) {
      final double burstR = _speed[i] * maxR * decel;
      double x = center.dx + _dirX[i] * burstR;
      double y = center.dy + _dirY[i] * burstR;
      double alpha;
      double sizeMul;
      int rgb = _rgb[i];

      if (i < nameCount) {
        final double asm = smoothstep(phase(p, 0.40, 0.94));
        final ui.Offset target = nameTargets![i];
        x += (center.dx + target.dx - x) * asm;
        y += (center.dy + target.dy - y) * asm;
        // Wild while flying, settling to a faint shimmer once placed.
        final double wob = (0.6 + 7.0 * (1 - asm)) * born;
        x += wob * math.sin(time * _twFreq[i] * 1.8 + _twPhase[i]);
        y += wob * math.cos(time * _twFreq[i] * 1.4 + _twPhase[i] * 1.7);
        final double release = 1 - nameHold;
        x += _dirX[i] * 120 * release;
        y += (_dirY[i] * 120 - 60) * release;
        alpha = born * (0.55 + 0.45 * asm) * nameHold;
        // Blend toward a uniform small radius as the glyph settles:
        // varied debris sizes read as chaos, uniform dots read as type.
        final double radBlend = _radius[i] + (1.5 - _radius[i]) * asm * 0.75;
        sizeMul = (0.9 + 0.4 * asm) * radBlend / _radius[i];
        rgb = _lerpRgb(rgb, 0xEAF1FF, asm);
      } else {
        final double flicker =
            0.8 + 0.2 * math.sin(time * _twFreq[i] * 3 + _twPhase[i]);
        alpha = born * (1 - smoothstep(phase(p, 0.30, 0.85))) * flicker;
        sizeMul = 1.5 - 0.9 * p;
      }

      final double s = _radius[i] * sizeMul * 5.0 / kSpriteSize;
      final int j = i * 4;
      rst[j] = s;
      rst[j + 1] = 0;
      rst[j + 2] = x - s * half;
      rst[j + 3] = y - s * half;
      final int a = (255 * alpha).round().clamp(0, 255);
      colors[i] = (a << 24) | rgb;
    }
  }
}

/// The single frame loop of the site. Each tick: read scroll, smooth
/// the clock, integrate particle physics, notify the painter. Owns
/// every piece of per-frame mutable state so widgets stay dumb.
class UniverseSimulation extends ChangeNotifier {
  UniverseSimulation(this.clock,
      {this.constellations = kConstellations,
      this.projects = kProjects,
      this.packages = kPackages,
      this.roles = kRoles});

  final UniverseClock clock;
  final List<Constellation> constellations;
  final List<Project> projects;
  final List<PubPackage> packages;
  final List<Role> roles;

  StarField? field;
  ui.Image? sprite;
  Float32List rstTransforms = Float32List(0);
  Float32List spriteRects = Float32List(0);
  Int32List spriteColors = Int32List(0);

  // --- Big Bang state ---
  BurstField? burst;
  Float32List burstRst = Float32List(0);
  Float32List burstRects = Float32List(0);
  Int32List burstColors = Int32List(0);

  /// True while the debris buffers hold meaningful data for this `t`.
  bool burstLive = false;

  /// Assembly targets for the hero name, relative to [bangCenter];
  /// null until the text raster finishes (debris just stays debris).
  List<ui.Offset>? nameTargets;

  /// Epicenter of everything: singularity, flash, and name.
  ui.Offset bangCenter = ui.Offset.zero;

  /// Compiled flash shader; null means "not loaded yet" or "failed",
  /// and the painter falls back to gradient rings either way.
  ui.FragmentShader? flashShader;

  /// Screen-shake offset, applied to the whole canvas by the painter.
  /// Amplitude is a pure function of `t` (rewindable); only the
  /// jitter phase rides on wall-time.
  double shakeX = 0;
  double shakeY = 0;

  // --- Stellar era state ---
  SkillStars? skills;

  // --- Planetary era state ---
  PlanetSystem? planets;

  // --- Civilizations era state ---
  CareerStream? career;

  // --- Finale state ---
  /// Wall-time when the contact singularity was last clicked; the
  /// painter draws a ~1.4s mini big-bang from this moment.
  double contactBurstStart = -10;

  /// Pointer hovering the new singularity (widgets set this; the
  /// painter brightens the halo in response).
  bool contactHover = false;

  void igniteContactBurst() {
    contactBurstStart = time;
  }

  /// The star under the pointer / pinned by tap, for the detail card.
  /// Widgets listen to this, not to the whole simulation.
  final ValueNotifier<SkillHover?> skillHover = ValueNotifier(null);
  int? _hoverIndex;
  int? _pinnedIndex;

  ui.Size viewport = ui.Size.zero;

  /// Cursor (desktop) or touch point (mobile) in screen coordinates;
  /// null when nothing is near the glass.
  ui.Offset? pointer;

  /// Wall-clock seconds since attach — drives ambient motion only
  /// (twinkle, idle drift). Scroll-time `t` drives everything else.
  double time = 0;

  /// Global starfield opacity: 0 before the Big Bang (stars don't
  /// exist yet), ramping to 1 as the universe ignites.
  double fieldAlpha = 0;

  Ticker? _ticker;
  Duration _lastTick = Duration.zero;

  void attach(TickerProvider vsync) {
    createGlowSprite().then((image) => sprite = image);
    _loadFlashShader();
    _ticker = vsync.createTicker(_onTick)..start();
  }

  Future<void> _loadFlashShader() async {
    try {
      final program =
          await ui.FragmentProgram.fromAsset('shaders/bigbang.frag');
      flashShader = program.fragmentShader();
    } catch (_) {
      // Painter falls back to gradient flash + chromatic rings.
    }
  }

  /// Hands the rasterized hero-name points to the burst field.
  void setNameTargets(List<ui.Offset> points, ui.Offset center) {
    nameTargets = points;
    bangCenter = center;
  }

  /// Called from build when layout size is known. Regenerates the
  /// field only when the particle budget actually changes; generation
  /// is seeded, so star N keeps its position across rebuilds.
  void setViewport(ui.Size size) {
    if (size == viewport || size.isEmpty) return;
    viewport = size;
    bangCenter =
        ui.Offset(size.width / 2, size.height * kBangCenterYFraction);
    final int budget = starBudget(size);
    if (field?.count != budget) {
      field = StarField(count: budget);
      rstTransforms = Float32List(budget * 4);
      spriteColors = Int32List(budget);
      spriteRects = _makeSpriteRects(budget);
    }
    // Generous: the burst only lives for one era, and the atlas path
    // doesn't blink at a few thousand instances. Most of these become
    // the name, so this budget is what makes the glyphs crisp.
    final int burstBudget = (budget * 2.2).round().clamp(900, 3600);
    if (burst?.count != burstBudget) {
      burst = BurstField(count: burstBudget);
      burstRst = Float32List(burstBudget * 4);
      burstColors = Int32List(burstBudget);
      burstRects = _makeSpriteRects(burstBudget);
    }
    skills = SkillStars(constellations: constellations, size: size);
    _hoverIndex = null;
    _pinnedIndex = null;
    planets =
        PlanetSystem(projects: projects, packages: packages, size: size);
    career = CareerStream(roles: roles, size: size);
  }

  /// Tap dispatch from the page (raw pointer taps, since the scroll
  /// surface owns gestures). Currently: pin/unpin a skill star.
  void tapAt(ui.Offset position) {
    final PlanetSystem? planetary = planets;
    if (planetary != null &&
        PlanetSystem.eraAlpha(clock.value) > 0 &&
        planetary.tapAt(position, clock.value)) {
      return;
    }
    final SkillStars? s = skills;
    if (s == null || SkillStars.eraAlpha(clock.value) < 0.4) return;
    int? hit;
    double best = double.infinity;
    for (int i = 0; i < s.stars.length; i++) {
      final double dx = position.dx - s.stars[i].x;
      final double dy = position.dy - s.stars[i].y;
      final double d2 = dx * dx + dy * dy;
      final double r = math.max(30.0, s.stars[i].haloRadius * 0.9);
      if (d2 < r * r && d2 < best) {
        best = d2;
        hit = i;
      }
    }
    _pinnedIndex = (hit == _pinnedIndex) ? null : hit;
  }

  /// Particles the burst can spare for the name without gutting the
  /// debris cloud — cap for the text sampler.
  int get nameTargetBudget => ((burst?.count ?? 0) * 0.7).floor();

  static Float32List _makeSpriteRects(int count) {
    final rects = Float32List(count * 4);
    for (int i = 0; i < count; i++) {
      rects[i * 4 + 2] = kSpriteSize.toDouble();
      rects[i * 4 + 3] = kSpriteSize.toDouble();
    }
    return rects;
  }

  void _onTick(Duration elapsed) {
    final double dt =
        ((elapsed - _lastTick).inMicroseconds / 1e6).clamp(0.0, 1 / 15);
    _lastTick = elapsed;
    time += dt;
    clock.tick(dt);

    final double t = clock.value;
    // The Present Moment is a calmer region of space: the starfield
    // dims as the journey settles, and stays soft into the finale.
    final double calm = (1 -
            0.45 * Era.present.presence(t) -
            0.25 * Era.newUniverse.presence(t))
        .clamp(0.3, 1.0);
    final double alpha = smoothstep(phase(t, 0.055, 0.16)) * calm;
    final bool starsLive = alpha > 0 || fieldAlpha > 0;
    fieldAlpha = alpha;

    final StarField? f = field;
    if (starsLive && f != null && !viewport.isEmpty) {
      f.updateInto(
        rstTransforms,
        spriteColors,
        size: viewport,
        t: t,
        time: time,
        dt: dt,
        fieldAlpha: alpha,
        pointer: pointer,
      );
    }

    // Debris exists from detonation until the name has fully
    // dispersed into the stellar era.
    final BurstField? b = burst;
    final bool bLive = t > 0.046 && t < 0.24 && b != null && !viewport.isEmpty;
    if (bLive) {
      b.updateInto(
        burstRst,
        burstColors,
        size: viewport,
        t: t,
        time: time,
        center: bangCenter,
        nameTargets: nameTargets,
      );
    }
    burstLive = bLive;

    final double bp = Era.bigBang.progress(t);
    final double shakeAmp =
        16 * math.exp(-bp * 7) * smoothstep(phase(bp, 0.0, 0.05));
    shakeX = shakeAmp * math.sin(time * 39);
    shakeY = 0.7 * shakeAmp * math.cos(time * 27);

    _tickSkills(dt, t);
    planets?.update(dt: dt, t: t, time: time);
    if (t > 0.62 && t < 0.90) career?.update(t: t);

    notifyListeners();
  }

  void _tickSkills(double dt, double t) {
    final SkillStars? s = skills;
    if (s == null) return;
    if (SkillStars.eraAlpha(t) <= 0) {
      _pinnedIndex = null;
      _setHover(null);
      return;
    }
    _hoverIndex = s.update(
      dt: dt,
      t: t,
      pointer: pointer,
      highlight: _hoverIndex ?? _pinnedIndex,
    );
    final int? active = _hoverIndex ?? _pinnedIndex;
    _setHover(active == null ? null : s.hoverInfo(active, constellations));
  }

  void _setHover(SkillHover? next) {
    final SkillHover? prev = skillHover.value;
    if (next == null && prev == null) return;
    if (next != null &&
        prev != null &&
        next.index == prev.index &&
        (next.position - prev.position).distance < 1.0) {
      return;
    }
    skillHover.value = next;
  }

  @override
  void dispose() {
    skillHover.dispose();
    _ticker?.dispose();
    super.dispose();
  }
}
