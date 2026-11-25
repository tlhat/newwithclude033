import 'package:haneen_kids_vod/haneen_kids_exports.dart';
import 'package:haneen_kids_vod/l10n/app_localizations.dart';

/// Exact spoken lines for the academy hint button and the "سؤال التثبيت"
/// (mastery quiz). Clip lookup is keyed by this exact text, so the screen and
/// the recording list must both come from here (no emoji in the spoken text).
class AcademyVoiceTexts {
  static String tier3(AppLocalizations l10n, AcademyTrackLesson lesson) {
    final content = HintLadderEngine.buildSafeWorkedExample(
      forbiddenAnswers: <String>[
        ...lesson.quizOptions,
        lesson.correctOption,
        ...lesson.alternativeRemediationOptions,
        lesson.alternativeRemediationCorrect,
      ],
      candidateWords: lesson.cards.map((c) => c.wordExample).toList(),
      candidateEmojis: lesson.cards.map((c) => c.emoji).toList(),
    );
    if (content.isCurriculumExample) {
      return l10n.companionHintTier3(content.exampleWord, content.exampleEmoji);
    }
    return l10n.companionHintTier3Fallback(lesson.targetWordOrPhrase);
  }

  static String hint(AppLocalizations l10n, AcademyTrackLesson lesson, int level) =>
      switch (level) {
        1 => l10n.companionHintTier1(lesson.targetWordOrPhrase),
        2 => l10n.companionHintTier2(lesson.targetWordOrPhrase),
        _ => tier3(l10n, lesson),
      };

  /// The mastery question and its choices, read aloud.
  static String quiz(AcademyTrackLesson lesson) =>
      'سؤال التثبيت. ${lesson.quizQuestion} الاختيارات: ${lesson.quizOptions.join('، ')}.';
}
