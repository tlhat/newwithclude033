import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/features/brain_games/screens/extra_games.dart';

void main() {
  test('clock math and arabic label', () {
    expect(ClockMath.label(3, 0), '٣:٠٠');
    expect(ClockMath.minuteAngle(30), closeTo(pi, 1e-9));
    expect(ClockMath.hourAngle(3, 0), closeTo(pi / 2, 1e-9));
  });
  test('slide puzzle shuffles stay solvable (reversible moves)', () {
    final Random r = Random(1);
    for (int i = 0; i < 50; i++) {
      final List<int> b = SlidePuzzle.shuffled(r);
      expect(b.toSet().length, 9);
      // count inversions: solvable 3x3 has even inversions
      int inv = 0;
      final List<int> f = b.where((x) => x != 0).toList();
      for (int a = 0; a < f.length; a++) {
        for (int c = a + 1; c < f.length; c++) {
          if (f[a] > f[c]) inv++;
        }
      }
      expect(inv % 2, 0);
    }
    expect(SlidePuzzle.solved([1, 2, 3, 4, 5, 6, 7, 8, 0]), true);
  });
  test('every maze can be solved', () {
    for (final g in MazeData.levels) {
      expect(MazeData.solvable(g), true);
    }
  });
  test('plant grows only with water and sun together', () {
    expect(PlantGrowth.stage(10, 0), 0);
    expect(PlantGrowth.stage(2, 2), 1);
    expect(PlantGrowth.stage(20, 20), 4);
  });
  test('game catalogs have unique ids', () {
    expect(kWidgetGames.map((g) => g.id).toSet().length, kWidgetGames.length);
  });
}
