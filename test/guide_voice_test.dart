import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/core/services/guide_voice.dart';
import 'package:haneen_kids_vod/features/exercises/game_catalog.dart';

void main() {
  test('spokenText drops emoji and keeps Arabic', () {
    expect(spokenText('كام 🍎 في الصف ده؟ 🍎'), 'كام في الصف ده؟');
  });

  test('manifest covers every game intro, feedback line and exercise prompt', () {
    final List m = jsonDecode(File('tools/guide_manifest.json').readAsStringSync()) as List;
    final Set<String> texts = m.map((x) => x['text'] as String).toSet();
    final Set<String> ids = m.map((x) => x['id'] as String).toSet();
    for (final String t in [...GuideVoice.rightLines, ...GuideVoice.wrongLines, ...GuideVoice.widgetIntro.values]) {
      expect(texts.contains(spokenText(t)), true, reason: t);
    }
    for (final g in kExerciseGames) {
      expect(texts.contains(spokenText(GuideVoice.exerciseIntroText(g))), true, reason: g.skill);
      expect(ids.contains('gi_ex_${g.skill}'), true);
    }
    final List ex = jsonDecode(File('assets/exercises/exercises_v1.json').readAsStringSync()) as List;
    for (final e in ex) {
      expect(texts.contains(spokenText(e['prompt'] as String)), true, reason: e['id'] as String);
    }
    for (final x in m) {
      expect((x['text'] as String).length < 200, true);
    }
  });
}
