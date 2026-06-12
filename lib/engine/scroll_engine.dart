import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import 'eras.dart';

/// Master clock of the universe.
///
/// Owns the single [ScrollController], converts scroll offset into a
/// raw time target, and exposes a smoothed time as [value] (0..1).
/// Smoothing is a frame-rate-independent exponential chase, so the
/// discrete steps of a mouse wheel read as one continuous cinematic
/// motion — and rewinding is just scrolling up.
///
/// The clock does not tick itself: [UniverseSimulation] advances it
/// via [tick] so the whole universe shares one frame loop.
class UniverseClock extends ValueNotifier<double> {
  UniverseClock() : super(0.0) {
    scrollController.addListener(_readScroll);
  }

  /// Total scroll runway, in viewport heights. More pages = slower,
  /// more deliberate pacing through the eras.
  static const double pages = 18.0;

  /// Chase rate per second: higher snaps faster, lower floats more.
  static const double _chaseRate = 6.0;

  final ScrollController scrollController = ScrollController();
  double _target = 0.0;

  /// Raw (unsmoothed) scroll time — what [value] is chasing.
  double get target => _target;

  /// Advance the smoothed time by [dt] seconds.
  void tick(double dt) {
    final double gap = _target - value;
    if (gap.abs() < 0.00005) {
      if (value != _target) value = _target;
      return;
    }
    value += gap * (1 - math.exp(-_chaseRate * dt));
  }

  /// Smooth-scrolls the page so the clock lands on the era's center.
  /// Used by the timeline scrubber in place of a navbar.
  void travelTo(Era era) {
    if (!scrollController.hasClients) return;
    final double extent = scrollController.position.maxScrollExtent;
    if (extent <= 0) return;
    scrollController.animateTo(
      era.center * extent,
      // Long jumps deserve longer journeys; clamp keeps it snappy.
      duration: Duration(
          milliseconds:
              (600 + 1400 * (era.center - value).abs()).round().clamp(600, 2000)),
      curve: Curves.easeInOutCubic,
    );
  }

  void _readScroll() {
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    if (position.maxScrollExtent <= 0) return;
    _target = (position.pixels / position.maxScrollExtent).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }
}
