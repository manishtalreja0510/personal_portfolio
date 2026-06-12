import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show KeyDownEvent, KeyEvent;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/portfolio_data.dart';
import '../engine/eras.dart';
import '../engine/particle_engine.dart';
import '../engine/scroll_engine.dart';
import '../engine/text_particles.dart';
import '../ui/cosmic_scrubber.dart';
import '../ui/motion_toggle.dart';
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
  final FocusNode _focusNode = FocusNode();
  Size _heroSize = Size.zero;
  Offset _downPosition = Offset.zero;
  int _downTimeMs = 0;
  String _typed = '';
  final List<int> _singularityTapsMs = [];

  bool _appliedSystemMotionPref = false;
  static const String _kMotionPrefKey = 'reduceMotion';

  @override
  void initState() {
    super.initState();
    _clock = UniverseClock();
    _sim = UniverseSimulation(_clock)..attach(this);
    _restoreMotionPref();
  }

  /// Precedence: a stored choice beats the OS default (which
  /// didChangeDependencies applies first, synchronously). Only
  /// changes made after restore — i.e. explicit toggles — persist.
  Future<void> _restoreMotionPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final bool? stored = prefs.getBool(_kMotionPrefKey);
    if (stored != null) _sim.reduceMotion.value = stored;
    _sim.reduceMotion.addListener(() {
      prefs.setBool(_kMotionPrefKey, _sim.reduceMotion.value);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honor prefers-reduced-motion once on startup; the toggle can
    // override it afterwards.
    if (!_appliedSystemMotionPref) {
      _appliedSystemMotionPref = true;
      if (MediaQuery.of(context).disableAnimations) {
        _sim.reduceMotion.value = true;
      }
    }
  }

  /// Desktop easter egg: a rolling buffer of typed characters.
  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final String? ch = event.character;
    if (ch == null || ch.isEmpty) return;
    _typed = (_typed + ch.toLowerCase());
    if (_typed.length > 12) _typed = _typed.substring(_typed.length - 12);
    if (_typed.endsWith('flutter')) {
      _typed = '';
      _sim.triggerEasterEgg();
    }
  }

  /// Mobile easter egg: five taps on the landing singularity.
  void _countSingularityTap(Offset position) {
    if (_clock.value >= Era.bigBang.start) return;
    if ((position - _sim.bangCenter).distance > 90) return;
    final int now = DateTime.now().millisecondsSinceEpoch;
    _singularityTapsMs.add(now);
    _singularityTapsMs.removeWhere((ms) => now - ms > 4000);
    if (_singularityTapsMs.length >= 5) {
      _singularityTapsMs.clear();
      _sim.triggerEasterEgg();
    }
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
      _countSingularityTap(event.localPosition);
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
    _focusNode.dispose();
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
          // scroll surface, so scrolling and gravity coexist. The
          // KeyboardListener above it catches "flutter" being typed.
          return KeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKeyEvent: _handleKey,
            child: Listener(
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
                  // Singularity caption, scroll hint, hero subtitle.
                  RepaintBoundary(
                    child: HeroOverlay(sim: _sim),
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
                  // The cosmic ruler — the site's only navigation.
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 12 + MediaQuery.paddingOf(context).bottom,
                    height: 64,
                    child: CosmicScrubber(clock: _clock),
                  ),
                  // Accessibility: the reduce-motion switch.
                  Positioned(
                    top: 14 + MediaQuery.paddingOf(context).top,
                    right: 16,
                    child: MotionToggle(sim: _sim),
                  ),
                ],
              ),
            ),
            ),
          );
        },
      ),
    );
  }
}
