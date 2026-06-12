import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/portfolio_data.dart';
import '../../engine/eras.dart';
import '../../engine/particle_engine.dart';

/// Style of the particle-assembled hero name. The same style is used
/// to rasterize assembly targets, so it lives here as the single
/// source of truth for the hero's typography.
TextStyle heroNameStyle(double viewportWidth) => GoogleFonts.orbitron(
      fontSize: (viewportWidth * 0.125).clamp(44.0, 150.0),
      fontWeight: FontWeight.w700,
      letterSpacing: (viewportWidth * 0.012).clamp(2.0, 14.0),
      color: const Color(0xFFFFFFFF),
    );

/// Text that lives over the first two eras: the singularity caption
/// and scroll hint, then the hero subtitle once the name assembles.
/// The name itself is pure particles — only its subtitle is a widget.
class HeroOverlay extends StatelessWidget {
  const HeroOverlay({super.key, required this.sim});

  final UniverseSimulation sim;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size size = constraints.biggest;
        final double anchorY = size.height * kBangCenterYFraction;
        final double nameHalfHeight =
            heroNameStyle(size.width).fontSize! * 0.62;
        final bool compact = size.width < 700;

        return ValueListenableBuilder<double>(
          valueListenable: sim.clock,
          builder: (context, t, _) {
            final double sp = Era.singularity.progress(t);
            final double bp = Era.bigBang.progress(t);
            // Visible on landing, gone before the bang.
            final double captionA = 1 - smoothstep(phase(sp, 0.55, 0.95));
            final double hintA = 1 - smoothstep(phase(t, 0.006, 0.028));
            // Subtitle arrives with the assembled name, leaves with it.
            final double nameHold = 1 - smoothstep(phase(t, 0.165, 0.225));
            final double titleA = smoothstep(phase(bp, 0.80, 0.98)) * nameHold;

            return Semantics(
              label: '$kName — $kTitle',
              child: Stack(
                children: [
                  if (captionA > 0.001)
                    Positioned(
                      top: anchorY + 96,
                      left: 24,
                      right: 24,
                      child: _Entrance(
                        child: Opacity(
                          opacity: captionA,
                          child: Text(
                            kSingularityLine,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: compact ? 14 : 17,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 2.2,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (hintA > 0.001)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 84,
                      child: Opacity(
                        opacity: hintA,
                        child: ValueListenableBuilder<bool>(
                          valueListenable: sim.reduceMotion,
                          builder: (context, reduced, _) =>
                              _PulsingHint(animate: !reduced),
                        ),
                      ),
                    ),
                  if (titleA > 0.001)
                    Positioned(
                      top: anchorY + nameHalfHeight + (compact ? 14 : 22),
                      left: 24,
                      right: 24,
                      child: Opacity(
                        opacity: titleA,
                        child: Text(
                          kTitle.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: compact ? 12.0 : 16.0,
                            letterSpacing: compact ? 2.4 : 3.6,
                            color: Colors.white.withValues(alpha: 0.62),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// One-shot gentle fade-in for the landing moment.
class _Entrance extends StatelessWidget {
  const _Entrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 2000),
      curve: Curves.easeOut,
      builder: (context, v, c) => Opacity(opacity: v, child: c),
      child: child,
    );
  }
}

/// "Scroll to begin time" with a slow breathing pulse — held steady
/// under reduced motion.
class _PulsingHint extends StatefulWidget {
  const _PulsingHint({required this.animate});

  final bool animate;

  @override
  State<_PulsingHint> createState() => _PulsingHintState();
}

class _PulsingHintState extends State<_PulsingHint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulsingHint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity:
          _controller.drive(CurveTween(curve: Curves.easeInOut)).drive(
                Tween(begin: 0.32, end: 0.85),
              ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            kScrollHint.toUpperCase(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11.5,
              letterSpacing: 3.2,
              color: Colors.white,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down_rounded,
              size: 22, color: Colors.white70),
        ],
      ),
    );
  }
}
