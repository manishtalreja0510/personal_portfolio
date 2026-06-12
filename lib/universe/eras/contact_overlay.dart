import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/portfolio_data.dart';
import '../../engine/finale.dart';
import '../../engine/particle_engine.dart';
import '../../ui/scroll_passthrough.dart';

/// The finale, layered above the scroll surface: the closing line,
/// five contact links orbiting the new singularity as glowing bodies,
/// the singularity's own tap target (mini big-bang + email), and a
/// selectable email address for copy-paste.
class ContactOverlay extends StatelessWidget {
  const ContactOverlay({super.key, required this.sim});

  final UniverseSimulation sim;

  void _open(String url) =>
      launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final Size size = constraints.biggest;
      final bool compact = size.width < 700;

      return AnimatedBuilder(
        animation: sim,
        builder: (context, _) {
          final double a = contactAlpha(sim.clock.value);
          if (a <= 0.001) return const SizedBox.shrink();
          final Offset center = newSingularityCenter(size);
          final orbit = contactOrbitRadii(size);

          return Stack(children: [
            // Closing line — pure text, transparent to pointers.
            Positioned(
              left: 24,
              right: 24,
              top: size.height * (compact ? 0.10 : 0.13),
              child: IgnorePointer(
                child: Opacity(
                  opacity: a,
                  child: Column(children: [
                    Text(
                      'ERA VII · A NEW UNIVERSE',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        letterSpacing: 4,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Text(
                        kContactLine,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: compact ? 17 : 22,
                          fontWeight: FontWeight.w300,
                          height: 1.55,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),

            // Orbiting contact bodies.
            for (int i = 0; i < kContactLinks.length; i++)
              _orbitBody(i, center, orbit.rx, orbit.ry, a),

            // The singularity's tap target: ignite + email.
            Positioned(
              left: center.dx - 70,
              top: center.dy - 70,
              width: 140,
              height: 140,
              child: ScrollPassthrough(
                clock: sim.clock,
                child: Semantics(
                  button: true,
                  label: 'Start a new universe — email Manish',
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => sim.contactHover = true,
                    onExit: (_) => sim.contactHover = false,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        sim.igniteContactBurst();
                        _open(kContactLinks.first.url);
                      },
                    ),
                  ),
                ),
              ),
            ),

            // Selectable email + colophon.
            Positioned(
              left: 24,
              right: 24,
              top: center.dy + orbit.ry + (compact ? 56 : 72),
              child: Opacity(
                opacity: a,
                child: Column(children: [
                  SelectionArea(
                    child: Text(
                      kEmail,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: compact ? 13 : 14.5,
                        letterSpacing: 1.2,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                  const SizedBox(height: 26),
                  IgnorePointer(
                    child: Text(
                      'DESIGNED & BUILT WITH FLUTTER',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 9,
                        letterSpacing: 3,
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ]);
        },
      );
    });
  }

  Widget _orbitBody(
      int i, Offset center, double rx, double ry, double a) {
    final ContactLink link = kContactLinks[i];
    final Offset pos = contactOrbitPosition(
      index: i,
      count: kContactLinks.length,
      time: sim.ambientTime,
      center: center,
      rx: rx,
      ry: ry,
    );
    // Bodies on the near side of the orbit pass in front (brighter).
    final bool near = pos.dy >= center.dy;
    final double bodyAlpha = a * (near ? 1.0 : 0.55);

    return Positioned(
      left: pos.dx - 52,
      top: pos.dy - 14,
      width: 104,
      height: 52,
      child: ScrollPassthrough(
        clock: sim.clock,
        child: Semantics(
          link: true,
          label: link.label,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _open(link.url),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.92 * bodyAlpha),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFBFD0FF)
                              .withValues(alpha: 0.6 * bodyAlpha),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    link.label.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 9.5,
                      letterSpacing: 2,
                      color: Colors.white.withValues(alpha: 0.65 * bodyAlpha),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
