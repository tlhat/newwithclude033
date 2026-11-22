import 'dart:math';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class CognitiveSkillDomainScore {
  final String domainKey;
  final String titleAr;
  final String emoji;
  final int scorePercent; // 0..100
  final bool needsReinforcement;

  const CognitiveSkillDomainScore({
    required this.domainKey,
    required this.titleAr,
    required this.emoji,
    required this.scorePercent,
    required this.needsReinforcement,
  });
}

class AiTutorRecommendation {
  final String childId;
  final String childName;
  final int adaptiveDifficultyTier; // 1..4
  final int recommendedGameTabIndex; // 0..9 in BrainGamesHubScreen
  final String recommendedGameId;
  final String recommendedGameTitleAr;
  final String recommendedGameTitleEn;
  final int recommendedGameLevel; // 1..100
  final AcademyTrackLesson recommendedAcademyLesson;
  final String strongestDomainTitleAr;
  final String focusDomainTitleAr;
  final String haneenInteractiveVoicePromptAr;
  final String parentInsightSummaryAr;
  final List<CognitiveSkillDomainScore> domainScores;
  final Map<String, dynamic> privacySafeCloudPayload;
  final bool worksCompletelyOffline;

  const AiTutorRecommendation({
    required this.childId,
    required this.childName,
    required this.adaptiveDifficultyTier,
    required this.recommendedGameTabIndex,
    required this.recommendedGameId,
    required this.recommendedGameTitleAr,
    required this.recommendedGameTitleEn,
    required this.recommendedGameLevel,
    required this.recommendedAcademyLesson,
    required this.strongestDomainTitleAr,
    required this.focusDomainTitleAr,
    required this.haneenInteractiveVoicePromptAr,
    required this.parentInsightSummaryAr,
    required this.domainScores,
    required this.privacySafeCloudPayload,
    this.worksCompletelyOffline = true,
  });
}

/// Hybrid Offline-First Educational AI Tutor Service (`v3.8`).
/// - Operates 100% offline using a deterministic cognitive skill heuristic engine,
///   ensuring all core games and lessons work without internet or external API dependency.
/// - Analyzes each child's performance across memory, matching, classification, puzzles,
///   math, letters/words, pronunciation, and etiquette to select the best next game & lesson.
/// - Strictly privacy-preserving: never collects or transmits raw audio or unnecessary PII.
class EducationalAiTutorService {
  static const bool kRequiresInternetForCoreDecisions = false;
  static const bool kCollectsRawVoiceAudioOrPersonalPhotos = false;

  static List<CognitiveSkillDomainScore> computeDomainScores(
      ChildProfile child) {
    final Map<String, int> g = child.gameProgressByGameId;
    final int memoryLvl = g['memory_match_lvl'] ?? g['memory_match'] ?? 0;
    final int oddLvl = g['odd_one_out'] ?? 0;
    final int patternLvl = g['pattern_logic'] ?? 0;
    final int seqLvl = g['seq'] ?? 0;
    final int mathLvl = g['visual_math'] ?? g['quick_math'] ?? 0;
    final int wordLvl = g['arabic_word'] ?? 0;
    final int picMatchLvl = g['pic_match'] ?? 0;
    final int classifyLvl = g['classify'] ?? 0;
    final int soundLvl = g['sound_id'] ?? 0;
    final int etiquetteLvl = g['etiquette_draw'] ?? 0;

    int scoreFromLevelAndSaved(String key, int rawPoints) {
      final int saved = child.cognitiveSkillScoresByDomain[key] ?? 0;
      return max(saved, (35 + rawPoints * 12).clamp(35, 100));
    }

    final int memoryScore = scoreFromLevelAndSaved('memory_focus', memoryLvl);
    final int matchingScore =
        scoreFromLevelAndSaved('matching_shapes', picMatchLvl + (memoryLvl ~/ 2));
    final int classificationScore = scoreFromLevelAndSaved(
        'classification_sorting', classifyLvl + (oddLvl ~/ 2));
    final int puzzlesScore = scoreFromLevelAndSaved(
        'puzzles_logic', patternLvl + oddLvl + seqLvl);
    final int mathScore = scoreFromLevelAndSaved('math_counting', mathLvl);
    final int lettersScore = scoreFromLevelAndSaved(
        'letters_words', wordLvl + child.completedLessons.length);
    final int listeningScore = scoreFromLevelAndSaved(
        'listening_pronunciation',
        soundLvl + child.correctPronunciationsCount);
    final int etiquetteScore =
        scoreFromLevelAndSaved('etiquette_social', etiquetteLvl + 1);

    final List<Map<String, dynamic>> rawDomains = [
      {
        'key': 'memory_focus',
        'title': 'الذاكرة والتركيز البصري',
        'emoji': '🃏',
        'score': memoryScore,
      },
      {
        'key': 'matching_shapes',
        'title': 'المطابقة وربط الصور بالكلمات',
        'emoji': '🖼️',
        'score': matchingScore,
      },
      {
        'key': 'classification_sorting',
        'title': 'التصنيف والفرز المنطقي',
        'emoji': '🗂️',
        'score': classificationScore,
      },
      {
        'key': 'puzzles_logic',
        'title': 'الألغاز والتفكير المنطقي',
        'emoji': '🧩',
        'score': puzzlesScore,
      },
      {
        'key': 'math_counting',
        'title': 'الأرقام والحساب المبسط',
        'emoji': '🔢',
        'score': mathScore,
      },
      {
        'key': 'letters_words',
        'title': 'الحروف وتكوين الكلمات',
        'emoji': '🔤',
        'score': lettersScore,
      },
      {
        'key': 'listening_pronunciation',
        'title': 'الاستماع والنطق الواضح',
        'emoji': '🎙️',
        'score': listeningScore,
      },
      {
        'key': 'etiquette_social',
        'title': 'الآداب والسلوكيات الجميلة',
        'emoji': '🎨',
        'score': etiquetteScore,
      },
    ];

    return rawDomains
        .map(
          (d) => CognitiveSkillDomainScore(
            domainKey: d['key'] as String,
            titleAr: d['title'] as String,
            emoji: d['emoji'] as String,
            scorePercent: d['score'] as int,
            needsReinforcement: (d['score'] as int) < 65,
          ),
        )
        .toList();
  }

  /// Generates a personalized, non-repetitive Game + Lesson recommendation for `child`.
  static AiTutorRecommendation analyzeAndRecommendForChild(ChildProfile child) {
    final List<CognitiveSkillDomainScore> domains = computeDomainScores(child);
    final int adaptiveTier =
        HundredLevelGamesGenerator.computeAdaptiveDifficultyTier(
      ageGroup: child.age,
      currentCurriculumTier: child.currentCurriculumTier,
      gamesCompletedCount: child.gamesCompletedCount,
    );

    CognitiveSkillDomainScore strongest = domains.first;
    CognitiveSkillDomainScore lowest = domains.first;
    for (final d in domains) {
      if (d.scorePercent > strongest.scorePercent) strongest = d;
      if (d.scorePercent < lowest.scorePercent) lowest = d;
    }

    int targetGameTab = 3; // Default Memory Match
    String targetGameId = 'memory_match';
    String targetGameTitle = 'الذاكرة البصرية (١٠٠ مرحلة)';
    String targetGameTitleEn = 'Visual Memory (100 levels)';
    int currentLvl = (child.gameProgressByGameId['memory_match_lvl'] ?? 0) + 1;

    switch (lowest.domainKey) {
      case 'memory_focus':
        targetGameTab = 3;
        targetGameId = 'memory_match';
        targetGameTitle = 'الذاكرة البصرية المتدرجة';
        targetGameTitleEn = 'Progressive Visual Memory';
        currentLvl = (child.gameProgressByGameId['memory_match_lvl'] ?? 0) + 1;
        break;
      case 'matching_shapes':
        targetGameTab = 6;
        targetGameId = 'picture_word_match';
        targetGameTitle = 'مطابقة الصور والكلمات';
        targetGameTitleEn = 'Picture & Word Matching';
        currentLvl = (child.gameProgressByGameId['pic_match'] ?? 0) + 1;
        break;
      case 'classification_sorting':
        targetGameTab = 7;
        targetGameId = 'smart_classification';
        targetGameTitle = 'لعبة التصنيف الذكي';
        targetGameTitleEn = 'Smart Classification';
        currentLvl = (child.gameProgressByGameId['classify'] ?? 0) + 1;
        break;
      case 'puzzles_logic':
        targetGameTab = 2;
        targetGameId = 'pattern_logic';
        targetGameTitle = 'الألغاز وإكمال الأنماط';
        targetGameTitleEn = 'Puzzles & Pattern Completion';
        currentLvl = (child.gameProgressByGameId['pattern_logic'] ?? 0) + 1;
        break;
      case 'math_counting':
        targetGameTab = 4;
        targetGameId = 'quick_math';
        targetGameTitle = 'الحساب والجمع البصري';
        targetGameTitleEn = 'Visual Math & Addition';
        currentLvl = (child.gameProgressByGameId['visual_math'] ?? 0) + 1;
        break;
      case 'letters_words':
        targetGameTab = 5;
        targetGameId = 'arabic_word';
        targetGameTitle = 'الحروف وبناء الكلمات';
        targetGameTitleEn = 'Letters & Word Building';
        currentLvl = (child.gameProgressByGameId['arabic_word'] ?? 0) + 1;
        break;
      case 'listening_pronunciation':
        targetGameTab = 8;
        targetGameId = 'sound_recognition';
        targetGameTitle = 'أصوات الحيوانات والاستماع';
        targetGameTitleEn = 'Animal Sounds & Listening';
        currentLvl = (child.gameProgressByGameId['sound_id'] ?? 0) + 1;
        break;
      case 'etiquette_social':
        targetGameTab = 0;
        targetGameId = 'etiquette_board';
        targetGameTitle = 'مرسم الآداب والسلوك';
        targetGameTitleEn = 'Etiquette Drawing Studio';
        currentLvl = (child.gameProgressByGameId['etiquette_draw'] ?? 0) + 1;
        break;
    }

    final List<AcademyTrackLesson> recommendedLessons =
        AdaptiveLearningEngine.getRecommendedLessonsForChild(child);
    final AcademyTrackLesson nextLesson = recommendedLessons.isNotEmpty
        ? recommendedLessons.first
        : kHaneenAcademyCurriculum.first;

    final int clampedLevel = currentLvl.clamp(1, 100);
    final String haneenVoicePrompt =
        'مرحباً يا ${child.name}! أنا صديقتك حنين 🌟 لاحظت أنك رائع في «${strongest.titleAr}»، وأقترح عليك اليوم تحدياً ممتعاً في لعبة «$targetGameTitle» (المرحلة $clampedLevel) ثم درس «${nextLesson.title}» لنقوي مهارة «${lowest.titleAr}» معاً باللعب!';

    final String parentInsight =
        '🤖 تحليل المساعد التربوي الذكي: يتفوق ${child.name} في (${strongest.titleAr}: ${strongest.scorePercent}%)، ويقترح المحرك التركيز على (${lowest.titleAr}: ${lowest.scorePercent}%) عبر لعبة «$targetGameTitle» ودرس «${nextLesson.title}» بمستوى صعوبة تكيفي ($adaptiveTier من ٤).';

    final Map<String, int> numericSkillMap = {
      for (final d in domains) d.domainKey: d.scorePercent,
    };

    return AiTutorRecommendation(
      childId: child.id,
      childName: child.name,
      adaptiveDifficultyTier: adaptiveTier,
      recommendedGameTabIndex: targetGameTab,
      recommendedGameId: targetGameId,
      recommendedGameTitleAr: targetGameTitle,
      recommendedGameTitleEn: targetGameTitleEn,
      recommendedGameLevel: clampedLevel,
      recommendedAcademyLesson: nextLesson,
      strongestDomainTitleAr: '${strongest.emoji} ${strongest.titleAr}',
      focusDomainTitleAr: '${lowest.emoji} ${lowest.titleAr}',
      haneenInteractiveVoicePromptAr: haneenVoicePrompt,
      parentInsightSummaryAr: parentInsight,
      domainScores: domains,
      privacySafeCloudPayload: {
        'childId': child.id,
        'adaptiveDifficultyTier': adaptiveTier,
        'recommendedGameId': targetGameId,
        'recommendedLessonId': nextLesson.id,
        'cognitiveSkillScoresByDomain': numericSkillMap,
        'containsRawAudioOrPii': false,
      },
      worksCompletelyOffline: true,
    );
  }
}
