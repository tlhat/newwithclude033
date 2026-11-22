import 'dart:math';
import 'package:haneen_kids_vod/core/utils/arabic_text_utils.dart';
import 'package:haneen_kids_vod/features/pronunciation/models/pronunciation_evaluation.dart';

class PronunciationCoachService {
  /// Privacy guarantee: voice evaluation only compares recognized text tokens in memory;
  /// raw audio recordings are NEVER stored on disk or uploaded to any external server.
  static const bool isRawAudioStoredOrUploaded = false;

  /// Normalizes Arabic or English speech for gentle, age-appropriate (2–6 yrs) phonetic matching.
  static String _normalizeBilingualToken(
    String input, {
    bool extraToddlerTolerance = false,
  }) {
    String norm = normalizeArabicForSpeech(input).toLowerCase().trim();
    // Apply child-friendly phonetic equivalence for common early-childhood substitutions
    norm = norm
        .replaceAll('ث', 'س')
        .replaceAll('ذ', 'ز')
        .replaceAll('ظ', 'ز')
        .replaceAll('ق', 'ك')
        .replaceAll('ض', 'د')
        .replaceAll('ط', 'ت')
        .replaceAll('ص', 'س');
    if (extraToddlerTolerance) {
      // Developmental substitutions natural for ages 2–4 (e.g., ر -> ل/ي, ش -> س, ج -> د)
      norm = norm
          .replaceAll('ر', 'ل')
          .replaceAll('ش', 'س')
          .replaceAll('ج', 'د')
          .replaceAll('غ', 'خ');
    }
    return norm.replaceAll(RegExp(r'[^a-z0-9\u0600-\u06FF\s]'), '');
  }

  /// Generates a slow, clear syllable/word breakdown for gentle listening & repetition.
  static String buildSlowSyllableGuide(String targetPhrase) {
    final List<String> words = targetPhrase
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    return words.join(' • ');
  }

  /// Evaluates Arabic or English pronunciation with warm, zero-frustration encouragement,
  /// adapting phonetic tolerance to the child's age group (2–6 years).
  static PronunciationEvaluation evaluate(
    String target,
    String spoken, {
    String childAgeGroup = '3–6 سنوات',
  }) {
    return evaluateForChildAge(
      target: target,
      spoken: spoken,
      childAgeGroup: childAgeGroup,
    );
  }

  static PronunciationEvaluation evaluateForChildAge({
    required String target,
    required String spoken,
    required String childAgeGroup,
  }) {
    final String ageNorm = childAgeGroup.trim();
    final bool isYoungToddler = ageNorm.contains('2') ||
        ageNorm.startsWith('٢') ||
        ageNorm.contains('3–4') ||
        ageNorm.contains('3-4');

    final String cleanTarget = _normalizeBilingualToken(
      target,
      extraToddlerTolerance: isYoungToddler,
    );
    final String cleanSpoken = _normalizeBilingualToken(
      spoken,
      extraToddlerTolerance: isYoungToddler,
    );
    final String syllableGuide = buildSlowSyllableGuide(target);

    if (cleanSpoken.isEmpty) {
      return PronunciationEvaluation(
        stars: 1,
        feedbackMessage:
            'حنين تسمعك بحب يا بطل! استمع للمقاطع ببطء ($syllableGuide) وجرب معي مرة أخرى بصوتك الجميل 🌟',
        matchRatio: 0.25,
        supportiveTier: 'gentle_retry',
        syllableBreakdown: syllableGuide,
        ageToleranceApplied: isYoungToddler,
        isCorrect: false,
      );
    }

    final List<String> targetWords =
        cleanTarget.split(' ').where((w) => w.isNotEmpty).toList();
    final List<String> spokenWords =
        cleanSpoken.split(' ').where((w) => w.isNotEmpty).toList();

    if (targetWords.isEmpty) {
      return PronunciationEvaluation(
        stars: 3,
        feedbackMessage: 'رائع جداً يا بطل! نطق ممتاز وواضح 🌟',
        matchRatio: 1.0,
        supportiveTier: 'excellent',
        syllableBreakdown: syllableGuide,
        ageToleranceApplied: isYoungToddler,
        isCorrect: true,
      );
    }

    double matchedScore = 0;
    final List<String> matchedList = [];
    final List<String> missingList = [];

    for (final tw in targetWords) {
      bool exactHit = false;
      bool partialHit = false;
      for (final sw in spokenWords) {
        if (sw == tw || sw.contains(tw) || tw.contains(sw)) {
          exactHit = true;
          break;
        }
        if (sw.length >= 2 &&
            tw.length >= 2 &&
            sw.substring(0, 2) == tw.substring(0, 2)) {
          partialHit = true;
        } else if (sw.isNotEmpty && tw.isNotEmpty && sw[0] == tw[0]) {
          partialHit = true;
        }
      }
      if (exactHit) {
        matchedScore += 1.0;
        matchedList.add(tw);
      } else if (partialHit) {
        matchedScore += isYoungToddler ? 0.80 : 0.65;
        matchedList.add(tw);
      } else {
        missingList.add(tw);
      }
    }

    final double ratio = min(1.0, matchedScore / targetWords.length);
    final double threeStarThreshold = isYoungToddler ? 0.55 : 0.72;
    final double twoStarThreshold = isYoungToddler ? 0.25 : 0.35;

    if (ratio >= threeStarThreshold) {
      return PronunciationEvaluation(
        stars: 3,
        feedbackMessage:
            'ما شاء الله! حنين فخورة بنطقك الواضح والجميل يا بطل الفصاحة! ٣ نجوم ذهبية 🌟🌟🌟',
        matchRatio: ratio,
        supportiveTier: 'excellent',
        syllableBreakdown: syllableGuide,
        ageToleranceApplied: isYoungToddler,
        isCorrect: true,
        matchedWords: matchedList,
        missingOrWrongWords: missingList,
      );
    } else if (ratio >= twoStarThreshold) {
      return PronunciationEvaluation(
        stars: 2,
        feedbackMessage:
            'محاولة رائعة جداً يا بطل! نطقت الحروف بشكل جميل ($syllableGuide) — نجمتان للتشجيع 🌟🌟',
        matchRatio: ratio,
        supportiveTier: 'good_effort',
        syllableBreakdown: syllableGuide,
        ageToleranceApplied: isYoungToddler,
        isCorrect: true,
        matchedWords: matchedList,
        missingOrWrongWords: missingList,
      );
    } else {
      return PronunciationEvaluation(
        stars: 1,
        feedbackMessage:
            'صوتك جميل وشجاع يا بطل! لنستمع إليها مع حنين ببطء: ($syllableGuide) ونرددها معاً بهدوء 🌟',
        matchRatio: max(0.25, ratio),
        supportiveTier: 'gentle_retry',
        syllableBreakdown: syllableGuide,
        ageToleranceApplied: isYoungToddler,
        isCorrect: false,
        matchedWords: matchedList,
        missingOrWrongWords: missingList,
      );
    }
  }
}
