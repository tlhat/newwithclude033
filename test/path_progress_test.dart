import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haneen_kids_vod/features/home/path_progress.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('opening a step does not complete it; only real completion does', () async {
    const tabs = [0, 1, 2, 1, 0]; // story, lesson, game, lesson, story
    var counts = await PathProgress.countsToday('c1');
    expect(PathProgress.doneFlags(tabs, counts), everyElement(false));

    await PathProgress.record('c1', PathProgress.story);
    counts = await PathProgress.countsToday('c1');
    // first story step done, the closing story step still open
    expect(PathProgress.doneFlags(tabs, counts),
        [true, false, false, false, false]);

    await PathProgress.record('c1', PathProgress.story);
    await PathProgress.record('c1', PathProgress.lesson);
    counts = await PathProgress.countsToday('c1');
    expect(PathProgress.doneFlags(tabs, counts),
        [true, true, false, false, true]);
  });

  test('progress is per child', () async {
    await PathProgress.record('a', PathProgress.game);
    expect((await PathProgress.countsToday('b'))[PathProgress.game], 0);
  });
}
