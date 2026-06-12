import 'package:aiportfoliowebsite/engine/text_particles.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sampleTextPoints traces glyphs, centered, within bounds', () async {
    const style = TextStyle(fontSize: 100, color: Color(0xFFFFFFFF));
    final points = await sampleTextPoints('MANISH', style, stride: 4);

    expect(points, isNotEmpty);
    // Points are centered around the origin...
    final double meanX =
        points.fold<double>(0, (s, p) => s + p.dx) / points.length;
    expect(meanX.abs(), lessThan(30));
    // ...and never outside a plausible text box for this font size.
    for (final p in points) {
      expect(p.dy.abs(), lessThan(120));
    }
  });

  test('maxPoints thins evenly instead of truncating', () async {
    const style = TextStyle(fontSize: 100, color: Color(0xFFFFFFFF));
    final all = await sampleTextPoints('MANISH', style, stride: 3);
    final thinned =
        await sampleTextPoints('MANISH', style, stride: 3, maxPoints: 50);

    expect(thinned.length, lessThanOrEqualTo(51));
    // Even thinning keeps both ends of the word covered.
    final double allMax = all.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
    final double thinnedMax =
        thinned.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
    expect(thinnedMax, greaterThan(allMax * 0.7));
  });
}
