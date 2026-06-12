import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../engine/scroll_engine.dart';

/// Interactive widgets (link pills, info panels) must sit *above*
/// the invisible scroll surface to be tappable — which would turn
/// them into scroll dead-zones. This wrapper forwards mouse-wheel
/// and vertical-drag input back to the universe's scroll controller,
/// so time keeps flowing under the pointer.
class ScrollPassthrough extends StatelessWidget {
  const ScrollPassthrough({super.key, required this.clock, required this.child});

  final UniverseClock clock;
  final Widget child;

  void _scrollBy(double delta) {
    final controller = clock.scrollController;
    if (!controller.hasClients) return;
    final position = controller.position;
    controller.jumpTo(
      (position.pixels + delta).clamp(0.0, position.maxScrollExtent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) _scrollBy(event.scrollDelta.dy);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onVerticalDragUpdate: (details) => _scrollBy(-details.delta.dy),
        child: child,
      ),
    );
  }
}
