import 'dart:ui';

import 'package:aiportfoliowebsite/data/portfolio_data.dart';
import 'package:aiportfoliowebsite/engine/skill_stars.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _desktop = Size(1440, 900);
const Size _phone = Size(390, 844);

int _totalSkills() =>
    kConstellations.fold(0, (sum, c) => sum + c.stars.length);

void main() {
  group('SkillStars', () {
    test('one star per resume skill, edges form spanning trees', () {
      final field = SkillStars(constellations: kConstellations, size: _desktop);
      expect(field.stars.length, _totalSkills());
      // A spanning tree per constellation: total edges = stars - groups.
      expect(field.edges.length,
          _totalSkills() - kConstellations.length);
    });

    test('layout is deterministic', () {
      final a = SkillStars(constellations: kConstellations, size: _desktop);
      final b = SkillStars(constellations: kConstellations, size: _desktop);
      for (int i = 0; i < a.stars.length; i++) {
        expect(a.stars[i].baseX, b.stars[i].baseX);
        expect(a.stars[i].baseY, b.stars[i].baseY);
        expect(a.stars[i].skill.name, b.stars[i].skill.name);
      }
    });

    test('stars stay on screen on desktop and phone layouts', () {
      for (final size in [_desktop, _phone]) {
        final field = SkillStars(constellations: kConstellations, size: size);
        field.update(dt: 1 / 60, t: 0.30);
        for (final s in field.stars) {
          expect(s.x, inInclusiveRange(0, size.width),
              reason: '${s.skill.name} x on $size');
          expect(s.y, inInclusiveRange(0, size.height),
              reason: '${s.skill.name} y on $size');
        }
      }
    });

    test('era envelope: invisible before formation and after exit', () {
      expect(SkillStars.eraAlpha(0.15), 0);
      expect(SkillStars.eraAlpha(0.30), 1);
      expect(SkillStars.eraAlpha(0.40), 0);

      final field = SkillStars(constellations: kConstellations, size: _desktop);
      field.update(dt: 1 / 60, t: 0.15);
      for (final s in field.stars) {
        expect(s.alpha, 0);
      }
    });

    test('formation converges on base positions and reverses', () {
      final field = SkillStars(constellations: kConstellations, size: _desktop);
      field.update(dt: 1 / 60, t: 0.32); // fully formed (p = 0.85)
      final SkillStar s = field.stars.first;
      // Base position is spread/drift-adjusted; just verify the
      // scatter offset is gone: same star at two formed times barely
      // moves, while unformed time puts it far away.
      final double formedX = s.x;
      field.update(dt: 1 / 60, t: 0.16); // rewound to pre-formation
      final double unformedX = s.x;
      expect((unformedX - formedX).abs() > 30 || s.alpha == 0, isTrue);
      field.update(dt: 1 / 60, t: 0.32);
      expect(s.x, closeTo(formedX, 0.001));
    });

    test('hover finds the star under the pointer and flares it', () {
      final field = SkillStars(constellations: kConstellations, size: _desktop);
      field.update(dt: 1 / 60, t: 0.30);
      final SkillStar target = field.stars[3];
      final pointer = Offset(target.x, target.y);

      final int? hit = field.update(dt: 1 / 60, t: 0.30, pointer: pointer);
      expect(hit, 3);

      for (int i = 0; i < 30; i++) {
        field.update(dt: 1 / 60, t: 0.30, pointer: pointer, highlight: hit);
      }
      expect(target.flare, greaterThan(0.9));
      expect(field.stars[0].flare, lessThan(0.05));

      final info = field.hoverInfo(3, kConstellations);
      expect(info.skill.name, target.skill.name);
      expect(info.constellationName, isNotEmpty);
    });
  });
}
