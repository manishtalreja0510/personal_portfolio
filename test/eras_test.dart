import 'package:aiportfoliowebsite/engine/eras.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Era timeline', () {
    test('covers [0, 1] contiguously with no gaps or overlaps', () {
      expect(Era.values.first.start, 0.0);
      expect(Era.values.last.end, 1.0);
      for (int i = 1; i < Era.values.length; i++) {
        expect(Era.values[i].start, Era.values[i - 1].end,
            reason: '${Era.values[i].name} must start where '
                '${Era.values[i - 1].name} ends');
      }
    });

    test('Era.at maps boundaries to the era that begins there', () {
      expect(Era.at(0.0), Era.singularity);
      expect(Era.at(0.05), Era.bigBang);
      expect(Era.at(0.10), Era.bigBang);
      expect(Era.at(0.35), Era.planetary);
      expect(Era.at(0.999), Era.newUniverse);
      expect(Era.at(1.0), Era.newUniverse);
    });

    test('progress is clamped and linear inside the era', () {
      expect(Era.stellar.progress(0.0), 0.0);
      expect(Era.stellar.progress(0.15), 0.0);
      expect(Era.stellar.progress(0.25), closeTo(0.5, 1e-9));
      expect(Era.stellar.progress(0.35), 1.0);
      expect(Era.stellar.progress(1.0), 1.0);
    });

    test('presence is 1 inside, 0 far away, soft at the edges', () {
      expect(Era.planetary.presence(0.5), 1.0);
      expect(Era.planetary.presence(0.0), 0.0);
      expect(Era.planetary.presence(1.0), 0.0);
      final double nearEdge = Era.planetary.presence(0.35 - 0.02);
      expect(nearEdge, greaterThan(0.0));
      expect(nearEdge, lessThan(1.0));
      // The first era is fully present at t = 0 (the landing moment).
      expect(Era.singularity.presence(0.0), 1.0);
    });

    test('phase remaps and clamps sub-ranges', () {
      expect(phase(0.5, 0.4, 1.0), closeTo(1 / 6, 1e-9));
      expect(phase(0.2, 0.4, 1.0), 0.0);
      expect(phase(1.2, 0.4, 1.0), 1.0);
    });
  });
}
