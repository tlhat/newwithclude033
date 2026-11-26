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
      expect(['CC0', 'Public domain', 'CC BY-SA 3.0', 'CC BY-SA 4.0'],
          contains(r[2]));
      if (r[2].startsWith('CC BY')) expect(r[1].isNotEmpty, isTrue);
    }
    expect(File('assets/audio/real_sounds/CREDITS.md').existsSync(), isTrue);
  });
  test('CC BY-SA files are credited in the license file', () {
    final md = File('assets/audio/real_sounds/CREDITS.md').readAsStringSync();
    expect(md, contains('CC BY-SA'));
    expect(md, contains('Single Cow Moo'));
    expect(md, contains('Barking of a dog'));
  });
  test('emoji map points only at existing sounds', () {
    expect(RealSounds.keyFor('🐱 القطة الأليفة'), 'cat');
    expect(RealSounds.keyFor('🦁 الأسد الشجاع'), 'lion');
    expect(RealSounds.keyFor('🚂 القطار السريع'), 'train');
    expect(RealSounds.keyFor('🐶'), 'dog');
    expect(RealSounds.keyFor('🐮'), 'cow');
    expect(RealSounds.keyFor('🐟'), isNull);
  });
}
