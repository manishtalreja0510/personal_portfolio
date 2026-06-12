import 'package:flutter/material.dart';

import '../engine/particle_engine.dart';
import 'scroll_passthrough.dart';

/// The reduce-motion switch, top corner of the screen. Freezes the
/// universe's ambient clock (twinkle, orbits, beams, comet streaks,
/// shake, cursor gravity) while keeping the scroll journey intact.
class MotionToggle extends StatelessWidget {
  const MotionToggle({super.key, required this.sim});

  final UniverseSimulation sim;

  @override
  Widget build(BuildContext context) {
    return ScrollPassthrough(
      clock: sim.clock,
      child: ValueListenableBuilder<bool>(
        valueListenable: sim.reduceMotion,
        builder: (context, reduced, _) {
          return Semantics(
            button: true,
            toggled: reduced,
            label: reduced ? 'Resume motion' : 'Reduce motion',
            child: Tooltip(
              message:
                  reduced ? 'Motion reduced — click to resume' : 'Reduce motion',
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => sim.reduceMotion.value = !reduced,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.35),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: reduced ? 0.4 : 0.18),
                      ),
                    ),
                    child: Icon(
                      reduced
                          ? Icons.motion_photos_off_outlined
                          : Icons.motion_photos_on_outlined,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
