import 'dart:ui';

/// Viewport-area-based particle budget. The performance pass (phase j)
/// adds a frame-time probe that can lower this further at runtime;
/// until then, area is an honest proxy that keeps phones at a few
/// hundred background stars and desktops near the ceiling.
int starBudget(Size size) {
  if (size.isEmpty) return 0;
  final double area = size.width * size.height;
  return (area / 900).round().clamp(250, 1600);
}
