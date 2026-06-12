import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The standard era title treatment: a small roman-numeral overline,
/// the era name in display type, and an optional poetic subtitle.
/// Every era from Stellar Formation onward uses this at its top.
class EraHeading extends StatelessWidget {
  const EraHeading({
    super.key,
    required this.overline,
    required this.title,
    this.subtitle,
    required this.opacity,
    this.compact = false,
  });

  final String overline;
  final String title;
  final String? subtitle;
  final double opacity;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (opacity <= 0.001) return const SizedBox.shrink();
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            overline,
            style: GoogleFonts.spaceGrotesk(
              fontSize: compact ? 9.5 : 11,
              letterSpacing: 4.5,
              color: Colors.white.withValues(alpha: 0.35),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title.toUpperCase(),
            textAlign: TextAlign.center,
            style: GoogleFonts.orbitron(
              fontSize: compact ? 17 : 22,
              fontWeight: FontWeight.w600,
              letterSpacing: compact ? 4 : 7,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 7),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: compact ? 12 : 13.5,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.6,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
