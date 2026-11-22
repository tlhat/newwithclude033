import 'package:haneen_kids_vod/haneen_kids_exports.dart';

/// Phase 4: offline, deterministic bridge from the Phase 2 lesson attempt
/// ledger to the existing AdaptiveLearningEngine recommendations.
///
/// - Derives per-lesson mastery levels from ledger history.
/// - Detects repeated mistakes / weak concepts and triggers remediation
///   by feeding `needsRemediationLessonIds` (no scores are mutated).
/// - Recommends the next lesson (reusing the engine's ordering) and a
///   brain game (reusing `EducationalAiTutorService`), with gradual
///   difficulty adjustment only.
class LessonProgressBridgeResult {
  final List<String> weakLessonIds;
  final List<String> remediationLessonIds;
  final AcademyTrackLesson nextLesson;
  final LessonMasteryLevel nextLessonMastery;
  final AiTutorRecommendation gameRecommendation;
  final bool triggeredRemediation;
  final String recommendationMessageAr;

  LessonProgressBridgeResult({
    required this.weakLessonIds,
    required this.remediationLessonIds,
    required this.nextLesson,
    required this.nextLessonMastery,
    required this.gameRecommendation,
    required this.triggeredRemediation,
    required this.recommendationMessageAr,
  });
}

class LessonProgressBridge {
  /// A lesson is weak when its ledger shows a `repeatedMistake` in the
  /// latest 3 attempts, or >= 2 `incorrect`/`repeatedMistake` in the
  /// latest 4 attempts.
  static bool isWeakLesson(List<LessonAttemptRecord> records) {
    if (records.isEmpty) return false;
    final List<LessonAttemptRecord> latest3 = records.take(3).toList();
    if (latest3
        .any((r) => r.outcome == LessonAttemptOutcome.repeatedMistake)) {
      return true;
    }
    final List<LessonAttemptRecord> latest4 = records.take(4).toList();
    final int failures = latest4
        .where((r) =>
            r.outcome == LessonAttemptOutcome.incorrect ||
            r.outcome == LessonAttemptOutcome.repeatedMistake)
        .length;
    return failures >= 2;
  }

  /// Bridges the ledger to engine recommendations. Pure function:
  /// returns derived lists; the caller applies them to the profile.
  static LessonProgressBridgeResult analyze({
    required ChildProfile child,
    List<AcademyTrackLesson>? curriculum,
  }) {
    final List<AcademyTrackLesson> allLessons =
        curriculum ?? AdaptiveLearningEngine.getCurriculumForLanguage();

    // 1) Weak lessons from ledger history (repeated mistakes).
    final List<String> weakLessonIds = <String>[];
    for (final MapEntry<String, List<LessonAttemptRecord>> entry
        in child.lessonAttemptsByLessonId.entries) {
      if (isWeakLesson(entry.value)) {
        weakLessonIds.add(entry.key);
      }
    }

    // 2) Remediation = weak lessons not already flagged for remediation.
    final List<String> remediationLessonIds = weakLessonIds
        .where((id) => !child.needsRemediationLessonIds.contains(id))
        .toList();

    // 3) Next lesson: reuse engine ordering with remediation ids merged in.
    // `ChildProfile` has no copyWith; assign-restore is synchronous and
    // side-effect free (identical list restored even on throw).
    final List<String> originalRemediation = child.needsRemediationLessonIds;
    AcademyTrackLesson nextLesson;
    try {
      child.needsRemediationLessonIds = [
        ...originalRemediation,
        ...remediationLessonIds,
      ];
      nextLesson = AdaptiveLearningEngine.getRecommendedLessonsForChild(
        child,
        curriculum: allLessons,
      ).first;
    } finally {
      child.needsRemediationLessonIds = originalRemediation;
    }

    final LessonMasteryLevel nextMastery =
        LessonAttemptLedgerEngine.deriveMasteryLevel(
      records: child.lessonAttemptsByLessonId[nextLesson.id] ?? const [],
      existingMasteryScore:
          AdaptiveLearningEngine.getLessonMasteryScore(child, nextLesson.id),
      requiredMasteryScore: nextLesson.requiredMasteryScore,
    );

    // 4) Brain game recommendation + gradual difficulty (existing service).
    final AiTutorRecommendation gameRec =
        EducationalAiTutorService.analyzeAndRecommendForChild(child);

    final bool triggered = remediationLessonIds.isNotEmpty;
    final String message = triggered
        ? 'يتطلب مفهوم «${nextLesson.title}» تدريباً إضافياً — سنبدأ بمراجعة لطيفة ثم نكمل!'
        : 'أحسنت! جاهز للدرس التالي: «${nextLesson.title}» 🌟';

    return LessonProgressBridgeResult(
      weakLessonIds: weakLessonIds..sort(),
      remediationLessonIds: remediationLessonIds..sort(),
      nextLesson: nextLesson,
      nextLessonMastery: nextMastery,
      gameRecommendation: gameRec,
      triggeredRemediation: triggered,
      recommendationMessageAr: message,
    );
  }
}
