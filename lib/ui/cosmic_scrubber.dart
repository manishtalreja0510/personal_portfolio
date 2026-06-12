import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../engine/eras.dart';
import '../engine/scroll_engine.dart';
import 'scroll_passthrough.dart';

/// When each era "happened", for the ruler's hover labels.
const Map<Era, String> kEraDates = {
  Era.singularity: '13.8B years ago',
  Era.bigBang: 'the first instant',
  Era.stellar: '13.2B years ago',
  Era.planetary: '9B years ago',
  Era.civilizations: '10,000 years ago',
  Era.present: 'today',
  Era.newUniverse: 'tomorrow',
};

/// The cosmic ruler — the site's only navigation. A thin timeline on
/// the bottom edge from "13.8B years ago" to "NOW": hover to see the
/// era under the cursor, click to travel there, drag to scrub time
/// by hand.
class CosmicScrubber extends StatefulWidget {
  const CosmicScrubber({super.key, required this.clock});

  final UniverseClock clock;

  @override
  State<CosmicScrubber> createState() => _CosmicScrubberState();
}

class _CosmicScrubberState extends State<CosmicScrubber> {
  double? _hoverX;
  bool _dragging = false;

  void _scrubTo(double fraction) {
    final controller = widget.clock.scrollController;
    if (!controller.hasClients) return;
    final position = controller.position;
    controller.jumpTo(
        (fraction * position.maxScrollExtent)
            .clamp(0.0, position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double w = constraints.maxWidth;
      final bool wide = w > 560;
      final Era? hoverEra =
          _hoverX == null ? null : Era.at((_hoverX! / w).clamp(0.0, 1.0));

      return ScrollPassthrough(
        clock: widget.clock,
        child: Semantics(
          label: 'Cosmic timeline — click an era to travel there',
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onHover: (e) => setState(() => _hoverX = e.localPosition.dx),
            onExit: (_) => setState(() => _hoverX = null),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => widget.clock
                  .travelTo(Era.at((d.localPosition.dx / w).clamp(0.0, 1.0))),
              onHorizontalDragStart: (d) => setState(() {
                _dragging = true;
                _hoverX = d.localPosition.dx;
              }),
              // Tracking _hoverX during the drag gives touch users
              // the same era label feedback hover gives the mouse.
              onHorizontalDragUpdate: (d) {
                setState(() => _hoverX = d.localPosition.dx);
                _scrubTo((d.localPosition.dx / w).clamp(0.0, 1.0));
              },
              onHorizontalDragEnd: (_) => setState(() {
                _dragging = false;
                _hoverX = null;
              }),
              child: Stack(clipBehavior: Clip.none, children: [
                ValueListenableBuilder<double>(
                  valueListenable: widget.clock,
                  builder: (context, t, _) => CustomPaint(
                    size: Size(w, 64),
                    painter: _RulerPainter(
                        t: t, hoverEra: hoverEra, dragging: _dragging),
                  ),
                ),
                if (wide)
                  Positioned(left: 0, top: 46, child: _endLabel('13.8B YEARS AGO')),
                Positioned(right: 0, top: 46, child: _endLabel('NOW')),
                if (hoverEra != null)
                  Positioned(
                    left: (_hoverX! - 80).clamp(0.0, w - 160),
                    top: 0,
                    width: 160,
                    child: IgnorePointer(
                      child: Column(children: [
                        Text(
                          hoverEra.label.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10.5,
                            letterSpacing: 2.2,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          kEraDates[hoverEra]!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 9,
                            letterSpacing: 1.4,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ]),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      );
    });
  }

  Widget _endLabel(String text) => IgnorePointer(
        child: Text(
          text,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 8.5,
            letterSpacing: 2.4,
            color: Colors.white.withValues(alpha: 0.30),
          ),
        ),
      );
}

class _RulerPainter extends CustomPainter {
  _RulerPainter({required this.t, this.hoverEra, required this.dragging});

  final double t;
  final Era? hoverEra;
  final bool dragging;

  static const double _lineY = 38;

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;

    final Paint base = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.10);
    canvas.drawLine(Offset(0, _lineY), Offset(w, _lineY), base);

    // The traveled portion of time glows.
    final Paint lit = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.30);
    canvas.drawLine(Offset(0, _lineY), Offset(t * w, _lineY), lit);

    // Hovered era underlined brighter.
    if (hoverEra != null) {
      final Paint seg = Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.22);
      canvas.drawLine(Offset(hoverEra!.start * w, _lineY),
          Offset(hoverEra!.end * w, _lineY), seg);
    }

    // Era boundary ticks.
    final Paint tick = Paint()
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: 0.25);
    for (final era in Era.values) {
      final double x = era.start * w;
      canvas.drawLine(Offset(x, _lineY - 4), Offset(x, _lineY + 4), tick);
    }

    // The marker: where the visitor is in cosmic time.
    final Offset marker = Offset((t * w).clamp(5.0, w - 5.0), _lineY);
    canvas.drawCircle(
      marker,
      dragging ? 12 : 9,
      Paint()
        ..shader = ui.Gradient.radial(marker, dragging ? 12 : 9, [
          Colors.white.withValues(alpha: 0.55),
          Colors.white.withValues(alpha: 0.0),
        ]),
    );
    canvas.drawCircle(
        marker, dragging ? 4.5 : 3.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_RulerPainter old) =>
      old.t != t || old.hoverEra != hoverEra || old.dragging != dragging;
}
