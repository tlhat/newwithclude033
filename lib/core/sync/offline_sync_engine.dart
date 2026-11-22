import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:haneen_kids_vod/haneen_kids_exports.dart';

class SyncMutationRecord {
  final String idempotencyKey;
  final String parentEmail;
  final String childId;
  final String entityType;
  final String entityId;
  final String operation;
  final Map<String, dynamic> payload;
  final String clientTimestampIso;
  int retryCount;

  SyncMutationRecord({
    required this.idempotencyKey,
    required this.parentEmail,
    this.childId = '',
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    String? clientTimestampIso,
    this.retryCount = 0,
  }) : clientTimestampIso =
            clientTimestampIso ?? DateTime.now().toIso8601String();

  Map<String, dynamic> toJson() => {
        'idempotencyKey': idempotencyKey,
        'parentEmail': parentEmail,
        'childId': childId,
        'entityType': entityType,
        'entityId': entityId,
        'operation': operation,
        'payload': payload,
        'clientTimestampIso': clientTimestampIso,
        'retryCount': retryCount,
      };

  factory SyncMutationRecord.fromJson(Map<String, dynamic> json) {
    return SyncMutationRecord(
      idempotencyKey: (json['idempotencyKey'] ?? '').toString(),
      parentEmail: (json['parentEmail'] ?? '').toString(),
      childId: (json['childId'] ?? '').toString(),
      entityType: (json['entityType'] ?? 'child_profile').toString(),
      entityId: (json['entityId'] ?? '').toString(),
      operation: (json['operation'] ?? 'upsert').toString(),
      payload: json['payload'] is Map
          ? Map<String, dynamic>.from(json['payload'] as Map)
          : <String, dynamic>{},
      clientTimestampIso:
          (json['clientTimestampIso'] ?? DateTime.now().toIso8601String())
              .toString(),
      retryCount: int.tryParse(json['retryCount']?.toString() ?? '0') ?? 0,
    );
  }
}

class ChildSyncConflictResolver {
  static ChildProfile resolveConflict({
    required ChildProfile local,
    required ChildProfile remote,
  }) {
    final bool remoteIsNewer = remote.updatedAt.isAfter(local.updatedAt) ||
        (remote.updatedAt.isAtSameMomentAs(local.updatedAt) &&
            remote.syncVersionSeq > local.syncVersionSeq);

    final ChildProfile baseSettings = remoteIsNewer ? remote : local;

    final List<String> mergedLessons = <String>{
      ...local.completedLessons,
      ...remote.completedLessons,
    }.toList();

    final List<String> mergedActivities = <String>{
      ...local.completedActivities,
      ...remote.completedActivities,
    }.toList();

    final List<String> mergedVocab = <String>{
      ...local.practicedVocabulary,
      ...remote.practicedVocabulary,
    }.toList();

    final List<String> mergedFavorites = <String>{
      ...local.favoriteStoryIds,
      ...remote.favoriteStoryIds,
    }.toList();

    final List<String> mergedLikes = <String>{
      ...local.likedVideoIds,
      ...remote.likedVideoIds,
    }.toList();

    final List<String> mergedCosmetics = <String>{
      'hero_crown_basic',
      ...local.unlockedCosmetics,
      ...remote.unlockedCosmetics,
    }.toList();

    final Map<String, String> mergedAchievements = <String, String>{
      ...remote.unlockedAchievements,
      ...local.unlockedAchievements,
    };

    final Map<String, int> mergedGames = <String, int>{
      ...local.gameProgressByGameId,
    };
    remote.gameProgressByGameId.forEach((gameId, remoteLvl) {
      final int localLvl = mergedGames[gameId] ?? 0;
      if (remoteLvl > localLvl) {
        mergedGames[gameId] = remoteLvl;
      }
    });

    final Map<String, int> mergedMastery = <String, int>{
      ...local.skillMasteryByLessonId,
    };
    remote.skillMasteryByLessonId.forEach((lessonId, remoteScore) {
      final int localScore = mergedMastery[lessonId] ?? 0;
      if (remoteScore > localScore) {
        mergedMastery[lessonId] = remoteScore;
      }
    });

    final Map<String, int> mergedCognitiveDomains = <String, int>{
      ...local.cognitiveSkillScoresByDomain,
    };
    remote.cognitiveSkillScoresByDomain.forEach((domainKey, remoteScore) {
      final int localScore = mergedCognitiveDomains[domainKey] ?? 0;
      if (remoteScore > localScore) {
        mergedCognitiveDomains[domainKey] = remoteScore;
      }
    });

    final List<String> mergedRemediation = <String>{
      ...local.needsRemediationLessonIds,
      ...remote.needsRemediationLessonIds,
    }
        .where((lessonId) =>
            (mergedMastery[lessonId] ?? 0) <
            AdaptiveLearningEngine.kMasteryThresholdPercent)
        .toList();

    final int newlyMergedLessonsCount = mergedLessons.length -
        max(local.completedLessons.length, remote.completedLessons.length);
    final int newlyMergedActivitiesCount = mergedActivities.length -
        max(local.completedActivities.length,
            remote.completedActivities.length);

    final int mergedStars = max(local.starsEarned, remote.starsEarned) +
        (max(0, newlyMergedLessonsCount) * 2) +
        (max(0, newlyMergedActivitiesCount) * 2);

    final int mergedIq =
        max(local.intelligencePoints, remote.intelligencePoints) +
            (max(0, newlyMergedLessonsCount) * 15) +
            (max(0, newlyMergedActivitiesCount) * 15);

    final Map<String, ChildActivityLogEntry> uniqueLogs = {};
    for (final entry in [
      ...local.liveActivityTimeline,
      ...remote.liveActivityTimeline
    ]) {
      uniqueLogs['${entry.timestampIso}_${entry.actionTitle}'] = entry;
    }
    final List<ChildActivityLogEntry> mergedTimeline =
        uniqueLogs.values.toList()
          ..sort((a, b) => b.timestampIso.compareTo(a.timestampIso));
    final List<ChildActivityLogEntry> cappedTimeline =
        mergedTimeline.take(35).toList();

    final Set<String> mergedCompanionUnlocked = {
      ...local.companionAvatar.unlockedItems,
      ...remote.companionAvatar.unlockedItems,
    };
    final resolvedCompanion = baseSettings.companionAvatar.copyWith(
      unlockedItems: mergedCompanionUnlocked.toList(),
    );

    // Phase 2: lesson attempt ledger union merge (union by record id,
    // newest timestamp wins, re-capped to 10 per lesson, idempotent).
    final Map<String, List<LessonAttemptRecord>> mergedLessonAttempts =
        LessonAttemptLedgerEngine.mergeLedgers(
      local.lessonAttemptsByLessonId,
      remote.lessonAttemptsByLessonId,
    );

    final ChildProfile resolved = ChildProfile(
      id: local.id,
      name: baseSettings.name,
      age: baseSettings.age,
      gender: baseSettings.gender,
      companionAvatar: resolvedCompanion,
      educationLevel: baseSettings.educationLevel,
      currentCurriculumTier: max(
        local.currentCurriculumTier,
        remote.currentCurriculumTier,
      ),
      dailyTimeLimit: baseSettings.dailyTimeLimit,
      starsEarned: mergedStars,
      chosenAvatar: baseSettings.chosenAvatar,
      usedMinutesToday: max(local.usedMinutesToday, remote.usedMinutesToday),
      watchedVideosToday:
          max(local.watchedVideosToday, remote.watchedVideosToday),
      correctPronunciationsCount: max(local.correctPronunciationsCount,
          remote.correctPronunciationsCount),
      intelligencePoints: mergedIq,
      gamesCompletedCount:
          max(local.gamesCompletedCount, remote.gamesCompletedCount),
      isDeviceRemotelyLocked: baseSettings.isDeviceRemotelyLocked,
      remoteLockReasonMessage: baseSettings.remoteLockReasonMessage,
      currentLiveStatus: baseSettings.currentLiveStatus,
      familyPairingCode: baseSettings.familyPairingCode,
      lastActiveAcademyLessonId: baseSettings.lastActiveAcademyLessonId,
      allowMicrophone: baseSettings.allowMicrophone,
      allowExternalVideos: baseSettings.allowExternalVideos,
      offlineOnlyMode: baseSettings.offlineOnlyMode,
      reduceMotion: baseSettings.reduceMotion,
      highContrastMode: baseSettings.highContrastMode,
      allowSoundEffectsAndVoice: baseSettings.allowSoundEffectsAndVoice,
      lowMemoryPerformanceMode: baseSettings.lowMemoryPerformanceMode,
      preferredVoicePersonaId: baseSettings.preferredVoicePersonaId,
      preferredVoiceDialect: baseSettings.preferredVoiceDialect,
      preferredVoiceSpeed: baseSettings.preferredVoiceSpeed,
      completedActivities: mergedActivities,
      completedLessons: mergedLessons,
      skillMasteryByLessonId: mergedMastery,
      needsRemediationLessonIds: mergedRemediation,
      cognitiveSkillScoresByDomain: mergedCognitiveDomains,
      unlockedAchievements: mergedAchievements,
      unlockedCosmetics: mergedCosmetics,
      favoriteStoryIds: mergedFavorites,
      practicedVocabulary: mergedVocab,
      gameProgressByGameId: mergedGames,
      likedVideoIds: mergedLikes,
      liveActivityTimeline: cappedTimeline,
      lessonAttemptsByLessonId: mergedLessonAttempts,
      updatedAt: remoteIsNewer ? remote.updatedAt : local.updatedAt,
      syncVersionSeq: max(local.syncVersionSeq, remote.syncVersionSeq) + 1,
    );
    return resolved;
  }
}

class OfflineSyncQueueService {
  static const String kOutboxStorageKey = 'supabase_offline_sync_outbox_v36';
  static const String kAppliedKeysStorageKey =
      'supabase_applied_idempotency_keys_v36';

  final SharedPreferences _prefs;
  final String prefix;
  final List<SyncMutationRecord> _pendingQueue = [];
  final Set<String> _appliedIdempotencyKeys = {};

  OfflineSyncQueueService(this._prefs, {this.prefix = ''}) {
    _loadFromPrefs();
  }

  String get outboxKey => '$prefix$kOutboxStorageKey';
  String get appliedKeysKey => '$prefix$kAppliedKeysStorageKey';

  List<SyncMutationRecord> get pendingQueue =>
      List.unmodifiable(_pendingQueue);

  Set<String> get appliedIdempotencyKeys =>
      Set.unmodifiable(_appliedIdempotencyKeys);

  int get pendingCount => _pendingQueue.length;

  void _loadFromPrefs() {
    _pendingQueue.clear();
    _appliedIdempotencyKeys.clear();
    String? rawQueue = _prefs.getString(outboxKey);
    if ((rawQueue == null || rawQueue.isEmpty) && prefix.isNotEmpty) {
      rawQueue = _prefs.getString(kOutboxStorageKey);
    }
    if (rawQueue != null && rawQueue.isNotEmpty) {
      try {
        final List<dynamic> list = jsonDecode(rawQueue);
        for (final item in list) {
          if (item is Map) {
            _pendingQueue.add(
                SyncMutationRecord.fromJson(Map<String, dynamic>.from(item)));
          }
        }
      } catch (_) {}
    }
    List<String>? savedApplied = _prefs.getStringList(appliedKeysKey);
    if ((savedApplied == null || savedApplied.isEmpty) && prefix.isNotEmpty) {
      savedApplied = _prefs.getStringList(kAppliedKeysStorageKey);
    }
    if (savedApplied != null) {
      _appliedIdempotencyKeys.addAll(savedApplied);
    }
  }

  Future<void> _persistToPrefs() async {
    final String raw =
        jsonEncode(_pendingQueue.map((e) => e.toJson()).toList());
    final List<String> applied = _appliedIdempotencyKeys.take(500).toList();
    await _prefs.setString(outboxKey, raw);
    await _prefs.setStringList(appliedKeysKey, applied);
    if (prefix.isNotEmpty) {
      await _prefs.setString(kOutboxStorageKey, raw);
      await _prefs.setStringList(kAppliedKeysStorageKey, applied);
    }
  }

  Future<bool> enqueueMutation(SyncMutationRecord record) async {
    final String key = record.idempotencyKey.trim();
    if (key.isEmpty) return false;
    if (_appliedIdempotencyKeys.contains(key)) {
      return false;
    }
    final int existingIdx =
        _pendingQueue.indexWhere((m) => m.idempotencyKey == key);
    if (existingIdx != -1) {
      _pendingQueue[existingIdx] = record;
    } else {
      _pendingQueue.add(record);
    }
    await _persistToPrefs();
    return true;
  }

  Future<void> markMutationsApplied(Iterable<String> keys) async {
    final Set<String> keySet = keys.map((k) => k.trim()).toSet();
    _pendingQueue.removeWhere((m) => keySet.contains(m.idempotencyKey));
    _appliedIdempotencyKeys.addAll(keySet);
    await _persistToPrefs();
  }

  Future<void> removePendingMutationsForChild(String childId) async {
    _pendingQueue.removeWhere((m) => m.childId == childId);
    await _persistToPrefs();
  }

  Future<void> clearAllForParent(String parentEmail) async {
    final String norm = parentEmail.trim().toLowerCase();
    _pendingQueue
        .removeWhere((m) => m.parentEmail.trim().toLowerCase() == norm);
    await _persistToPrefs();
  }
}
