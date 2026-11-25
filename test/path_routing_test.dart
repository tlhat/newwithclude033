import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/features/home/screens/my_path_screen.dart';

void main() {
  test('every path step opens its own activity', () {
    for (final age in [3, 4, 5, 6, 7, 9]) {
      for (final s in MyPathPlan.stepsFor(age)) {
        if (s.tab == 1) {
          expect(s.trackId, isNotNull, reason: '${s.title} age $age');
          expect(s.trackId, isNot('smart_path'));
        }
        if (s.tab == 2) {
          expect(s.gameIndex, isNotNull, reason: '${s.title} age $age');
        }
      }
    }
    final colors = MyPathPlan.stepsFor(4).firstWhere((s) => s.title == 'ألوان وأشكال');
    expect(colors.trackId, 'colors_shapes');
  });
}
