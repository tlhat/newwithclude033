import 'package:haneen_kids_vod/features/activities/services/adaptive_learning_engine.dart';
import 'package:haneen_kids_vod/features/activities/services/lesson_attempt_ledger.dart';
import 'package:haneen_kids_vod/features/companion/models/avatar_customization_model.dart';
import 'package:haneen_kids_vod/l10n/app_localizations.dart';

/// Standard internal curriculum tiers (P2 Global Expansion standard)
enum CurriculumTier {
  beginner,
  elementary,
  intermediate,
  advanced;

  static CurriculumTier fromInt(int tier) {
    switch (tier) {
      case 1:
        return CurriculumTier.beginner;
      case 2:
        return CurriculumTier.elementary;
      case 3:
        return CurriculumTier.intermediate;
      case 4:
        return CurriculumTier.advanced;
      default:
        return CurriculumTier.elementary;
    }
  }

  int toInt() {
    switch (this) {
      case CurriculumTier.beginner:
        return 1;
      case CurriculumTier.elementary:
        return 2;
      case CurriculumTier.intermediate:
        return 3;
      case CurriculumTier.advanced:
        return 4;
    }
  }

  String localizedLabel(AppLocalizations loc) {
    switch (this) {
      case CurriculumTier.beginner:
        return loc.tierBeginner;
      case CurriculumTier.elementary:
        return loc.tierElementary;
      case CurriculumTier.intermediate:
        return loc.tierIntermediate;
      case CurriculumTier.advanced:
        return loc.tierAdvanced;
    }
  }
}

class ChildActivityLogEntry {
  final String timestampIso;
  final String actionTitle;
  final String categoryBadge;

  const ChildActivityLogEntry({
    required this.timestampIso,
    required this.actionTitle,
    required this.categoryBadge,
  });

  factory ChildActivityLogEntry.fromJson(Map<String, dynamic> json) {
    return ChildActivityLogEntry(
      timestampIso: (json['timestampIso'] ?? DateTime.now().toIso8601String())
          .toString(),
      actionTitle: (json['actionTitle'] ?? '').toString(),
      categoryBadge: (json['categoryBadge'] ?? 'نشاط').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestampIso': timestampIso,
      'actionTitle': actionTitle,
      'categoryBadge': categoryBadge,
    };
  }
}

class ChildProfile {
  final String id;
  String name;
  String age;
  String gender;
  String educationLevel;
  int currentCurriculumTier;
  int dailyTimeLimit;
  int starsEarned;
  String chosenAvatar;
  AvatarCustomizationModel companionAvatar;
  int usedMinutesToday;
  int watchedVideosToday;
  int correctPronunciationsCount;
  int intelligencePoints;
  int gamesCompletedCount;
  /// Shown in the UI: the limit in minutes, or the infinity sign when none is set.
  String get limitShown => dailyTimeLimit > 0 ? '$dailyTimeLimit' : '∞';
  bool isDeviceRemotelyLocked;
  String remoteLockReasonMessage;
  String currentLiveStatus;
  String familyPairingCode;
  String lastActiveAcademyLessonId;
  bool allowMicrophone;
  bool allowExternalVideos;
  bool offlineOnlyMode;
  bool reduceMotion;
  bool highContrastMode;
  bool allowSoundEffectsAndVoice;
  bool lowMemoryPerformanceMode;
  String preferredVoicePersonaId;
  String preferredVoiceDialect;
  double preferredVoiceSpeed;
  List<String> completedActivities;
  List<String> completedLessons;
  Map<String, int> skillMasteryByLessonId;
  List<String> needsRemediationLessonIds;
  Map<String, int> cognitiveSkillScoresByDomain;
  Map<String, String> unlockedAchievements;
  List<String> unlockedCosmetics;
  List<String> favoriteStoryIds;
  List<String> practicedVocabulary;
  Map<String, int> gameProgressByGameId;
  List<String> likedVideoIds;
  List<ChildActivityLogEntry> liveActivityTimeline;
  Map<String, List<LessonAttemptRecord>> lessonAttemptsByLessonId;
  DateTime updatedAt;
  int syncVersionSeq;

  ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    this.gender = 'boy',
    this.educationLevel = 'مبتدئ',
    int? currentCurriculumTier,
    required this.dailyTimeLimit,
    this.starsEarned = 0,
    required this.chosenAvatar,
    AvatarCustomizationModel? companionAvatar,
    this.usedMinutesToday = 0,
    this.watchedVideosToday = 0,
    this.correctPronunciationsCount = 0,
    this.intelligencePoints = 10,
    this.gamesCompletedCount = 0,
    this.isDeviceRemotelyLocked = false,
    this.remoteLockReasonMessage =
        'تم قفل شاشة التطبيق الآن من هاتف ولي الأمر. حان وقت الراحة أو اللعب الواقعي يا بطل!',
    this.currentLiveStatus = 'متصل — يتصفح أكاديمية وقصص حنين',
    this.familyPairingCode = 'HK-8824',
    this.lastActiveAcademyLessonId = 'les_arabic_alif',
    this.allowMicrophone = true,
    this.allowExternalVideos = true,
    this.offlineOnlyMode = false,
    this.reduceMotion = false,
    this.highContrastMode = false,
    this.allowSoundEffectsAndVoice = true,
    this.lowMemoryPerformanceMode = false,
    this.preferredVoicePersonaId = 'haneen',
    this.preferredVoiceDialect = 'msa',
    this.preferredVoiceSpeed = 1.0,
    List<String>? completedActivities,
    List<String>? completedLessons,
    Map<String, int>? skillMasteryByLessonId,
    List<String>? needsRemediationLessonIds,
    Map<String, int>? cognitiveSkillScoresByDomain,
    Map<String, String>? unlockedAchievements,
    List<String>? unlockedCosmetics,
    List<String>? favoriteStoryIds,
    List<String>? practicedVocabulary,
    Map<String, int>? gameProgressByGameId,
    List<String>? likedVideoIds,
    List<ChildActivityLogEntry>? liveActivityTimeline,
    Map<String, List<LessonAttemptRecord>>? lessonAttemptsByLessonId,
    DateTime? updatedAt,
    this.syncVersionSeq = 1,
  })  : companionAvatar = companionAvatar ??
            AvatarCustomizationModel(
              gender: CompanionGender.fromJson(gender),
            ),
        currentCurriculumTier = currentCurriculumTier ??
            AdaptiveLearningEngine.inferInitialTier(
              ageGroup: age,
              educationLevel: educationLevel,
            ),
        updatedAt = updatedAt ?? DateTime.now(),
        completedActivities = completedActivities ?? [],
        completedLessons = completedLessons ?? [],
        skillMasteryByLessonId = skillMasteryByLessonId ?? {},
        needsRemediationLessonIds = needsRemediationLessonIds ?? [],
        cognitiveSkillScoresByDomain = cognitiveSkillScoresByDomain ?? {},
        unlockedAchievements = unlockedAchievements ?? {},
        unlockedCosmetics = unlockedCosmetics ?? ['hero_crown_basic'],
        favoriteStoryIds = favoriteStoryIds ?? [],
        practicedVocabulary = practicedVocabulary ?? [],
        gameProgressByGameId = gameProgressByGameId ?? {},
        likedVideoIds = likedVideoIds ?? [],
        lessonAttemptsByLessonId = lessonAttemptsByLessonId ?? {},
        liveActivityTimeline = liveActivityTimeline ??
            [
              ChildActivityLogEntry(
                timestampIso: DateTime.now().toIso8601String(),
                actionTitle: 'بدأ جلسة التعلم الآمنة على منصة حنين',
                categoryBadge: 'جلسة مباشرة',
              ),
            ];

  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    final Map<String, String> parsedAchievements = {};
    if (json['unlockedAchievements'] is Map) {
      (json['unlockedAchievements'] as Map).forEach((k, v) {
        parsedAchievements[k.toString()] = v.toString();
      });
    }
    final Map<String, int> parsedGameProgress = {};
    if (json['gameProgressByGameId'] is Map) {
      (json['gameProgressByGameId'] as Map).forEach((k, v) {
        parsedGameProgress[k.toString()] = int.tryParse(v.toString()) ?? 0;
      });
    }
    final Map<String, int> parsedSkillMastery = {};
    final dynamic rawSkillMastery =
        json['skillMasteryByLessonId'] ?? json['skill_mastery_by_lesson_id'];
    if (rawSkillMastery is Map) {
      rawSkillMastery.forEach((k, v) {
        parsedSkillMastery[k.toString()] =
            (int.tryParse(v.toString()) ?? 0).clamp(0, 100);
      });
    }
    final Map<String, int> parsedDomainScores = {};
    final dynamic rawDomainScores = json['cognitiveSkillScoresByDomain'] ??
        json['cognitive_skill_scores_by_domain'];
    if (rawDomainScores is Map) {
      rawDomainScores.forEach((k, v) {
        parsedDomainScores[k.toString()] =
            (int.tryParse(v.toString()) ?? 0).clamp(0, 100);
      });
    }
    final String parsedAge =
        (json['age'] ?? json['age_group'] ?? json['ageGroup'] ?? '3–6 سنوات').toString();
    final String parsedEduLevel =
        (json['educationLevel'] ?? json['education_level'] ?? 'مبتدئ').toString();

    final String parsedGender = (json['gender'] ?? 'boy').toString();
    AvatarCustomizationModel? parsedCompanion;
    if (json['companionAvatar'] is Map) {
      parsedCompanion = AvatarCustomizationModel.fromJson(
        Map<String, dynamic>.from(json['companionAvatar'] as Map),
      );
    } else if (json['companion_avatar'] is Map) {
      parsedCompanion = AvatarCustomizationModel.fromJson(
        Map<String, dynamic>.from(json['companion_avatar'] as Map),
      );
    }

    return ChildProfile(
      id: (json['id'] ?? 'child_${DateTime.now().millisecondsSinceEpoch}')
          .toString(),
      name: (json['name'] ?? json['display_name'] ?? json['displayName'] ?? 'فارس').toString(),
      age: parsedAge,
      gender: parsedGender,
      educationLevel: parsedEduLevel,
      companionAvatar: parsedCompanion,
      currentCurriculumTier: int.tryParse(
              (json['currentCurriculumTier'] ??
                      json['current_curriculum_tier'] ??
                      '')
                  .toString()) ??
          AdaptiveLearningEngine.inferInitialTier(
            ageGroup: parsedAge,
            educationLevel: parsedEduLevel,
          ),
      dailyTimeLimit: int.tryParse(
              (json['dailyTimeLimit'] ?? json['daily_time_limit'] ?? json['dailyQuota'] ?? '20')
                  .toString()) ??
          20,
      starsEarned: int.tryParse((json['starsEarned'] ?? json['stars_earned'])?.toString() ?? '0') ?? 0,
      chosenAvatar:
          (json['chosenAvatar'] ?? json['chosen_avatar'] ?? json['avatarEmoji'] ?? '🦁').toString(),
      usedMinutesToday:
          int.tryParse((json['usedMinutesToday'] ?? json['used_minutes_today'])?.toString() ?? '0') ?? 0,
      watchedVideosToday: int.tryParse(
              (json['watchedVideosToday'] ?? json['watched_videos_today'] ?? json['watchedToday'] ?? '0')
                  .toString()) ??
          0,
      correctPronunciationsCount: int.tryParse(
              (json['correctPronunciationsCount'] ?? json['correct_pronunciations_count'])?.toString() ?? '0') ??
          0,
      intelligencePoints:
          int.tryParse((json['intelligencePoints'] ?? json['intelligence_points'])?.toString() ?? '10') ?? 10,
      gamesCompletedCount:
          int.tryParse((json['gamesCompletedCount'] ?? json['games_completed_count'])?.toString() ?? '0') ?? 0,
      isDeviceRemotelyLocked: json['isDeviceRemotelyLocked'] == true || json['is_device_remotely_locked'] == true,
      remoteLockReasonMessage: (json['remoteLockReasonMessage'] ??
              json['remote_lock_reason_message'] ??
              'تم قفل شاشة التطبيق الآن من هاتف ولي الأمر. حان وقت الراحة يا بطل!')
          .toString(),
      currentLiveStatus:
          (json['currentLiveStatus'] ?? json['current_live_status'] ?? 'متصل — يتعلم في أكاديمية حنين')
              .toString(),
      familyPairingCode: (json['familyPairingCode'] ?? json['family_pairing_code'] ?? 'HK-8824').toString(),
      lastActiveAcademyLessonId:
          (json['lastActiveAcademyLessonId'] ?? json['last_active_academy_lesson_id'] ?? 'les_arabic_alif').toString(),
      allowMicrophone: (json['allowMicrophone'] ?? json['allow_microphone']) != false,
      allowExternalVideos: (json['allowExternalVideos'] ?? json['allow_external_videos']) != false,
      offlineOnlyMode: (json['offlineOnlyMode'] ?? json['offline_only_mode']) == true,
      reduceMotion: (json['reduceMotion'] ?? json['reduce_motion']) == true,
      highContrastMode: (json['highContrastMode'] ?? json['high_contrast_mode']) == true,
      allowSoundEffectsAndVoice:
          (json['allowSoundEffectsAndVoice'] ??
                  json['allow_sound_effects_and_voice']) !=
              false,
      lowMemoryPerformanceMode:
          (json['lowMemoryPerformanceMode'] ??
                  json['low_memory_performance_mode']) ==
              true,
      preferredVoicePersonaId: (json['preferredVoicePersonaId'] ??
              json['preferred_voice_persona_id'] ??
              'haneen')
          .toString(),
      preferredVoiceDialect: (json['preferredVoiceDialect'] ??
              json['preferred_voice_dialect'] ??
              'msa')
          .toString(),
      preferredVoiceSpeed: (double.tryParse((json['preferredVoiceSpeed'] ??
                      json['preferred_voice_speed'] ??
                      '1.0')
                  .toString()) ??
              1.0)
          .clamp(0.7, 1.2),
      completedActivities: (json['completedActivities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      completedLessons: (json['completedLessons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      skillMasteryByLessonId: parsedSkillMastery,
      needsRemediationLessonIds: ((json['needsRemediationLessonIds'] ??
                  json['needs_remediation_lesson_ids']) as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      cognitiveSkillScoresByDomain: parsedDomainScores,
      unlockedAchievements: parsedAchievements,
      unlockedCosmetics: (json['unlockedCosmetics'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['hero_crown_basic'],
      favoriteStoryIds: (json['favoriteStoryIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      practicedVocabulary: (json['practicedVocabulary'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      gameProgressByGameId: parsedGameProgress,
      likedVideoIds: (json['likedVideoIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      liveActivityTimeline: (json['liveActivityTimeline'] as List<dynamic>?)
              ?.map((e) => ChildActivityLogEntry.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      lessonAttemptsByLessonId:
          LessonAttemptLedgerEngine.ledgerFromJson(json['lessonAttemptsByLessonId']),
      updatedAt: DateTime.tryParse(
              (json['updatedAt'] ?? json['updated_at'] ?? '').toString()) ??
          DateTime.now(),
      syncVersionSeq: int.tryParse(
              (json['syncVersionSeq'] ?? json['sync_version_seq'] ?? '1')
                  .toString()) ??
          1,
    );
  }

  void touchSyncVersion() {
    updatedAt = DateTime.now();
    syncVersionSeq++;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'companionAvatar': companionAvatar.toJson(),
      'educationLevel': educationLevel,
      'currentCurriculumTier': currentCurriculumTier,
      'dailyTimeLimit': dailyTimeLimit,
      'starsEarned': starsEarned,
      'chosenAvatar': chosenAvatar,
      'usedMinutesToday': usedMinutesToday,
      'watchedVideosToday': watchedVideosToday,
      'correctPronunciationsCount': correctPronunciationsCount,
      'intelligencePoints': intelligencePoints,
      'gamesCompletedCount': gamesCompletedCount,
      'isDeviceRemotelyLocked': isDeviceRemotelyLocked,
      'remoteLockReasonMessage': remoteLockReasonMessage,
      'currentLiveStatus': currentLiveStatus,
      'familyPairingCode': familyPairingCode,
      'lastActiveAcademyLessonId': lastActiveAcademyLessonId,
      'allowMicrophone': allowMicrophone,
      'allowExternalVideos': allowExternalVideos,
      'offlineOnlyMode': offlineOnlyMode,
      'reduceMotion': reduceMotion,
      'highContrastMode': highContrastMode,
      'allowSoundEffectsAndVoice': allowSoundEffectsAndVoice,
      'lowMemoryPerformanceMode': lowMemoryPerformanceMode,
      'preferredVoicePersonaId': preferredVoicePersonaId,
      'preferredVoiceDialect': preferredVoiceDialect,
      'preferredVoiceSpeed': preferredVoiceSpeed,
      'completedActivities': completedActivities,
      'completedLessons': completedLessons,
      'skillMasteryByLessonId': skillMasteryByLessonId,
      'needsRemediationLessonIds': needsRemediationLessonIds,
      'cognitiveSkillScoresByDomain': cognitiveSkillScoresByDomain,
      'unlockedAchievements': unlockedAchievements,
      'unlockedCosmetics': unlockedCosmetics,
      'favoriteStoryIds': favoriteStoryIds,
      'practicedVocabulary': practicedVocabulary,
      'gameProgressByGameId': gameProgressByGameId,
      'likedVideoIds': likedVideoIds,
      'liveActivityTimeline':
          liveActivityTimeline.map((e) => e.toJson()).toList(),
      'lessonAttemptsByLessonId':
          LessonAttemptLedgerEngine.ledgerToJson(lessonAttemptsByLessonId),
      'updatedAt': updatedAt.toIso8601String(),
      'syncVersionSeq': syncVersionSeq,
    };
  }

  /// Maps ChildProfile to Supabase PostgreSQL snake_case columns
  Map<String, dynamic> toSupabaseRow({required String parentId}) {
    return {
      'id': id,
      'parent_id': parentId,
      'display_name': name,
      'age_group': age,
      'gender': gender,
      'companion_avatar': companionAvatar.toJson(),
      'chosen_avatar': chosenAvatar,
      'education_level': educationLevel,
      'daily_time_limit': dailyTimeLimit,
      'used_minutes_today': usedMinutesToday,
      'watched_videos_today': watchedVideosToday,
      'stars_earned': starsEarned,
      'intelligence_points': intelligencePoints,
      'games_completed_count': gamesCompletedCount,
      'correct_pronunciations_count': correctPronunciationsCount,
      'allow_microphone': allowMicrophone,
      'allow_external_videos': allowExternalVideos,
      'offline_only_mode': offlineOnlyMode,
      'reduce_motion': reduceMotion,
      'high_contrast_mode': highContrastMode,
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
