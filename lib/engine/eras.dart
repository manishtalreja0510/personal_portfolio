import 'dart:math' as math;

/// The seven eras of the universe, each owning a slice of global
/// scroll-time `t` in [0, 1]. Every animation on the site is a pure
/// function of `t`, which is what makes scrolling backward literally
/// rewind the world.
enum Era {
  singularity('The Singularity', 0.00, 0.05),
  bigBang('The Big Bang', 0.05, 0.15),
  stellar('Stellar Formation', 0.15, 0.35),
  planetary('Planetary Accretion', 0.35, 0.65),
  civilizations('The Age of Civilizations', 0.65, 0.85),
  present('The Present Moment', 0.85, 0.95),
  newUniverse('A New Universe', 0.95, 1.00);

  const Era(this.label, this.start, this.end);

  final String label;
  final double start;
  final double end;

  double get span => end - start;

  /// Midpoint of the era in global time — scrubber jump target.
  double get center => start + span / 2;

  /// Progress through this era, clamped to [0, 1].
  double progress(double t) => ((t - start) / span).clamp(0.0, 1.0);

  /// Visibility weight for crossfading era layers: 1 while `t` is
  /// inside the era, easing to 0 across [fade] beyond either edge,
  /// so neighbouring eras overlap softly during transitions.
  double presence(double t, {double fade = 0.04}) {
    final double rise = ((t - (start - fade)) / fade).clamp(0.0, 1.0);
    final double fall = (((end + fade) - t) / fade).clamp(0.0, 1.0);
    return smoothstep(math.min(rise, fall));
  }

  /// The era that owns time `t`.
  static Era at(double t) {
    for (final era in values.reversed) {
      if (t >= era.start) return era;
    }
    return Era.singularity;
  }
}

/// Hermite smoothstep on [0, 1] — the house easing for crossfades.
double smoothstep(double x) {
  final double v = x.clamp(0.0, 1.0);
  return v * v * (3 - 2 * v);
}

/// Remap `t` from [a, b] to [0, 1], clamped. The workhorse for
/// sequencing beats inside an era ("name assembles during the last
/// 60% of the Big Bang" = phase(t, 0.4, 1.0) of the era's progress).
double phase(double t, double a, double b) =>
    ((t - a) / (b - a)).clamp(0.0, 1.0);
