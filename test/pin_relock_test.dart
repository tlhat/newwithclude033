import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/app/pin_relock_policy.dart';

void main() {
  final t0 = DateTime(2026, 1, 1, 10);
  test('PIN is asked again after being away, not for a short trip', () {
    expect(PinRelockPolicy.shouldRelock(pausedAt: t0, now: t0.add(const Duration(seconds: 5)), pinRequiredAtAll: true), isFalse);
    expect(PinRelockPolicy.shouldRelock(pausedAt: t0, now: t0.add(const Duration(seconds: 15)), pinRequiredAtAll: true), isTrue);
    expect(PinRelockPolicy.shouldRelock(pausedAt: t0, now: t0.add(const Duration(minutes: 10)), pinRequiredAtAll: false), isFalse);
    expect(PinRelockPolicy.shouldRelock(pausedAt: null, now: t0, pinRequiredAtAll: true), isFalse);
  });
}
