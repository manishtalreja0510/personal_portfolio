import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/portfolio_data.dart';
import '../../engine/eras.dart';
import '../../engine/particle_engine.dart';
import '../../engine/planet_system.dart';
import '../../ui/era_heading.dart';
import '../../ui/scroll_passthrough.dart';

/// Non-interactive text for the Planetary era (sits *below* the
/// scroll surface): just the era heading — everything else in this
/// era needs taps, so it lives in [PlanetaryInteractive].
class PlanetaryOverlay extends StatelessWidget {
  const PlanetaryOverlay({super.key, required this.sim});

  final UniverseSimulation sim;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final Size size = constraints.biggest;
      final bool compact = size.width < 700;
      return ValueListenableBuilder<double>(
        valueListenable: sim.clock,
        builder: (context, t, _) {
          final double a = PlanetSystem.eraAlpha(t);
          if (a <= 0.001) return const SizedBox.shrink();
          final double p = Era.planetary.progress(t);
          return Stack(children: [
            Positioned(
              top: size.height * 0.055,
              left: 24,
              right: 24,
              child: EraHeading(
                overline: 'ERA IV',
                title: Era.planetary.label,
                subtitle: 'Worlds form from the work',
                opacity: a * smoothstep(phase(p, 0.02, 0.08)),
                compact: compact,
              ),
            ),
          ]);
        },
      );
    });
  }
}

/// Everything tappable in the Planetary era, layered *above* the
/// scroll surface: per-planet info panels with store links, the
/// zoomed case-study modal, and the pinned comet (package) card.
/// Wrapped in [ScrollPassthrough] so wheel/drag still move time.
class PlanetaryInteractive extends StatelessWidget {
  const PlanetaryInteractive({super.key, required this.sim});

  final UniverseSimulation sim;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final Size size = constraints.biggest;
      final bool tall = size.height > size.width;
      return AnimatedBuilder(
        animation: sim,
        builder: (context, _) {
          final PlanetSystem? ps = sim.planets;
          final double t = sim.clock.value;
          final double a = PlanetSystem.eraAlpha(t);
          if (ps == null || a <= 0.001) return const SizedBox.shrink();

          return Stack(children: [
            for (int k = 0; k < ps.specs.length; k++)
              if (ps.states[k].focus > 0.03 && ps.zoomEase < 0.6)
                _infoPanel(ps, k, size, tall, a),
            if (ps.pinnedComet != null)
              _cometCard(ps, ps.pinnedComet!, size, tall),
            if (ps.zoomEase > 0.02 && ps.zoomIndex != null)
              _caseStudy(ps, ps.zoomIndex!, size, tall),
          ]);
        },
      );
    });
  }

  // ---------------------------------------------------------------
  // Info panel beside the focused planet
  // ---------------------------------------------------------------

  Widget _infoPanel(
      PlanetSystem ps, int k, Size size, bool tall, double a) {
    final PlanetSpec spec = ps.specs[k];
    final Project project = spec.project;
    final PlanetState s = ps.states[k];
    final double opacity =
        (s.focus * (1 - ps.zoomEase) * a).clamp(0.0, 1.0);
    if (opacity <= 0.01) return const SizedBox.shrink();

    final Widget content = ScrollPassthrough(
      clock: sim.clock,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'PLANET 0${k + 1} / 0${ps.specs.length} · ${project.duration.toUpperCase()}',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              letterSpacing: 3,
              color: spec.atmosphere.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            project.name,
            style: GoogleFonts.orbitron(
              fontSize: tall ? 22 : 28,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            project.tagline,
            style: GoogleFonts.spaceGrotesk(
              fontSize: tall ? 13 : 14.5,
              fontStyle: FontStyle.italic,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            project.summary,
            style: GoogleFonts.spaceGrotesk(
              fontSize: tall ? 12.5 : 13.5,
              height: 1.55,
              color: Colors.white.withValues(alpha: 0.68),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final link in project.links)
                _LinkPill(
                  label: link.label.toUpperCase(),
                  url: link.url,
                  color: spec.atmosphere,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'TAP THE PLANET FOR THE FULL STORY',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 9,
              letterSpacing: 2.6,
              color: Colors.white.withValues(alpha: 0.32),
            ),
          ),
        ],
      ),
    );

    // The panel parallax-slides at a fraction of the planet's speed.
    if (tall) {
      return Positioned(
        left: 20,
        right: 20,
        top: size.height * 0.52 + s.offset * size.height * 0.06,
        child: Opacity(opacity: opacity, child: content),
      );
    }
    return Positioned(
      left: size.width * 0.56 + s.offset * size.width * 0.22,
      width: (size.width * 0.36).clamp(280.0, 440.0),
      top: 0,
      bottom: 0,
      child: Opacity(
        opacity: opacity,
        child: Center(child: content),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Zoomed case study
  // ---------------------------------------------------------------

  Widget _caseStudy(PlanetSystem ps, int k, Size size, bool tall) {
    final PlanetSpec spec = ps.specs[k];
    final Project project = spec.project;
    final double z = ps.zoomEase.clamp(0.0, 1.0);

    final Widget card = Container(
      width: tall ? size.width - 24 : (size.width * 0.42).clamp(360.0, 500.0),
      constraints: BoxConstraints(maxHeight: size.height * 0.78),
      decoration: BoxDecoration(
        color: const Color(0xF2020409),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: spec.atmosphere.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: spec.atmosphere.withValues(alpha: 0.14),
            blurRadius: 40,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 16, 10, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'PLANET 0${k + 1} · ${project.duration.toUpperCase()}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      letterSpacing: 3,
                      color: spec.atmosphere.withValues(alpha: 0.9),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => ps.zoomIndex = null,
                  icon: const Icon(Icons.close_rounded,
                      size: 20, color: Colors.white54),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: GoogleFonts.orbitron(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    project.tagline,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13.5,
                      fontStyle: FontStyle.italic,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final bullet in project.caseStudy)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    spec.atmosphere.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              bullet,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                height: 1.55,
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tech in project.tech)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Text(
                            tech,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      for (final link in project.links)
                        _LinkPill(
                          label: link.label.toUpperCase(),
                          url: link.url,
                          color: spec.atmosphere,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return Positioned.fill(
      child: Stack(children: [
        GestureDetector(
          onTap: () => ps.zoomIndex = null,
          child: Container(
            color: Colors.black.withValues(alpha: 0.45 * z),
          ),
        ),
        Align(
          alignment: tall ? Alignment.bottomCenter : Alignment.centerRight,
          child: Padding(
            padding: tall
                ? const EdgeInsets.only(bottom: 12)
                : const EdgeInsets.only(right: 40),
            child: Transform.translate(
              offset: tall
                  ? Offset(0, 32 * (1 - z))
                  : Offset(40 * (1 - z), 0),
              child: Opacity(opacity: z, child: card),
            ),
          ),
        ),
      ]),
    );
  }

  // ---------------------------------------------------------------
  // Comet (pub.dev package) card
  // ---------------------------------------------------------------

  Widget _cometCard(PlanetSystem ps, int c, Size size, bool tall) {
    final PubPackage package = ps.packages[c];
    const Color cometColor = Color(0xFF9CC8FF);
    return Positioned(
      left: tall ? 16 : 32,
      bottom: tall ? 110 : 90,
      width: (size.width - 32).clamp(200.0, 330.0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
        decoration: BoxDecoration(
          color: const Color(0xE6020409),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cometColor.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: cometColor.withValues(alpha: 0.12),
              blurRadius: 28,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                  'OPEN SOURCE · PUB.DEV',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 9.5,
                    letterSpacing: 2.8,
                    color: cometColor.withValues(alpha: 0.9),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => ps.pinnedComet = null,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded,
                      size: 16, color: Colors.white54),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              package.name,
              style: GoogleFonts.orbitron(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              package.description,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: 12),
            _LinkPill(
              label: 'VIEW ON PUB.DEV',
              url: package.url,
              color: cometColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// Outline pill that opens an external link in a new tab.
class _LinkPill extends StatelessWidget {
  const _LinkPill({required this.label, required this.url, required this.color});

  final String label;
  final String url;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      label: label,
      child: GestureDetector(
        onTap: () => launchUrl(
          Uri.parse(url),
          webOnlyWindowName: '_blank',
        ),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: color.withValues(alpha: 0.55)),
              color: color.withValues(alpha: 0.08),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10.5,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_outward_rounded,
                    size: 12, color: color.withValues(alpha: 0.9)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
