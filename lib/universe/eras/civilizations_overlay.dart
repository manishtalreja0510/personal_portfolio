import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/portfolio_data.dart';
import '../../engine/career_stream.dart';
import '../../engine/eras.dart';
import '../../engine/particle_engine.dart';
import '../../ui/era_heading.dart';

/// Widget text for the Age of Civilizations: the era heading and one
/// role card per pulsar — company, title, period, and highlight
/// bullets that fade in one by one as the node approaches focus.
/// Nothing here is tappable, so it sits below the scroll surface.
class CivilizationsOverlay extends StatelessWidget {
  const CivilizationsOverlay({super.key, required this.sim});

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
          final double a = CareerStream.eraAlpha(t);
          final CareerStream? stream = sim.career;
          if (a <= 0.001 || stream == null) {
            return const SizedBox.shrink();
          }
          final double p = Era.civilizations.progress(t);

          return Stack(children: [
            Positioned(
              top: size.height * 0.055,
              left: 24,
              right: 24,
              child: EraHeading(
                overline: 'ERA V',
                title: Era.civilizations.label,
                subtitle: 'A career flows through time',
                opacity: a * smoothstep(phase(p, 0.02, 0.08)),
                compact: compact,
              ),
            ),
            for (final node in stream.nodes)
              if (node.approach > 0.02) _roleCard(node, size, tall, a),
          ]);
        },
      );
    });
  }

  Widget _roleCard(PulsarNode node, Size size, bool tall, double a) {
    final double opacity = (node.approach * a).clamp(0.0, 1.0);
    final Role role = node.role;

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          role.period.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            letterSpacing: 3,
            color: node.color.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          role.company,
          style: GoogleFonts.orbitron(
            fontSize: tall ? 19 : 24,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          role.title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: tall ? 13 : 14.5,
            fontStyle: FontStyle.italic,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 14),
        for (int i = 0; i < role.highlights.length; i++)
          _bullet(role.highlights[i], i, node, tall),
      ],
    );

    if (tall) {
      return Positioned(
        left: 20,
        right: 20,
        top: size.height * 0.44,
        child: Opacity(opacity: opacity, child: content),
      );
    }
    // Desktop: the card rides beside its pulsar.
    final double left =
        (node.x + 76).clamp(24.0, size.width - 24.0 - 400.0);
    return Positioned(
      left: left,
      width: 400,
      top: 0,
      bottom: 0,
      child: Opacity(
        opacity: opacity,
        child: Center(child: content),
      ),
    );
  }

  /// Highlights surface one at a time off the node's approach ramp.
  Widget _bullet(String text, int i, PulsarNode node, bool tall) {
    final double reveal =
        smoothstep(phase(node.approach, 0.35 + 0.18 * i, 0.6 + 0.18 * i));
    return Opacity(
      opacity: reveal,
      child: Transform.translate(
        offset: Offset(0, 10 * (1 - reveal)),
        child: Padding(
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
                    color: node.color.withValues(alpha: 0.8),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: tall ? 12.5 : 13.5,
                    height: 1.55,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
