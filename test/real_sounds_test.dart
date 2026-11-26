import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/core/services/real_sounds.dart';
import 'package:haneen_kids_vod/core/services/real_sounds_credits.dart';

void main() {
  test('every real sound key has a file and a credit; licenses are free', () {
    for (final k in RealSounds.keys) {
      expect(File(RealSounds.assetFor(k)).existsSync(), isTrue, reason: k);
    }
    expect(kRealSoundCredits.length, RealSounds.keys.length);
    for (final r in kRealSoundCredits) {
      expect(['CC0', 'Public domain'], contains(r[2]));
    }
    expect(File('assets/audio/real_sounds/CREDITS.md').existsSync(), isTrue);
  });
  test('emoji map points only at existing sounds', () {
    expect(RealSounds.keyFor('🐱 القطة الأليفة'), 'cat');
    expect(RealSounds.keyFor('🦁 الأسد الشجاع'), 'lion');
    expect(RealSounds.keyFor('🚂 القطار السريع'), 'train');
    expect(RealSounds.keyFor('🐶'), isNull);
    expect(RealSounds.keyFor('🐮'), isNull);
  });
}
