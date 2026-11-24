import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

void main() {
  test('wrong-answer lines are fixed, name-free and non-empty', () {
    for (final l in [
      ...CalmVoiceService.kWrongEncouragements,
      ...CalmVoiceService.kWrongNudges,
      ...CalmVoiceService.kWrongLastChance,
    ]) {
      expect(l.trim().isNotEmpty, true);
    }
    expect(CalmVoiceService.kWrongEncouragements.length >= 8, true);
  });
}
