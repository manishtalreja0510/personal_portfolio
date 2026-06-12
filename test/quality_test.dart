import 'dart:ui';

import 'package:aiportfoliowebsite/engine/quality.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('starBudget', () {
    test('scales with area between sane bounds', () {
      expect(starBudget(Size.zero), 0);
      expect(starBudget(const Size(390, 844)), inInclusiveRange(250, 600));
      expect(starBudget(const Size(1920, 1080)), 1600);
    });
  });

  group('QualityController', () {
    test('steady 60fps never drops the tier', () {
      final q = QualityController();
      for (int i = 0; i < 600; i++) {
        expect(q.sample(1 / 60), isFalse);
      }
      expect(q.tier, 1.0);
    });

    test('sustained jank steps down through the tiers to a floor', () {
      final q = QualityController();
      bool dropped = false;
      for (int i = 0; i < 90 && !dropped; i++) {
        dropped = q.sample(1 / 30);
      }
      expect(dropped, isTrue, reason: '3s of 30fps should drop a tier');
      expect(q.tier, 0.7);

      // Still janky after the cooldown → second drop.
      for (int i = 0; i < 400; i++) {
        q.sample(1 / 30);
      }
      expect(q.tier, 0.45);

      // Floor: never below the lowest tier.
      for (int i = 0; i < 600; i++) {
        q.sample(1 / 30);
      }
      expect(q.tier, 0.45);
    });

    test('recovered frame rate stops the descent', () {
      final q = QualityController();
      for (int i = 0; i < 90; i++) {
        q.sample(1 / 30);
      }
      expect(q.tier, 0.7);
      // Smooth again at the lower budget → tier is sticky, no change.
      for (int i = 0; i < 600; i++) {
        expect(q.sample(1 / 60), isFalse);
      }
      expect(q.tier, 0.7);
    });

    test('tab-switch and startup spikes are ignored', () {
      final q = QualityController();
      for (int i = 0; i < 50; i++) {
        expect(q.sample(0.5), isFalse); // 500ms gaps: not GPU signal
      }
      expect(q.tier, 1.0);
    });
  });
}
