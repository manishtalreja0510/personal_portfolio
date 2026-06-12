import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/portfolio_data.dart';
import '../engine/eras.dart';
import '../engine/particle_engine.dart';
import '../engine/scroll_engine.dart';
import '../engine/text_particles.dart';
import 'eras/civilizations_overlay.dart';
import 'eras/contact_overlay.dart';
import 'eras/hero_overlay.dart';
import 'eras/planetary_overlay.dart';
import 'eras/present_overlay.dart';
import 'eras/stellar_overlay.dart';
import 'universe_painter.dart';

/// The single scroll-driven cinematic page. The visible universe is
/// painted in a fixed fullscreen layer; an invisible scrollable on
/// top only supplies scroll physics and feeds the [UniverseClock].
class UniversePage extends StatefulWidget {
  const UniversePage({super.key});

  @override
  State<UniversePage> createState() => _UniversePageState();
}

class _UniversePageState extends State<UniversePage>
    with SingleTickerProviderStateMixin {
  late final UniverseClock _clock;
  late final UniverseSimulation _sim;
  Size _heroSize = Size.zero;
  Offset _downPosition = Offset.zero;
  int _downTimeMs = 0;

  @override
  void initState() {
    super.initState();
    _clock = UniverseClock();
    _sim = UniverseSimulation(_clock)..attach(this);
  }

  /// Manual tap detection on the raw pointer stream: the scroll
  /// surface owns all gestures, so "taps" are downs that neither
  /// moved nor lingered. Routed to the simulation for star pinning.
  void _handleUp(PointerUpEvent event) {
    if (event.kind != PointerDeviceKind.mouse) _sim.pointer = null;
    final int elapsed =
        DateTime.now().millisecondsSinceEpoch - _downTimeMs;
    if (elapsed < 350 &&
        (event.localPosition - _downPosition).distance < 14) {
      _sim.tapAt(event.localPosition);
    }
  }

  /// Re-rasterizes the hero name into particle targets whenever the
  /// viewport changes (font size is responsive). Async: until it
  /// lands, the burst is pure debris, which is fine for a few frames.
  void _maybeRegenHeroTargets(Size size) {
    if ((size.width - _heroSize.width).abs() < 1 &&
        (size.height - _heroSize.height).abs() < 1) {
      return;
    }
    _heroSize = size;
    final TextStyle style = heroNameStyle(size.width);
    Future(() async {
      // Make sure Orbitron is actually loaded before rasterizing,
      // or the targets would trace the fallback font's glyphs.
      try {
        await GoogleFonts.pendingFonts();
      } catch (_) {}
      final points = await sampleTextPoints(
        kHeroName,
        style,
        stride: size.width < 700 ? 2.5 : 3,
        maxPoints: _sim.nameTargetBudget,
      );
      if (!mounted || _heroSize != size) return;
      _sim.setNameTargets(
        points,
        Offset(size.width / 2, size.height * kBangCenterYFraction),
      );
    });
  }

  @override
  void dispose() {
    _sim.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          _sim.setViewport(constraints.biggest);
          _maybeRegenHeroTargets(constraints.biggest);
          // Raw pointer tracking feeds cursor gravity: hover/drag on
          // desktop, touch points on mobile. The Listener wraps the
          // scroll surface, so scrolling and gravity coexist.
          return Listener(
            onPointerHover: (e) => _sim.pointer = e.localPosition,
            onPointerMove: (e) => _sim.pointer = e.localPosition,
            onPointerDown: (e) {
              _sim.pointer = e.localPosition;
              _downPosition = e.localPosition;
              _downTimeMs = DateTime.now().millisecondsSinceEpoch;
            },
            onPointerUp: _handleUp,
            onPointerCancel: (_) => _sim.pointer = null,
            child: MouseRegion(
              onExit: (_) => _sim.pointer = null,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // The living universe. Isolated behind a
                  // RepaintBoundary: it repaints every frame without
                  // ever re-laying-out the widgets above it.
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: UniversePainter(_sim),
                      isComplex: true,
                      willChange: true,
                    ),
                  ),
                  // Era scaffolding (phase a) — replaced era by era.
                  RepaintBoundary(
                    child: ValueListenableBuilder<double>(
                      valueListenable: _clock,
                      builder: (context, t, _) => _EraPlaceholderView(t: t),
                    ),
                  ),
                  // Singularity caption, scroll hint, hero subtitle.
                  RepaintBoundary(
                    child: HeroOverlay(clock: _clock),
                  ),
                  // Stellar era: heading, cosmic facts, skill cards.
                  RepaintBoundary(
                    child: StellarOverlay(sim: _sim),
                  ),
                  // Planetary era heading (non-interactive).
                  RepaintBoundary(
                    child: PlanetaryOverlay(sim: _sim),
                  ),
                  // Career light-stream: heading and role cards.
                  RepaintBoundary(
                    child: CivilizationsOverlay(sim: _sim),
                  ),
                  // The Present Moment: about, education, hobbies.
                  RepaintBoundary(
                    child: PresentOverlay(clock: _clock),
                  ),
                  // Invisible scroll surface — pure physics, no pixels.
                  ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      controller: _clock.scrollController,
                      physics: const ClampingScrollPhysics(),
                      child: SizedBox(
                        width: constraints.maxWidth,
                        height: constraints.maxHeight * UniverseClock.pages,
                      ),
                    ),
                  ),
                  // Tappable content lives ABOVE the scroll surface;
                  // ScrollPassthrough keeps wheel/drag moving time.
                  RepaintBoundary(
                    child: PlanetaryInteractive(sim: _sim),
                  ),
                  // The finale: orbiting contact links + singularity.
                  RepaintBoundary(
                    child: ContactOverlay(sim: _sim),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Temporary chrome: the debug HUD and the proto-scrubber. The
/// scrubber becomes the cosmic-ruler navigation in phase (h); the
/// HUD disappears entirely once tuning is done.
class _EraPlaceholderView extends StatelessWidget {
  const _EraPlaceholderView({required this.t});

  final double t;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _hud(Era.at(t)),
        _protoScrubber(),
      ],
    );
  }

  // Temporary debug readout — removed once the real eras land.
  Widget _hud(Era current) {
    return Positioned(
      left: 16,
      top: 16,
      child: Text(
        't ${t.toStringAsFixed(3)}  ·  ${current.label}  ·  '
        '${(current.progress(t) * 100).toStringAsFixed(0)}%',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  /// Minimal timeline bar with era tick marks — grows into the
  /// cosmic-ruler scrubber in phase (h).
  Widget _protoScrubber() {
    return Positioned(
      left: 32,
      right: 32,
      bottom: 28,
      child: SizedBox(
        height: 10,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double w = constraints.maxWidth;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 4,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 2,
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                for (final era in Era.values)
                  Positioned(
                    top: 2,
                    left: era.start * w,
                    child: Container(
                      width: 2,
                      height: 6,
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                Positioned(
                  top: 0,
                  left: (t * w - 5).clamp(0.0, w - 10),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.85),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
