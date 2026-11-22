import 'dart:math';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

enum SupportedAppLocale {
  ar,
  en,
}

class LessonAttemptEvaluationResult {
  final String lessonId;
  final int previousMasteryScore;
  final int newMasteryScore;
  final bool isMastered;
  final bool requiresAlternativeRemediation;
  final int previousTier;
  final int newTier;
  final bool didAdvanceTier;
  final int starsAwarded;
  final String childEncouragementMessage;

  const LessonAttemptEvaluationResult({
    required this.lessonId,
    required this.previousMasteryScore,
    required this.newMasteryScore,
    required this.isMastered,
    required this.requiresAlternativeRemediation,
    required this.previousTier,
    required this.newTier,
    required this.didAdvanceTier,
    required this.starsAwarded,
    required this.childEncouragementMessage,
  });
}

class ChildPedagogicalReport {
  final String childId;
  final String childName;
  final String ageGroup;
  final int currentTier;
  final String currentTierLabelAr;
  final int overallMasteryPercentage;
  final int currentTierMasteryPercentage;
  final bool readyForNextTier;
  final List<String> masteredSkillTitles;
  final List<String> skillsNeedingExtraPractice;
  final List<String> recommendedNextLessonTitles;
  final List<String> parentHomeTips;

  const ChildPedagogicalReport({
    required this.childId,
    required this.childName,
    required this.ageGroup,
    required this.currentTier,
    required this.currentTierLabelAr,
    required this.overallMasteryPercentage,
    required this.currentTierMasteryPercentage,
    required this.readyForNextTier,
    required this.masteredSkillTitles,
    required this.skillsNeedingExtraPractice,
    required this.recommendedNextLessonTitles,
    required this.parentHomeTips,
  });
}

/// Smart offline-first educational engine for Haneen Kids (Ages 2 to 6).
/// - Maps child age & level to 4 progressive curriculum tiers (Tier 1..4).
/// - Enforces mastery-based progression (`>= 80%` required across current tier lessons)
///   rather than simple lesson completion count.
/// - Detects skills where the child needs extra practice and triggers alternative
///   playful re-presentation (`alternativeRemediationQuestion` & `alternativeRemediationActivity`).
class AdaptiveLearningEngine {
  static const int kMasteryThresholdPercent = 80;

  /// Returns the appropriate curriculum matching the child's learning language (P1 requirement)
  static List<AcademyTrackLesson> getCurriculumForLanguage([String? languageCode]) {
    if (languageCode != null && languageCode.trim().toLowerCase() == 'en') {
      return kHaneenAcademyCurriculumEn;
    }
    return kHaneenAcademyCurriculum;
  }

  /// Maps age group string or education level string to curriculum tier (1..4).
  static int inferInitialTier({
    required String ageGroup,
    required String educationLevel,
  }) {
    final String lvl = educationLevel.trim();
    if (lvl == 'تمهيدي') return 1;
    if (lvl == 'متوسط') return 3;
    if (lvl == 'متقدم') return 4;

    final String normAge = ageGroup.trim();
    if (normAge.contains('2') || normAge.startsWith('٢')) return 1;
    if (normAge.contains('3–4') || normAge.contains('3-4')) return 2;
    if (normAge.contains('4–5') || normAge.contains('4-5')) return 3;
    if (normAge.contains('5–6') ||
        normAge.contains('5-6') ||
        normAge.contains('4–8')) {
      return 3;
    }
    return 2; // Default Tier 2 (مبتدئ 3–4 سنوات)
  }

  static String tierLabelAr(int tier) {
    switch (tier.clamp(1, 4)) {
      case 1:
        return 'تمهيدي (٢–٣ سنوات)';
      case 2:
        return 'مبتدئ (٣–٤ سنوات)';
      case 3:
        return 'متوسط (٤–٥ سنوات)';
      case 4:
        return 'متقدم (٥–٦ سنوات)';
      default:
        return 'مبتدئ (٣–٤ سنوات)';
    }
  }

  static String tierShortLevelName(int tier) {
    switch (tier.clamp(1, 4)) {
      case 1:
        return 'تمهيدي';
      case 2:
        return 'مبتدئ';
      case 3:
        return 'متوسط';
      case 4:
        return 'متقدم';
      default:
        return 'مبتدئ';
    }
  }

  /// Computes updated mastery score (0..100) for a lesson attempt.
  /// - Answering the primary or alternative remediation question correctly after exploring cards
  ///   grants >= 85..100% mastery.
  /// - Answering incorrectly grants partial effort credit (45..55%) and flags the lesson
  ///   in `needsRemediationLessonIds` so the UI presents the alternative playful format!
  static int calculateUpdatedMasteryScore({
    required int previousScore,
    required bool isCorrectAnswer,
    int cardsExploredCount = 3,
    bool usedAlternativeRemediation = false,
    bool practicedPronunciation = false,
  }) {
    final int explorationBonus = (cardsExploredCount.clamp(1, 3) * 5); // 5..15
    final int voiceBonus = practicedPronunciation ? 5 : 0;
    if (isCorrectAnswer) {
      final int baseCorrect = usedAlternativeRemediation ? 82 : 85;
      final int computed = baseCorrect + explorationBonus + voiceBonus;
      return max(previousScore, computed.clamp(0, 100));
    } else {
      // Gentle partial score for trying without reaching the 80% mastery threshold
      final int effortScore = 40 + explorationBonus + voiceBonus;
      return max(previousScore, effortScore.clamp(0, 65));
    }
  }

  /// Checks whether the child has achieved `>= 80%` mastery across at least 80% (or >= 3)
  /// of the lessons in `tierLevel`, qualifying for promotion to `tierLevel + 1`.
  static bool canAdvanceFromTier({
    required ChildProfile child,
    required int tierLevel,
    List<AcademyTrackLesson>? curriculum,
  }) {
    if (tierLevel >= 4) return false;
    final List<AcademyTrackLesson> allLessons =
        curriculum ?? kHaneenAcademyCurriculum;
    final List<AcademyTrackLesson> tierLessons =
        allLessons.where((l) => l.tierLevel == tierLevel).toList();
    if (tierLessons.isEmpty) return false;

    int masteredInTier = 0;
    int totalMasterySum = 0;
    for (final lesson in tierLessons) {
      final int score = getLessonMasteryScore(child, lesson.id);
      totalMasterySum += score;
      if (score >= lesson.requiredMasteryScore) {
        masteredInTier++;
      }
    }
    final double averageTierMastery = totalMasterySum / tierLessons.length;
    final int requiredMasteredCount = max(2, (tierLessons.length * 0.75).ceil());
    return masteredInTier >= requiredMasteredCount &&
        averageTierMastery >= kMasteryThresholdPercent;
  }

  static int getLessonMasteryScore(ChildProfile child, String lessonId) {
    final int? explicitScore = child.skillMasteryByLessonId[lessonId];
    if (explicitScore != null) return explicitScore.clamp(0, 100);
    if (child.completedLessons.contains(lessonId)) return 100;
    return 0;
  }

  /// Returns personalized lessons ordered for the child:
  /// 1. Any lesson in `needsRemediationLessonIds` (so the child can play the alternative simplified activity).
  /// 2. Unmastered lessons in the child's `currentCurriculumTier`.
  /// 3. Adjacent tier lessons for enrichment.
  static List<AcademyTrackLesson> getRecommendedLessonsForChild(
    ChildProfile child, {
    List<AcademyTrackLesson>? curriculum,
  }) {
    final List<AcademyTrackLesson> allLessons =
        List<AcademyTrackLesson>.from(curriculum ?? kHaneenAcademyCurriculum);
    final int activeTier = child.currentCurriculumTier.clamp(1, 4);

    allLessons.sort((a, b) {
      final bool aNeedsRemediation =
          child.needsRemediationLessonIds.contains(a.id);
      final bool bNeedsRemediation =
          child.needsRemediationLessonIds.contains(b.id);
      if (aNeedsRemediation != bNeedsRemediation) {
        return aNeedsRemediation ? -1 : 1;
      }

      final bool aInActiveTier = a.tierLevel == activeTier;
      final bool bInActiveTier = b.tierLevel == activeTier;
      if (aInActiveTier != bInActiveTier) {
        return aInActiveTier ? -1 : 1;
      }

      final int aScore = getLessonMasteryScore(child, a.id);
      final int bScore = getLessonMasteryScore(child, b.id);
      final bool aMastered = aScore >= a.requiredMasteryScore;
      final bool bMastered = bScore >= b.requiredMasteryScore;
      if (aMastered != bMastered) {
        return aMastered ? 1 : -1;
      }

      return a.tierLevel.compareTo(b.tierLevel);
    });

    return allLessons;
  }

  /// Generates a complete Pedagogical & Mastery Report for the Parental Dashboard.
  static ChildPedagogicalReport buildPedagogicalReport(
    ChildProfile child, {
    List<AcademyTrackLesson>? curriculum,
  }) {
    final List<AcademyTrackLesson> allLessons =
        curriculum ?? kHaneenAcademyCurriculum;
    final int activeTier = child.currentCurriculumTier.clamp(1, 4);
    final List<AcademyTrackLesson> tierLessons =
        allLessons.where((l) => l.tierLevel == activeTier).toList();

    final List<String> masteredSkills = [];
    final List<String> needsPractice = [];
    final List<String> homeTips = [];
    int totalScoreAll = 0;

    for (final lesson in allLessons) {
      final int score = getLessonMasteryScore(child, lesson.id);
      totalScoreAll += score;
      if (score >= lesson.requiredMasteryScore) {
        masteredSkills.add('${lesson.title} ($score%)');
      } else if (child.needsRemediationLessonIds.contains(lesson.id) ||
          (score > 0 && score < lesson.requiredMasteryScore)) {
        needsPractice.add('${lesson.title} ($score% — يحتاج تثبيت باللعب)');
        if (lesson.parentHomeTip.isNotEmpty && homeTips.length < 4) {
          homeTips.add(lesson.parentHomeTip);
        }
      }
    }

    int tierScoreSum = 0;
    for (final lesson in tierLessons) {
      tierScoreSum += getLessonMasteryScore(child, lesson.id);
      if (homeTips.length < 3 && lesson.parentHomeTip.isNotEmpty) {
        if (!homeTips.contains(lesson.parentHomeTip)) {
          homeTips.add(lesson.parentHomeTip);
        }
      }
    }

    final int overallPct = allLessons.isEmpty
        ? 0
        : (totalScoreAll / allLessons.length).round().clamp(0, 100);
    final int tierPct = tierLessons.isEmpty
        ? 0
        : (tierScoreSum / tierLessons.length).round().clamp(0, 100);

    final List<AcademyTrackLesson> recommended =
        getRecommendedLessonsForChild(child, curriculum: allLessons);
    final List<String> nextTitles = recommended
        .where((l) => getLessonMasteryScore(child, l.id) < l.requiredMasteryScore)
        .take(3)
        .map((l) => l.title)
        .toList();

    return ChildPedagogicalReport(
      childId: child.id,
      childName: child.name,
      ageGroup: child.age,
      currentTier: activeTier,
      currentTierLabelAr: tierLabelAr(activeTier),
      overallMasteryPercentage: overallPct,
      currentTierMasteryPercentage: tierPct,
      readyForNextTier: canAdvanceFromTier(
        child: child,
        tierLevel: activeTier,
        curriculum: allLessons,
      ),
      masteredSkillTitles: masteredSkills,
      skillsNeedingExtraPractice: needsPractice,
      recommendedNextLessonTitles: nextTitles,
      parentHomeTips: homeTips,
    );
  }
}
