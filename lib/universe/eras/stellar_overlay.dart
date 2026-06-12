import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/portfolio_data.dart';
import '../../engine/eras.dart';
import '../../engine/particle_engine.dart';
import '../../engine/skill_stars.dart';
import '../../ui/era_heading.dart';

/// Widget text for the Stellar Formation era: the era heading, the
/// drifting cosmic facts, and the skill detail card that follows the
/// hovered/pinned star.
class StellarOverlay extends StatelessWidget {
  const StellarOverlay({super.key, required this.sim});

  final UniverseSimulation sim;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final Size size = constraints.biggest;
      final bool compact = size.width < 700;
      final bool tall = size.height > size.width;

      return ValueListenableBuilder<double>(
        valueListenable: sim.clock,
        builder: (context, t, _) {
          final double a = SkillStars.eraAlpha(t);
          if (a <= 0.001) return const SizedBox.shrink();
          final double p = Era.stellar.progress(t);
          // Text waits a touch longer than the stars themselves.
          final double headingA =
              a * smoothstep(phase(t, 0.215, 0.26));

          final factSpots = tall
              ? const [
                  Offset(0.50, 0.085),
                  Offset(0.26, 0.885),
                  Offset(0.74, 0.885),
                ]
              : const [
                  Offset(0.50, 0.24),
                  Offset(0.50, 0.50),
                  Offset(0.50, 0.76),
                ];

          return Stack(
            children: [
              Positioned(
                top: size.height * 0.06,
                left: 24,
                right: 24,
                child: EraHeading(
                  overline: 'ERA III',
                  title: Era.stellar.label,
                  subtitle: 'The skills condense',
                  opacity: headingA,
                  compact: compact,
                ),
              ),
              for (int i = 0; i < kCosmicFacts.length && i < 3; i++)
                _fact(i, factSpots[i], size, p, a, compact),
              ValueListenableBuilder<SkillHover?>(
                valueListenable: sim.skillHover,
                builder: (context, hover, _) {
                  if (hover == null) return const SizedBox.shrink();
                  return _detailCard(hover, size, compact);
                },
              ),
            ],
          );
        },
      );
    });
  }

  /// A headline stat drifting by like a distant object — staggered
  /// entrance, slight upward parallax against the stars.
  Widget _fact(
      int i, Offset spot, Size size, double p, double a, bool compact) {
    final fact = kCosmicFacts[i];
    final double appear =
        smoothstep(phase(p, 0.45 + i * 0.08, 0.60 + i * 0.08));
    final double opacity = a * appear;
    if (opacity <= 0.001) return const SizedBox.shrink();
    final double drift = (0.5 - p) * size.height * 0.16 * (1 + i * 0.2);

    return Positioned(
      left: spot.dx * size.width - 140,
      top: spot.dy * size.height + drift,
      width: 280,
      child: Opacity(
        opacity: opacity,
        child: Column(
          children: [
            Text(
              fact.value,
              style: GoogleFonts.orbitron(
                fontSize: compact ? 24 : 32,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              fact.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: compact ? 11 : 12.5,
                letterSpacing: 1.8,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Floating card beside the flared star: constellation overline,
  /// skill name, one-line detail. Clamped to stay on screen.
  Widget _detailCard(SkillHover hover, Size size, bool compact) {
    const double width = 250.0;
    final bool flipX = hover.position.dx + 24 + width > size.width - 12;
    final double left = flipX
        ? (hover.position.dx - 24 - width).clamp(12.0, size.width - width - 12)
        : hover.position.dx + 24;
    final double top =
        (hover.position.dy - 44).clamp(12.0, size.height - 140);

    return Positioned(
      left: left,
      top: top,
      width: width,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: const Color(0xCC000208),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hover.color.withValues(alpha: 0.45),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: hover.color.withValues(alpha: 0.12),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hover.constellationName.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 9.5,
                  letterSpacing: 2.8,
                  color: hover.color.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hover.skill.name,
                style: GoogleFonts.orbitron(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                hover.skill.detail,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12.5,
                  height: 1.45,
                  color: Colors.white.withValues(alpha: 0.62),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
