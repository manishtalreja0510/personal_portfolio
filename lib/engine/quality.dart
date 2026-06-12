import 'dart:ui';

/// Viewport-area-based particle budget: phones get a few hundred
/// background stars, desktops up to the ceiling. The runtime tier
/// from [QualityController] scales this down further on weak GPUs.
int starBudget(Size size) {
  if (size.isEmpty) return 0;
  final double area = size.width * size.height;
  return (area / 900).round().clamp(250, 1600);
}

/// Watches real frame times and steps the particle budget down on
/// sustained jank. Deliberately down-only and sticky: an oscillating
/// star count looks far worse than a stable, slightly sparser sky.
class QualityController {
  /// Multiplier applied to particle budgets (1.0 → full sky).
  double tier = 1.0;

  static const List<double> _tiers = [1.0, 0.7, 0.45];

  /// Exponentially-smoothed frame time, seeded at 60fps.
  double _ema = 1 / 60;
  double _slowFor = 0;
  double _cooldown = 0;

  /// Feed one frame delta. Returns true when the tier just dropped —
  /// the caller should rebuild its particle fields.
  bool sample(double dt) {
    // Startup spikes and tab-switch gaps are not GPU signal.
    if (dt <= 0 || dt > 0.1) return false;
    _ema += (dt - _ema) * 0.05;
    if (_cooldown > 0) {
      _cooldown -= dt;
      return false;
    }
    if (_ema > 1 / 45) {
      _slowFor += dt;
    } else {
      _slowFor = 0;
    }
    final int index = _tiers.indexOf(tier);
    if (_slowFor > 1.5 && index < _tiers.length - 1) {
      tier = _tiers[index + 1];
      _slowFor = 0;
      _cooldown = 3; // let the new budget prove itself
      _ema = 1 / 60;
      return true;
    }
    return false;
  }
}
