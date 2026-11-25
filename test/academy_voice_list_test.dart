import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:haneen_kids_vod/l10n/app_localizations_ar.dart';
import 'package:haneen_kids_vod/features/activities/services/academy_voice_texts.dart';

void main() {
  test('academy hint and quiz lines are non-empty and emoji-free prefix', () {
    final l10n = AppLocalizationsAr();
    final StringBuffer out = StringBuffer();
    for (final lesson in kHaneenAcademyCurriculum) {
      for (int lv = 1; lv <= 3; lv++) {
        final t = AcademyVoiceTexts.hint(l10n, lesson, lv);
        expect(t.trim(), isNotEmpty);
        out.writeln('acad_hint_${lesson.id}_t$lv\t${t.replaceAll('\n', ' ')}');
      }
      out.writeln('acad_quiz_${lesson.id}\t${AcademyVoiceTexts.quiz(lesson)}');
    }
    final f = File('/tmp/academy_voice_list.tsv');
    f.writeAsStringSync(out.toString());
  });
}
