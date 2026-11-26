import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/core/entitlements/entitlements.dart';

void main() {
  setUp(() => Entitlements.subscribed.value = false);
  test('free tier: tier 1 lessons, first stories and games only', () {
    expect(Entitlements.academyLessonLocked(1), isFalse);
    expect(Entitlements.academyLessonLocked(2), isTrue);
    expect(Entitlements.storyLocked(Entitlements.freeStoryCount - 1), isFalse);
    expect(Entitlements.storyLocked(Entitlements.freeStoryCount), isTrue);
    expect(Entitlements.gameLocked(0), isFalse);
    expect(Entitlements.gameLocked(Entitlements.freeGameCount), isTrue);
  });
  test('stub subscription unlocks everything locally', () {
    Entitlements.subscribed.value = true;
    expect(Entitlements.academyLessonLocked(4), isFalse);
    expect(Entitlements.storyLocked(50), isFalse);
    expect(Entitlements.gameLocked(50), isFalse);
  });
}
