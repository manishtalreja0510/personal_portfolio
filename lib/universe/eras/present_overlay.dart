import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/portfolio_data.dart';
import '../../engine/eras.dart';
import '../../engine/finale.dart';
import '../../engine/scroll_engine.dart';
import '../../ui/era_heading.dart';

/// The Present Moment: a warm first-person statement, with education,
/// certification and languages as quiet side-notes. Intentionally the
/// calmest screen of the site — no interactions, no urgency.
class PresentOverlay extends StatelessWidget {
  const PresentOverlay({super.key, required this.clock});

  final UniverseClock clock;

  static final List<({String overline, String body})> _facts = [
    (overline: 'EDUCATION', body: kEducation),
    (overline: 'CERTIFICATION', body: kCertification),
    (overline: 'LANGUAGES', body: kLanguages),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final Size size = constraints.biggest;
      final bool compact = size.width < 700;

      return ValueListenableBuilder<double>(
        valueListenable: clock,
        builder: (context, t, _) {
          final double a = presentAlpha(t);
          if (a <= 0.001) return const SizedBox.shrink();
          final double p = Era.present.progress(t);
          final double drift = (0.5 - p) * size.height * 0.05;

          final double statementA =
              a * smoothstep(phase(p, 0.16, 0.34));
          return Stack(children: [
            Positioned(
              top: size.height * 0.055,
              left: 24,
              right: 24,
              child: EraHeading(
                overline: 'ERA VI',
                title: Era.present.label,
                subtitle: 'A calm region of space',
                opacity: a * smoothstep(phase(p, 0.05, 0.16)),
                compact: compact,
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: size.height * (compact ? 0.24 : 0.30) + drift,
              child: Column(children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Opacity(
                    opacity: statementA,
                    child: Transform.translate(
                      offset: Offset(0, 14 * (1 - statementA)),
                      child: Text(
                        kAboutStatement,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: compact ? 14.5 : 17,
                          fontWeight: FontWeight.w300,
                          height: 1.75,
                          color: Colors.white.withValues(alpha: 0.80),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 28 : 44),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: compact
                      ? Column(children: [
                          for (int i = 0; i < _facts.length; i++) ...[
                            _fact(i, p, a, compact),
                            const SizedBox(height: 18),
                          ],
                        ])
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < _facts.length; i++)
                              Expanded(child: _fact(i, p, a, compact)),
                          ],
                        ),
                ),
              ]),
            ),
          ]);
        },
      );
    });
  }

  Widget _fact(int i, double p, double a, bool compact) {
    final fact = _facts[i];
    final double reveal =
        a * smoothstep(phase(p, 0.32 + i * 0.09, 0.48 + i * 0.09));
    return Opacity(
      opacity: reveal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(children: [
          Text(
            fact.overline,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 9.5,
              letterSpacing: 3,
              color: const Color(0xFFBFD0FF).withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            fact.body,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: compact ? 12.5 : 13.5,
              height: 1.5,
              color: Colors.white.withValues(alpha: 0.62),
            ),
          ),
        ]),
      ),
    );
  }
}
