import 'dart:convert';
import 'dart:io';
import 'package:haneen_kids_vod/features/activities/models/academy_track_lesson_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/core/services/local_audio_library.dart';
import 'package:haneen_kids_vod/features/brain_games/services/hundred_level_games_generator.dart';
import 'package:haneen_kids_vod/features/brain_games/services/game_voice_texts.dart';

/// Every speaker button in the games must find a bundled clip for the exact
/// text it speaks. Offline, a missing clip means silence.
void main() {
  test('game speaker buttons all have bundled clips', () async {
    final Map<String, dynamic> raw = jsonDecode(
        File('assets/audio/audio_index.json').readAsStringSync());
    LocalAudioLibrary.setIndexForTesting(
        raw.map((k, v) => MapEntry(k, v.toString())));
    bool has(String t) {
      for (final p in LocalAudioLibrary.kPersonaIds) {
        if (raw.containsKey(LocalAudioLibrary.keyFor(p, t))) return true;
      }
      return false;
    }
    final Map<String, List<int>> miss = {};
    void check(String name, int i, String t) {
      if (!has(t)) miss.putIfAbsent(name, () => []).add(i);
    }
    for (int i = 0; i < 100; i++) {
      final e = HundredLevelGamesGenerator.getEtiquetteDrawingLevel(i);
      check('etiquette', i,
          '${e['title']}. ${e['etiquetteLesson']}. ${e['arabicDuaOrPhrase']}');
      final o = HundredLevelGamesGenerator.getOddOneOutLevel(i);
      check('odd', i, o['title'] as String);
      final p = HundredLevelGamesGenerator.getPatternLogicLevel(i);
      check('pattern', i, p['hint'] as String);
      final w = HundredLevelGamesGenerator.getArabicWordLevel(i);
      check('word', i, '${w['prompt']} الكلمة هي ${w['word']}');
      final pw = HundredLevelGamesGenerator.getPictureWordMatchLevel(i);
      check('picword', i,
          GameVoiceTexts.pictureWord(i + 1, pw['word'] as String, pw['hint'] as String));
      final s = HundredLevelGamesGenerator.getSoundAndListeningLevel(i);
      check('sound_current', i,
          GameVoiceTexts.sound(s['soundText'] as String, s['question'] as String));
      final r = HundredLevelGamesGenerator.getLogicalSequenceAndRiddleLevel(i);
      check('riddle', i,
          GameVoiceTexts.riddle(r['title'] as String, r['riddleTip'] as String));
      final m = HundredLevelGamesGenerator.getVisualMathLevel(i);
      check('math', i, m['mode'] == 'add'
          ? 'المرحلة ${m['levelNumber']}: اجمع ${m['a']} زائد ${m['b']} يساوي كم؟'
          : 'المرحلة ${m['levelNumber']}: عدّ الأشكال بهدوء واختر الرقم الصحيح!');
      if (i == 0) stdout.writeln('math mode: ${m['mode']}');
    }
    int lessons = 0;
    for (final l in kHaneenAcademyCurriculum) {
      lessons++;
      for (int c = 0; c < l.cards.length; c++) {
        check('academy_card', lessons * 100 + c, l.cards[c].spokenNarration);
      }
    }
    stdout.writeln('academy lessons checked: $lessons');
    expect(miss, isEmpty);
    stdout.writeln('MISSING (button -> level indexes): ${miss.map((k, v) => MapEntry(k, v.length))}');
    for (final k in miss.keys) {
      stdout.writeln('$k first miss: ${miss[k]!.take(5)}');
    }
  });
}
